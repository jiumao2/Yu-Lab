function output = DisplayMEDs
% 2/9/2023
% Jianing Yu
% go through MED files in current folder (stored in session folders)

%%  function ComputeKornblumAllSessions

% find out name of the rat
thisFolder = pwd;
thisFolderSplitted = strsplit(thisFolder, '\');
NameIndex =  find(strcmp(thisFolderSplitted, 'ANMs'))+1;
ratName = thisFolderSplitted{NameIndex};
disp(['this rat is: ', ratName])

% Read folders
rootFolder = pwd;
files = dir(rootFolder);
dirFlags = [files.isdir];
subFolders                 =        files(dirFlags);
subFolderNames      =        {subFolders(3:end).name};
dataFolderNames    = {};
for k =1:length(subFolderNames)
    if ~isempty(str2num(subFolderNames{k}))
        dataFolderNames = [dataFolderNames  subFolderNames{k}];
        fprintf('Subfolder #%d = %s \n', k,  subFolderNames{k})
    end;
end;

% disp(dataFolderNames')
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~')
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~')
% Now go into each folder, read the txt files
thisFolder = pwd;

for i =1:length(dataFolderNames)
    txtFile = dir(fullfile(thisFolder, dataFolderNames{i}, '*.txt'));
    if ~isempty(txtFile)

        if length(txtFile) == 1

            % Read protocol name
            metadata = Behavior.MED.med_to_protocol(fullfile(thisFolder, dataFolderNames{i}, txtFile.name));
            protocol = metadata.ProtocolName;
            disp([dataFolderNames{i} ' | ' protocol ' | Experiment: ' metadata.Experiment])
        else
            disp(['Multiple files found in folder: ', dataFolderNames{i}])
        end;
    end;
end;
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~')
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~')

