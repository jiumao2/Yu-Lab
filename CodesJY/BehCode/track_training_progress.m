function behavout=track_training_progress(filename)

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

%% find out press-on-time
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
    n_leverpress = length(ind_leverpress);
    % time of presses
    time_leverpress= time_leverpress(1:end-1);
end;

% press duration for each press, in ms
press_durs = (time_leverrelease-time_leverpress)*1000;


%% find out reward time
ind_reward=find(Time_events(:, 2)==13);
n_reward = length(ind_reward);
% time of reward
time_reward= Time_events(ind_reward, 1);

%% find out successful presses
ind_good_presses=[];
for i=1:n_leverpress

    if ~isempty(find(time_reward==time_leverrelease(i)))
        ind_good_presses=[ind_good_presses i];
    end;
    
end;

ind_bad_presses=setdiff([1:n_leverpress], ind_good_presses);  % bad presses include both early and premature release



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

ind_premature_releases=setdiff(ind_bad_presses, inter_trial_presses);

%% find out reaction time
ind_tone=find(Time_events(:, 2)==11);
n_tone = length(ind_tone);
% time of presses
time_tone= Time_events(ind_tone, 1);
reaction_time = zeros(1, n_tone);

ind_valid_presses = [ind_good_presses ind_premature_releases];

ind_tone_late = [];
for i = 1:n_tone
    
    if ~isempty(time_leverrelease(find(time_leverrelease>=time_tone(i), 1, 'first')))
        reaction_time(i) = 1000*(time_leverrelease(find(time_leverrelease>=time_tone(i), 1, 'first'))-time_tone(i));
    else
        reaction_time(i) = NaN;
    end;
    
end;



figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 20], 'paperpositionmode', 'auto' )

subplot(2, 1, 1)
set(gca, 'nextplot', 'add', 'ylim', [0 2800], 'xlim', [0 3600])
line([time_leverlighton time_leverlighton], [0 500], 'color', 'b')
line([time_leverlightoff time_leverlightoff], [0 500], 'color', 'b', 'linestyle', ':')

title(session_name)


good_col=[0 1 0]*0.75;

plot(time_leverrelease(inter_trial_presses), press_durs(inter_trial_presses), 'ko', 'linewidth', 1)
for i=1:length(press_durs(inter_trial_presses))
    line([time_leverpress(inter_trial_presses(i)) time_leverrelease(inter_trial_presses(i))], [press_durs(inter_trial_presses(i)) press_durs(inter_trial_presses(i))], 'linewidth', .5, 'color', 'k')
end;

plot(time_leverrelease(ind_premature_releases), press_durs(ind_premature_releases), 'ro', 'linewidth', 1)
for i=1:length(press_durs(ind_premature_releases))
    line([time_leverpress(ind_premature_releases(i)) time_leverrelease(ind_premature_releases(i))], [press_durs(ind_premature_releases(i)) press_durs(ind_premature_releases(i))], 'linewidth', .5, 'color', 'r')
end;

plot(time_leverrelease(ind_good_presses), press_durs(ind_good_presses), 'o', 'linewidth', 1, 'color', good_col)
for i=1:length(press_durs(ind_good_presses))
    line([time_leverpress(ind_good_presses(i)) time_leverrelease(ind_good_presses(i))], [press_durs(ind_good_presses(i)) press_durs(ind_good_presses(i))], 'linewidth', .5, 'color', good_col)
end;

xlabel ('Time (s)')
ylabel ('Press duration (ms)')

subplot(2, 1, 2)
set(gca, 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 3600])
plot(time_tone, reaction_time, 'o', 'linewidth', 1, 'color', good_col)

xlabel ('Time (s)')
ylabel ('Reaction time (ms)')

print (gcf,'-dpng', [session_name])

%% save data
behout.SessionName     =   session_name;
behout.PressTime       =   time_leverpress;
behout.ReleaseTime     =   time_leverrelease;
behout.ReactionTime    =   reaction_time;
behout.TimeTone       =    time_tone;           % trigger signal for release 







