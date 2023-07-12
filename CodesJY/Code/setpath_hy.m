path_this = path;
path_split = strsplit(path_this,';');
path_new = path_split(contains(path_split,'MATLAB'));

my_path = 'C:\Users\pku\Documents\GitHub\Yu-Lab';
my_path_all = genpath(my_path);

path_out = [my_path_all,strjoin(path_new,';')];
path(path_out);
clear;


