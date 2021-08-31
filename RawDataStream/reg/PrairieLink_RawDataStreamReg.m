% PrairieLinkRawDataStream
% ========================
% Convert and save raw data on-line
% Lloyd Russell 2016. Optimised on 2017-03-10. Added 'GUI' on 2017-04-11
% Henry Dalgleish 2018 implemented online motion correction (using Suite2P functions)
%
% To do:
% ------
% * Fix first run bug - very first time running does not connect to PV
% * Header could be improved by containing bitdepth, and number of channels
%
% File header:
% ------------
% First 2 blocks of output file will contain the following information:
% - pixelsPerLine
% - linesPerFrame


% make figure
handles = [];
handles.fig = figure('Name','PrairieLink RawDataStream',...
    'Position',[50 100 320 130], 'MenuBar','none', 'NumberTitle','off',...
    'Color','w');

% add button
handles.GREEN = [0.05 0.85 0.35];
handles.StartButton = uicontrol('Style','Pushbutton',...
    'Position',[10 10 300 40], 'String','Start', 'FontSize',20,...
    'BackgroundColor',handles.GREEN, 'ForegroundColor','w',...
    'Callback',@ClickStart);

% add text
handles.DoRegistration = uicontrol('Style','Checkbox',...
    'Position',[10 105 300 15],'BackgroundColor','w', 'String','Do registration');

handles.LoadRefImgButton = uicontrol('Style','Pushbutton',...
    'Position',[190 105 120 15],'BackgroundColor','w', 'String','Load reference image',...
    'Callback',@LoadReferenceImage);

handles.RefImgText = uicontrol('Style','Text',...
    'Position',[10 90 300 15],'BackgroundColor','w', 'String','(Reference image)',...
    'FontAngle','Italic');

handles.FileNameText = uicontrol('Style','Text',...
    'Position',[10 75 300 15],'BackgroundColor','w', 'String','(Filename)',...
    'FontWeight','Bold', 'Enable','Inactive', 'ButtonDownFcn',@ClickFilename);

handles.ProgressText = uicontrol('Style','Text',...
    'Position',[10 60 300 15],'BackgroundColor','w', 'String','(Progress)');

handles.RefImgLoaded = false;
handles.numPlanes = 1;  % default

% store handles in guidata
guidata(handles.fig, handles)


% callback function
function ClickStart(h, e)
fclose('all');

% retrieve guidata
handles = guidata(h);

% get ready for online registration
DoRegistration = handles.DoRegistration.Value;  % get value, don't want to ever turn on or off mid acquisition.
if DoRegistration
    if ~handles.RefImgLoaded
        LoadReferenceImage(h,e);
    end
    
    handles = guidata(h);
    numPlanes = handles.numPlanes;
    ops = handles.ops;
    refImg = handles.refImg;
    
    % initialise gpu. (is this needed?)
    for i = 100
        gframe = single(gpuArray(refImg(:,:,1)));
    end
    % clear gframe?
else
    numPlanes = 1;
end

% initialise PrairieLink
pl = actxserver('PrairieLink.Application');
pl.Connect();
pl.SendScriptCommands('-DoNotWaitForScans');
pl.SendScriptCommands('-LimitGSDMABufferSize true 100');
pl.SendScriptCommands('-StreamRawData true 120'); % NB used to be 50
pl.SendScriptCommands('-fa 1');  % set frame averaging to 1

% get acquisition settings
samplesPerPixel      = pl.SamplesPerPixel();
pixelsPerLine        = pl.PixelsPerLine();
linesPerFrame        = pl.LinesPerFrame();
totalSamplesPerFrame = samplesPerPixel*pixelsPerLine*linesPerFrame;
yaml                 = ReadYaml('settings.yml');
flipEvenRows         = yaml.FlipEvenLines;  % toggle whether to flip even or odd lines; 1=even, 0=odd; Bruker2=1, Bruker1=0;

% get file name
baseDirectory = pl.GetState('directory', 1);
tSeriesName   = pl.GetState('directory', 4);
tSeriesIter   = pl.GetState('fileIteration', 4);
tSeriesIter   = sprintf('%0.3d', str2double(tSeriesIter));
filePath      = [baseDirectory, filesep, tSeriesName '-' tSeriesIter];

% display file name
completeFileName = [filePath '.bin'];
handles.FileNameText.String = completeFileName;
handles.StartButton.BackgroundColor = [.8 .8 .8];


% open binary file for writing
if DoRegistration
    fileID = fopen([filePath '_onlineREG.bin'], 'wb');
    shiftsAndCorrFileID = fopen([filePath '_ShiftsAndCorr.bin'],'wb');
else
    fileID = fopen([filePath '.bin'], 'wb');
end

% write file header
fwrite(fileID, pixelsPerLine, 'uint16');
fwrite(fileID, linesPerFrame, 'uint16');

% flush buffer
flushing = 1;
while flushing
    [samples, numSamplesRead] = pl.ReadRawDataStream(0);
    if numSamplesRead == 0
        flushing = 0;
    end
end

% start the current t-series
pl.SendScriptCommands('-TSeries');

% initialise state variables, buffer, and counters/records
running        = 1;
started        = 0;
loopCounter    = 1;
buffer_size    = 100;
timeout_s      = 3;
framesCounter  = 0;
frameNum       = 0;
buffer         = [];
allSamplesRead = zeros(1,buffer_size);
msg            = [];
droppedData    = [];
time_since     = 0;
nsr            = zeros(1,20000,'single');
dv = [nan nan];
cv = nan;

% get data, do conversion, save to file
while running
    % start timer
    %tic;
    
    % get raw data stream (timer = ~20ms)
    tic;
    [samples, numSamplesRead] = pl.ReadRawDataStream(0);
    nsr(loopCounter) = toc;
    
    % append new data to any remaining old data
    buffer = [buffer samples(1:numSamplesRead)];
    
    % extract full frames
    numWholeFramesGrabbed = floor(length(buffer)/totalSamplesPerFrame);
    toProcess = buffer(1:numWholeFramesGrabbed*totalSamplesPerFrame);
    
    % clear data from buffer
    buffer = buffer((numWholeFramesGrabbed*totalSamplesPerFrame)+1:end);
    
    % process the acquired frames (timer = ~5ms)
    if numWholeFramesGrabbed > 0
        for i = 1:numWholeFramesGrabbed
            if started == 0
                started = 1;
            end
            tic;
            % get plane
            plane = mod(frameNum,numPlanes)+1;
            
            % get single frame
            frame = toProcess(((i-1)*totalSamplesPerFrame)+1:(i*totalSamplesPerFrame));
            
            % process the frame (C++ mex code)
            frame = PrairieLink_ProcessFrame(frame, samplesPerPixel, linesPerFrame, pixelsPerLine, flipEvenRows);
            
            % register frame HD 20180702
            if DoRegistration
                [regFrame,dv,cv] = return_offsets_phasecorr(single(gpuArray(frame)),ops{plane});
                
                % save processed frame and correlation values to file
                fwrite(fileID, gather(uint16(regFrame)), 'uint16');
                fwrite(shiftsAndCorrFileID, [gather(dv) gather(cv)], 'single');
            else
                fwrite(fileID, frame, 'uint16');
            end
            
            % increment frame counter
            frameNum = frameNum + 1;
        end
    end
    
    % display progress
    if DoRegistration
        msg = ['Frame: ' num2str(frameNum) ', Loop: ' num2str(loopCounter) '. Shifts: ' num2str(gather(dv(1)),'%.1f') ', ' num2str(gather(dv(2)),'%.1f') ];
    else
        msg = ['Frame: ' num2str(frameNum) ', Loop: ' num2str(loopCounter)];
    end
    handles.ProgressText.String = msg;
    drawnow
    
    % increment counters
    allSamplesRead(mod(loopCounter-1,buffer_size)+1) = numSamplesRead; % NB modified to add finite buffer
    framesCounter = framesCounter + numWholeFramesGrabbed;
    loopCounter = loopCounter + 1;
    
    % test for dropped data
    droppedData = pl.DroppedData();
    if droppedData(end)
        fprintf(2, ['\n!!! DROPPED DATA AT FRAME ' num2str(framesCounter) ' !!!\n'])
        fprintf(msg)
    end
    
    % exit loop if finished (if no data collected for previous X loops and time elapsed is > timeout_s)
    if started && loopCounter > buffer_size && sum(allSamplesRead) == 0
        if time_since > timeout_s
            running = 0;
        end
        time_since = time_since + toc;
    else
        time_since = 0;
    end
end

% clean up
assignin('base','t',nsr)
fclose(fileID);
if DoRegistration
    fclose(shiftsAndCorrFileID);
end
pl.Disconnect();
handles.StartButton.BackgroundColor = handles.GREEN;
end


function ClickFilename(h, e)
% retrieve guidata
handles = guidata(h);

% get filename
CompleteFilePath = handles.FileNameText.String;

% extract path
[FolderPath,FileName,FileExt] = fileparts(CompleteFilePath);

% open explorer at current file directory
dos(['explorer ' FolderPath]);
end


function LoadReferenceImage(h, e)
% retrieve guidata
handles = guidata(h);

% select the image
[fileName,dirName] = uigetfile('*.tif','Select reference image/stack for registration','MultiSelect','on');
cd(dirName)
if ~iscell(fileName)
    fileName = {fileName};
end

% build full paths
fullPath = [];
for i = 1:numel(fileName)
    fullPath{i} = [dirName filesep fileName{i}];
end

% set the gui label
handles.RefImgText.String = fileName{1};

% load image(s)
refImg = [];
ops = cell(numel(fullPath));
for i = 1:numel(fullPath)
    temp = imread(fullPath{i});
    refImg(:,:,i) = permute(temp,[2 1]);  % because PL data is different index order, but permuted for matlab when reading in.
    [ops{i}] = setup_registration_phasecorr(refImg(:,:,i));
end

% save to handles
handles.numPlanes = size(refImg,3);
handles.ops = ops;
handles.refImg = refImg;
handles.RefImgLoaded = true;

% set do registration to true (why else did you load the ref img?)
handles.DoRegistration.Value = true;

% store handles in guidata
guidata(handles.fig, handles)
end
