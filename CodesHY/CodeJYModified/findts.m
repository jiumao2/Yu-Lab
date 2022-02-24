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
    tf_current =  ReadTimestampSEQ(seqfile, framestart);
    catch 
        toc
        % it now reaches the end of seq file. now it is the time to end
        % counting
        return
    end
    
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












