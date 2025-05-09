function r_all = kilomatchOutput2r_all(Output, spikeInfo, folder_data, varargin)
% This function transfer automated tracking neurons into r_all.mat.
% Additional steps will be done with manual arguments such as excluding bad units.
%
% Output: the output of kilomatch
% spikeInfo: the input to kilomatch
% folder_data: the folder that contains all the folder with `r` files inside
% name-value pairs:
%   depth_range
%   included_sessions
%   min_firing_rate
%

included_sessions = -1;
depth_range = [-Inf, Inf];
min_firing_rate = 0;

if nargin > 3
    for k = 1:2:size(varargin,2)
        if strcmpi(varargin{k},'depth_range')
            depth_range = varargin{k+1};
        elseif strcmpi(varargin{k},'included_sessions')
            included_sessions = varargin{k+1};    
        elseif strcmpi(varargin{k},'min_firing_rate')
            min_firing_rate = varargin{k+1};
        else
            error('Wrong argument!');
        end
    end
end

r_all = struct();
r_all.AnimalName = spikeInfo(1).RatName;

% handling r
sessions = unique({spikeInfo.Session});

if ~(length(included_sessions) == 1 && included_sessions == -1)
    sessions = sessions(included_sessions);
else
    included_sessions = 1:Output.NumSession;
end

n_sessions_out = length(sessions);

r_all.r_filenames = cell(1, n_sessions_out);
r_all.r = cell(n_sessions_out, 1);

for k = 1:n_sessions_out
    r_all.r_filenames{k} = fullfile(folder_data, sessions{k},...
        ['RTarray_', r_all.AnimalName, '_', sessions{k}, '.mat']);

    fprintf('Loading %s ...\n', r_all.r_filenames{k});
    load(r_all.r_filenames{k});
    
    if isfield(r, 'PSTH')
        r = rmfield(r, 'PSTH');
    end

    if isfield(r, 'PopPSTH')
        r = rmfield(r, 'PopPSTH');
    end

    if isfield(r.Units.SpikeTimes, 'spk_id')
        r.Units.SpikeTimes = rmfield(r.Units.SpikeTimes, 'spk_id');
    end

    for j = 1:length(r.Units.SpikeTimes)
        r.Units.SpikeTimes(j).wave = mean(r.Units.SpikeTimes(j).wave, 1);
    end

    % change all the channels to 1
    for j = 1:length(r.Units.SpikeTimes)
        r.Units.SpikeNotes(j,1) = 1;
        r.Units.SpikeNotes(j,2) = j;
    end

    r_all.r{k} = r;
end

%% handling units
% check sessions
is_good_session = arrayfun(@(x)any(included_sessions == x.SessionIndex), spikeInfo);
idx_good_session = find(is_good_session == 1);

% check firing rate
duration = zeros(1, Output.NumSession);
for k = 1:length(duration)
    if size(spikeInfo(1).SpikeTimes, 1) == 1
        t_all = cat(2, spikeInfo(Output.Sessions == k).SpikeTimes);
    else
        t_all = cat(1, spikeInfo(Output.Sessions == k).SpikeTimes);
    end
    duration(k) = (max(t_all) - min(t_all))./1000;
end

firing_rates = arrayfun(@(x)length(x.SpikeTimes)./duration(x.SessionIndex), spikeInfo);
idx_good_fr = find(firing_rates > min_firing_rate);

% check depth
depth = Output.Locations(:,2);
idx_good_depth = find(depth >= depth_range(1) & depth <= depth_range(2));

idx_good = intersectAll({idx_good_session, idx_good_fr, idx_good_depth});

[~, idx_sort] = sort(depth(idx_good));
idx_good_sorted = idx_good(idx_sort);

% compute the number of included clusters
idx_clusters_out = Output.IdxCluster(idx_good_sorted);
n_clusters_out = length(unique(idx_clusters_out)) - 1 + sum(idx_clusters_out == -1);

% set other units to -1
idx_others = setdiff(1:Output.NumUnits, idx_good_sorted);
idx_clusters_good = Output.IdxCluster;
idx_clusters_good(idx_others) = -1;

count_cluster = 0;
units_included = [];
rIndex_RawChannel_Number = cell(n_clusters_out, 1);
for k = 1:length(idx_good_sorted)
    idx_this = idx_good_sorted(k);
    if any(units_included == idx_this)
        continue
    end

    idx_cluster = idx_clusters_good(idx_this);

    if idx_cluster == -1
        idx_units = idx_this;
    else
        idx_units = find(idx_clusters_good == idx_cluster);
    end

    % find these units in r
    rIndex = zeros(length(idx_units), 1);
    number_this = zeros(length(idx_units), 1);
    for j = 1:length(idx_units)
        session_this = spikeInfo(idx_units(j)).SessionIndex;
        unit_this = spikeInfo(idx_units(j)).Unit;

        assert(length(r_all.r{session_this}.Units.SpikeTimes(unit_this).timings) == length(spikeInfo(idx_units(j)).SpikeTimes))
        rIndex(j) = session_this;
        number_this(j) = unit_this;
    end
    
    units_included = [units_included, idx_units'];
    
    count_cluster = count_cluster + 1;
    rIndex_RawChannel_Number{count_cluster} = [rIndex, ones(length(idx_units), 1), number_this];
end

assert(n_clusters_out == length(rIndex_RawChannel_Number));

% make tables
tbl = table();

Channel = ones(n_clusters_out, 1);
Number = (1:n_clusters_out)';
tbl.Channel = Channel;
tbl.Number = Number;
tbl.rIndex_RawChannel_Number = rIndex_RawChannel_Number;

r_all.UnitsCombined = tbl;

end