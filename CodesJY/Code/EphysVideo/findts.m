function tsout = findts(seqfile)

% Jianing Yu
% 4.14.2021 find timestamp information from .seq file
% tsout.ts: time stamp in ms
% tsout.skipind: skip index (frame[s] before this frame is skipped)
% the function will end once it reaches the end of fid. 
% Last modified by Yue Huang 3.30.2022

n_frame = ReadFrameNumSEQ(seqfile);
ts = zeros(1,n_frame);
ts_start = ReadTimestampSEQ(seqfile, 1);
tic

for k = 1:n_frame
    ts(k) = ReadTimestampSEQ(seqfile, k) - ts_start;
    if rem(k, 1000)==0
        sprintf('last frame time %2.0f s', ts(k)/1000)
    end
end
ts = ts-ts(1);
tsout.ts = ts;
tsout.skipind = [];    
    
end












