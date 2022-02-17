function bUpdated =  GetOptoBehPress(isession, ibpodsession)
% 5/30/2021
% Jianing Yu and Hengkun Ren

b=track_training_progress_advanced(isession);

load(ibpodsession);
sd = SessionData;

press_time_bpod = []; % press time
pressstim = []; % 1: stim occurs when press, 0: no stimapp2press_time_bpod= []; % time from approach to press

stim_time = [];  % for each appstim == 1, the laser stimulation time is plotted here. time and laser stim pattern can be found in bpod or wavesurfer files. 
stim_pattern = []; % dur, freq, pulse-dur

for j =1 : length(sd.RawEvents.Trial)
    
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1))  % stim trials
        pressstim                         =           [pressstim 1];
        stim_time                      =           [stim_time sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1)];
        stim_pattern                  =           [stim_pattern; sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
    else
        pressstim                         =           [pressstim 0];
    end;
    
    press_time_bpod         =           [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForPress(end)];
    
end;

% now, every press_time_bpod should be corresponding to a press in
% b.PressTime. Our next step is to identify the index the link
% press_time_bpod to b.PressTime

IndBpod2MED = findseqmatch(b.PressTime*1000, press_time_bpod*1000, 1);
% Now determine the time of approach/laserstim in MED's time domain
PressTimeMED = b.PressTime(IndBpod2MED);
StimTimeMED = Map2TimeInB(stim_time, press_time_bpod, b.PressTime, IndBpod2MED);

bUpdated = b;
bUpdated.PressTimeBpodvsMED = [press_time_bpod; PressTimeMED];
bUpdated.PressTimeBpodIndex = IndBpod2MED;
bUpdated.PressStimIndex = pressstim;
bUpdated.StimTime = StimTimeMED;
bUpdated.StimProfile = stim_pattern;

save bUpdated bUpdated


% 

