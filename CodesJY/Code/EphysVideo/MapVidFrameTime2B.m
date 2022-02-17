function tframes_in_b = MapVidFrameTime2B(tLEDon,  tbeh_trigger, Indout, tsROI);

% Jianing Yu
% 5/1/2021
% given LED time, indout, and trigger time in b, conver the time of each
% frame to a time in behavior domain

tframes_in_b = []; % this is the frame time in behavior time domain

for i=1:length(tLEDon)
    if i==1
        frames_sofar = find(tsROI<=tLEDon(i));
    elseif  i ==length(tLEDon)
        frames_sofar = find(tsROI>tLEDon(i-1));
    else
        frames_sofar = find(tsROI>tLEDon(i-1) & tsROI<=tLEDon(i));
    end;
    frames_sofar_remap = tsROI(frames_sofar) - tLEDon(i) + tbeh_trigger(Indout(i));  % convert the frame time to time in the behavior domain
    tframes_in_b = [tframes_in_b frames_sofar_remap];
end;

