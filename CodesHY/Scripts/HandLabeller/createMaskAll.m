path_to_data = {
    'E:\Lesion\UniDLS'
};
folder_root = 'C:\Users\jiumao\Desktop\HandLabeller';
addpath(folder_root);
mask_last = NaN;

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
    
            cd(path_data)
            if exist(fullfile(path_data, 'timestamps.mat'), 'file')
                load(fullfile(path_data, 'timestamps.mat'));
                if ~isfield(ts, 'mask')
                    createMask;
                    mask_last = ts.mask;
                end
            else
                createMask;
                mask_last = ts.mask;
            end
    
            disp([path_data, ' done!']);
        end
    
        cd(folder_root);
    end
end


