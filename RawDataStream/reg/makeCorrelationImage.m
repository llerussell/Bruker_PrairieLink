function corrImg = makeCorrelationImage(varargin)
% LR 2018. Make and save out a correlation image
% varargin: number of planes

if ~nargin
    num_planes = 4;
else
    num_planes = varargin{1};
end

% get file path
[filename, folderpath] = uigetfile('*.bin; *.raw; *.tif', 'Select a movie');
fullpath = [folderpath filename];
cd(folderpath)

% options
num_neighbours = 8;
num_frames_for_corr = Inf;
corr_downsample_factor = 10;

% load movie
disp(['Loading ' fullpath])
data = DataLoader(fullpath);
nframes = floor(size(data,3)/num_planes);
num_frames_for_corr = min(num_frames_for_corr, nframes);

% save name
[pathstr, name, ext] = fileparts(fullpath);


% make and save corr image
for i = 1:num_planes
    disp(['    Plane ' num2str(i) ' of ' num2str(num_planes)])
    save_name = [pathstr filesep name];
    plane_str = ['_Plane' num2str(i)];

    if num_planes==1
        temp = data(:,:,i:4:end);
    else
        temp = data(:,:,i:num_planes:end);
    end
    temp = smoothdata(temp, 3, 'movmean', corr_downsample_factor);
    temp = uint16(temp);
    temp = single(downsample(temp, corr_downsample_factor));
    
%     % exclude some outlier frames:
%     tmp2trace = squeeze(mean(mean(temp,1),2));
%     badframes = zscore(tmp2trace) > 1.5  |  zscore(tmp2trace) < -1;
%     tmp2trace(badframes) = nan;
%     temp = temp(:,:,~badframes);
    
    
    
    % make a max/mean/std image
    maxImg = nanmax(temp,[],3);
    meanImg = nanmean(temp,3);
    stdImg = nanstd(temp,[],3);
    TiffWriter(uint16(maxImg*10), [save_name '_MaxImg' plane_str '.tif'], 16, 0)
    TiffWriter(uint16(meanImg*10), [save_name '_MeanImg' plane_str '.tif'], 16, 0)
    TiffWriter(uint16(stdImg*10), [save_name '_StdImg' plane_str '.tif'], 16, 0)

    
    
    [corrImg, ~] = makeCorrImg(temp, num_neighbours);
    
    corrImg(corrImg<0) = 0;
    corrImg(isnan(corrImg)) = 0;
    corrImg(isinf(corrImg)) = 0;
    
    corrImg = corrImg - min(corrImg(:));
    corrImg = corrImg ./ max(corrImg(:));
    
    % save image
    TiffWriter(uint16(corrImg*(65535)), [save_name '_CorrImg' plane_str '.tif'], 16, 0)
end

