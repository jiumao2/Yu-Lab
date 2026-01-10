function [IndSort, IndInsignificant] = RankActivityFlat(PopOut)
% Jianing Yu 5/15/2023
% PopOut is population psth produce by Spikes.SRT.PopulationActivity.m
% 7/8/2023 modified

FPs = PopOut.FPs;
if size(PopOut.Units, 2) >= 5
    n_regions = max(PopOut.Units(:,5));
else
    n_regions = 1;
end

IndSort = cell(1,n_regions) ;
IndInsignificant  = cell(1,n_regions);
for ib = 1:n_regions
    if n_regions == 1
        idx_units = 1:size(PopOut.Units, 1);
    else
        idx_units = find(PopOut.Units(:,5)==ib);
    end

    n_unit = length(idx_units); %size(PopOut.Units, 1);
    FPindx = 1;
    n_events = 3; % press, release, reward

    % PressTimeRange      = [-2000, FPs(FPindx)];
    % ReleaseTimeRange  = [-500 1000];
    TriggerTimeRange  = [-2000 2000];
    RewardTimeRange  = [-2000 2000];

    PSTHs_Flat = [];
    IndMax = zeros(1, n_unit);
    SigMod = zeros(1, n_unit); % if 1, neural activity is significantly modulated at some points
    pVal_critical = 0.05/3;
    pVals = zeros(n_events, n_unit);

    for i =1:n_unit

        % tPress = PopOut.Press{FPindx}(1, :);
        % PSTH_Press = PopOut.Press{FPindx}(i+1, :);
        % IndPress = find(tPress>=PressTimeRange(1) & tPress<=PressTimeRange(2));
        % pVals(1, i)      =      PopOut.PressStat{FPindx}.StatOut(i).pval;
        %
        % tRelease= PopOut.Release{FPindx}(1, :);
        % PSTH_Release = PopOut.Release{FPindx}(i+1, :);
        % IndRelease = find(tRelease>=ReleaseTimeRange(1) & tRelease<=ReleaseTimeRange(2));
        % pVals(2, i)      =      PopOut.ReleaseStat{FPindx}.StatOut(i).pval;

        tTrigger= PopOut.Trigger{FPindx}(1, :);
        PSTH_Trigger = PopOut.Trigger{FPindx}(idx_units(i)+1, :);
        IndTrigger = find(tTrigger>=TriggerTimeRange(1) & tTrigger<=TriggerTimeRange(2));
        pVals(2, i)      =      PopOut.TriggerStat{FPindx}.StatOut(idx_units(i)).pval;

        tReward = PopOut.Reward{FPindx}(1, :);
        PSTH_Reward = PopOut.Reward{FPindx}(idx_units(i)+1, :);
        IndReward = find(tReward>=RewardTimeRange(1) & tReward<=RewardTimeRange(2));
        pVals(3, i)      =      PopOut.RewardStat{FPindx}.StatOut(idx_units(i)).pval;

        PSTH_Flat =  [PSTH_Trigger(IndTrigger) PSTH_Reward(IndReward)];
        PSTHs_Flat = [PSTHs_Flat; PSTH_Flat];

        [~, IndMax(i)] = max(PSTH_Flat);
        if min(pVals(:, i))<pVal_critical
            SigMod(i) = 1;
        end
    end

    [~, IndSort{ib}] = sort(IndMax);
    SigMod = SigMod(IndSort{ib});
    IndSort{ib} = [IndSort{ib}(SigMod==1) IndSort{ib}(SigMod==0)];
    SigMod =  [SigMod(SigMod==1) SigMod(SigMod==0)];
    IndInsignificant{ib} =find(SigMod==0);
end