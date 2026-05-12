function [X, Y, meta] = processNeuralData(spikeTimes, trialEvents, continuous, params)
%PROCESSNEURALDATA Build X and Y from spikes, trial events, continuous covariates.
%
% trialEvents format:
%   trialEvents.<eventName> is [nTrial x 1] absolute time (s), can contain NaN per trial
%
% continuous format:
%   continuous.time  [Nc x 1] (strictly increasing)
%   continuous.value [Nc x K]
%   continuous.names {1 x K} (optional)
%
% No extrapolation:
%   continuous covariates interpolated with extrap = NaN; bins with NaN are dropped.

if ~isnumeric(spikeTimes) || ~isvector(spikeTimes)
    error('spikeTimes must be a numeric vector.');
end
spikeTimes = spikeTimes(:);

if ~isstruct(trialEvents)
    error('trialEvents must be a struct with fields as event arrays (nTrial x 1).');
end
evFieldList = fieldnames(trialEvents);
if isempty(evFieldList), error('trialEvents has no fields.'); end

% nTrial from trialEvents
nTrial = [];
for i = 1:numel(evFieldList)
    v = trialEvents.(evFieldList{i});
    if ~isnumeric(v) || ~isvector(v)
        error('trialEvents.%s must be a numeric vector.', evFieldList{i});
    end
    v = v(:);
    if isempty(nTrial), nTrial = numel(v);
    elseif numel(v) ~= nTrial
        error('All trialEvents fields must have the same length (nTrial).');
    end
    trialEvents.(evFieldList{i}) = v;
end

if nargin < 3 || isempty(continuous)
    continuous = struct('time', [], 'value', [], 'names', {{}});
end
if ~isstruct(continuous)
    error('continuous must be a struct (time/value/names).');
end

if nargin < 4 || ~isstruct(params) || ~isfield(params,'BinWidth')
    error('params must be from GLMmodel.makePreprocessParams.');
end
binwidth = params.BinWidth;

% Continuous
useCont = isfield(continuous,'time') && ~isempty(continuous.time);
if useCont
    continuous.time = continuous.time(:);
    if ~isfield(continuous,'value') || isempty(continuous.value)
        error('continuous.value is required when continuous.time is provided.');
    end
    if size(continuous.value,1) ~= numel(continuous.time)
        error('continuous.value must match continuous.time length.');
    end
    if any(diff(continuous.time) <= 0)
        error('continuous.time must be strictly increasing.');
    end

    K = size(continuous.value,2);
    if ~isfield(continuous,'names') || isempty(continuous.names)
        continuous.names = arrayfun(@(k)sprintf('cont_%d',k), 1:K, 'UniformOutput', false);
    else
        if numel(continuous.names) ~= K
            error('continuous.names must match columns of continuous.value.');
        end
    end
else
    K = 0;
end

% Events requested
evNames = params.Event.Names;
E = numel(evNames);
evWindows = params.Event.Windows;
useEvents = (E > 0);

% Precompute event-lag columns
eventColInfo = struct('name', {}, 't_pre', {}, 't_post', {}, 'nLag', {}, 'lagEdges', {}, 'colIdx', {});
nEventCols = 0;

if useEvents
    eventColInfo = repmat(struct('name','', 't_pre',0, 't_post',0, 'nLag',0, 'lagEdges',[], 'colIdx',[]), 1, E);
    for e = 1:E
        nm = char(evNames{e});
        if ~isfield(trialEvents, nm)
            error('trialEvents missing required event field "%s".', nm);
        end
        tpre = evWindows(e,1);
        tpost = evWindows(e,2);
        lagEdges = (-tpre):binwidth:(tpost);
        nLag = max(0, numel(lagEdges)-1);

        eventColInfo(e).name = nm;
        eventColInfo(e).t_pre = tpre;
        eventColInfo(e).t_post = tpost;
        eventColInfo(e).nLag = nLag;
        eventColInfo(e).lagEdges = lagEdges(:);
        eventColInfo(e).colIdx = (nEventCols+1):(nEventCols+nLag);
        nEventCols = nEventCols + nLag;
    end
end

% Feature names
featureNames = {};
if useCont, featureNames = [featureNames, continuous.names(:)']; end
if useEvents
    for e = 1:E
        nm = eventColInfo(e).name;
        for j = 1:eventColInfo(e).nLag
            featureNames{end+1} = sprintf('%s_lag%03d', nm, j); %#ok<AGROW>
        end
    end
end
P = K + nEventCols;

% Per-trial buffers
X_all = cell(nTrial,1);
Y_all = cell(nTrial,1);
tCenter_all = cell(nTrial,1);
trialId_all = cell(nTrial,1);

for tr = 1:nTrial
    [ok, tStart, tEnd] = GLMmodel.getTrialWindow(tr, trialEvents, params, eventColInfo);
    if ~ok
        X_all{tr} = []; Y_all{tr} = [];
        tCenter_all{tr} = []; trialId_all{tr} = [];
        continue;
    end

    edges = tStart:binwidth:tEnd;
    if numel(edges) < 2
        X_all{tr} = []; Y_all{tr} = [];
        tCenter_all{tr} = []; trialId_all{tr} = [];
        continue;
    end

    tCenter = edges(1:end-1) + binwidth/2;
    Nbin = numel(tCenter);

    % Y
    Y = histcounts(spikeTimes, edges).';
    Y = Y(:);

    % X
    X = zeros(Nbin, P);

    % Continuous: NaN outside range (no extrap)
    if useCont
        Xi = interp1(continuous.time, continuous.value, tCenter(:), ...
            params.Continuous.InterpMethod, NaN);
        X(:,1:K) = Xi;
    end

    % Event-lag one-hot
    if useEvents && nEventCols > 0
        base = K;
        for e = 1:E
            evName = eventColInfo(e).name;
            tev = trialEvents.(evName)(tr);

            if ~isfinite(tev)
                if strcmp(params.MissingEventPolicy, 'error')
                    error('Missing event "%s" in trial %d.', evName, tr);
                else
                    continue;
                end
            end

            rel = tCenter(:) - tev;
            j = discretize(rel, eventColInfo(e).lagEdges);
            valid = ~isnan(j);
            if any(valid)
                rows = find(valid);
                cols = base + eventColInfo(e).colIdx(j(valid));
                X(sub2ind(size(X), rows, cols)) = 1;
            end
        end
    end

    % Drop bins with NaN continuous covariates
    if useCont && params.Continuous.DropBinsWithNaN
        keep = all(isfinite(X(:,1:K)), 2);
        X = X(keep,:);
        Y = Y(keep,:);
        tCenter = tCenter(keep);
    end

    if isempty(Y)
        X_all{tr} = []; Y_all{tr} = [];
        tCenter_all{tr} = []; trialId_all{tr} = [];
        continue;
    end

    X_all{tr} = X;
    Y_all{tr} = Y;
    tCenter_all{tr} = tCenter(:);
    trialId_all{tr} = tr*ones(numel(Y),1);
end

% Concatenate
X = vertcat(X_all{:});
Y = vertcat(Y_all{:});
tCenter = vertcat(tCenter_all{:});
trialId = vertcat(trialId_all{:});

% meta
meta = struct();
meta.binwidth = binwidth;
meta.tCenter = tCenter;
meta.trialId = trialId;
meta.featureNames = featureNames;
meta.eventColInfo = eventColInfo;
meta.params = params;

end
