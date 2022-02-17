function [life, b, e]=recordinglife(cellnum, code, sweepnums)

% b: beginning
% e: ending
pd=pwd;

cd('W:\users\Jianing\Data\physiology');

time=[];

for i=1:length(sweepnums)
    tracenum=sweepnums(i);
    
if tracenum < 10
    filler = '000';
elseif tracenum <100
    filler = '00';
elseif tracenum <1000
    filler = '0';
end

d = load([cellnum filesep cellnum code filler int2str(tracenum) '.xsg'],'-mat');

time(i)=datenum(d.header.xsgFileCreationTimestamp)*24*60;

end;

b=time(1); e=time(end);

life=e-b;

cd (pd)