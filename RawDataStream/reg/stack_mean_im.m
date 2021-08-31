function [varargout] = stack_mean_im(varargin)

num_planes = 1;
if ~isempty(varargin)
    num_planes = varargin{1};
end

% Load stack and split
d = uigetdir('Select stack directory');
f = dir([d filesep '*.tif']);
f = {f(:).name};
stack = ImReader(d);
stack = split_stack(stack,num_planes);

%% Registration
do_registration        = true;
use_gpu                = true;
ops = [];
ops.nonrigid = 0;
ops.planesToProcess = 1;
ops.doRegistration = do_registration;
ops.dobidi = 0;
ops.NiterPrealign = 1;
ops.SubPixel = 10;
ops.useGPU = use_gpu;
ops.showTargetRegistration = 0;
ops.mouse_name = 'a';
ops.date = '1';
ops.nplanes = 1;
ops.kriging = 0;
ops.RegFileBinLocation = getOr(ops, {'RegFileBinLocation'}, []);
ops.splitFOV           = getOr(ops, {'splitFOV'}, [1 1]);
ops.smooth_time_space = getOr(ops, 'smooth_time_space', []);
[Ly, Lx, ~, ~] = size(stack);
ops.Ly = Ly;
ops.Lx = Lx;

mean_images = zeros(size(stack,1),size(stack,2),num_planes,'single');
for i = 1:size(stack,4)
    frames_for_mean = stack(:,:,:,i);
    ops1 = align_iterative(single(squeeze(frames_for_mean(:,:,:))), ops);
    mean_images(:,:,i) = ops1.mimg;
    
%     mean_images(:,:,i) = mean(stack(:,:,:,i),3);
%     subplot(1,num_planes,i)
%     imshow(mean_images(:,:,i),[])
end

parent_dir = [d '_stack'];
mkdir(parent_dir);
name_chunks = strsplit(f{1},'_');
name = strjoin(name_chunks(1:3),'_');
for i = 1:size(mean_images,3)
    imwrite(uint16(mean_images(:,:,i)),[parent_dir filesep [name '_plane' num2str(i,'%03d') '.tif']]);
end

if nargout>0
    varargout = mean_images;
end

