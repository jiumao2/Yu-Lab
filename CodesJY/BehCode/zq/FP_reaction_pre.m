function bout=FP_reaction_pre(filename)

% Jianing Yu Oct 30 2019
% Qiang Zheng Nov 16 2019                                                                                                                                                                 
% for step7 threeFPsmixed training, the following information matters:


session_name = strrep(filename(1:end-4), '_', '-');
Time_events=med_to_tec_new(filename,100);

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
%% find out successful releases
ind_good_releases=[];
for i=1:n_leverrelease
    if ~isempty(find(time_reward==time_leverrelease(i)))
        ind_good_releases=[ind_good_releases i];
    end;
end;
%% find out premature releases
time_premature= Time_events(Time_events(:, 2)==50, 1);
ind_premature=find(Time_events(:, 2)==50);
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

%% find out releases that occur when the lever light is off (inter-trial releases)
ind_trial4_releases=setdiff([1:n_leverrelease], ind_good_releases);
ind_trial3_releases=ind_trial4_releases';
ind_trial2_releases=setdiff(ind_trial3_releases, ind_premature_releases);
ind_trial_releases=setdiff(ind_trial2_releases, ind_late_releases);
ind_nottrial_releases=setdiff([1:n_leverrelease], ind_trial_releases');
ind_valid_releases2=setdiff(ind_nottrial_releases, ind_premature_releases);
ind_valid_releases=ind_valid_releases2';

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
%% find out FP in good reactions
ind_late_releases2=ind_late_releases';
for i=1:length(ind_late_releases)
    ind_late_tone(i)=find(ind_valid_releases(:,1)==ind_late_releases2(i));
end
ind_good_tone2=setdiff([1:length(ind_valid_releases)],ind_late_tone);
ind_good_tone=ind_good_tone2';
FP2  = time_tone-time_leverpress(ind_valid_releases);
FP=FP2(ind_good_tone);
%% find FP in late and premature
% late
ind_tone(ind_good_tone,2)=FP; 
% ind_tone_zero=find(ind_tone(:,2)==0);
% ind_tone_zerono=setdiff([1:length(ind_tone)],ind_tone_zero);
% ind_tone_nozero(:,2)=ind_tone(ind_tone_zerono,2);
% ind_tone_nozero(:,1)=ind_tone(ind_tone_zerono,1);

for i=1:length(ind_late_tone);
 if ~isempty(find(ind_good_tone2>=ind_late_tone(i), 1, 'first'));
        i_late = ind_good_tone2(find(ind_good_tone2>=ind_late_tone(i), 1, 'first'));
        ind_tone(ind_late_tone(i),2)=ind_tone(i_late,2);
        FP_late(i) = ind_tone(i_late,2);
 end
end

n_FP_late_min=length(find(FP_late==0.5));
n_FP_late_mid=length(find(FP_late==1.0));
n_FP_late_max=length(find(FP_late==1.5));


n_FP_late=[n_FP_late_min,n_FP_late_mid,n_FP_late_max];
% premature
ind_premature(:,2)=nan;
for i=1:length(ind_premature);
 if ~isempty(find(ind_tone(:,1)>=ind_premature(i), 1, 'first'));
        i_premature = find(ind_tone(:,1)>=ind_premature(i), 1, 'first');
        ind_premature(i,2)=ind_tone(i_premature,2);
        ind_premature(i,3)=press_durs(ind_premature_releases(i));
        FP_premature(i) = ind_tone(i_premature,2);

 end
end

n_FP_premature_min=length(find(FP_premature==0.5));
n_FP_premature_mid=length(find(FP_premature==1.0));
n_FP_premature_max=length(find(FP_premature==1.5));
n_FP_premature=[n_FP_premature_min,n_FP_premature_mid,n_FP_premature_max];


%% find plot parameters
reaction_time2=reaction_time';
good_reaction_time=reaction_time2(ind_good_tone);
ind_tone(:,3)=ind_tone(:,2)*1000+reaction_time2;
press_durs_mixed=[ind_tone(:,2:3);ind_premature(:,2:3)]; %%%%%%  highlight!!!! 166.167--175.176
FP_reaction=[FP,good_reaction_time];
FP_reaction=[ind_good_presses',FP_reaction];
FP_reaction=[FP_reaction;[nan nan nan]];

ind_FP_reaction_min=find(FP_reaction(:,2)==0.5);
ind_FP_reaction_min(1)=[];
ind_FP_reaction_mid=find(FP_reaction(:,2)==1.0);
ind_FP_reaction_mid(1)=[];
ind_FP_reaction_max=find(FP_reaction(:,2)==1.5);
% find n in (n-1)
% 0.5
ind_min_pre=ind_FP_reaction_min+1;
ind_discontinuous=[0];
for i=1:length(ind_min_pre)
if FP_reaction(ind_min_pre(i),1)-FP_reaction(ind_FP_reaction_min(i),1)~=1
   ind_discontinuous=[ind_discontinuous;i];
end
end
ind_discontinuous(1)=[];
ind_min_pre(ind_discontinuous)=[];  % everything following a 0.5s FP
% 1.0
ind_mid_pre=ind_FP_reaction_mid+1;
ind_discontinuous=[0];
for i=1:length(ind_mid_pre)
if FP_reaction(ind_mid_pre(i),1)-FP_reaction(ind_FP_reaction_mid(i),1)~=1
   ind_discontinuous=[ind_discontinuous;i];
end
end
ind_discontinuous(1)=[];
ind_mid_pre(ind_discontinuous)=[];   % everything following a 0.5s FP
% 1.5
ind_max_pre=ind_FP_reaction_max+1;
ind_discontinuous=[0];
for i=1:length(ind_max_pre)
if FP_reaction(ind_max_pre(i),1)-FP_reaction(ind_FP_reaction_max(i),1)~=1
   ind_discontinuous=[ind_discontinuous;i];
end
end
ind_discontinuous(1)=[];
ind_max_pre(ind_discontinuous)=[];   % everything following a 0.5s FP
% find (n-1)=0.5
FP_reaction_min_pre=FP_reaction(ind_min_pre,2:3);
ind_min_pre_min=find(FP_reaction_min_pre(:,1)==0.5);
ind_min_pre_mid=find(FP_reaction_min_pre(:,1)==1.0);
ind_min_pre_max=find(FP_reaction_min_pre(:,1)==1.5);
% find (n-1)=1
FP_reaction_mid_pre=FP_reaction(ind_mid_pre,2:3);
ind_mid_pre_min=find(FP_reaction_mid_pre(:,1)==0.5);
ind_mid_pre_mid=find(FP_reaction_mid_pre(:,1)==1.0);
ind_mid_pre_max=find(FP_reaction_mid_pre(:,1)==1.5);
% find (n-1)=1.5
FP_reaction_max_pre=FP_reaction(ind_max_pre,2:3);
ind_max_pre_min=find(FP_reaction_max_pre(:,1)==0.5);
ind_max_pre_mid=find(FP_reaction_max_pre(:,1)==1.0);
ind_max_pre_max=find(FP_reaction_max_pre(:,1)==1.5);
%% plot (n-1)=0.5

mean_min_pre_min=mean(FP_reaction_min_pre(ind_min_pre_min,2));
mean_min_pre_mid=mean(FP_reaction_min_pre(ind_min_pre_mid,2));
mean_min_pre_max=mean(FP_reaction_min_pre(ind_min_pre_max,2));
mixed_mean_min=[mean_min_pre_min;mean_min_pre_mid;mean_min_pre_max];
FP_single=[0.5;1.0;1.5];
% SEM_min_min = std(FP_reaction_min_pre(ind_min_pre_min,2))./sqrt(length(FP_reaction_min_pre(ind_min_pre_min,2)));
% SEM_min_mid = std(FP_reaction_min_pre(ind_min_pre_mid,2))./sqrt(length(FP_reaction_min_pre(ind_min_pre_mid,2)));
% SEM_min_max = std(FP_reaction_min_pre(ind_min_pre_max,2))./sqrt(length(FP_reaction_min_pre(ind_min_pre_max,2)));
% SEM_min=[SEM_min_min;SEM_min_mid;SEM_min_max];

%% plot (n-1)=1.0

mean_mid_pre_min=mean(FP_reaction_mid_pre(ind_mid_pre_min,2));
mean_mid_pre_mid=mean(FP_reaction_mid_pre(ind_mid_pre_mid,2));
mean_mid_pre_max=mean(FP_reaction_mid_pre(ind_mid_pre_max,2));
mixed_mean_mid=[mean_mid_pre_min;mean_mid_pre_mid;mean_mid_pre_max];
FP_single=[0.5;1.0;1.5];
% SEM_mid_min = std(FP_reaction_mid_pre(ind_mid_pre_min,2))./sqrt(length(FP_reaction_mid_pre(ind_mid_pre_min,2)));
% SEM_mid_mid = std(FP_reaction_mid_pre(ind_mid_pre_mid,2))./sqrt(length(FP_reaction_mid_pre(ind_mid_pre_mid,2)));
% SEM_mid_max = std(FP_reaction_mid_pre(ind_mid_pre_max,2))./sqrt(length(FP_reaction_mid_pre(ind_mid_pre_max,2)));
% SEM_mid=[SEM_mid_min;SEM_mid_mid;SEM_mid_max];
%% plot (n-1)=1.5

mean_max_pre_min=mean(FP_reaction_max_pre(ind_max_pre_min,2));
mean_max_pre_mid=mean(FP_reaction_max_pre(ind_max_pre_mid,2));
mean_max_pre_max=mean(FP_reaction_max_pre(ind_max_pre_max,2));
mixed_mean_max=[mean_max_pre_min;mean_max_pre_mid;mean_max_pre_max];
FP_single=[0.5;1.0;1.5];
% SEM_max_min = std(FP_reaction_max_pre(ind_max_pre_min,2))./sqrt(length(FP_reaction_max_pre(ind_max_pre_min,2)));
% SEM_max_mid = std(FP_reaction_max_pre(ind_max_pre_mid,2))./sqrt(length(FP_reaction_max_pre(ind_max_pre_mid,2)));
% SEM_max_max = std(FP_reaction_max_pre(ind_max_pre_max,2))./sqrt(length(FP_reaction_max_pre(ind_max_pre_max,2)));
% SEM_max=[SEM_max_min;SEM_max_mid;SEM_max_max];
%%  plot 
% figure(20); clf(20)
% set(gcf, 'unit', 'centimeters', 'position',[2 2 22 18], 'paperpositionmode', 'auto' )
% subplot(2, 6, [1 2 3 4 7 8 9 10])
% %plot(FP_single,mixed_mean','color','k')
% errorbar(FP_single,mixed_mean',SEM,'K-o') 
% box off
% set(gca, 'nextplot', 'add', 'ylim', [0 600], 'xlim', [0 2])
% 
% xlabel ('FP (s)')
% ylabel ('Average reaction time (ms)')
% hainfo=subplot(2, 6, [ 5 6  11 12])
% 
% axis off

%% save data
bout.Metadata = med_to_protocol(filename);

% axes(hainfo)
% 
% text(0, 0.8, strrep(bout.Metadata.ProtocolName, '_', '-'))
% text(0,0.7, upper(bout.Metadata.SubjectName))
% text(0, 0.6, bout.Metadata.Date)
% text(0, 0.5, bout.Metadata.StartTime)

bout.SessionName     =      session_name;
bout.Correct         =      ind_good_presses;
bout.Premature       =      n_FP_premature;
bout.Late            =      n_FP_late;
bout.ReactionTime.min    =      FP_reaction(ind_FP_reaction_min,3);
bout.ReactionTime.mid    =      FP_reaction(ind_FP_reaction_mid,3);
bout.ReactionTime.max    =      FP_reaction(ind_FP_reaction_max,3);
bout.MixedMean.min       =      mixed_mean_min;
bout.MixedMean.mid       =      mixed_mean_mid;
bout.MixedMean.max       =      mixed_mean_max;
% bout.SEM.min       =      SEM_min;
% bout.SEM.mid       =      SEM_mid;
% bout.SEM.max       =      SEM_max;
bout.FP.min.min = [FP_reaction_min_pre(ind_min_pre_min,2)];
bout.FP.min.mid = [FP_reaction_min_pre(ind_min_pre_mid,2)];
bout.FP.min.max = [FP_reaction_min_pre(ind_min_pre_max,2)];
bout.FP.mid.min = [FP_reaction_mid_pre(ind_mid_pre_min,2)];
bout.FP.mid.mid = [FP_reaction_mid_pre(ind_mid_pre_mid,2)];
bout.FP.mid.max = [FP_reaction_mid_pre(ind_mid_pre_max,2)];
bout.FP.max.min = [FP_reaction_max_pre(ind_max_pre_min,2)];
bout.FP.max.mid = [FP_reaction_max_pre(ind_max_pre_mid,2)];
bout.FP.max.max = [FP_reaction_max_pre(ind_max_pre_max,2)];
bout.FPsingle        =      FP_single;
bout.pressdurs =press_durs_mixed;
% savename = ['B_' upper(bout.Metadata.SubjectName) '_' strrep(bout.Metadata.Date, '-', '_') '_' strrep(bout.Metadata.ProtocolName, '_', '-')];
% b=bout;
% save (savename, 'b')
% 
% mkdir('Fig');
% savename=fullfile(pwd, 'Fig', savename)
% 
% print (gcf,'-dpng', [savename])
% print (gcf,'-dpdf', [savename], '-bestfit')
% saveas(gcf, savename, 'fig')
