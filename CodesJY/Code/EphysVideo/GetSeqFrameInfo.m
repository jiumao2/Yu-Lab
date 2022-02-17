function FrameInfo = GetSeqFrameInfo(frame_range)

% Jianing Yu
%2021/5/21
% Get frame timestamps and ROI

%% Get frame times
seqfiles = dir('*.seq');

if length(seqfiles)>0;
    for i=1:length(seqfiles)
        SeqVidFile{i} = seqfiles(i).name;
    end;
end;

MedFile=dir('*.txt');

if nargin<1
    frame_range = [3200 3200]+5*60*100;
end;
%% extract mask, use frames from 5*60*50 to 5*60*50+60*50
mask = ExtractMaskSeq(SeqVidFile{1}, frame_range);
%% based on "mask", extract pixel intensity in ROI from all frames
tsROI = [];
SummedROI = [];
SeqFrameIndx = [];
SeqFileIndx = [];
tic

clc
sprintf('Extracting ......')

for i=1:length(SeqVidFile)
    
    %  Read all frames:
    kframe =1;
    keepreading = 1;
    tstart = 0;
    while keepreading ==1
        try
            [thisFrame]         =   ReadJpegSEQ(SeqVidFile{i}, [kframe kframe]);
            imgOut = double(thisFrame{1});
            tf           = thisFrame{2};
            
            roi_k = sum(imgOut(mask));
            
            tf_hr      =    str2num(tf([13 14]))*3600*1000;
            tf_mn    =      str2num(tf([16 17]))*60*1000;
            tf_ss      =      str2num(tf([19 20]))*1000;
            tf_ms    =      str2num(tf([22:end]))/1000;
            
            tf_current = round(sum([tf_hr, tf_mn, tf_ss, tf_ms]));
            
            if kframe == 1;
                tstart = tf_current;
            else
                if tf_current > tstart
                    keepreading = 1;
                else
                    keepreading = 0;
                end;
            end;
            
            if keepreading
                tf_current          =   tf_current - tstart;
                
                tsROI                 =   [tsROI tf_current];
                SummedROI     =   [SummedROI roi_k];
                SeqFrameIndx   =   [SeqFrameIndx kframe];
                SeqFileIndx        =   [SeqFileIndx i];
                
                kframe = kframe + 1;
            end;
            
            if rem(kframe, 100)==0
                sprintf('100s frames extracted %2.0d ', kframe/100)
            end
            
        catch
            keepreading = 0;
        end;
        
    end;
end;
toc

tsROI = tsROI - tsROI(1); % onset normalized to 0
FrameInfo                          =   [];
FrameInfo.tframe               = tsROI;
FrameInfo.mask                 = mask;
FrameInfo.ROI                   = SummedROI;
FrameInfo.SeqVidFile        = SeqVidFile;
FrameInfo.SeqFileIndx        = SeqFileIndx;
FrameInfo.SeqFrameIndx   = SeqFrameIndx;
FrameInfo.MEDfile              = MedFile.name;

% Save for now because it takes a long time to get tsROI
save FrameInfo FrameInfo