y_min = 560;
y_max = 4160;
num_channels = 361;

folder_root = 'L:\Ephys\Punch\Sessions';
folder_out = 'J:\Punch';

dir_out = dir(folder_root);
folder_names = {dir_out.name};

chanMap = [];
for k = 1:length(folder_names)
    folder_this = folder_names{k};

    if strcmpi(folder_this, '20241101')
        continue
    end
    if length(folder_this) ~= 8
        continue
    end

    % has been sorted
    if exist(fullfile(folder_out, folder_this, 'catgt_Exp_g0', 'params.py'), 'file')
        continue
    end
    if exist(fullfile(folder_out, folder_this, 'catgt_Exp_g0', 'Exp_g0_ct_offsets.txt'), 'file')
        continue
    end
    
    % generate chanMap.mat
    SGLXMetaToCoords(fullfile(folder_root, folder_this, 'Exp_g0\Exp_g0_imec0\Exp_g0_t0.imec0.ap.meta'));
    close all;
    
    chanMap = load(fullfile(folder_root, folder_this, 'Exp_g0\Exp_g0_imec0\chanMap.mat'));
    
    idx_good = find(chanMap.connected == 1 & chanMap.ycoords >= y_min & chanMap.ycoords <= y_max);

    assert(length(idx_good) == num_channels);

    % change the idx_good to 0 starts index
    idx_good = sort(idx_good);
    idx_start = idx_good(1);
    idx_end = idx_good(end);
    for j = 2:length(idx_good)
        if idx_good(j) - idx_good(j-1) == 1
            continue
        end

        idx_end = [idx_end, idx_good(j-1)];
        idx_start = [idx_start, idx_good(j)];
    end

    idx_start = sort(idx_start) - 1; % zero based
    idx_end = sort(idx_end) - 1;

    assert(length(idx_start) == length(idx_end));
    assert(sum(idx_end - idx_start) + length(idx_start) == num_channels);

    save_str = '';
    for j = 1:length(idx_start)
         save_str = [save_str, num2str(idx_start(j)), ':', num2str(idx_end(j))];
         if j ~= length(idx_start)
             save_str = [save_str, ','];
         end
    end

    cat_gt_str = ['CatGT -dir='...
        fullfile(folder_root, folder_this),...
        ' -run=Exp -g=0 -t=0 -ni -ap -prb=0 -prb_fld -dest=',...
        fullfile(folder_out, folder_this),...
        ' -zerofillmax=0 -gblcar -save=2,0,0,',...
        save_str];

    % make the destiny folder
    if ~exist(fullfile(folder_out, folder_this), 'dir')
        mkdir(fullfile(folder_out, folder_this));
    end
    
    disp(cat_gt_str);
    system(cat_gt_str);

end

