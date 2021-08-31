function [downsampled_array] = downsample_HD(array, factor,varargin)
   
% Default method is mean
method = 'mean';
for v = 1:numel(varargin)
    if strcmpi(varargin{1},'sum')
        method = 'sum';
    elseif strcmpi(varargin{v},'median')
        method = 'median';
    elseif strcmpi(varargin{v},'prctile')
        method = 'prctile';
        prc = varargin{v+1};
    end
end

if min(size(array)) == 1
    % Reshape array
    num_elems = numel(array);
    num_cols = ceil(num_elems/factor);
    downsampled_array = nan(factor,num_cols);
    downsampled_array(1:num_elems) = array;
    
    % Downsample according to method
    switch method
        case 'mean'
            downsampled_array = nanmean(downsampled_array,1);
        case 'sum'
            downsampled_array = nansum(downsampled_array,1);
        case 'median'
            downsampled_array = nanmedian(downsampled_array,1);
        case 'prctile'
            downsampled_array = prctile(downsampled_array,prc,1);
    end
else
    % Reshape array
    num_elems = numel(array(1,:));
    num_cols = ceil(num_elems/factor);
    out_array = nan(size(array,1),num_cols);
    for i = 1:size(array,1)
        num_elems = numel(array(i,:));
        num_cols = ceil(num_elems/factor);
        downsampled_array = nan(factor,num_cols);
        downsampled_array(1:num_elems) = array(i,:);
        
        % Downsample according to method
        switch method
            case 'mean'
                downsampled_array = nanmean(downsampled_array,1);
            case 'sum'
                downsampled_array = nansum(downsampled_array,1);
            case 'median'
                downsampled_array = nanmedian(downsampled_array,1);
            case 'prctile'
                downsampled_array = prctile(downsampled_array,prc,1);
        end
        out_array(i,:) = downsampled_array;
    end
    downsampled_array = out_array;
end

end

