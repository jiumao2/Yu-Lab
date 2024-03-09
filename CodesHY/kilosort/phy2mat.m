function cluster_info = phy2mat(dir_name)
cluster_info_filename = fullfile(dir_name, 'cluster_info.tsv');
if ~exist(cluster_info_filename,'file')
    error(['File "',cluster_info_filename,'" cannot be find']);
end

cluster_info = readtable(cluster_info_filename,'Delimiter','\t','FileType','text');

end