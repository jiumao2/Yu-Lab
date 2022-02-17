function tsout = findts(seqfile)

% Jianing Yu
% 4.14.2021 find timestamp information from .seq file
% tsout.ts: time stamp in ms
% tsout.skipind: skip index (frame[s] before this frame is skipped)
% the function will end once it reaches the end of fid. 

framestart = 1;
keepcounting = 1;
skips =[];
tic
while keepcounting
    if rem(framestart, 1000)==0
        sprintf('last frame time %2.0f s', ts(end)/1000)
    end
    try
    [tstamp, headin] =  ReadTimestampSEQ(seqfile, [framestart framestart]);
    catch 
        toc
        % it now reaches the end of seq file. now it is the time to end
        % counting
        return
    end;
    
    tf = tstamp{1};
    
    tf_hr      =    str2num(tf([13 14]))*3600*1000;
    tf_mn    =      str2num(tf([16 17]))*60*1000;
    tf_ss      =      str2num(tf([19 20]))*1000;
    tf_ms    =      str2num(tf([22:end]))/1000;
    
    tf_current = sum([tf_hr, tf_mn, tf_ss, tf_ms]);
    
    if framestart==1
        tfstart = tf_current;
        ts(framestart)=tf_current-tfstart;
    else
        if tf_current-ts(end)>1
            ts(framestart)=tf_current-tfstart;
            
            if ts(end)-ts(end-1)>15
                skips = [skips framestart];
            end;
            
        else
            keepcounting = 0;
        end;
    end;
    
    framestart = framestart+1;
    
    tsout.ts = ts; 
    tsout.skipind = [];
end;












