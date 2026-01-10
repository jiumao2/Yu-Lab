function [IndSortS, IndInsignificant] = RankActivityFlat(PopOut)
% Jianing Yu 5/15/2023
% PopOut is population psth produce by Spikes.SRT.PopulationActivity.m
% 7/8/2023 modified 

FPs = PopOut.FPs;
 
n_unit = size(PopOut.Units, 1);
FPindx = 1; 
n_events = 3; % press, release, reward

PressTimeRange      = [-2000, 1500];
ReleaseTimeRange  = [-500 1000];
RewardTimeRange  = [-1000 2000];

 PSTHs_Flat = [];
IndMax = zeros(1, n_unit);
SigMod = zeros(1, n_unit); % if 1, neural activity is significantly modulated at some points
pVal_critical = 0.05/3;
pVals = zeros(n_events, n_unit);

for i =1:n_unit
        
    tPress = PopOut.Press{FPindx}(1, :);
    PSTH_Press = PopOut.Press{FPindx}(i+1, :);
    IndPress = find(tPress>=PressTimeRange(1) & tPress<=PressTimeRange(2));
    pVals(1, i)      =      PopOut.PressStat{FPindx}.StatOut(i).pval;

    tRelease= PopOut.Release{FPindx}(1, :);
    PSTH_Release = PopOut.Release{FPindx}(i+1, :);
    IndRelease = find(tRelease>=ReleaseTimeRange(1) & tRelease<=ReleaseTimeRange(2));
    pVals(2, i)      =      PopOut.ReleaseStat{FPindx}.StatOut(i).pval;

    tReward = PopOut.Reward{FPindx}(1, :);
    PSTH_Reward = PopOut.Reward{FPindx}(i+1, :);
    IndReward = find(tReward>=RewardTimeRange(1) & tReward<=RewardTimeRange(2));
    pVals(3, i)      =      PopOut.RewardStat{FPindx}.StatOut(i).pval;

    PSTH_Flat = [PSTH_Press(IndPress) PSTH_Release(IndRelease) PSTH_Reward(IndReward)];
    PSTHs_Flat = [PSTHs_Flat; PSTH_Flat];

    [~, IndMax(i)] = max(PSTH_Flat);
    if min(pVals(:, i))<pVal_critical
        SigMod(i) = 1;
    end
end

[~, IndSort] = sort(IndMax); 
SigMod = SigMod(IndSort);
IndSort = [IndSort(SigMod==1) IndSort(SigMod==0)];
SigMod =  [SigMod(SigMod==1) SigMod(SigMod==0)];
IndInsignificant =find(SigMod==0);

IndSortS = cell(1,2);
for ib = 1: length(IndSortS)
    indS = IndSort(find(PopOut.Units(:,5)==ib));
    
end

