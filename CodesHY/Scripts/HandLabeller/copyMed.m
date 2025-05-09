med_folder = 'F:\MED';
folder_data = 'I:\LYJ\RawVideos\PawPreferenceWithHY';
lesion_types = {'BiM1', 'BiDLS'};

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
            
            year = session_this(1:4);
            month = session_this(5:6);
            day = session_this(7:8);

            dir_out = dir(fullfile(med_folder, animal_name_this, [...
                num2str(year), '-', num2str(month), '-', num2str(day),...
                '_*_Subject ', animal_name_this, '.txt']));

            if isempty(dir_out)
                disp(['No Med found in ', session_folder]);
                continue
            end
            
            med_names = {dir_out.name};
            if length(med_names) >= 2
                disp(['More than 2 Med files found in ', session_folder]);
            end

            for ii = 1:length(med_names)
                med_path = fullfile(med_folder, animal_name_this, med_names{ii});
                disp(['Copying ', med_path, ' to ', session_folder, '...']);
                copyfile(med_path, session_folder);
            end
        end
    end
end


