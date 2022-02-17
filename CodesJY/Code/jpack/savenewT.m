function savenewT(T)
% in case there is no 'spikes.mat'
spikes.cellNum=T.cellNum;
spikes.cellCode=T.cellCode;
spikes.mouseName=T.mouseName;
spikes.sessionName=T.sessionName;
spikes.depth=T.depth;

spikes.trialnums=[]; % this is more trial index.
spikes.behtrialnums=[];
spikes.time=[];
spikes.waves=[];
spikes.projs=[];
spikes.choose=[];
spikes.pcdraw=[];
spikes.threshold=[];

T=mergeT_and_spikes(T, spikes);
file=dir(['trial_array_' '*.mat']);
newfilename=['Tarray' file.name(end-13:end)];
if ~isempty(file)
    save(newfilename, 'T');
end;

% also save to new place:
% C:\Work\Dropbox\Work\OldPhysiologyData
path=finddropbox;
mkdir([path 'Work\OldPhysiologyData\' T.cellNum])
save ([path 'Work\OldPhysiologyData\' T.cellNum '\' newfilename], 'T')

file=dir(['ConTA_' [T.cellNum T.cellCode] '.mat']);

if ~isempty(file)
    copyfile(file.name, [path 'Work\OldPhysiologyData\' T.cellNum '\' file.name])
else
    display(['cannot find--' ['ConTA_' [T.cellNum T.cellCode] '.mat']])
end;
