function send_psth_pop(brain)

if nargin<1
    brain = input('Where did you record these neurons?', 's')
end;


this_folder                       =      pwd;
if ispc
    folder_split                      =       split(this_folder, '\');
else
    folder_split                      =       split(this_folder, '/');
end;
rat_name                        =       folder_split{end-1};
session_name                =       folder_split{end};
 
psth_new_name             =      ['PopulationPSTH_' rat_name, '_', session_name, '.mat'];
psth_name                      =     psth_new_name;

% send r array to the data folder
target_folder  = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'PopulationPSTH', brain);

if ~exist(target_folder, 'dir')
  mkdir(target_folder);
end

target_name = fullfile(target_folder, psth_new_name);
copyfile(psth_name, target_name);

clc
disp(['PSTH pop sent to: ' target_folder])
if ispc
winopen(target_folder)
end;

% check if there is also a population fig

fod = fullfile(pwd, 'Fig');
this_fig = dir(fullfile(fod, 'Population*.png'));

if ~isempty(this_fig.name)
    copyfile(fullfile(this_fig.folder, this_fig.name), target_folder);
end;

