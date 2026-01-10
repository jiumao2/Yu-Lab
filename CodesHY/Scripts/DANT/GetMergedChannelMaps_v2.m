folder_data = 'G:\HectorData'; % the folder that contains session data, e.g. folder_data/20250510/
rat_name = 'Hector';
addpath(genpath('./EphysCodeWHB'));

chanMap = [];

dir_out = dir(folder_data);
folder_names = {dir_out.name};

for k = 1:length(folder_names)
    folder_this = folder_names{k};
    if length(folder_this) ~= 8 && length(folder_this) ~= 10
        continue
    end

    % load necessary data
    dir_out = dir(fullfile(folder_data, folder_this, 'RClass_*.mat'));
    if ~isempty(dir_out)
        r_filename = dir_out.name;
    else
        dir_out = dir(fullfile(folder_data, folder_this, 'RTarray*.mat'));
        r_filename = dir_out.name;
    end

    disp(['Processing ', folder_this, '...']);

    if isfile(fullfile(folder_data, folder_this, 'catgt_Exp_g0', 'chanMap.mat'))
        chanMap_this = load(fullfile(folder_data, folder_this, 'catgt_Exp_g0', 'chanMap.mat'));
    else
        clear r rClass;
        load(fullfile(folder_data, folder_this, r_filename));
    
        % get event times
        if ~exist('r', 'var')
            r = rClass;
        end        
        chanMap_this = r.Units.ChannelMap;
    end

    chanMap_temp = struct();
    chanMap_temp.xcoords = chanMap_this.xcoords(chanMap_this.connected == 1);
    chanMap_temp.ycoords = chanMap_this.ycoords(chanMap_this.connected == 1);
    chanMap_temp.kcoords = chanMap_this.kcoords(chanMap_this.connected == 1);
    chanMap_temp.connected = chanMap_this.connected(chanMap_this.connected == 1);

    if isempty(chanMap)
        chanMap = chanMap_temp;
    else
        chanMap(end+1) = chanMap_temp;
    end
    fprintf('%s done!\n', folder_this);
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










