function send_r()

if nargin<1
    this_folder          =      pwd;
    folder_split          =     split(this_folder, '\');    
    rat_name            =       folder_split{end-1};
    session_name    =       folder_split{end};
    r_name               =      Spikes.r_name;
    r_names = strsplit(r_name, '_');
    rat_name = r_names{2};
    session_name = extractBefore(r_names{3}, '.mat');
end;

% send r array to the data folder
target_folder  = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'RTarray', rat_name);
if ~exist(target_folder, 'dir')
    mkdir(target_folder)
end
copyfile(r_name, target_folder)
disp('Done!')