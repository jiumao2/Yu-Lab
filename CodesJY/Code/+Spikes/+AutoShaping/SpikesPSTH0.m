function PSTHOut = SpikesPSTH(r, ind, varargin)
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
RewardTimeDomain = [3000 2000];
TriggerTimeDomain = [5000 3000];
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
    % if length(r.BehaviorClass)>1
    %     r.BehaviorClass = r.BehaviorClass{1};
    % end
    % MixedFPs                =       r.BehaviorClass.MixedFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
    Subject = r.BehaviorClass.Subject;
    SessionInfo = r.BehaviorClass.Date;
else
    % MixedFPs = Spikes.findFP(r);
    Subject = r.Meta(1).Subject;
    SessionInfo = strrep( r.Meta(1).DateTime(1:11), '-', '_');
end
MixedFPs = [];
nFPs                        =       length(MixedFPs);

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




%% Trigger
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_triggers)); % trigger time in ms.


%%  Rewards
ind_rewards                =       find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards                    =       Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_rewards));
move_time                  =       zeros(1, length(t_rewards));
tmax                            =      10000; % allow at most 100 second between a successful release and poke
% t_rewards_FP               =       zeros(1, length(t_rewards)); % find out press FP associated with each reward

for i =1:length(t_rewards)
    dt = t_rewards(i)-t_triggers;
    dt = dt(dt>0 & dt<tmax); % reward must be collected within 2 sec after a correct release
    if ~isempty(dt)
        move_time(i) = dt(end);
        % % FPs_correct_presses
        % ind = find(t_correct_releases==t_rewards(i)-dt(end));
        % if ~isempty(ind)
        %     %             disp(ind)
        %     t_rewards_FP(i) = FPs_correct_presses(ind);
        % else
        %     disp('Not found')
        % end
    else
        move_time(i) = NaN;
    end
end

t_rewards                         =           t_rewards(~isnan(move_time));
move_time                       =           move_time(~isnan(move_time));
% FP_rewards                     =            t_rewards_FP(~isnan(move_time));
% Check movement time distribution
Edges =(0:100:5000);
figure(45); clf;
histogram(move_time, Edges)
xlabel('Movement time (ms)')
ylabel('Count')

% sort reward according to FP
% MixedFPs                =       r.BehaviorClass.MixedFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
% nFPs                        =       length(MixedFPs);
% t_rewards_sorted = cell(1, nFPs);
% move_time_sorted = cell(1, nFPs);
% for ifp =1:nFPs
%     ind = find(FP_rewards == MixedFPs(ifp));
%     t_rewards_sorted{ifp} = t_rewards(ind);
%     move_time_sorted{ifp} = move_time(ind);
%     % rank them
%     [move_time_sorted{ifp}, indsort] = sort(move_time_sorted{ifp});
%     t_rewards_sorted{ifp} =  t_rewards_sorted{ifp}(indsort);
% end
% 
% move_time = move_time_sorted;
% t_rewards = t_rewards_sorted;

% Find out the reward pokes (last poke before valve.)
% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_portin));
% have a look at the difference between poke and trigger (looks like there
% might be some contamination)
t_reward_pokes              =          [];
dt                                     =          []; % poke leading to reward

    for i=1:length(t_rewards)
        t_portin_this = t_portin(t_portin >t_rewards(i)-1550 & t_portin<t_rewards(i)+100);
        if ~isempty(t_portin_this)
            t_reward_pokes(i) = t_portin_this(1);
            dt = [dt t_reward_pokes(i)-t_rewards(i)];
            %             disp(dt);
        else
            t_reward_pokes(i) = NaN;
        end
    end



% due to technical error, pokes that occured 200 ms after reward is not
% real, should be corrected. (I don' t see this actually. Omitted for now 5/3/2023)
% check poke after reward
t_rewards_prime = t_rewards';
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

    for i =1:length(t_rewards)
        stack = stack+1;
        t_relative = t_portin - t_rewards(i);
        t_relative = t_relative(t_relative>t_lim(1) & t_relative<t_lim(2));
        [~, ind] = min(abs(t_rewards(i)-t_reward_pokes));
        if ~isempty(t_relative)
            scatter(t_relative, stack, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
        end
        plot(t_reward_pokes(ind) -t_rewards(i), stack, '+', 'markersize', 4, 'linewidth', 1, 'color', 'c')
    end


% bad (nonrewarded) poke: sometimes, rat will poke even after an unsuccessful response.
% Pick these out and plot them

move_time_nonreward = [];
ind_badpoke = find(strcmp(rb.Labels, 'BadPoke'));
t_badpoke = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_badpoke)); % trigger time in ms.
t_nonreward_pokes = t_badpoke;
% bad_responses = [t_premature_releases; t_late_releases];
% for i =1:length(t_badpoke)
%     t_ipoke = t_portin(find(t_portin>t_badpoke(i), 1, 'first')); % first poke after a bad release
% 
%     if ~isempty(t_ipoke) && ~isempty(t_ipress) && t_ipoke < t_ipress
%         t_nonreward_pokes            =    [t_nonreward_pokes t_ipoke];
%         move_time_nonreward       =     [move_time_nonreward t_ipoke-bad_responses(i)];
%     end
% end
% [move_time_nonreward, indsort_nonreward_pokes] =  sort(move_time_nonreward);
% t_nonreward_pokes = t_nonreward_pokes(indsort_nonreward_pokes);




%% Summarize


% if checkplot
% 
%     figure;
%     ifp = 1;
%     % plot raster
%     nplot = length(t_correct_presses_sorted{ifp});
%     axes('unit', 'normalized', ...
%         'position', [.1 .1 .8 .8],...
%         'nextplot', 'add', ...
%         'xlim', [-1 2]*1000, 'ylim', [0 nplot+1], 'ydir', 'reverse', ...
%         'ytick', [0 20], 'xtick', [-2000:1000:2000],...
%         'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
%         'XTickLabelRotation', 0, 'color', 'none', ...
%         'ticklength',[.015 .1]);
%     axis off
%     for k =1:nplot
%         xx = t_correct_presses_sorted{ifp}(k);
%         yy = [0 .8]+k;
%         if ~isempty(xx)
%             line([0; 0], yy, 'color', 'k')
%         end
%         xx = t_correct_releases_sorted{ifp}(k)-xx;
%         yy = [0 .8]+k;
%         if ~isempty(xx)
%             plot(xx, yy, 'o', 'color', 'r')
%         end
% 
%         % Plot reaction time
%         xx = rt_presses_sorted{ifp}(k)+MixedFPs(ifp);
%         yy = [0 1]+k;
%         if ~isempty(xx)
%             line([xx; xx], yy, 'color', 'c', 'linewidth', 1)
%         end
% 
%     end
% 
% end

PSTHOut.ANM_Session                               =     {Subject, SessionInfo};
% PSTHOut.Presses.Labels                             =     [repmat({'Correct'}, 1, length(t_correct_presses_sorted)), 'Premature', 'Late', 'All'];
% PSTHOut.Presses.Time                                =   cell(1, length(PSTHOut.Presses.Labels));
% PSTHOut.Presses.Time(1: length(t_correct_presses_sorted))  = t_correct_presses_sorted;
% PSTHOut.Presses.Time(length(t_correct_presses_sorted)+1)  = {t_premature_presses};
% PSTHOut.Presses.Time(length(t_correct_presses_sorted)+2)  = {t_late_presses};
% PSTHOut.Presses.Time(length(t_correct_presses_sorted)+3)  = {t_presses};
% 
% PSTHOut.Presses.FP                                    =     {MixedFPs, FPs_premature_presses, FPs_late_presses};
% PSTHOut.Presses.RT_Correct                      =     rt_presses_sorted;
% PSTHOut.Presses.PressDur.Premature        =     premature_duration_presses;
% PSTHOut.Presses.PressDur.Late                  =     late_duration_presses;
% PSTHOut.Releases.Labels                             =     [repmat({'Correct'}, 1, length(t_correct_presses_sorted)), 'Premature', 'Late'];
% PSTHOut.Releases.Time                                =   cell(1, length(PSTHOut.Releases.Labels));
% PSTHOut.Releases.Time(1: length(t_correct_presses_sorted))  = t_correct_releases_sorted;
% PSTHOut.Releases.Time(length(t_correct_presses_sorted)+1)  = {t_premature_releases};
% PSTHOut.Releases.Time(length(t_correct_presses_sorted)+2)  = {t_late_releases};
% PSTHOut.Releases.FP                                    =     {MixedFPs, FPs_premature_releases, FPs_late_releases};
% PSTHOut.Releases.RT_Correct                      =     rt_releases_sorted;
% PSTHOut.Releases.PressDur.Premature        =     premSature_duration_releases;
% PSTHOut.Releases.PressDur.Late                  =     late_duration_releases;
PSTHOut.Pokes.Time                                       =       t_portin;
PSTHOut.Pokes.RewardPoke.Time                  =       t_reward_pokes; % it is a cell now!
PSTHOut.Pokes.RewardPoke.Move_Time       =       move_time;         % it is a cell now!
PSTHOut.Pokes.NonrewardPoke.Time             =       t_nonreward_pokes;
PSTHOut.Pokes.NonrewardPoke.Move_Time   =      move_time_nonreward;
% PSTHOut.Triggers.Labels                                  =       {'TriggerTime_DifferentFPs' 'TriggerTime_Late'};
PSTHOut.Triggers.Time                                     =       t_triggers;
PSTHOut.Rewards.Time                                     =       t_rewards;
% PSTHOut.Triggers.Time(1: length(t_triggers_FPs))                                     =       t_triggers_FPs;
% PSTHOut.Triggers.Time(end)                                     =      {t_triggers_late};
% PSTHOut.Triggers.RT                                        =       [RT_triggers_FPs, {triggers_RTs_late}];
% PSTHOut.Triggers.FP                                         =       {MixedFPs, FP_triggers_late};

% PSTHOut.OptoEpochs.Begs                             =     t_opto_begs;
% PSTHOut.OptoEpochs.Ends                             =     t_opto_ends;

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
    
    PSTHOut.PSTH(iku)       = Spikes.AutoShaping.ComputePlotPSTH(r, PSTHOut, ku,...
        'RewardTimeDomain', RewardTimeDomain,...
        'TriggerTimeDomain', TriggerTimeDomain,...
        'ToSave', ToSave);
end

if takeall
    
    % r.PSTH.Events.Presses             = PSTHOut.Presses;
    % r.PSTH.Events.Releases            = PSTHOut.Releases;
    r.PSTH.Events.Pokes               = PSTHOut.Pokes;
    r.PSTH.Events.Triggers            = PSTHOut.Triggers;
    % r.PSTH.Events.OptoEpochs          = PSTHOut.OptoEpochs;
    % r.PSTH.Events.Presses             = PSTHOut.Presses;
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

