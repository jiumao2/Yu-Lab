cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY0995
goodtrialnums(1).cell='JY0995';
load('trial_array_ANM236461_1402012_JY0995AAAA.mat')
load('badtrials.mat')
goodtrialnums(1).trials=setdiff(T.trialNums, [T.stimtrialNums badtrials findbadtrials(T, 0)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY1009
goodtrialnums(2).cell='JY1009';
load('trial_array_ANM236459_140325_JY1009AAAA.mat')
load('badtrials.mat')
goodtrialnums(2).trials=setdiff(T.trialNums, [T.stimtrialNums, badtrials findbadtrials(T, 0)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY1041
goodtrialnums(3).cell='JY1041';
load('trial_array_ANM220466_140403_JY1041AAAA.mat')
goodtrialnums(3).trials=setdiff(T.trialNums, [T.stimtrialNums findbadtrials(T, 0)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY1045
goodtrialnums(4).cell='JY1045';
load('trial_array_ANM220470_140409_JY1045AAAA.mat')
load('badtrials.mat')
goodtrialnums(4).trials=setdiff(T.trialNums, [T.stimtrialNums, badtrials findbadtrials(T, 0)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY0520
goodtrialnums(5).cell='JY0520';
load('trial_array_ANM190963_130408_JY0520AAAC.mat')
load('badtrials.mat')
goodtrialnums(5).trials=setdiff(T.trialNums, [T.stimtrialNums, badtrials findbadtrials(T, 1)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY0861
goodtrialnums(6).cell='JY0861';
load('trial_array_ANM214848_131010_JY0861AAAA.mat')
load('badtrials.mat')
goodtrialnums(6).trials=setdiff(T.trialNums, [T.stimtrialNums, badtrials findbadtrials(T, 0)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY1008
goodtrialnums(7).cell='JY1008';
load('trial_array_ANM234411_140216_JY1008AAAA.mat')
load('badtrials.mat')
goodtrialnums(7).trials=setdiff(T.trialNums, [T.stimtrialNums, badtrials findbadtrials(T, 0)]);

cd C:\Work\Projects\BehavingVm\Data\Vmdata\JY1048
goodtrialnums(8).cell='JY1048';
load('trial_array_ANM223517_140411_JY1048AAAA.mat')
load('badtrials.mat')
goodtrialnums(8).trials=setdiff(T.trialNums, [T.stimtrialNums, badtrials findbadtrials(T, 0)]);



