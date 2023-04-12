function  PostMED     =   findMEDName(SessionNames)
PostMED = {};
for i =1:length(SessionNames)
    rootFolder = pwd;
    SessionFolder = fullfile(rootFolder, SessionNames{i});
    thisFile = dir(fullfile(SessionFolder, '*.txt'));
    PostMED = [PostMED thisFile.name];
end;

end