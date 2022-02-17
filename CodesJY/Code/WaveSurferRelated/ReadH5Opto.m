function sout = ReadH5Opto(filename)

% Jianing Yu 5/19/2021 
%This reads data from wavesurfer. 

if nargin<1
    xfile = dir('*.h5');
    filename = xfile.name;
end;

s = ws.loadDataFile(filename); % this reads data in h5 file. 
Fs = s.header.AcquisitionSampleRate; % sampling rate, per sec


ChLabels = {'Press', 'Trigger', 'Opto', 'Approach', 'Frames'};

% construct time series
t = [1:size(s.sweep_0001.analogScans, 1)]*1000/Fs; % this is time, in ms

sout.Labels            =       ChLabels;
sout.Time               =       t;
sout.Unit                =      'ms';
sout.Signals           =       s.sweep_0001.analogScans;