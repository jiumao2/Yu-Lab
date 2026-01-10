folder_root = 'J:\Punch';

while true
    dir_out = dir(folder_root);
    folder_names = {dir_out.name};
    
    folder_data = {};
    for k = 1:length(folder_names)
        folder_this = folder_names{k};
        if strcmpi(folder_this, '20241101')
            continue
        end
        if length(folder_this) ~= 8
            continue
        end
    
        if ~exist(fullfile(folder_root, folder_this), 'dir')
            continue
        end
        
        % has been sorted
        if exist(fullfile(folder_root, folder_this, 'catgt_Exp_g0', 'params.py'), 'file')
            continue
        end
        
        % not ready for sorting
        if ~exist(fullfile(folder_root, folder_this, 'catgt_Exp_g0', 'Exp_g0_ct_offsets.txt'), 'file')
            continue
        end
        
        folder_data{end+1} = folder_this;
    end
    
    fprintf('%d folders are found!\n', length(folder_data));
    disp(folder_data);
    
    %% running kilosort
    addpath(genpath('C:\Users\pku\Documents\GitHub\Kilosort_2_5'));
    chanMapFile = 'J:\Punch\slicedChanMap.mat';

    for k = 1:length(folder_data)
        folder_this = fullfile(folder_root, folder_data{k});
        folder_output = fullfile(folder_this, 'catgt_Exp_g0');
    
        rootZ = folder_output;
        rootH = folder_output;

        copyfile(chanMapFile, fullfile(folder_output, 'chanMap.mat'));
        
        fprintf('Running kilosort in %s!\n', folder_this);
        run(fullfile(folder_root, 'main_kilosort.m'));

        print(193, fullfile(folder_this, 'Motion.png'), '-dpng', '-r600');
        print(194, fullfile(folder_this, 'DriftMap.png'), '-dpng', '-r600');

        if exist('rez', 'var')
            clear rez;
        end
        
        close all;

        % delete Exp_g0_tcat.imec0.ap.bin to save space
        delete(fullfile(folder_output, 'Exp_g0_tcat.imec0.ap.bin'));

        fprintf('Kilosort done in %s!\n', folder_this);
    end

    pause(10);
end


