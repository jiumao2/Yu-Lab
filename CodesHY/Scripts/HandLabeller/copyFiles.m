good_camera_names = {'00D45424616', '00D41932992', '00D41932971'};

bad_camera_names = {'00D41932960', '00D41933035', '00D41932998'};

data = readtable('DataSummary.xlsx', 'NumHeaderLines', 0);

folder_data = 'F:\Video';
folder_dest = 'I:\LYJ\RawVideos\PawPreferenceWithHY';

for k = 1:height(data)
    lesion_type = data(k,1).Variables;
    lesion_type = lesion_type{1};

    animal_name = data(k,2).Variables;
    animal_name = animal_name{1};

    idx = 3;
    while idx<=size(data, 2)
        session = data(k,idx).Variables;
        if iscell(session) || isnan(session)
            break
        end
        disp([lesion_type, ' ', animal_name, ' ', num2str(session)]);

        % find the folder of the session
        folder_to_copy = find_folder(animal_name, session, folder_data);

        % copy to destination
        if ~exist(fullfile(folder_dest, lesion_type), 'dir')
            mkdir(fullfile(folder_dest, lesion_type));
        end
        if ~exist(fullfile(folder_dest, lesion_type, animal_name), 'dir')
            mkdir(fullfile(folder_dest, lesion_type, animal_name));
        end

        path_dest = fullfile(folder_dest, lesion_type, animal_name, num2str(session));
        copy_to_destination(folder_to_copy, path_dest, bad_camera_names);

        idx = idx+1;
    end
end

function out = find_folder(animal_name, session, folder_data)
    data_path = fullfile(folder_data, animal_name);
    dir_out = dir(data_path);
    folder_names = {dir_out.name};

    for k = 1:length(folder_names)
        if strcmp(folder_names{k}, '.') || strcmp(folder_names{k}, '..')
            continue
        end
        
        if strcmp(folder_names{k}, num2str(session))
            out = fullfile(data_path, folder_names{k});
            return
        end

        folder_this = fullfile(data_path, folder_names{k});
        if ~exist(folder_this, 'dir')
            continue
        end

        dir_out = dir(folder_this);
        subfolders = {dir_out.name};
        for j = 1:length(subfolders)
            subfolder_this = fullfile(folder_this, subfolders{j});
            if strcmp(subfolders{j}, num2str(session))
                out = subfolder_this;
                return
            end
        end
    end

    out = []; 
end

function copy_to_destination(folder_to_copy, path_dest, bad_camera_names)
    if ~exist(path_dest, 'dir')
        mkdir(path_dest);
    end

    dir_out = dir(folder_to_copy);
    filenames = {dir_out.name};
    for k = 1:length(filenames)
        filename_this = fullfile(folder_to_copy, filenames{k});
        if ~isfile(filename_this)
            continue
        end

        % every video should have corresponding timestamps
        if strcmp(filename_this(end-3:end), '.avi') && ~exist([filename_this(1:end-3), 'txt'], 'file')
            disp([filename_this, ' does not have timestamp .txt file!']);
            continue
        end

        flag = false;
        for j = 1:length(bad_camera_names)
            if ~isempty(strfind(filename_this, bad_camera_names{j}))
                flag = true;
            end
        end
        if flag
            continue
        end

        % copy this file
        filename_destination = fullfile(path_dest, filenames{k});
        disp(['Copying ', filename_this, ' to ', filename_destination, '...']);
        copyfile(filename_this, filename_destination);

    end
end
