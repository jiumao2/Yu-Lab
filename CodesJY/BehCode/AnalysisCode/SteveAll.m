arrayfun(@(x)x.name, dir('*.txt'), 'UniformOutput', false)

FileNames = {
    '2019-10-29_17h36m_Subject steve.txt'
    '2019-10-30_19h18m_Subject Steve.txt'
    '2019-10-31_18h43m_Subject Steve.txt'
    '2019-10-31_19h16m_Subject Steve.txt'
    '2019-11-01_20h48m_Subject steve.txt'
    '2019-11-02_21h53m_Subject steve.txt'
    '2019-11-04_19h13m_Subject steve.txt'
    '2019-11-05_20h54m_Subject steve.txt'
    '2019-11-06_19h13m_Subject steve.txt'
    '2019-11-07_19h11m_Subject steve.txt'
    '2019-11-08_21h57m_Subject steve.txt'
    };


bAll=struct('Metadata',[],'SessionName',[],'PressTime',[],'ReleaseTime', [],...
    'Correct',[],'Premature',[],'Late',[],'Dark', [],...
    'ReactionTime',[],'TimeTone',[],'IndToneLate',[]);


for i=1:length(FileNames)
    bAll(i)=track_training_progress_advanced(FileNames{i});
end;


savename = ['bAll_' upper(bAll(i).Metadata.SubjectName)];
save (savename, 'bAll')

close all;
plotbAll(bAll)