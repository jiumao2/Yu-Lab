path_to_data = {
    'E:\Video'
};
folder_root = 'C:\Users\jiumao\Desktop\HandLabeller';
addpath(folder_root);

for k_path = 1:length(path_to_data)
    folder_this = path_to_data{k_path};
    dir_out = dir(folder_this);
    animals = {dir_out.name};

    for i_animal = 1:length(animals)
        if strcmp(animals{i_animal}, '.') || strcmp(animals{i_animal}, '..')
            continue
        end
        
        animal_folder = fullfile(folder_this, animals{i_animal});
    
        dir_out = dir(animal_folder);
        sessions = {dir_out.name};
        for j_session = 1:length(sessions)
            path_data = fullfile(animal_folder, sessions{j_session});
    
            % check the path
            if ~exist(path_data, 'dir') || length(sessions{j_session})~=8
                continue
            end

            if strcmpi(animals{i_animal}, 'Jaya') && (strcmpi(sessions{j_session}, '20231102') || strcmpi(sessions{j_session}, '20231103'))
                disp('Skip Jaya 20231102 / 20231103');
                continue
            end
    
            cd(path_data)
            if exist(fullfile(path_data, 'timestamps.mat'), 'file')
                load(fullfile(path_data, 'timestamps.mat'));
                if ~isfield(ts, 'FrameTimesSide')
                    disp(['Align videos in ', path_data]);
                    AlignSEQVideos;
                end
            else
                error('No timestamps found!');
            end
    
            disp([path_data, ' done!']);
        end
    
        cd(folder_root);
    end
end