function fileinfo = FindAviFiles

% 5/6/2021
% This is to find avi files in current folder. as well as the associated
% txt files

xfiles = dir('Cam*.avi');
nfiles = length(xfiles);

datefiles   =   [];
vfiles      =   {};
txtfiles    =   {};
for i=1:nfiles
    vfiles{i}       =   xfiles(i).name;
    txtfiles{i}     =   strrep(xfiles(i).name, 'avi', 'txt');
    datefiles(i)    =   xfiles(i).datenum;
end;

% sort dates

[DatefilesSorted, indsort] = sort(datefiles);
VidFiles = vfiles(indsort);
TxtFiles  = txtfiles(indsort);

fileinfo.Vids = VidFiles';
fileinfo.Txts = TxtFiles';

MEDfiles = dir('*Subject*.txt');

if length(MEDfiles)>0
    fileinfo.MED = MEDfiles.name;
end;