function [IndSort, IndInsignificant] = RankActivityFlatS(PopOut)
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
for ib = 1:length(IndSort)
    if n_regions == 1
        idx_units = 1:size(PopOut.Units, 1);
    else
        idx_units = find(PopOut.Units(:,5)==ib);
    end

    n_unit = length(idx_units);
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

    for i = 1: n_unit

        tPress = PopOut.Press{FPindx}(1, :);
        PSTH_Press = PopOut.Press{FPindx}(idx_units(i)+1, :);
        IndPress = find(tPress>=PressTimeRange(1) & tPress<=PressTimeRange(2));
        pVals(1, i)      =      PopOut.PressStat{FPindx}.StatOut(idx_units(i)).pval;

        tRelease= PopOut.Release{FPindx}(1, :);
        PSTH_Release = PopOut.Release{FPindx}(idx_units(i)+1, :);
        IndRelease = find(tRelease>=ReleaseTimeRange(1) & tRelease<=ReleaseTimeRange(2));
        pVals(2, i)      =      PopOut.ReleaseStat{FPindx}.StatOut(idx_units(i)).pval;

        tReward = PopOut.Reward{FPindx}(1, :);
        PSTH_Reward = PopOut.Reward{FPindx}(idx_units(i)+1, :);
        IndReward = find(tReward>=RewardTimeRange(1) & tReward<=RewardTimeRange(2));
        pVals(3, i)      =      PopOut.RewardStat{FPindx}.StatOut(idx_units(i)).pval;

        PSTH_Flat = [PSTH_Press(IndPress)  PSTH_Release(IndRelease)  PSTH_Reward(IndReward)];%
        PSTHs_Flat = [PSTHs_Flat; PSTH_Flat];

        %     % 局部加权散点平滑
        % span = 0.1; % 平滑系数(0-1)
        % smoothedY = smooth(1:length(PSTH_Flat), PSTH_Flat, span, 'loess');
        %
        % % 绘图比较
        % plot(1:length(PSTH_Flat), PSTH_Flat, 'b', 1:length(PSTH_Flat), smoothedY, 'r', 'LineWidth', 2);
        % legend('原始数据', '局部回归平滑');

        % max
        [~, IndMax(i)] = max(PSTH_Flat);

        % % half max
        % [peakValue, peakIndex] = max(PSTH_Flat);
        % % peakX = x(peakIndex);
        % halfMax = mean([max(PSTH_Flat) PSTH_Flat(1)]);
        % leftIndex = find(PSTH_Flat(1:peakIndex) <= halfMax, 1, 'last');
        % IndMax(i) = leftIndex;


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