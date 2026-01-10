folder_animal = 'J:\Punch';
dir_out = dir(folder_animal);
folder_names = {dir_out.name};

path_autocuration = 'C:\Work\AutoCurationKilosort';
addpath(genpath(path_autocuration));

while true
    for k = 1:length(folder_names)
        folder_this = folder_names{k};
        if ~exist(fullfile(folder_animal, folder_this), 'dir')
            continue
        end
    
        if length(folder_this) ~= 8
            continue
        end
    
        % has been sorted
        if ~exist(fullfile(folder_animal, folder_this, 'catgt_Exp_g0', 'params.py'), 'file')
            continue
        end
    
        % has been curated
        if exist(fullfile(folder_animal, folder_this, 'catgt_Exp_g0', 'QualityMetrics.mat'), 'file')
            continue
        end
    
        folder_data = fullfile(folder_animal, folder_this, 'catgt_Exp_g0');
        setting_filenames = 'J:\Punch\settingsAutoCuration.json';
    
        fprintf('Running in %s ...\n', folder_data);
        
        % read the settings
        userSettings = jsonc.jsoncDecode(fileread(setting_filenames));
        user_settings = userSettings;
        
        % remove clusters which are pure noise
        detectNoiseClusters(folder_data, userSettings);
        
        % clean the waveforms in each cluster
        removeNoiseInsideCluster(folder_data, userSettings);
        
        % todo: detect and do splits and merges
        % split first (should be very conserative)
    %     split_info = getPotentialSplits(folder_data, userSettings);
        
        % merge
    %     getPotentialMerges(folder_data, userSettings);
        
        % remove duplicated clusters
        removeDuplicatedClusters(folder_data, userSettings);
        
        % determine the quality of each cluster
        computeQualityMetrics(folder_data);
        labelWithQualityMetrics(folder_data, userSettings);
        
        % realign the spike times
        realignClusterSpikeTimes(folder_data, userSettings);
        
        % output to cluster_info.tsv
        updateClusterInfo(folder_data);
    end

    disp('All sessions available are curated!');
    pause(60);
end
