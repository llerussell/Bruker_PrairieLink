function [split_stack] = split_stack(stack,nPlanes)

% Vectorised method
[nRows,nCols,nSlices] = size(stack);
slicesPerPlane = floor(nSlices/nPlanes);
nSlices = slicesPerPlane*nPlanes;

idcs = reshape(reshape([1:nSlices],nPlanes,slicesPerPlane)',[],1);
split_stack = stack(:,:,idcs);
split_stack = reshape(split_stack,nRows,nCols,slicesPerPlane,nPlanes);


%%% Old method
% split_stack = zeros(size(stack,1),size(stack,2),ceil(size(stack,3)/nPlanes),nPlanes);
% num_slices = size(stack,3);
% for i = 1:nPlanes
%     slices = i:nPlanes:num_slices;
%     split_stack(:,:,1:numel(slices),i) = stack(:,:,slices);
% end

end

