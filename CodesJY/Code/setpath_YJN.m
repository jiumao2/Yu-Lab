path_this = path;
path_split = strsplit(path_this,';');
path_new = path_split(contains(path_split,'MATLAB'));

my_path = 'C:\Users\jiumao\Desktop\Yu Lab\MyCodes';
my_path_all = genpath(my_path);

my_path_split = strsplit(my_path_all,';');
my_path_new = my_path_split(~contains(my_path_split,'git')...
    & ~contains(my_path_split,'+'));
%%
path_out = [strjoin(my_path_new,';'), strjoin(path_new,';')];
path(path_out);
clear;