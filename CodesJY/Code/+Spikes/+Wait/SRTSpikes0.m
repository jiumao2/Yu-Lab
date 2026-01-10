function PSTHOut = SRTSpikes(r, ind, varargin)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port.
% V5: add poke events following an unsuccesful release

% SRTSpikes(r, 13, 'FRrange', [0 35])

% ind can be singular or a vector

% 8.9.2020
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

% 5/7/2023 revised to adopt new FP schedule (e.g., 500 1000 1500)

set_matlab_default;
takeall = 0;

if isempty(ind)

    ind =  (1:length(r.Units.SpikeTimes));
    takeall =1;
else
    if length(ind) ==2
        ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
        ind = ind_unit;
    end
end
ku_all = ind; % ind is used in different places

tic
ComputeRange = [];  % this is the range where time is extracted. Event times outside of this range will be discarded. Empty means taking everything

PressTimeDomain = [2500 2500]; % default
ReleaseTimeDomain = [1000 2000];
RewardTimeDomain = [2000 2000];
TriggerTimeDomain = [1000 2000];
reward_col = [237, 43, 42]/255;
ToSave = 'on';
r_name=[];
savepath = pwd;
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            %             case 'FRrange'
            %                 FRrange = varargin{i+1};
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ReleaseTimeDomain'
                ReleaseTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ComputeRange'
                ComputeRange = varargin{i+1}*1000; % convert to ms
            case 'ToSave'
                ToSave = varargin{i+1};
            case 'r_name'
                r_name = varargin{i+1};
            case 'path' % add by WXN 20250417
                savepath = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

rb                            =       r.Behavior;
% all FPs
if isfield(r, 'BehaviorClass')
    if length(r.BehaviorClass)>1
        r.BehaviorClass = r.BehaviorClass{1};
    end
    MixedFPs                =       r.BehaviorClass.MixedFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
    Subject = r.BehaviorClass.Subject;
    SessionInfo = r.BehaviorClass.Date;
else
    MixedFPs = Spikes.findFP(r);
    Subject = r.Meta(1).Subject;
    SessionInfo = strrep( r.Meta(1).DateTime(1:11), '-', '_');
end
nFPs   =       length(MixedFPs);
% maxFP = max(MixedFPs);
% if max(MixedFPs)==1500
%     nFPs = 2;
% else
%     nFPs = 1;
% end


%% Check if opto is applied
if isfield(r, 'Analog') && isfield(r.Analog, 'Opto')
    t_opto = r.Analog.Opto(:, 1);
    opto     = r.Analog.Opto(:, 2);
    opto_threshold = max(opto)*0.5;
    t_separation = 1*1000;
    % begs of opto stim
    opto_above = find(opto > opto_threshold);
    ind_seps = find(diff(opto_above)>t_separation);
    opto_begs = [opto_above(1); opto_above(ind_seps+1)];
    opto_ends = [opto_above(ind_seps); opto_above(end)];
    
    t_opto_begs = t_opto(opto_begs);
    t_opto_ends = t_opto(opto_ends);
else
    t_opto_begs = [];
    t_opto_ends = [];
end

%% Presses
ind_press                                 =       find(strcmp(rb.Labels, 'LeverPress'));
t_presses                                 =       Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_press));
disp(['Number of presses is ' num2str(length(t_presses))])
% index and time of correct presses
t_correct_presses                     =       t_presses(rb.CorrectIndex);
FPs_correct_presses                =       Spikes.SRT.shape_it(rb.Foreperiods(rb.CorrectIndex));
% get correct response
for i =1:nFPs
    t_correct_presses_sorted{i}      =   t_correct_presses(FPs_correct_presses == MixedFPs(i));
end
t_correct_presses_sorted{nFPs+1}  = t_correct_presses(FPs_correct_presses < max(MixedFPs));
%% Release
ind_release                              =        find(strcmp(rb.Labels, 'LeverRelease'));
t_releases                               =        Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_release));
t_correct_releases                       =        t_releases(rb.CorrectIndex);
for i =1:nFPs
    t_correct_releases_sorted{i}      =         t_correct_releases(FPs_correct_presses == MixedFPs(i));
end
t_correct_releases_sorted{nFPs+1}      =         t_correct_releases(FPs_correct_presses < max(MixedFPs));

rt_correct                                     =         t_correct_releases - t_correct_presses - FPs_correct_presses;
% reaction time
indsort = cell(1, nFPs);

checkplot = 0;
% check releases
if checkplot
    figure;
   
    % plot raster
    nplot = length(t_correct_releases);
    axes('unit', 'normalized', ...
        'position', [.1 .1 .8 .8],...
        'nextplot', 'add', ...
        'xlim', [-1 2]*1000, 'ylim', [0 nplot+1], 'ydir', 'reverse', ...
        'ytick', [0 20], 'xtick', [-2000:1000:2000],...
        'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0, 'color', 'none', ...
        'ticklength',[.015 .1]);
    axis off
    for k =1:nplot
        xx = t_correct_presses(k);
        yy = [0 .8]+k;
        if ~isempty(xx)
            line([0; 0], yy, 'color', 'k')
        end
        xx = t_correct_releases(k)-xx;
        yy = [0 .8]+k;
        if ~isempty(xx)
            plot(xx, yy, 'o', 'color', 'r')
        end

        % Plot reaction time
        xx = rt_correct(k)+FPs_correct_presses(k);
        yy = [0 1]+k;
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'c', 'linewidth', 1)
        end
    end
end


for i =1:nFPs+1
    if i == nFPs+1
        rt_correct_sorted{i}                        =          rt_correct(FPs_correct_presses < max(MixedFPs));
    % [rt_correct_sorted{i}, indsort{i}]          =          sort(rt_correct_sorted{i});
    % t_correct_presses_sorted{i}                 =          t_correct_presses_sorted{i}(indsort{i});
    % t_correct_releases_sorted{i}                =          t_correct_releases_sorted{i}(indsort{i});

    else
        rt_correct_sorted{i}                        =          rt_correct(FPs_correct_presses == MixedFPs(i));
    [rt_correct_sorted{i}, indsort{i}]          =          sort(rt_correct_sorted{i});
    t_correct_presses_sorted{i}                 =          t_correct_presses_sorted{i}(indsort{i});
    t_correct_releases_sorted{i}                =          t_correct_releases_sorted{i}(indsort{i});

    end
    
    if checkplot
        figure;

        % plot raster
        nplot = length(t_correct_presses_sorted{i});
        axes('unit', 'normalized', ...
            'position', [.1 .1 .8 .8],...
            'nextplot', 'add', ...
            'xlim', [-1 2]*1000, 'ylim', [0 nplot+1], 'ydir', 'reverse', ...
            'ytick', [0 20], 'xtick', [-2000:1000:2000],...
            'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
            'XTickLabelRotation', 0, 'color', 'none', ...
            'ticklength',[.015 .1]);
        axis off
        for k =1:nplot
            xx = t_correct_presses_sorted{i}(k);
            yy = [0 .8]+k;
            if ~isempty(xx)
                line([0; 0], yy, 'color', 'k')
            end
            xx = t_correct_releases_sorted{i}(k)-xx;
            yy = [0 .8]+k;
            if ~isempty(xx)
                plot(xx, yy, 'o', 'color', 'r')
            end

            % Plot reaction time
            xx = rt_correct_sorted{i}(k)+MixedFPs(i);
            yy = [0 1]+k;
            if ~isempty(xx)
                line([xx; xx], yy, 'color', 'c', 'linewidth', 1)
            end
        end
    end
end

rt_presses_sorted                        =          rt_correct_sorted;
rt_releases_sorted                       =          rt_correct_sorted;

% check releases

if checkplot

    figure;
    ifp = 1;
    % plot raster
    nplot = length(t_correct_presses_sorted{ifp});
    axes('unit', 'normalized', ...
        'position', [.1 .1 .8 .8],...
        'nextplot', 'add', ...
        'xlim', [-1 2]*1000, 'ylim', [0 nplot+1], 'ydir', 'reverse', ...
        'ytick', [0 20], 'xtick', [-2000:1000:2000],...
        'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0, 'color', 'none', ...
        'ticklength',[.015 .1]);
    axis off
    for k =1:nplot
        xx = t_correct_presses_sorted{ifp}(k);
        yy = [0 .8]+k;
        if ~isempty(xx)
            line([0; 0], yy, 'color', 'k')
        end
        xx = t_correct_releases_sorted{ifp}(k)-xx;
        yy = [0 .8]+k;
        if ~isempty(xx)
            plot(xx, yy, 'o', 'color', 'r')
        end

        % Plot reaction time
        xx = rt_correct_sorted{ifp}(k)+MixedFPs(ifp);
        yy = [0 1]+k;
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'c', 'linewidth', 1)
        end

    end

end



%% Premature responses



ind_premature                   =            find(strcmp(r.Behavior.Outcome, 'Premature'));
t_presses_premature         =            t_presses(ind_premature);
t_releases_premature         =           t_releases(ind_premature);
FPs_premature                  =            Spikes.SRT.shape_it(rb.Foreperiods(ind_premature));

ind_FPs=cell(1, nFPs); % index of FPs
t_premature_presses_FPs         =       cell(1, nFPs);
t_premature_releases_FPs        =       cell(1, nFPs);
premature_duration                    =        cell(1, nFPs);
indx_premature_duration            =        cell(1, nFPs);

t_premature_presses = []; % sorted version time of premature press
t_premature_releases = []; % sorted, time of premature releases
premature_duration_presses = [];
premature_duration_releases = [];
FPs_premature_presses = [];
FPs_premature_releases= [];

for i=1:nFPs+1
    if  i == nFPs+1
        ind_FPs{i}    =  find(FPs_premature < max(MixedFPs));
    else
    ind_FPs{i}    =  find(FPs_premature == MixedFPs(i));
    end
    t_premature_presses_FPs{i} =  t_presses_premature(ind_FPs{i});
    t_premature_releases_FPs{i} =  t_releases_premature(ind_FPs{i});
    
    premature_duration_iFP =  t_premature_releases_FPs{i} -  t_premature_presses_FPs{i};
    [premature_duration{i}, indx_premature_duration{i}] =  sort(premature_duration_iFP);
    t_premature_presses_FPs{i} = t_premature_presses_FPs{i}(indx_premature_duration{i});
    t_premature_releases_FPs{i} = t_premature_releases_FPs{i}(indx_premature_duration{i});
    if i < nFPs+1
    t_premature_presses = [t_premature_presses; t_premature_presses_FPs{i}];
    t_premature_releases = [t_premature_releases; t_premature_releases_FPs{i}];
    
    premature_duration_presses = [premature_duration_presses;  t_premature_releases_FPs{i}-t_premature_presses_FPs{i}];
    premature_duration_releases = [premature_duration_releases;  t_premature_releases_FPs{i}-t_premature_presses_FPs{i}];
    
    FPs_premature_presses = [FPs_premature_presses; MixedFPs(i)*ones(length(ind_FPs{i}), 1)];
    FPs_premature_releases = [FPs_premature_releases; MixedFPs(i)*ones(length( ind_FPs{i}), 1)];
    end
end

%% Late response
ind_late                   =            find(strcmp(r.Behavior.Outcome, 'Late'));
t_presses_late         =            t_presses(ind_late);
t_releases_late         =           t_releases(ind_late);
FPs_late                  =            Spikes.SRT.shape_it(rb.Foreperiods(ind_late));

ind_FPs                             =       cell(1, nFPs); % index of FPs
t_late_presses_FPs            =       cell(1, nFPs);
t_late_releases_FPs           =       cell(1, nFPs);
late_duration                    =        cell(1, nFPs);
indx_late_duration            =        cell(1, nFPs);

t_late_presses = []; % sorted version time of premature press
t_late_releases = []; % sorted, time of premature releases
late_duration_presses = [];
late_duration_releases = [];
FPs_late_presses = [];
FPs_late_releases= [];

for i=1:nFPs+1
    if i == nFPs+1
        ind_FPs{i}    =  find(FPs_late < max(MixedFPs));
    else
     ind_FPs{i}    =  find(FPs_late == MixedFPs(i));
    end
    t_late_presses_FPs{i} =  t_presses_late(ind_FPs{i});
    t_late_releases_FPs{i} =  t_releases_late(ind_FPs{i});
    
    late_duration_iFP =  t_late_releases_FPs{i} -  t_late_presses_FPs{i};
    [late_duration{i}, indx_late_duration{i}] =  sort(late_duration_iFP);
    t_late_presses_FPs{i} = t_late_presses_FPs{i}(indx_late_duration{i});
    t_late_releases_FPs{i} = t_late_releases_FPs{i}(indx_late_duration{i});
    if i < nFPs+1
    t_late_presses = [t_late_presses; t_late_presses_FPs{i}];
    t_late_releases = [t_late_releases; t_late_releases_FPs{i}];
    
    late_duration_presses = [late_duration_presses;  t_late_releases_FPs{i}-t_late_presses_FPs{i}];
    late_duration_releases = [late_duration_releases;  t_late_releases_FPs{i}-t_late_presses_FPs{i}];
    
    FPs_late_presses = [FPs_late_presses; MixedFPs(i)*ones(length( ind_FPs{i}), 1)];
    FPs_late_releases = [FPs_late_releases; MixedFPs(i)*ones(length( ind_FPs{i}), 1)];
    end
end

%%  Rewards
ind_rewards                =       find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards                    =       Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_rewards));
move_time                  =       zeros(1, length(t_rewards));
tmax                            =      10000; % allow at most 10 second between a successful release and poke
t_rewards_FP               =       zeros(1, length(t_rewards)); % find out press FP associated with each reward

for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correct_releases;
    dt = dt(dt>0 & dt<tmax); % reward must be collected within 2 sec after a correct release
    if ~isempty(dt)
        move_time(i) = dt(end);
        % FPs_correct_presses
        ind = find(t_correct_releases==t_rewards(i)-dt(end));
        if ~isempty(ind)
            %             disp(ind)
            t_rewards_FP(i) = FPs_correct_presses(ind);
        else
            disp('Not found')
        end
    else
        move_time(i) = NaN;
    end
end

t_rewards                         =           t_rewards(~isnan(move_time));
move_time                       =           move_time(~isnan(move_time));
FP_rewards                     =            t_rewards_FP(~isnan(move_time));
% Check movement time distribution
Edges =(0:100:5000);
figure(45); clf;
histogram(move_time, Edges)
xlabel('Movement time (ms)')
ylabel('Count')

% sort reward according to FP
% MixedFPs                =       r.BehaviorClass.MixedFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
% nFPs                        =       length(MixedFPs);
t_rewards_sorted = cell(1, nFPs+1);
move_time_sorted = cell(1, nFPs+1);
for ifp =1:nFPs+1
    if ifp == nFPs+1
        ind = find(FP_rewards < max(MixedFPs));
    else
    ind = find(FP_rewards == MixedFPs(ifp));
    end
    t_rewards_sorted{ifp} = t_rewards(ind);
    move_time_sorted{ifp} = move_time(ind);
    % rank them

    [move_time_sorted{ifp}, indsort] = sort(move_time_sorted{ifp});
    t_rewards_sorted{ifp} =  t_rewards_sorted{ifp}(indsort);
end

move_time = move_time_sorted;
t_rewards = t_rewards_sorted;

% Find out the reward pokes (last poke before valve.)
% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_portin));
% have a look at the difference between poke and trigger (looks like there
% might be some contamination)
t_reward_pokes              =          cell(1, nFPs+1);
dt                                     =          []; % poke leading to reward
for ifp = 1:nFPs+1
    for i=1:length(t_rewards{ifp})
        t_portin_this = t_portin(t_portin >t_rewards{ifp}(i)-1550 & t_portin<t_rewards{ifp}(i)+100);
        if ~isempty(t_portin_this)
            t_reward_pokes{ifp}(i) = t_portin_this(1);
            dt = [dt t_reward_pokes{ifp}(i)-t_rewards{ifp}(i)];
            %             disp(dt);
        else
            t_reward_pokes{ifp}(i) = NaN;
        end
    end
end


% due to technical error, pokes that occured 200 ms after reward is not
% real, should be corrected. (I don' t see this actually. Omitted for now 5/3/2023)
% check poke after reward
t_rewards_prime = cell2mat(t_rewards(1:end-1)');
dt1=zeros(1, length(t_rewards_prime));
for i =1:length(t_rewards_prime)
    %     disp(i)
    
    indx = find(t_portin>t_rewards_prime(i), 1, 'first');
    if ~isempty(indx)
        dt1(i) = t_portin(indx) - t_rewards_prime(i);
    end
end

% disp(t_reward_pokes);

Edges =(0:1:200);
figure(46); clf;
subplot(2, 2, 1)
histogram(dt1, Edges);
xlabel('latency from reward to poke (ms)')
subplot(2, 2, 2)
histogram(dt, Edges);
xlabel('latency from poke to reward (ms)')
ylabel('Count')
subplot(2, 2, [3 4])
t_lim = [-500 500];
set(gca, 'xlim', t_lim, 'ylim', [0 length(t_rewards)], 'nextplot', 'add')

stack = 0;
for ifp =1:nFPs
    for i =1:length(t_rewards{ifp})
        stack = stack+1;
        t_relative = t_portin - t_rewards{ifp}(i);
        t_relative = t_relative(t_relative>t_lim(1) & t_relative<t_lim(2));
        [~, ind] = min(abs(t_rewards{ifp}(i)-t_reward_pokes{ifp}));
        if ~isempty(t_relative)
            scatter(t_relative, stack, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
        end
        plot(t_reward_pokes{ifp}(ind) -t_rewards{ifp}(i), stack, '+', 'markersize', 4, 'linewidth', 1, 'color', 'c')
    end
end

% bad (nonrewarded) poke: sometimes, rat will poke even after an unsuccessful response.
% Pick these out and plot them
t_nonreward_pokes = [];
move_time_nonreward = [];
bad_responses = [t_premature_releases; t_late_releases];
for i =1:length(bad_responses)
    t_ipoke = t_portin(find(t_portin>bad_responses(i), 1, 'first')); % first poke after a bad release
    t_ipress = t_presses(find(t_presses>bad_responses(i), 1, 'first'));
    if ~isempty(t_ipoke) && ~isempty(t_ipress) && t_ipoke < t_ipress
        t_nonreward_pokes            =    [t_nonreward_pokes t_ipoke];
        move_time_nonreward       =     [move_time_nonreward t_ipoke-bad_responses(i)];
    end
end
[move_time_nonreward, indsort_nonreward_pokes] =  sort(move_time_nonreward);
t_nonreward_pokes = t_nonreward_pokes(indsort_nonreward_pokes);

%% Trigger
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_triggers)); % trigger time in ms.

triggers_types = cell(1, length(t_triggers));
triggers_FPs    = zeros(1, length(t_triggers));
triggers_RTs  = NaN*ones(1, length(t_triggers)); % reaction time (used for ranking later)

for i =1:length(t_triggers)
    it_trigger = t_triggers(i);
    % find the most recent press
    ind_recent_press = find(t_presses<it_trigger, 1, 'last');
    if ~isempty(ind_recent_press) && abs(t_presses(ind_recent_press)-it_trigger)<2500
        % check the condition
        triggers_types{i} = r.Behavior.Outcome{ind_recent_press};
        triggers_FPs(i) = r.Behavior.Foreperiods(ind_recent_press);
        ind_following_releases = find(t_releases>it_trigger, 1, 'first');
        if ~isempty(ind_following_releases)
            triggers_RTs(i) = t_releases(ind_following_releases) - it_trigger;
        end
    else
        triggers_types{i} = 'NaN';
        triggers_FPs(i) = NaN;
    end
end

t_triggers_late = t_triggers(strcmp(triggers_types, 'Late'));
FP_triggers_late = triggers_FPs(strcmp(triggers_types, 'Late'));
triggers_RTs_late = triggers_RTs(strcmp(triggers_types, 'Late'));
[triggers_RTs_late, ind_sorted] = sort(triggers_RTs_late);
t_triggers_late = t_triggers_late(ind_sorted);
FP_triggers_late = FP_triggers_late(ind_sorted);
% trigger according to FPs
t_triggers_FPs = cell(1, nFPs+1);
RT_triggers_FPs = cell(1, nFPs+1);

for i =1:nFPs
    % short trigger (to plot)
    t_triggers_FPs{i}           =            t_triggers(strcmp(triggers_types, 'Correct') & triggers_FPs == MixedFPs(i));
    RT_triggers_FPs{i}      =            triggers_RTs(strcmp(triggers_types, 'Correct') & triggers_FPs == MixedFPs(i));
    % sort according to reaction time
    [RT_triggers_FPs{i}, ind_sorted] = sort(RT_triggers_FPs{i});
    t_triggers_FPs{i} = t_triggers_FPs{i}(ind_sorted);
end
% FP < 1500, rank as FP, not RT
t_triggers_FPs{nFPs+1}           =            t_triggers(strcmp(triggers_types, 'Correct') & triggers_FPs < max(MixedFPs));
RT_triggers_FPs{nFPs+1}      =            triggers_RTs(strcmp(triggers_types, 'Correct') & triggers_FPs < max(MixedFPs));

%% Check ComputeRange

if ~isempty(ComputeRange)
    t_presses(t_presses<ComputeRange(1) | t_presses>ComputeRange(2))=[];
    
    for i=1:nFPs+1
        to_remove = find(t_correct_presses_sorted{i}<ComputeRange(1) | t_correct_presses_sorted{i}>ComputeRange(2) | t_correct_releases_sorted{i}<ComputeRange(1) | t_correct_releases_sorted{i}>ComputeRange(2));
        t_correct_releases_sorted{i}(to_remove)       =        [];
        rt_releases_sorted{i}(to_remove)                     =       [];
        t_correct_presses_sorted{i}(to_remove)       =        [];
        rt_presses_sorted{i}(to_remove)                     =       [];
    end
    to_remove_premature = find(t_premature_presses<ComputeRange(1) | t_premature_presses>ComputeRange(2) | t_premature_releases<ComputeRange(1) | t_premature_releases>ComputeRange(2));
    t_premature_presses(to_remove_premature)       =       [];
    premature_duration_presses(to_remove_premature)       =       [];
    FPs_premature_presses(to_remove_premature)  =       [];
    t_premature_releases(to_remove_premature)       =        [];
    premature_duration_releases(to_remove_premature)     =       [];
    FPs_premature_releases(to_remove_premature)  =       [];
    
    to_remove_late = find(t_late_presses<ComputeRange(1) | t_late_presses>ComputeRange(2) | t_late_releases<ComputeRange(1) | t_late_releases>ComputeRange(2));
    t_late_presses(to_remove_late)       =       [];
    late_duration_presses(to_remove_late)       =       [];
    FPs_late_presses(to_remove_late)  =       [];
    t_late_releases(to_remove_late)       =        [];
    late_duration_releases(to_remove_late)     =       [];
    FPs_late_releases(to_remove_late)  =       [];
    
    for i=1:nFPs+1
        to_remove_rewardpokes =  find(t_reward_pokes{i}<ComputeRange(1) | t_reward_pokes{i}>ComputeRange(2));
        t_reward_pokes{i}(to_remove_rewardpokes) = [];
        move_time{i}(to_remove_rewardpokes) = [];
    end
    
    to_remove_nonrewardpokes = find(t_nonreward_pokes<ComputeRange(1) | t_nonreward_pokes>ComputeRange(2));
    t_nonreward_pokes(to_remove_nonrewardpokes) = [];
    move_time_nonreward(to_remove_nonrewardpokes) = [];
    
    for i =1:nFPs+1
        to_remove = find(t_triggers_FPs{i}<ComputeRange(1) | t_triggers_FPs{i}>ComputeRange(2));
        t_triggers_FPs{i}(to_remove) = [];
        RT_triggers_FPs{i}(to_remove) = [];
    end
    
    to_remove_trigger_late = find(t_triggers_late<ComputeRange(1) | t_triggers_late>ComputeRange(2));
    t_triggers_late(to_remove_trigger_late) = [];
    triggers_RTs_late(to_remove_trigger_late) = [];
    FP_triggers_late(to_remove_trigger_late) = [];
    
end

%% Check opto
if ~isempty(t_opto_begs)
    % PressTimeDomain and ReleaseTimeDomain
    % check opto
    % the idea is none of PSTH computing range should fall inside any laser
    % stim periods
    figure(48); clf(48);
    axes('nextplot', 'add'); title('Optogenetic stimulation');
    for i =1:length(t_opto_begs)
        plotshaded([t_opto_begs(i) t_opto_ends(i)], [0 0; 8 8], 'b', 0.8);
    end
    hold on
    to_remove_press = [];
    for i =1:length(t_presses)
        event_beg = t_presses(i)-PressTimeDomain(1);
        event_end = t_presses(i)+PressTimeDomain(2);
        line([event_beg event_end], [7.5 7.5 ], 'color', 'k','linewidth', 4)
        % event_beg or event_end cannot be inside of any stim epochs.
        % opto_beg or opto_end cannot be inside of any event epochs
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_press = [to_remove_press i];
            plot(event_beg, 7.5, 'ro','markersize', 6)
        end
    end
    t_presses(to_remove_press) = [];
    text(100,7.8, 'Presses (all)', 'fontname', 'Arial', 'fontsize', 8)
    
    to_remove = cell(1, nFPs);
    for k =1:nFPs+1
        to_remove{k} = [];
        for i =1:length(t_correct_presses_sorted{k})
            event_beg = t_correct_presses_sorted{k}(i)-PressTimeDomain(1);
            event_end = t_correct_presses_sorted{k}(i)+PressTimeDomain(2);
            line([event_beg event_end], [1 1], 'color', 'k','linewidth', 4)
            % event_beg or event_end cannot be inside of any stim epochs.
            % opto_beg or opto_end cannot be inside of any event epochs
            if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
                to_remove{k}  = [ to_remove{k}  i];
                plot(event_beg, 1, 'ro','markersize', 6)
            end
        end
        for i =1:length(t_correct_releases_sorted{k})
            event_beg = t_correct_releases_sorted{k}(i)-ReleaseTimeDomain(1);
            event_end = t_correct_releases_sorted{k}(i)+ReleaseTimeDomain(2);
            line([event_beg event_end], [2 2], 'color', 'k','linewidth', 4)
            if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
                to_remove{k}  = [ to_remove{k}  i];
                plot(event_beg, 2, 'ro','markersize', 6)
            end
        end
        
        to_remove{k} = unique(to_remove{k});
        t_correct_presses_sorted{k}( to_remove{k})       =        [];
        rt_presses_sorted{k}( to_remove{k})                     =       [];
        t_correct_releases_sorted{k}( to_remove{k})       =        [];
        rt_releases_sorted{k}( to_remove{k})                     =       [];
    end
    
    to_remove_premature = [];
    for i =1:length(t_premature_presses)
        event_beg =t_premature_presses(i)-PressTimeDomain(1);
        event_end = t_premature_presses(i)+PressTimeDomain(2);
        line([event_beg event_end], [3 3], 'color', 'm','linewidth', 4)
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_premature = [to_remove_premature i];
            plot(event_beg, 3, 'ro','markersize', 6)
        end
    end
    
    for i =1:length(t_premature_releases)
        event_beg =t_premature_releases(i)-ReleaseTimeDomain(1);
        event_end = t_premature_releases(i)+ReleaseTimeDomain(2);
        line([event_beg event_end], [3.5 3.5], 'color', 'm','linewidth', 4)
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_premature = [to_remove_premature i];
            plot(event_beg, 3.5, 'ro','markersize', 6)
        end
    end
    
    to_remove_premature = unique(to_remove_premature);
    text(100, 3.2, 'Press|Premature', 'fontname', 'Arial', 'fontsize', 8)
    t_premature_presses(to_remove_premature)       =       [];
    premature_duration_presses(to_remove_premature)       =       [];
    FPs_premature_presses(to_remove_premature)  =       [];
    
    text(100, 3.7, 'Release|Premature', 'fontname', 'Arial', 'fontsize', 8)
    t_premature_releases(to_remove_premature)       =        [];
    premature_duration_releases(to_remove_premature)     =       [];
    FPs_premature_releases(to_remove_premature)  =       [];
    
    to_remove_late = [];
    for i =1:length(t_late_presses)
        event_beg =t_late_presses(i)-PressTimeDomain(1);
        event_end = t_late_presses(i)+PressTimeDomain(2);
        line([event_beg event_end], [4 4], 'color', 'c','linewidth', 4)
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_late = [to_remove_late i];
            plot(event_beg, 4, 'ro','markersize', 6)
        end
    end
    
    for i =1:length(t_late_releases)
        event_beg =t_late_releases(i)-ReleaseTimeDomain(1);
        event_end = t_late_releases(i)+ReleaseTimeDomain(2);
        line([event_beg event_end], [4.5 4.5], 'color', 'c','linewidth', 4)
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_late = [to_remove_late i];
            plot(event_beg, 4.5, 'ro','markersize', 6)
        end
    end
    
    to_remove_late = unique(to_remove_late);
    text(100, 4.2, 'Press|Late', 'fontname', 'Arial', 'fontsize', 8)
    t_late_presses(to_remove_late)       =       [];
    late_duration_presses(to_remove_late)       =       [];
    FPs_late_presses(to_remove_late)  =       [];
    
    text(100, 4.7, 'Release|Late', 'fontname', 'Arial', 'fontsize', 8)
    t_late_releases(to_remove_late)       =        [];
    late_duration_releases(to_remove_late)     =       [];
    FPs_late_releases(to_remove_late)  =       [];
    
    for ifp = 1:length(t_reward_pokes)
        to_remove_rewardpokes = [];
        for i =1:length(t_reward_pokes{ifp})
            event_beg =t_reward_pokes{ifp}(i)-RewardTimeDomain(1);
            event_end = t_reward_pokes{ifp}(i)+RewardTimeDomain(2);
            line([event_beg event_end], [5 5], 'color', 'g','linewidth', 4)
            if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
                to_remove_rewardpokes = [to_remove_rewardpokes i];
                plot(event_beg, 5, 'ro','markersize', 6)
            end
        end
        t_reward_pokes{ifp}(to_remove_rewardpokes) = [];
        move_time{ifp}(to_remove_rewardpokes) = [];
        text(100, 5.2, 'Reward poke', 'fontname', 'Arial', 'fontsize', 8)
    end
    
    to_remove_nonrewardpokes = [];
    for i =1:length(t_nonreward_pokes)
        event_beg =t_nonreward_pokes(i)-RewardTimeDomain(1);
        event_end = t_nonreward_pokes(i)+RewardTimeDomain(2);
        line([event_beg event_end], [5.5 5.5], 'color', 'g','linewidth', 4)
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_rewardpokes = [to_remove_rewardpokes i];
            plot(event_beg, 5.5, 'ro','markersize', 6)
        end
    end
    t_nonreward_pokes(to_remove_nonrewardpokes) = [];
    move_time_nonreward(to_remove_nonrewardpokes) = [];
    text(100, 5.7, 'Nonreward poke', 'fontname', 'Arial', 'fontsize', 8)
    
    for k =1:nFPs
        to_remove_trigger = [];
        for i =1:length(t_triggers_FPs{k})
            event_beg =t_triggers_FPs{k}(i)-TriggerTimeDomain(1);
            event_end = t_triggers_FPs{k}(i)+TriggerTimeDomain(2);
            line([event_beg event_end], [6 6], 'color', 'r','linewidth', 4)
            if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
                to_remove_trigger = [to_remove_trigger i];
                plot(event_beg, 6, 'ro','markersize', 6)
            end
        end
        t_triggers_FPs{k}(to_remove_trigger) = [];
        RT_triggers_FPs{k}(to_remove_trigger) = [];
        text(100, 6.2, 'Trigger|Short', 'fontname', 'Arial', 'fontsize', 8)
    end
    
    to_remove_trigger_late = [];
    for i =1:length(t_triggers_late)
        event_beg =t_triggers_late(i)-TriggerTimeDomain(1);
        event_end = t_triggers_late(i)+TriggerTimeDomain(2);
        line([event_beg event_end], [7 7], 'color', 'r','linewidth', 4)
        if ~isempty(find((t_opto_begs-event_beg).*(t_opto_ends-event_beg)<0 |  (t_opto_begs-event_end).*(t_opto_ends-event_end)<0 | (t_opto_begs-event_beg).*(t_opto_ends-event_end)<0, 1))
            to_remove_trigger_late = [to_remove_trigger_late i];
            plot(event_beg, 7, 'ro','markersize', 6)
        end
    end
    t_triggers_late(to_remove_trigger_late) = [];
    triggers_RTs_late(to_remove_trigger_late) = [];
    FP_triggers_late(to_remove_trigger_late) = [];
    text(100, 7.2, 'Trigger|Late', 'fontname', 'Arial', 'fontsize', 8);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% all events that fall within opto-stim duration are not removed.
    %%%%% %%%%%%%%%%%%%%%%%%%%%%%%%
end
%% Summarize


if checkplot

    figure;
    ifp = 1;
    % plot raster
    nplot = length(t_correct_presses_sorted{ifp});
    axes('unit', 'normalized', ...
        'position', [.1 .1 .8 .8],...
        'nextplot', 'add', ...
        'xlim', [-1 2]*1000, 'ylim', [0 nplot+1], 'ydir', 'reverse', ...
        'ytick', [0 20], 'xtick', [-2000:1000:2000],...
        'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0, 'color', 'none', ...
        'ticklength',[.015 .1]);
    axis off
    for k =1:nplot
        xx = t_correct_presses_sorted{ifp}(k);
        yy = [0 .8]+k;
        if ~isempty(xx)
            line([0; 0], yy, 'color', 'k')
        end
        xx = t_correct_releases_sorted{ifp}(k)-xx;
        yy = [0 .8]+k;
        if ~isempty(xx)
            plot(xx, yy, 'o', 'color', 'r')
        end

        % Plot reaction time
        xx = rt_presses_sorted{ifp}(k)+MixedFPs(ifp);
        yy = [0 1]+k;
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'c', 'linewidth', 1)
        end

    end

end

PSTHOut.ANM_Session                               =     {Subject, SessionInfo};
PSTHOut.Presses.Labels                             =     [repmat({'Correct'}, 1, length(t_correct_presses_sorted)-1),'Substandard', 'Premature', 'Late', 'All'];
PSTHOut.Presses.Time                                =   cell(1, length(PSTHOut.Presses.Labels));
PSTHOut.Presses.Time(1: length(t_correct_presses_sorted))  = t_correct_presses_sorted;
PSTHOut.Presses.Time(length(t_correct_presses_sorted)+1)  = {t_premature_presses};
PSTHOut.Presses.Time(length(t_correct_presses_sorted)+2)  = {t_late_presses};
PSTHOut.Presses.Time(length(t_correct_presses_sorted)+3)  = {t_presses};
PSTHOut.Presses.FP                                    =     {MixedFPs, MixedFPs(1:end-1),FPs_premature_presses, FPs_late_presses};
PSTHOut.Presses.RT_Correct                      =     rt_presses_sorted;
PSTHOut.Presses.PressDur.Premature        =     premature_duration_presses;
PSTHOut.Presses.PressDur.Late                  =     late_duration_presses;

PSTHOut.Releases.Labels                             =     [repmat({'Correct'}, 1, length(t_correct_presses_sorted)-1),'Substandard', 'Premature', 'Late', 'All'];
PSTHOut.Releases.Time                                =   cell(1, length(PSTHOut.Releases.Labels));
PSTHOut.Releases.Time(1: length(t_correct_presses_sorted))  = t_correct_releases_sorted;
PSTHOut.Releases.Time(length(t_correct_presses_sorted)+1)  = {t_premature_releases};
PSTHOut.Releases.Time(length(t_correct_presses_sorted)+2)  = {t_late_releases};
PSTHOut.Releases.Time(length(t_correct_presses_sorted)+3)  = {t_releases};

PSTHOut.Releases.FP                                    =     {MixedFPs, MixedFPs(1:end-1),FPs_premature_releases, FPs_late_releases};
PSTHOut.Releases.RT_Correct                      =     rt_releases_sorted;
PSTHOut.Releases.PressDur.Premature        =     premature_duration_releases;
PSTHOut.Releases.PressDur.Late                  =     late_duration_releases;

PSTHOut.Pokes.Time                                       =       t_portin;
PSTHOut.Pokes.RewardPoke.Time                  =       t_reward_pokes; % it is a cell now!
PSTHOut.Pokes.RewardPoke.Move_Time       =       move_time;         % it is a cell now!
PSTHOut.Pokes.NonrewardPoke.Time             =       t_nonreward_pokes;
PSTHOut.Pokes.NonrewardPoke.Move_Time   =      move_time_nonreward;

PSTHOut.Triggers.Labels                                  =       {'TriggerTime_DifferentFPs' 'Substandard' 'TriggerTime_Late' , 'All'};
PSTHOut.Triggers.Time                                     =       cell(1, length(t_triggers_FPs)+2);
PSTHOut.Triggers.Time(1: length(t_triggers_FPs))                                     =       t_triggers_FPs;
PSTHOut.Triggers.Time(end-1)                                     =      {t_triggers_late};
PSTHOut.Triggers.Time(end)                                     =      {t_triggers};
PSTHOut.Triggers.RT                                        =       [RT_triggers_FPs, {triggers_RTs_late}];
PSTHOut.Triggers.FP                                         =       {MixedFPs, MixedFPs(1:end-1), FP_triggers_late};

PSTHOut.OptoEpochs.Begs                             =     t_opto_begs;
PSTHOut.OptoEpochs.Ends                             =     t_opto_ends;

PSTHOut.SpikeNotes                                       =      r.Units.SpikeNotes;
%% Check how many units we need to compute
% derive PSTH from these
% go through each units if necessary
for iku =1:length(ku_all)
    ku = ku_all(iku);
    if ku>length(r.Units.SpikeTimes)
        disp('##########################################')
        disp('########### That is all you have ##############')
        disp('##########################################')
        return
    end
    disp('##########################################')
    disp(['Computing this unit: ' num2str(ku)])
    disp('##########################################')
    
    PSTHOut.PSTH(iku)       = Spikes.Wait.ComputePlotPSTH(r, PSTHOut, ku,...
        'PressTimeDomain', PressTimeDomain, ...
        'ReleaseTimeDomain', ReleaseTimeDomain, ...
        'RewardTimeDomain', RewardTimeDomain,...
        'TriggerTimeDomain', TriggerTimeDomain,...
        'ToSave', ToSave);
end

if takeall
    
    r.PSTH.Events.Presses             = PSTHOut.Presses;
    r.PSTH.Events.Releases            = PSTHOut.Releases;
    r.PSTH.Events.Pokes               = PSTHOut.Pokes;
    r.PSTH.Events.Triggers            = PSTHOut.Triggers;
    r.PSTH.Events.OptoEpochs          = PSTHOut.OptoEpochs;
    r.PSTH.Events.Presses             = PSTHOut.Presses;
    r.PSTH.PSTHs                         = PSTHOut.PSTH;

    % r_name = Spikes.r_name;
    

    if isempty(r_name)
        r_name = ['RTarray_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '.mat'];
    end
    
    save(r_name, 'r', '-v7.3');
    psth_new_name             =      [Subject, '_', SessionInfo, '_PSTHs.mat'];
    save(psth_new_name, 'PSTHOut', '-v7.3');

    % C:\Users\jiani\OneDrive\00_Work\03_Projects\05_Physiology\PSTHs
    % thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'PETHs', Subject);
    % if ~exist(thisFolder, 'dir')
    %     mkdir(thisFolder);
    % end
    % copyfile(psth_new_name, thisFolder);

end

