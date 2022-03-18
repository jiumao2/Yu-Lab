% This deals with the situation when frame signals were stored. 
 
%% Maurice 8-31-2020
% there are filenames = { 'datafile001.ns6',  'datafile002.ns6',  'datafile003.ns6'};
topviews = {
    '20211124-17-37-43.000.seq'     % session 001
    '20211124-17-58-18.000.seq'     % session 002
    };
 
sideviews ={
    '20211124-17-37-42.000.seq' % session 001
    '20211124-17-58-15.000.seq' % session 002
    };
 
% this is the function to extract time stamps from a seq file
ts_top = struct('ts', [], 'skipind', []);
for i=1:length(topviews)
    ts_top(i) = findts(topviews{i});
end
 
ts_side = struct('ts', [], 'skipind', []);
for i=1:length(sideviews)
    ts_side(i) = findts(sideviews{i});
end
clear ts
ts.top = ts_top;
ts.topviews = topviews;
ts.side = ts_side;
ts.sideviews = sideviews;
 
save timestamps ts
