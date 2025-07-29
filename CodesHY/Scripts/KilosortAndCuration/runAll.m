folder_names = {'20250722', '20250724'};

for i_folder = 1:length(folder_names)
    rootZ = fullfile('./', folder_names{i_folder}, 'catgt_Exp_g0'); % the raw data binary file is in this folder
    rootH = rootZ; % path to temporary binary file (same size as data, should be on fast SSD)

    nblocks = 5;

    run(fullfile('./', 'main_kilosort.m'));
    drawnow;

    try
        print(193, fullfile('./', folder_names{i_folder}, 'MotionA.png'), '-dpng', '-r300');
    catch
        disp('Figure 193 not existed!');
    end

    try
        print(194, fullfile('./', folder_names{i_folder}, 'MotionB.png'), '-dpng', '-r300');
    catch
        disp('Figure 194 not existed!');
    end

    clear rez
    close all;
end



