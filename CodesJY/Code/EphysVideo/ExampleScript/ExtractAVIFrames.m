%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%These are the required video and behavioral files.%%%%%%%%
 fileinfo = FindAviFiles;
 
 VidFiles = fileinfo.Vids;
 TsFiles = fileinfo.Txts;
 MEDfile = fileinfo.MED;
 % This command will be run in the end. 
Extrct           =       "ExportVideoFiles(b, FrameInfo, 'Event', 'Press', 'TimeRange', [2000 3000], 'SessionName',strrep(fileinfo.MED(1:10), '-', ''), 'RatName', MEDfile(27:strfind(MEDfile, '.')-1), 'Remake', 0)";
MakeSheet   =      "MakeSpreadSheet(b, FrameInfo, 'Event', 'Press', 'TimeRange', [2000 3000], 'SessionName', strrep(fileinfo.MED(1:10), '-', ''), 'RatName', MEDfile(27:strfind(MEDfile, '.')-1))";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% extract mask, use frames from 5*60*50 to 5*60*50+60*50
mask = ExtractMask(VidFiles{1}, [12000 12500]);

%% based on "mask", extract pixel intensity in ROI from all frames
tsROI = [];
SummedROI = []; 
AviFrameIndx = [];
AviFileIndx = [];
tic

clc
sprintf('Extracting ......')

for i=1:length(VidFiles)
    
    fileID              =    fopen(TsFiles{i}, 'r');
    formatSpec   =     '%f' ;
    NumOuts      =      fscanf(fileID, formatSpec); % this contains frame time (in ms) and frame index    
    fclose(fileID);
    
    ind_brk = find(NumOuts ==0);    
    FrameTs = NumOuts(1:ind_brk-1);  % frame times
    FrameIdx = NumOuts(ind_brk+1:end);                     % frame idx    
    filename = VidFiles{i};
    vidObj = VideoReader(filename);    
    for k =1:  vidObj.NumberOfFrames
        thisFrame = read(vidObj, [k k]);
        thisFrame = thisFrame(:, :, 1);
        roi_k = sum(thisFrame(mask));
        
        tsROI                 =   [tsROI FrameTs(k)];
        SummedROI     =   [SummedROI roi_k];
        AviFileIndx         =   [AviFileIndx i];
        AviFrameIndx    =   [AviFrameIndx k];
        
    end
end;
toc

tsROI = tsROI - tsROI(1); % onset normalized to 0
FrameInfo                          =   [];
FrameInfo.tframe               = tsROI;
FrameInfo.mask                 = mask;
FrameInfo.ROI                   = SummedROI;
FrameInfo.AviFile               = VidFiles;
FrameInfo.AviFileIndx        = AviFileIndx;
FrameInfo.AviFrameIndx   = AviFrameIndx;
FrameInfo.MEDfile            = MEDfile;

% Save for now because it takes a long time to get tsROI
save FrameInfo FrameInfo

%% next, map tLEDon to b's  TimeTone: [1×200 double]
% tone time is stored in "b", which is derived from  track_training_progress_advanced(MEDfile);
if isempty(dir(['B_*.mat']))
    track_training_progress_advanced(FrameInfo.MEDfile);
end;
behfile= dir('B_*mat');
load(fullfile(behfile.folder, behfile.name))
tbeh_trigger = b.TimeTone*1000;  % in ms

%%  The goal is to align tLEDon and tbeh_trigger
% alignment and print
%% extract LED-On time
tLEDon = FindLEDon(FrameInfo.tframe, FrameInfo.ROI);
Indout = findseqmatch(tbeh_trigger-tbeh_trigger(1), tLEDon-tLEDon(1), 1);
% these LEDon times are the ones that cannot be matched to trigger. It must be a false positive signal that was picked up by mistake in "tLEDon = FindLEDon(tsROI, SummedROI);"
ind_badROI = find(isnan(Indout));
tLEDon(ind_badROI) = []; % remove them
Indout(ind_badROI) = []; % at this point, each LEDon time can be mapped to a trigger time in b (Indout)
FrameInfo.tLEDon = tLEDon;
FrameInfo.Indout = Indout;
%% Now, let's redefine the frame time. Each frame time should be re-mapped to the timespace in b.
% all frame times are here: FrameInfo.tframe
tframes_in_b = MapVidFrameTime2B(FrameInfo.tLEDon,  tbeh_trigger, Indout, FrameInfo.tframe);
FrameInfo.tFramesInB = tframes_in_b;

imhappy = 0;
while ~imhappy
    %% Empirically, some events are still not well aligned. In particually, in a small subset of trials, LED starts to light up at trigger time we need to revise these trials.
    % some tLEDon need to be revised.
    
    tLEDon = CorrectLEDtime(b, FrameInfo); % update tLEDon
    Indout = findseqmatch(tbeh_trigger-tbeh_trigger(1), tLEDon, 1);
    % these LEDon times are the ones that cannot be matched to trigger. It must be a false positive signal that was picked up by mistake in "tLEDon = FindLEDon(tsROI, SummedROI);"
    ind_badROI = find(isnan(Indout));
    tLEDon(ind_badROI) = []; % remove them
    Indout(ind_badROI) = []; % at this point, each LEDon time can be mapped to a trigger time in b (Indout)
    FrameInfo.tLEDon = tLEDon;
    FrameInfo.Indout = Indout;
    tframes_in_b = MapVidFrameTime2B(FrameInfo.tLEDon,  tbeh_trigger, Indout, FrameInfo.tframe);
    FrameInfo.tFramesInB = tframes_in_b;
    clc
    reply = input('Are you happy? Y/N [Y]', 's');
    if isempty(reply)
        reply = 'Y';
    end;
    if strcmp(reply, 'Y')  ||  strcmp(reply, 'y')
        imhappy = 1;
    else
        imhappy =0;
    end
end;

%% check if the LED ON/OFF looks right around trigger stimulus
roi_collect = CheckAVIFrameTrigger(b, FrameInfo);
%% Check if Press and Release look alright
CheckAVIFramePressRelease(b, FrameInfo)
save FrameInfo FrameInfo
% Extract clips
eval(Extrct)
eval(MakeSheet)