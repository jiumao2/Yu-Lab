function undo_movefile(path_avi)
path_all= {[path_avi,'\long'],[path_avi,'\long\stim'],[path_avi,'\long\nostim'],[path_avi,'\short'],[path_avi,'\short\stim'],[path_avi,'\short\nostim']};
for k = 1:length(path_all)
    path_tmp = path_all{k};
    dir_output = dir(fullfile(path_tmp,'*.avi'));
    filenames = {dir_output.name};
    for j = 1:length(filenames)
        movefile(fullfile(path_tmp,filenames{j}), fullfile(path_avi,filenames{j}));
    end
end
rmdir([path_avi,'\long'],'s');
rmdir([path_avi,'\short'],'s');
end