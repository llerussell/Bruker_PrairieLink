function [regFrame,dv0,cx] = return_offsets_phasecorr_batch(frame,ops)
% Do phase correlation registration (sub-pixel with kriging) on a single
% frame using pre-calculated registration variables (ops)

% use with setup_registration_phasecorr.m
% e.g:
% [ops] = setup_registration_phasecorr(refImg)
% [dv0,cx] = return_offsets_phasecorr(frame,ops)

% Marius Pachitariu/Carsen Stringer Suite2P (2017)
% Modified by Henry Dalgleish for online image registration (2018)

% NB all input images must be of the same class

% prepare correlation map
%corrMap = fft2((ops.maskMul .* frame) + ops.maskOffset);
%corrMap = (corrMap./(ops.eps0 + abs(corrMap))) .* ops.cfRefImg;
numFrames = gpuArray(size(frame,3));
corrMap = fft2(bsxfun(@plus, ops.maskOffset, bsxfun(@times, ops.maskMul, frame)));
corrMap = bsxfun(@times, corrMap./(ops.eps0 + abs(corrMap)), ops.cfRefImg);

% compute correlation matrix
corrClip = fftshift(fftshift(real(ifft2(corrMap)), 1), 2);

% subpixel registration, kriging subpixel, allow only +/- ops.lcorr shifts
%[~,ii] = max(reshape(corrClip(floor(ops.ly/2)+1+[-ops.lcorr:ops.lcorr],floor(ops.lx/2)+1+[-ops.lcorr:ops.lcorr],:),[],1));
[~,ii] = max(reshape(corrClip(floor(ops.ly/2)+1+[-ops.lcorr:ops.lcorr],floor(ops.lx/2)+1+[-ops.lcorr:ops.lcorr],:), [], numFrames),[],1);
[iy, ix] = ind2sub((2*ops.lcorr+1) * [1 1], ii);
mxpt = [iy(:)+floor(ops.ly/2) ix(:)+floor(ops.lx/2)] - ops.lcorr;


% matrix +/- ops.lpad surrounding max point, regress onto subsampled grid, find max of grid
% [cx,ix]     = max(ops.Kmat * reshape(corrClip(mxpt(1)+ops.dl, mxpt(2)+ops.dl),[],1), [], 1);
% [ix11,ix21] = ind2sub(numel(ops.linds)*[1 1],ix);

dl = single(gpuArray(-ops.lpad:1:ops.lpad));
ccmat = gpuArray.zeros(numel(dl), numel(dl), numFrames, 'single');
parfor j = 1:numFrames
    ccmat(:, :, j) = corrClip(mxpt(j,1)+dl, mxpt(j,2)+dl, j);
end
ccmat = reshape(ccmat,[], numFrames);
ccb         = ops.Kmat * ccmat;
[cx,ix]     = max(ccb, [], 1);
[ix11,ix21] = ind2sub(numel(ops.linds)*[1 1],ix);
mdpt        = floor(numel(ops.linds)/2)+1;

% return offsets
%dv0 = (([ix11' ix21'] - floor(numel(ops.linds)/2)+1)/ops.subpixel + mxpt - [floor(ops.ly/2) floor(ops.lx/2)]) - 1;
dv0 = bsxfun(@minus, ([ix11' ix21'] - mdpt)/ops.subpixel + mxpt,[floor(ops.ly/2) floor(ops.lx/2)]) - 1;
dph         = 2*pi*(bsxfun(@times, dsBatch(1,1,:), Ny) + bsxfun(@times, dsBatch(:,2,:), Nx));
fdata       = fft2(dataBatch);
dregBatch   = gather(real(ifft2(fdata .* exp(1i * dph))));
% fdata = fft2(frame);
% regFrame = real(ifft2(fdata .* exp(1i * 2*pi*(dv0(1)*ops.Ny + dv0(2)*ops.Nx))));

end

