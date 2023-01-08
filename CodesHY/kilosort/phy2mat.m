function cluster_info = phy2mat(dir_name)
cluster_info_filename = fullfile(dir_name, 'cluster_info.tsv');
if ~exist(cluster_info_filename,'file')
    error(['File "',cluster_info_filename,'" cannot be find']);
end

cluster_info = readtable('cluster_info.tsv','Delimiter','\t','FileType','text');
cluster_group = readtable('cluster_group.tsv','Delimiter','\t','FileType','text');

for k = 1:height(cluster_group)
    cluster_info(cluster_info.cluster_id==cluster_group(k,:).cluster_id,:).KSLabel = cluster_group(k,:).group;
end

end