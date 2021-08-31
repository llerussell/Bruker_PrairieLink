function [ops] = setup_registration_phasecorr(refImg)
% Setup variables necessary for phase correlation registration
% Marius Pachitariu/Carsen Stringer Suite2P (2017)
% Modified by Henry Dalgleish for online image registration (2018)

[ops.ly,ops.lx] = size(refImg);
ops.yx_px       = [1:ops.ly ; 1:ops.lx]';

% Parameters
ops.subpixel    = 10;   % subpixel factor
ops.maskSlope   = 2;    % slope on taper mask preapplied to image.
ops.smoothSigma = 1.15; % SD pixels of gaussian smoothing applied to correlation map
ops.lpad        = 3;
ops.maxregshift = 0.1*max([ops.ly ops.lx]);

% Taper mask
[ys, xs] = ndgrid(1:ops.ly, 1:ops.lx);
ys = abs(ys - mean(ys(:)));
xs = abs(xs - mean(xs(:)));
mY = max(ys(:)) - 4;
mX = max(xs(:)) - 4;
ops.maskMul = single(1./(1 + exp((ys - mY)/ops.maskSlope)) ./(1 + exp((xs - mX)/ops.maskSlope)));
ops.maskOffset = mean(refImg(:))*(1 - ops.maskMul);

% Smoothing filter in frequency domain
hgx = exp(-(((0:ops.lx-1) - fix(ops.lx/2))/ops.smoothSigma).^2);
hgy = exp(-(((0:ops.ly-1) - fix(ops.ly/2))/ops.smoothSigma).^2);
hg = hgy'*hgx;
fhg = real(fftn(ifftshift(single(hg/sum(hg(:))))));

% fft of reference image 
ops.eps0     = single(1e-10);
ops.cfRefImg = conj(fftn(refImg));
ops.absRef   = abs(ops.cfRefImg);
ops.cfRefImg = ops.cfRefImg./(ops.eps0 + ops.absRef) .* fhg;

% allow max shifts +/- ops.lcorr
ops.lcorr  = round(min(ops.maxregshift, floor(min(ops.ly,ops.lx)/2)-ops.lpad));

% only need a small kernel +/- ops.lpad for smoothing
[x1,x2] = ndgrid([-ops.lpad:ops.lpad]);
xt = [x1(:) x2(:)]';

% compute kernels for regression
sigL     = .85; % kernel width in pixels
Kx = kernelD(xt,xt,sigL*[1;1]);
ops.linds = [-ops.lpad:1/ops.subpixel:ops.lpad];
[x1,x2] = ndgrid(ops.linds);
xg = [x1(:) x2(:)]';
Kg = kernelD(xg,xt,sigL*[1;1]);
ops.Kmat = Kg/Kx;

% setup region to register
ops.Nyx = ifftshift([(-fix(ops.ly/2):ceil(ops.ly/2)-1) ; (-fix(ops.lx/2):ceil(ops.lx/2)-1)]);
[ops.Nx,ops.Ny] = meshgrid(ops.Nyx(2,:),ops.Nyx(1,:));
ops.Nx = ops.Nx / ops.lx;
ops.Ny = ops.Ny / ops.ly;
ops.dl = -ops.lpad:1:ops.lpad;

if 1
    ops.dl = gpuArray(single(ops.dl));
    ops.lx = gpuArray(single(ops.lx));
    ops.ly = gpuArray(single(ops.ly));
    ops.Nyx = gpuArray(single(ops.Nyx));
    ops.Nx = gpuArray(single(ops.Nx));
    ops.Ny = gpuArray(single(ops.Ny));
    ops.yx_px = gpuArray(single(ops.yx_px));
    ops.linds = gpuArray(single(ops.linds));
    ops.maskMul = gpuArray(single(ops.maskMul));
    ops.maskOffset = gpuArray(single(ops.maskOffset));
    ops.cfRefImg = gpuArray(single(ops.cfRefImg));
    ops.absRef = gpuArray(single(ops.absRef));
    ops.Kmat = gpuArray(single(ops.Kmat));
else
    ops.dl = single(ops.dl);
    ops.lx = single(ops.lx);
    ops.ly = single(ops.ly);
    ops.Nyx = single(ops.Nyx);
    ops.Nx = single(ops.Nx);
    ops.Ny = single(ops.Ny);
    ops.yx_px = single(ops.yx_px);
    ops.linds = single(ops.linds);
    ops.maskMul = single(ops.maskMul);
    ops.maskOffset = single(ops.maskOffset);
    ops.cfRefImg = single(ops.cfRefImg);
    ops.absRef = single(ops.absRef);
    ops.Kmat = single(ops.Kmat);
end



end

