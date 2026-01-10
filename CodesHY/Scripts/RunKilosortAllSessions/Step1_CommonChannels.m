folder_root = 'E:\Ephys\Punch\Sessions';

dir_out = dir(folder_root);
folder_names = {dir_out.name};

chanMap = [];
for k = 1:length(folder_names)
    folder_this = folder_names{k};
    if length(folder_this) < 8
        continue
    end

    if strcmpi(folder_this, '20241101')
        continue
    end

    if ~exist(fullfile(folder_root, folder_this, 'Exp_g0\Exp_g0_imec0\Exp_g0_t0.imec0.ap.meta'), 'file')
        continue
    end
    
    SGLXMetaToCoords(fullfile(folder_root, folder_this, 'Exp_g0\Exp_g0_imec0\Exp_g0_t0.imec0.ap.meta'));
    close all;
    
    chanMap_this = load(fullfile(folder_root, folder_this, 'Exp_g0\Exp_g0_imec0\chanMap.mat'));
    
    if isempty(chanMap)
        chanMap = chanMap_this;
    else
        chanMap(end+1) = chanMap_this;
    end
    fprintf('%s done!\n', folder_this);
end

y_common = unique(chanMap(1).ycoords);

for k = 1:length(chanMap)
    y_common = intersect(y_common, chanMap(k).ycoords);
end

fprintf('Min y: %d, Max y: %d\n', min(y_common), max(y_common));

%%
y_range = [560, 4160];


%% Construct a chanmap from the files
chanMap_this = chanMap(1);
idx_good = find(chanMap_this.ycoords >= y_range(1) & chanMap_this.ycoords <= y_range(2) & chanMap_this.connected == 1);

connected = chanMap_this.connected(idx_good);
chanMap = 1:length(idx_good);
chanMap0ind = chanMap-1;
xcoords = chanMap_this.xcoords(idx_good);
ycoords = chanMap_this.ycoords(idx_good);
kcoords = chanMap_this.kcoords(idx_good);

save('./slicedChanMap.mat', 'connected', 'chanMap', 'chanMap0ind', 'xcoords', 'ycoords', 'kcoords');

fprintf('%d channels are included!\n', length(idx_good));










