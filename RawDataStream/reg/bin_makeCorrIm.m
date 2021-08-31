function [varargout] = bin_makeCorrIm(num_planes)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

ds_fac = 10;
if nargin < 1
    num_planes = 1;
end

[f,d] = uigetfile({'*.bin' '.tif'},'Select movie');
mov = ImReader([d filesep f]);
stack = split_stack(mov,num_planes);
[nRows,nCols,nSlices,nPlanes] = size(stack);

% Downsample the stack
ds_stack = zeros(nRows,nCols,ceil(nSlices/ds_fac),nPlanes);
for i = 1:nPlanes
    temp = downsample(stack(:,:,:,i),ds_fac);
    ds_stack(:,:,1:size(temp,3),i) = temp;
end

% Make correlation images for each plane
corrImg = zeros(nRows,nCols,nPlanes);
for i = 1:nPlanes
    [corrImg(:,:,i), ~] = makeCorrImg(ds_stack(:,:,1:end-1,i),4);
end

% Save out correlation images
[~,n] = fileparts([d f]);
out_dir = [d n '_corr'];
mkdir(out_dir);
for i = 1:nPlanes
    corr_save_name = [out_dir filesep n '_Plane' num2str(i,'%03d') '.tif'];
    try
        TiffWriter(uint16(corrImg(:,:,i)*65535), corr_save_name, 16, 0)
    catch
        TiffWriter(uint16(corrImg(:,:,i)*65535), corr_save_name, 16)
    end
end

if nargout>0
    varargout = corrImg;
end

end

