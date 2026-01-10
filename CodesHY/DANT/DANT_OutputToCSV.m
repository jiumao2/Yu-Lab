function tbl = DANT_OutputToCSV(Output, spikeInfo, path_csv)
idx_clusters = 1:Output.NumClusters;
cluster_size = arrayfun(@(x)sum(Output.IdxCluster == x), idx_clusters);

tbl = table();

sessions_out = {};
session_ids_out = {};
units_spikeinfo_out = {};
units_out = {};
channels_out = {};
num_in_channels_out = {};

units_not_clustered = find(Output.IdxCluster == -1);
n_clusters_total = Output.NumClusters + length(units_not_clustered);

cluster_ids = 1:n_clusters_total;
num_sessions = [cluster_size, ones(1, length(units_not_clustered))];

is_containing_channel_info = true;
for k = 1:n_clusters_total
    if k <= Output.NumClusters
        units_spikeInfo = find(Output.IdxCluster == idx_clusters(k));
    else
        units_spikeInfo = units_not_clustered(k - Output.NumClusters);
    end

    units = arrayfun(@(x)spikeInfo(x).Unit, units_spikeInfo);

    if isfield(spikeInfo, 'NumInChannel') && isfield(spikeInfo, 'ChannelR')
        channels = arrayfun(@(x)spikeInfo(x).ChannelR, units_spikeInfo);
        num_in_channels = arrayfun(@(x)spikeInfo(x).NumInChannel, units_spikeInfo);
    else
        is_containing_channel_info = false;
    end

    sessions_ids_this = arrayfun(@num2str, Output.Sessions(units_spikeInfo), 'UniformOutput', false);
    session_ids_str = strjoin(sessions_ids_this, ',');
    sessions_this = Output.SessionNames(units_spikeInfo);
    session_str = strjoin(sessions_this, ',');
    units_spikeInfo_this = arrayfun(@num2str, units_spikeInfo, 'UniformOutput', false);
    units_spikeInfo_str = strjoin(units_spikeInfo_this, ',');

    units_cell = arrayfun(@num2str, units, 'UniformOutput', false);
    units_str = strjoin(units_cell, ',');
    sessions_out{end+1} = session_str;
    session_ids_out{end+1} = session_ids_str;
    units_spikeinfo_out{end+1} = units_spikeInfo_str;
    units_out{end+1} = units_str;

    if is_containing_channel_info
        channels_cell = arrayfun(@num2str, channels, 'UniformOutput', false);
        channels_str = strjoin(channels_cell, ',');
        num_in_channels_cell = arrayfun(@num2str, num_in_channels, 'UniformOutput', false);
        num_in_channels_str = strjoin(num_in_channels_cell, ',');
        channels_out{end+1} = channels_str;
        num_in_channels_out{end+1} = num_in_channels_str;
    end
end

tbl.ClusterID = cluster_ids';
tbl.NumSessions = num_sessions';
tbl.Sessions = sessions_out';
tbl.SessionIDs = session_ids_out';
tbl.UnitsSpikeInfo = units_spikeinfo_out';
tbl.Units = units_out';

if is_containing_channel_info
    tbl.Channels = channels_out';
    tbl.NumInChannels = num_in_channels_out';
end

writetable(tbl, path_csv);

end