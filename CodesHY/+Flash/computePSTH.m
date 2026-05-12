function [psth, ts, trialspxmat, tspkmat, eventsKept, ind] = computePSTH(spikeTimes, eventTimes, params)

eventTimes = eventTimes(:);
eventTimes = eventTimes(~isnan(eventTimes));
if isempty(eventTimes)
    ts = -params.pre:params.binwidth:params.post;
    psth = zeros(size(ts));
    tspkmat = ts(:);
    trialspxmat = false(numel(tspkmat), 0);
    eventsKept = eventTimes;
    ind = [];
    return
end

[psth, ts, trialspxmat, tspkmat, eventsKept, ind] = Spikes.jpsth(spikeTimes, eventTimes, params);
psth = smoothdata(psth, 'gaussian', 5);
if isempty(ind)
    ind = 1:numel(eventsKept);
end
end
