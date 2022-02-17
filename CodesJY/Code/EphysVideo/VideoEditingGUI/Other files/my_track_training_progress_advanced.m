function bout=track_training_progress_advanced(filename)

% Jianing Yu Oct 30 2019

% for wait 1, 2 training, the following information matters:


session_name = strrep(filename(1:end-4), '_', '-');
Time_events=med_to_tec_new(filename, 100);

% Time_event = [Times/ST Events];  % TS is time slice in MedAssociates

%% find out lever-light-on time
ind_leveron=find(Time_events(:, 2)==15);
n_leverlight = length(ind_leveron);
% time when lever light is turned on
time_leverlighton = Time_events(ind_leveron, 1);


%% find out lever-light-off time
ind_leveroff=find(Time_events(:, 2)==25);
n_leverlight = length(ind_leveroff);
% time when lever light is turned on
time_leverlightoff = Time_events(ind_leveroff, 1);

%% find out press-time
ind_leverpress=find(Time_events(:, 2)==1);
n_leverpress = length(ind_leverpress);
% time of presses
time_leverpress= Time_events(ind_leverpress, 1);

ind_lever_release=find(Time_events(:, 2)==4);
n_leverrelease = length(ind_lever_release);
% time of releases
time_leverrelease= Time_events(ind_lever_release, 1);

if length(time_leverrelease)<length(time_leverpress) % final release was not registered before the session ended. 
    ind_leverpress=ind_leverpress(1:end-1);
%     n_leverpress = length(ind_leverpress);
    % time of presses
    time_leverpress= time_leverpress(1:end-1);
end;

% press duration for each press, in ms
if time_leverrelease(1)<time_leverpress(1)
    time_leverrelease(1)=[];
end;

if time_leverrelease(end)<time_leverpress(end)
    time_leverpress(end)=[];
end;

press_durs = (time_leverrelease-time_leverpress)*1000;
n_leverpress = length(time_leverpress);

%% find out reward time

ind_reward=find(Time_events(:, 2)==13);
if isempty(ind_reward)
    ind_reward=find(Time_events(:, 2)==18);
end;

n_reward = length(ind_reward);
% time of reward
time_reward= Time_events(ind_reward, 1);

%% find out successful presses
ind_good_presses = [];
ind_anticipatory_presses = [];

for i=1:n_leverpress
    if ~isempty(find(time_reward==time_leverrelease(i)))
        ind_good_presses=[ind_good_presses i];
    end;
end;

ind_bad_presses=setdiff([1:n_leverpress], ind_good_presses);  % bad presses include both early and premature release

%% find out premature releases
time_premature= Time_events(Time_events(:, 2)==50, 1);
[~, ind_premature_releases] = intersect(time_leverrelease, time_premature);

%% find out late releases
time_late = Time_events(Time_events(:, 2)==51, 1);   % this is the time of late_error z pulse
ind_late_releases = [];
for i = 1 : length(time_late)
   ind_late_releases = [ind_late_releases find((time_leverpress-time_late(i)).*(time_leverrelease-time_late(i))<=0)];
end;
time_late_lever_release = time_leverrelease(ind_late_releases);

%% find out presses that occur when the lever light is off (inter-trial presses)
inter_trial_presses=[];
for i = 1:length(ind_bad_presses)
    
    % most recent light on
    recent_lighton=time_leverlighton(find(time_leverlighton < time_leverpress(ind_bad_presses(i)), 1, 'last'));
    % most recent light off
    recent_lightoff=time_leverlightoff(find(time_leverlightoff < time_leverpress(ind_bad_presses(i)), 1, 'last'));
    
    if ~isempty(recent_lighton) && ~isempty(recent_lightoff) && recent_lightoff > recent_lighton
        inter_trial_presses=[inter_trial_presses ind_bad_presses(i)];
    end;
    
end;


%% find out reaction time
ind_tone=find(Time_events(:, 2)==11);
n_tone = length(ind_tone);
% time of presses
time_tone= Time_events(ind_tone, 1);
reaction_time = zeros(1, n_tone);

% ind_valid_presses = [ind_good_presses ind_premature_releases];
ind_tone_late = [];
ind_press_rt =[]; % index to track which presses trigger tone

for i = 1:n_tone
    if ~isempty(time_leverrelease(find(time_leverrelease>=time_tone(i), 1, 'first')))
        i_release_time = time_leverrelease(find(time_leverrelease>=time_tone(i), 1, 'first'));
        reaction_time(i) = 1000*(i_release_time-time_tone(i));
        if isempty(find(i_release_time == time_late_lever_release))  % not a late release
            ind_tone_late(i)=0;
        else
            ind_tone_late(i)=1;  % lever releases were late in response to these tones
        end;
    else
        reaction_time(i) = NaN;
        ind_tone_late(i)=NaN;
    end;
end;

% find out FP requirement:

FPs=[];
try
    fp_events=med_to_tec_fp(filename, 100);
    
    if size(fp_events, 1) >= length(time_leverpress)  % if this checks out, foreperiod requirement is documented.
        FPs=fp_events(1: length(time_leverpress), 2)*10;
    else
        FPs=NaN*ones(length(time_leverpress), 1);
    end;
end;

%% save data
bout.Metadata        =      med_to_protocol(filename);

bout.SessionName        =      session_name;
bout.PressTime             =      time_leverpress';
bout.ReleaseTime         =      time_leverrelease';
bout.Correct         =      ind_good_presses;
bout.Premature       =      ind_premature_releases';
bout.Late            =      ind_late_releases;
bout.Dark            =      inter_trial_presses;
bout.ReactionTime    =      reaction_time;
bout.TimeTone        =      time_tone';           % trigger signal for release 
bout.IndToneLate     =      ind_tone_late;
bout.FPs             =      FPs';
