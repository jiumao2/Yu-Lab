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

if length(time_leverrelease)>length(time_leverpress)
    time_leverrelease(end)=[];
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

figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 20 18], 'paperpositionmode', 'auto' )

ha1 = subplot(2, 5, [1 2 3 4 ])
set(gca, 'nextplot', 'add', 'ylim', [0 2800], 'xlim', [0 3600])
line([time_leverlighton time_leverlighton], [0 500], 'color', 'b')
line([time_leverlightoff time_leverlightoff], [0 500], 'color', 'b', 'linestyle', ':')

good_col=[0 1 0]*0.75;

plot(time_leverrelease(ind_good_presses), press_durs(ind_good_presses), 'o', 'linewidth', 1, 'color', good_col)
for i=1:length(press_durs(ind_good_presses))
    line([time_leverpress(ind_good_presses(i)) time_leverrelease(ind_good_presses(i))], [press_durs(ind_good_presses(i)) press_durs(ind_good_presses(i))], 'linewidth', .5, 'color', good_col)
end;

plot(time_leverrelease(ind_premature_releases), press_durs(ind_premature_releases), 'ro', 'linewidth', 1)
for i=1:length(press_durs(ind_premature_releases))
    line([time_leverpress(ind_premature_releases(i)) time_leverrelease(ind_premature_releases(i))], [press_durs(ind_premature_releases(i)) press_durs(ind_premature_releases(i))], 'linewidth', .5, 'color', 'r')
end;

plot(time_leverrelease(ind_late_releases), press_durs(ind_late_releases), 'ro', 'linewidth', 1, 'markerfacecolor', 'r')
for i=1:length(press_durs(ind_late_releases))
    line([time_leverpress(ind_late_releases(i)) time_leverrelease(ind_late_releases(i))], [press_durs(ind_late_releases(i)) press_durs(ind_late_releases(i))], 'linewidth', .5, 'color', 'm')
end;

plot(time_leverrelease(inter_trial_presses), press_durs(inter_trial_presses), 'ko', 'linewidth', 1)
for i=1:length(press_durs(inter_trial_presses))
    line([time_leverpress(inter_trial_presses(i)) time_leverrelease(inter_trial_presses(i))], [press_durs(inter_trial_presses(i)) press_durs(inter_trial_presses(i))], 'linewidth', .5, 'color', 'k')
end;

xlabel ('Time (s)')
ylabel ('Press duration (ms)')

hainfo=subplot(2, 5, 5)

set(gca, 'xlim', [1.95 10], 'ylim', [0 9], 'nextplot', 'add')
plot(2, 8, 'o', 'linewidth', 1, 'color', good_col)
text(2.5, 8, 'Correct')

plot(2, 7, 'ro', 'linewidth', 1)
text(2.5, 7, 'Premature')

plot(2, 6 , 'ro', 'linewidth', 1, 'markerfacecolor', 'r')
text(2.5, 6, 'Late')

plot(2, 5, 'ko', 'linewidth', 1)
text(2.5, 5, 'Dark')

axis off

ha2 = subplot(2, 5, [6 7 8 9])
set(gca, 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 3600])
plot(time_tone(ind_tone_late==1), reaction_time(ind_tone_late==1), 'ro', 'linewidth', 1, 'markerfacecolor', 'r', 'markersize', 4)
plot(time_tone(ind_tone_late==0), reaction_time(ind_tone_late==0), 'o', 'linewidth', 1, 'color', good_col, 'markersize', 4)


xlabel ('Time (s)')
ylabel ('Reaction time (ms)')

ha3 = subplot(2, 5, [10])
set(gca, 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 5], 'xtick', [])
hb1=bar([1], length(ind_good_presses));
set(hb1, 'EdgeColor', good_col, 'facecolor', 'none', 'linewidth', 2);
hb2=bar([2], length(ind_premature_releases))
set(hb2, 'EdgeColor', 'r', 'facecolor', 'none', 'linewidth', 2);
hb2=bar([3], length(ind_late_releases))
set(hb2, 'EdgeColor', 'r', 'facecolor', 'r', 'linewidth', 2);
hb3=bar([4], length(inter_trial_presses))
set(hb3, 'EdgeColor', 'k', 'facecolor', 'none', 'linewidth', 2);
axis 'auto y'

% add success rate:
per_success=length(ind_good_presses)/(length(ind_good_presses)+length(ind_premature_releases)+length(ind_late_releases));

text(3, 0.8*max(get(gca, 'ylim')), [sprintf('%2.1f %s', per_success*100), '%'], 'color', good_col)

ylabel ('Number')
%% save data
bout.Metadata        =      med_to_protocol(filename);
axes(hainfo)

text(2, 4, strrep(bout.Metadata.ProtocolName, '_', '-'))
text(2, 3, upper(bout.Metadata.SubjectName))
text(2, 2, bout.Metadata.Date)
text(2, 1, bout.Metadata.StartTime)

title(ha1, strrep(bout.Metadata.ProtocolName, '_', '-'))

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

savename = ['B_' upper(bout.Metadata.SubjectName) '_' strrep(bout.Metadata.Date, '-', '_') '_' strrep(bout.Metadata.StartTime, ':', '')];
b=bout;
save (savename, 'b')

mkdir('Fig');
savename=fullfile(pwd, 'Fig', savename)

% print (gcf,'-dpng', [savename], '-bestfit')
print (gcf,'-dpdf', [savename], '-bestfit')
print (gcf,'-dpng', [savename])
saveas(gcf, savename, 'fig')
