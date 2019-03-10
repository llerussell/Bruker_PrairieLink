function PrairieLinkPlayer()
% Lloyd Russell 2017
% displays the raw data saved by PraireLinkRawDataStream for quick inspection

% choose file
[FileName, PathName] = uigetfile('*.bin');
FullPath = [PathName filesep FileName];
cd(PathName)

% read data
data = PrairieLink_ReadRawFile(FullPath);
NumFrames = size(data, 3);

% display data
figure
axis off; axis square; axis tight
hold on
Image = imagesc(data(:,:,1));
FrameNumber = text(0,10,'1', 'color','w');
for i = 1:NumFrames
   Image.CData = data(:,:,i);
   FrameNumber.String = num2str(i);
   pause(0.001)
end
