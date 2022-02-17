function MakeSpreadSheetAllSessions(ANM, FolderName)

if nargin<2
    FolderName = [];
end;
% folder
FolderLoc           =        fullfile(pwd, FolderName);
AllMedFiles         =       arrayfun(@(x)x.name, dir(fullfile(pwd, FolderName, '*.txt')), 'UniformOutput', false);
SheetName        =        sprintf('%sTrainingRecord', ANM)


TableEvents        =        table(AllMedFiles);
writetable(TableEvents, SheetName, 'FileType','spreadsheet');
