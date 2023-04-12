% ___________________________________________________________________________________________
% File:             med_to_protocol.m
% File type:        Function
% Created on:       Nov 5 2019
% Created by:       Jianing Yu
% Last revised on:  Nov 5, 2019
% Last revised by:  Jianing Yu
%

function metadata = med_to_protocol(fNAME)

fid = fopen(fNAME);
if fid == -1
    fprintf ('\nIncorrect file: %s', fNAME)
    return;
end;

%%Scans the entire line in as a string, with spaces (to preserve number info)
fileString = fscanf(fid, '%c');

%% subject
k=strfind(fileString, 'Subject');
k2=strfind(fileString, 'Experiment');
k3=strfind(fileString, 'Group');

metadata.SubjectName=fileString([k(2)+9:k2-3]);
metadata.Experiment =  fileString(k2+12:k3-3);

%%  date
flag = '/';
tmp = find(fileString == flag);

month = fileString([tmp(1)-2:tmp(1)-1]);
date  = fileString([tmp(1)+1:tmp(1)+2]);
year  = fileString([tmp(2)+1:tmp(2)+2]);

metadata.Date = ['20' year month  date];

%% time
k=strfind(fileString, 'Start Time');
metadata.StartTime=fileString([k+12:k+19]);
k=strfind(fileString, 'End Time');
metadata.EndTime=fileString([k+10:k+17]);

%% protocol
k=strfind(fileString, 'MSN');
k2=strfind(fileString, 'C:');
metadata.ProtocolName=fileString([k+5:k2(2)-3]);

fclose(fid);
