function output = ReadShiftsAndCorrFile(varargin)
% varargin: filepath or empty
% output is Xshift, Yshift, CorrValue

if nargin == 0
    [filename, folderpath] = uigetfile('.bin', 'Select the shifts and correlation value file');
    filePath = [folderpath filename];
end

fileID = fopen(filePath);
data = fread(fileID, '*single');
fclose(fileID);

output = [];
output(:,1) = data(1:3:end);
output(:,2) = data(2:3:end);
output(:,3) = data(3:3:end);
