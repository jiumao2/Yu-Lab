path_to_data = {
    'D:\HY\Lesion\UniM1',...
    'D:\HY\Lesion\UniDLS',...
    'D:\HY\Lesion\BiM1',...
    'D:\HY\Lesion\BiDLS'...
};
folder_root = 'D:\HY\HandLabeller';
addpath(folder_root);

for k = 1:length(path_to_data)
    folder_this = path_to_data{k};
    dir_out = dir(folder_this);
    animals = {dir_out.name};
    
    for i = 1:length(animals)
        if strcmp(animals{i}, '.') || strcmp(animals{i}, '..')
            continue
        end
        animal_folder = fullfile(folder_this, animals{i});

        dir_out = dir(animal_folder);
        sessions = {dir_out.name};
        for j = 1:length(sessions)
            path_data = fullfile(animal_folder, sessions{j});
    
            % check the path
            if ~exist(path_data, 'dir') || length(sessions{j})~=8
                continue
            end

            % check if B_ file exists
            dir_out = dir(fullfile(path_data, 'B_*mat'));
            if ~isempty(dir_out)
                disp([path_data, ' B exist!']);
                continue
            end
        
    
            cd(path_data)
            load('timestamps.mat');
            track_training_progress_advanced(ts.MedFilename);
    
            disp([path_data, ' done!']);
            close all;
        end
    
        cd(folder_root);
    end
end


