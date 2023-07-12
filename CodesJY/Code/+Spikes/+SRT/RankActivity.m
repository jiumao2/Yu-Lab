function [IndSort, IndInsignificant] = RankActivity(PopOut)
% Jianing Yu 5/15/2023
% PopOut is population psth produce by Spikes.SRT.PopulationActivity.m
FPs = PopOut.FPs;
nFPs = length(PopOut.FPs);
n_unit = size(PopOut.Units, 1);
FPindx = 2; 
n_events = 3; % press, release, reward

pval_pop              =         zeros(n_events, n_unit);
tpeaks_pop            =         zeros(n_events, n_unit); % peak time
spkmax_pop        =          zeros(n_events, n_unit);
gap = 5000; % an arbiturary number

hf= 67;
figure(hf); clf(hf)
set(hf, 'units', 'centimeters', 'position', [2 5 25 11])
pval_pop_all = [];
tpeak_all = zeros(1, n_unit);

for i = 1:n_unit
    % press
    pval_pop(1, i)        =      PopOut.PressStat{FPindx}.StatOut(i).pval;
    tpeaks_pop(1, i)    =      PopOut.PressStat{FPindx}.StatOut(i).tpeak;
    [~, indpeak]= (min(abs(PopOut.Press{FPindx}(1, :) - PopOut.PressStat{FPindx}.StatOut(i).tpeak)));
    spkmax_pop(1, i)  =      PopOut.Press{FPindx}(i+1, [indpeak]);

    maxFP = max([max(PopOut.Press{FPindx}(i+1, :)), max(PopOut.Release{FPindx}(i+1, :)), max(PopOut.Reward{FPindx}(i+1, :))]);

    ha1 = subplot(1, 3, 1); % Plot PSTH 
    cla(ha1)
    set(ha1, 'next', 'add', 'xlim', [min(PopOut.Press{FPindx}(1, :)) max(PopOut.Press{FPindx}(1, :))],...
        'ylim', [0 maxFP])
    plot(PopOut.Press{FPindx}(1, :), PopOut.Press{FPindx}(i+1, :), 'color', 'k', 'linewidth', 1.5)
    line([PopOut.PressStat{FPindx}.StatOut(i).tpeak  PopOut.PressStat{FPindx}.StatOut(i).tpeak], [0 maxFP], 'color', 'm', 'linestyle', '-.', 'linewidth', 1.5)

    % release
    pval_pop(2, i)        =      PopOut.ReleaseStat{FPindx}.StatOut(i).pval;
    tpeaks_pop(2, i)    =      PopOut.ReleaseStat{FPindx}.StatOut(i).tpeak+gap;
    [~, indpeak]= (min(abs(PopOut.Release{FPindx}(1, :) - PopOut.ReleaseStat{FPindx}.StatOut(i).tpeak)));
    spkmax_pop(2, i)  =      PopOut.Release{FPindx}(i+1, [indpeak]);
    ha2 = subplot(1, 3, 2); % Plot PSTH
    cla(ha2)
    set(ha2, 'next', 'add', 'xlim', [min(PopOut.Release{FPindx}(1, :)) max(PopOut.Release{FPindx}(1, :))],...
        'ylim', [0 maxFP])
    plot(PopOut.Release{FPindx}(1, :), PopOut.Release{FPindx}(i+1, :), 'color', 'k', 'linewidth', 1.5)
    line([PopOut.ReleaseStat{FPindx}.StatOut(i).tpeak  PopOut.ReleaseStat{FPindx}.StatOut(i).tpeak], [0 maxFP], 'color', 'm', 'linestyle', '-.', 'linewidth', 1.5)
    title(['Unit# ' num2str(i)])
    % reward
    pval_pop(3, i)        =      PopOut.RewardStat{FPindx}.StatOut(i).pval;
    tpeaks_pop(3, i)    =      PopOut.RewardStat{FPindx}.StatOut(i).tpeak+2*gap;
    [~, indpeak]= (min(abs(PopOut.Reward{FPindx}(1, :) - PopOut.RewardStat{FPindx}.StatOut(i).tpeak)));
    spkmax_pop(3, i)  =      PopOut.Reward{FPindx}(i+1, [indpeak]);
    ha3 = subplot(1, 3, 3); % Plot PSTH
    cla(ha3)
    set(ha3, 'next', 'add', 'xlim', [min(PopOut.Reward{FPindx}(1, :)) max(PopOut.Reward{FPindx}(1, :))],...
        'ylim', [0 maxFP])
    plot(PopOut.Reward{FPindx}(1, :), PopOut.Reward{FPindx}(i+1, :), 'color', 'k', 'linewidth', 1.5)
    line([PopOut.RewardStat{FPindx}.StatOut(i).tpeak  PopOut.RewardStat{FPindx}.StatOut(i).tpeak], [0 maxFP], 'color', 'm', 'linestyle', '-.', 'linewidth', 1.5)
    % peak max
    [~, ind_max] = max(spkmax_pop(:, i));  %   spkmax_pop        3x30                 720  double
    switch ind_max
        case 1
            tpeak_all(i) = tpeaks_pop(ind_max, i);
            line(ha1, [tpeak_all(i)  tpeak_all(i)], [0 maxFP], 'color', 'g', 'linestyle', '-', 'linewidth', 2.5)
        case 2
            tpeak_all(i) = tpeaks_pop(ind_max, i);
            line(ha2, [tpeak_all(i)  tpeak_all(i)]-gap, [0 maxFP], 'color', 'g', 'linestyle', '-', 'linewidth', 2.5)
        case 3
            tpeak_all(i) = tpeaks_pop(ind_max, i);
            line(ha3, [ tpeak_all(i)  tpeak_all(i)]-2*gap, [0 maxFP], 'color', 'g', 'linestyle', '-', 'linewidth', 2.5)
    end;
    pval_pop_all(i) = min(pval_pop(:, i));
end;

[tpeak_all_sort, indsort] = sort(tpeak_all);
pval_pop_all = pval_pop_all(indsort);

IndInsignficant = pval_pop_all>0.05;
if ~isempty(find(IndInsignficant))
    pval_pop_all = [pval_pop_all(~IndInsignficant) pval_pop_all(IndInsignficant)];
    IndSort = [indsort(~IndInsignficant) indsort(IndInsignficant)];
else
    IndSort = indsort;
end;

IndInsignificant = indsort(IndInsignficant);