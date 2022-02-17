function bUpdated =  GetOptoBehApproach(isession, ibpodsession)

b=track_training_progress_advanced(isession);

load(ibpodsession);
sd = SessionData;

press_time_bpod = []; % press time
appstim = []; % 1: stim occurs when approach, 0: no stim
app2press_time_bpod= []; % time from approach to press
app_time = []; % approach time
app2press = [];  % 1: rat did a press after approach, 0: rat didn't do a press after approach
stim_time = [];  % for each appstim == 1, the laser stimulation time is plotted here. time and laser stim pattern can be found in bpod or wavesurfer files. 
stim_pattern = []; % dur, freq, pulse-dur

for j =1 : length(sd.RawEvents.Trial)
    app_time = [app_time sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForApproach(end)];
    
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))  % stim trials
        appstim                         =           [appstim 1];
        stim_time                      =           [stim_time sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForPressStim(1)];
        stim_pattern                  =           [stim_pattern; sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
    else
        appstim                         =           [appstim 0];
    end;
    
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)) % rat did a lever press
        press_time_bpod         =           [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
        app2press_time_bpod =           [app2press_time_bpod sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)-sd.RawEvents.Trial{j}.States.Masking(1)];
        app2press                    =           [app2press 1];
    else
        app2press = [app2press 0]; % rat didn't do a press
    end;
end;

% now, every press_time_bpod should be corresponding to a press in
% b.PressTime. Our next step is to identify the index the link
% press_time_bpod to b.PressTime

IndBpod2MED = findseqmatch(b.PressTime*1000, press_time_bpod*1000, 1);
% Now determine the time of approach/laserstim in MED's time domain
AppTimeMED = Map2TimeInB(app_time, press_time_bpod, b.PressTime, IndBpod2MED);
StimTimeMED = Map2TimeInB(stim_time, press_time_bpod, b.PressTime, IndBpod2MED);

bUpdated = b;
bUpdated.PressTimeBpodvsMED = [press_time_bpod; b.PressTime(IndBpod2MED)];
bUpdated.PressTimeBpodIndex = IndBpod2MED;
bUpdated.Approach = AppTimeMED;
bUpdated.ApproachStimIndex = appstim;
bUpdated.StimTime = StimTimeMED;
bUpdated.StimProfile = stim_pattern;

bUpdated.App2PressCompleted = app2press;
bUpdated.App2PressLatency = app2press_time_bpod;

save bUpdated bUpdated


% 

