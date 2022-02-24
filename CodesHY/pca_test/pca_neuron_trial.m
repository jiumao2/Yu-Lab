% function pca_neuron_trial(data_path,t_pre,t_post)
% data_path = 'c:/Users/jiumao/Desktop/Eli20210923';
set(groot,'defaultfigurerenderer','opengl')
% if ~exist('r','var')
%     load([data_path, '/RTarrayAll.mat'])
% end
spike_times = cell(length(r.Units.SpikeTimes),1);

max_spike_time = 0;
for k = 1:length(spike_times)
    spike_times{k} = r.Units.SpikeTimes(k).timings;
    if r.Units.SpikeTimes(k).timings(end)>max_spike_time
        max_spike_time = r.Units.SpikeTimes(k).timings(end);
    end
end

% unit_of_interest = [2     4     7     8    12    14    16  19];
unit_of_interest = [1,3,5,7,12,13,15,16,18,20];
% unit_of_interest = 1:length(r.Units.SpikeTimes);

% binned
spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

% gaussian kernel
spikes = smoothdata(spikes','gaussian',50)';
% spikes = zscore(spikes,0,2);

% pick correct trials and separate long-FP/short-FP trials
press_times = round(r.Behavior.EventTimings(r.Behavior.EventMarkers==3));
FP_long_index = r.Behavior.Foreperiods==1500;
FP_short_index = r.Behavior.Foreperiods==750;
correct_index = r.Behavior.CorrectIndex;

fp_long = [];
fp_short = [];
for k = 1:length(correct_index)
    if FP_long_index(correct_index(k))
        fp_long = [fp_long,k];
    elseif FP_short_index(correct_index(k))
        fp_short = [fp_short,k];
    end
end
FP_long_index = fp_long;
FP_short_index = fp_short;


t_pre = -1800;
t_post = 3000;
t_len = t_post-t_pre+1;

spikes_trial_flattened = zeros(length(unit_of_interest),t_len*length(correct_index));

for k = 1:length(correct_index)
    spikes_trial_flattened(:,t_len*(k-1)+1:t_len*k) = spikes(:,press_times(correct_index(k))+t_pre:press_times(correct_index(k))+t_post);
end

% zscore
spikes_trial_flattened = zscore(spikes_trial_flattened,0,2);
spikes_trial = reshape(spikes_trial_flattened',t_len,length(correct_index),length(unit_of_interest));

[coeff, score, latent, tsquared, explained] = pca(spikes_trial_flattened');
[lambda,psi,T,stats,F] = pca(spikes_trial_flattened');
% score(:,1) = -score(:,1);

figure;
bar(explained)
title('explained')

score_trial = reshape(score,t_len,length(correct_index),length(unit_of_interest));
figure;
for k = 1:4
    subplot(2,2,k)
    plot(t_pre:t_post,mean(score_trial(:,FP_long_index,k),2),'b-','lineWidth',3)
    hold on
    plot(t_pre:t_post,mean(score_trial(:,FP_short_index,k),2),'r-','lineWidth',3)
    legend('FP=1500ms','FP=750ms')
    hold on
    xline(0,'k--','HandleVisibility','off')
    xline(1500,'b--','HandleVisibility','off')
    xline(750,'r--','HandleVisibility','off')
    xlabel('time (ms)')
    ylabel(['PC',num2str(k)])
end

figure;
plot3(t_pre:t_post,mean(score_trial(:,FP_long_index,1),2),mean(score_trial(:,FP_long_index,2),2),'.-')
hold on
plot3(t_pre:t_post,mean(score_trial(:,FP_short_index,1),2),mean(score_trial(:,FP_short_index,2),2),'.-')

figure;
plot3(mean(score_trial(:,FP_long_index,1),2),mean(score_trial(:,FP_long_index,2),2),mean(score_trial(:,FP_long_index,3),2),'.-')
hold on
plot3(mean(score_trial(:,FP_short_index,1),2),mean(score_trial(:,FP_short_index,2),2),mean(score_trial(:,FP_short_index,3),2),'.-')

% Average
average_spikes_long = reshape(mean(spikes_trial(:,FP_long_index,:),2),t_len,[]);
average_spikes_short = reshape(mean(spikes_trial(:,FP_short_index,:),2),t_len,[]);

SpikeNotes = r.Units.SpikeNotes;
save([data_path, '/average_spikes.mat'],'average_spikes_long','average_spikes_short','SpikeNotes');

% end