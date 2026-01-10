rat_name = 'Gavi';
folder_output = './PETH_Figs';

if ~isfolder(folder_output)
    mkdir(folder_output);
end

folder_data = 'H:\Ephys\Gavi\Sessions';

% get all folders
dir_out = dir(folder_data);
folder_names = {dir_out.name};

for k = 1:length(folder_names)
    folder_this = folder_names{k}; % e.g., 20250607
    session = folder_this;

    % the length of the folder name should be 8
    if length(folder_this) ~= 8
        continue
    end

    % load necessary data
    r_filename = fullfile(folder_data, folder_this, ['RTarray_', rat_name, '_', session, '.mat']);
    if ~exist(r_filename, 'file')
        warning('R not found!');
        continue
    end

    disp(['Processing ', folder_this, '...']);

    folder_fig = fullfile(folder_data, folder_this, 'Fig');

    dir_output = dir(fullfile(folder_fig, [rat_name, '_', session, '_Ch*_Unit*.png']));
    fig_names = {dir_output.name};
    for j = 1:length(fig_names)
        ch = extractBetween(fig_names{j}, '_Ch', '_Unit');
        num_in_ch = extractBetween(fig_names{j}, '_Unit', '.png');
        new_name = [rat_name, '_', session, '_Ch', ch{1}, '_Unit', num_in_ch{1}, '.png'];

        % copy to the new folder
        path_fig = fullfile(folder_fig, fig_names{j});
        path_output = fullfile(folder_output, new_name);
        fprintf('Copying %s to %s ...\n', path_fig, path_output);
        copyfile(path_fig, path_output);
    end

    disp([folder_this, ' done!']);
end


