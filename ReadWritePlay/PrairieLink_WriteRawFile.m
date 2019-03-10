function PrairieLink_WriteRawFile(data, filePath)
% Write binary file to match that made by PrairieLink_RawDataStream
% Lloyd Russell 2017


% Open the file
fileID = fopen(filePath, 'wb');

% write file header
pixelsPerLine = size(data,1);
linesPerFrame = size(data,2);
fwrite(fileID, pixelsPerLine, 'uint16');
fwrite(fileID, linesPerFrame, 'uint16');

% Write data
fwrite(fileID, permute(data, [2 1 3]), 'uint16');  % little endian to match raw data

% Close the file
fclose(fileID);

