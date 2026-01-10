folder_root = 'D:\Dropbox\13_EphysProcessed\Dara'; % the folder that contains session data, e.g. folder_data/20250510/
rat_name = 'Dara';
folder_task = {'1_AutoShaping', '2_LeverPress', '3_LeverRelease', '4_Wait', '5_SRT_2FPProbeWin1000', '6_SRT_2FPProbe'};

chanMap = [];
for i_task = 1:length(folder_task)
    folder_data = fullfile(folder_root, folder_task{i_task});
    dir_out = dir(folder_data);
    folder_names = {dir_out.name};

    for k = 1:length(folder_names)
        folder_this = folder_names{k};
        if length(folder_this) ~= 8
            continue
        end

        % load necessary data
        r_filename = fullfile(folder_data, folder_this, ['RTarray_', rat_name, '_', folder_this, '.mat']);
        if ~isfile(r_filename)
            disp(r_filename)
            error('R not found!');
        end

        disp(['Processing ', folder_this, '...']);
        load(r_filename);

        chanMap_this = r.Units.ChanMap;

        if isempty(chanMap)
            chanMap = chanMap_this;
        else
            chanMap(end+1) = chanMap_this;
        end
        fprintf('%s done!\n', folder_this);
    end

end
save ./AllChanMap.mat chanMap;

%%
load ./AllChanMap.mat;

x_all = [];
y_all = [];
k_all = [];
for k = 1:length(chanMap)
    x_all = [x_all; chanMap(k).xcoords];
    y_all = [y_all; chanMap(k).ycoords];
    k_all = [k_all; chanMap(k).kcoords];
end

fprintf('Min y: %d, Max y: %d\n', min(y_all), max(y_all));

ids = y_all*1e6+x_all;
[~, idx_unique] = unique(ids);

xcoords = x_all(idx_unique);
ycoords = y_all(idx_unique);
kcoords = k_all(idx_unique);
chanMap = (1:length(idx_unique))';
chanMap0ind = chanMap - 1;
connected = true(length(idx_unique), 1);

save('./mergedChanMap.mat', 'connected', 'chanMap', 'chanMap0ind', 'xcoords', 'ycoords', 'kcoords');

fprintf('%d channels are included!\n', length(idx_unique));










