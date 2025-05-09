path_labelhand = 'C:\Users\jiumao\Desktop\HandLabeller\LabelHands.m';
folder_data = 'G:\Lesion';
lesion_types = {'UniDLS'};

for k = 1:length(lesion_types)
    folder_this = fullfile(folder_data, lesion_types{k});
    dir_out = dir(folder_this);
    animal_names = {dir_out.name};
    for j = 1:length(animal_names)
        if strcmp(animal_names{j}, '.') || strcmp(animal_names{j}, '..')
            continue
        end
        
        animal_folder = fullfile(folder_this, animal_names{j});
        if ~exist(animal_folder, 'dir')
            continue
        end

        animal_name_this = animal_names{j};
        dir_out = dir(animal_folder);
        sessions = {dir_out.name};
        for i = 1:length(sessions)
            session_this = sessions{i};
            session_folder = fullfile(animal_folder, sessions{i});

            if strcmp(session_this, '.') || strcmp(session_this, '..')
                continue
            end

            if ~exist(session_folder, 'dir')
                continue
            end
            

            disp(['Copying ', path_labelhand, ' to ', session_folder, '...']);
            copyfile(path_labelhand, session_folder);
        end
    end
end


