function [eventTimes, durations, conditionCodes] = sortErrorEvents(tPresses, tReleases, conditionIndex, mask)

eventTimes = [];
durations = [];
conditionCodes = [];
for iCond = 1:4
    idx = find(mask(:) & conditionIndex(:) == iCond);
    thisDur = tReleases(idx) - tPresses(idx);
    [thisDur, order] = sort(thisDur);
    idx = idx(order);
    eventTimes = [eventTimes; tPresses(idx)]; %#ok<AGROW>
    durations = [durations; thisDur]; %#ok<AGROW>
    conditionCodes = [conditionCodes; conditionIndex(idx)]; %#ok<AGROW>
end
end
