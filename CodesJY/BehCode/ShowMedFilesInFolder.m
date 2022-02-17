function x=ShowMedFilesInFolder
 
 x=arrayfun(@(x)x.name, dir(fullfile(pwd, 'MEDFiles', '*.txt')), 'UniformOutput', false)
 y=arrayfun(@(x)x.name, dir( fullfile(pwd, 'MEDFiles', '*.mat')), 'UniformOutput', false)