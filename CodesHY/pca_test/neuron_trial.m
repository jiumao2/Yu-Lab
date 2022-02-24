if ~exist('r','var')
    load('c:/Users/jiumao/Desktop/Russo20210910/RTarrayAll.mat')
    load('c:/Users/jiumao/Desktop/Russo20210910/PSTHOut.mat')
end
spike_times = cell(length(r.Units.SpikeTimes),1);

max_spike_time = 0;
for k = 1:length(spike_times)
    spike_times{k} = r.Units.SpikeTimes(k).timings;
    if r.Units.SpikeTimes(k).timings(end)>max_spike_time
        max_spike_time = r.Units.SpikeTimes(k).timings(end);
    end
end

% unit_of_interest = [2     4     7     8    12    14    16  19];
% unit_of_interest = [1,5,7,8,9,11,12,14,19];
unit_of_interest = 1:length(r.Units.SpikeTimes);

spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

spikes = smoothdata(spikes','gaussian',1000)';


press_times = round(r.Behavior.EventTimings(r.Behavior.EventMarkers==3));
FP_long_index = r.Behavior.Foreperiods==1500;
FP_short_index = r.Behavior.Foreperiods==750;

t_pre = -4000;
t_post = 4000;
t_len = t_post-t_pre+1;

% spikes_trial = zeros(length(unit_of_interest),t_len,length(press_times));
spikes_trial_flattened = zeros(length(unit_of_interest),t_len*length(press_times));
spikes_trial_flattened = zscore(spikes_trial_flattened,0,2);

for k = 1:length(press_times)
%     spikes_trial(:,:,k) = spikes(:,press_times(k)+t_pre:press_times(k)+t_post);
    spikes_trial_flattened(:,t_len*(k-1)+1:t_len*k) = spikes(:,press_times(k)+t_pre:press_times(k)+t_post);
end

% [coeff, score, latent, tsquared, explained] = pca(spikes_trial_flattened');
% 
% figure;
% plot(cumsum(explained),'x-')
% title('explained')
% ylabel('cumulative sum of explanation')

score_trial = reshape(spikes_trial_flattened',t_len,length(press_times),length(unit_of_interest));
figure;
subplot(231)
plot(t_pre:t_post,score_trial(:,FP_long_index,1),'color',[0.5,0.5,0.5],'lineWidth',0.5)
hold on
plot(t_pre:t_post,mean(score_trial(:,FP_long_index,1),2),'lineWidth',2)
subplot(232)
plot(t_pre:t_post,score_trial(:,FP_long_index,2),'color',[0.5,0.5,0.5],'lineWidth',0.5)
hold on
plot(t_pre:t_post,mean(score_trial(:,FP_long_index,2),2),'lineWidth',2)
subplot(233)
plot(t_pre:t_post,score_trial(:,FP_long_index,3),'color',[0.5,0.5,0.5],'lineWidth',0.5)
hold on
plot(t_pre:t_post,mean(score_trial(:,FP_long_index,3),2),'lineWidth',2)
subplot(234)
plot(t_pre:t_post,score_trial(:,FP_short_index,1),'color',[0.5,0.5,0.5],'lineWidth',0.5)
hold on
plot(t_pre:t_post,mean(score_trial(:,FP_short_index,1),2),'lineWidth',2)
subplot(235)
plot(t_pre:t_post,score_trial(:,FP_short_index,2),'color',[0.5,0.5,0.5],'lineWidth',0.5)
hold on
plot(t_pre:t_post,mean(score_trial(:,FP_short_index,2),2),'lineWidth',2)
subplot(236)
plot(t_pre:t_post,score_trial(:,FP_short_index,3),'color',[0.5,0.5,0.5],'lineWidth',0.5)
hold on
plot(t_pre:t_post,mean(score_trial(:,FP_short_index,3),2),'lineWidth',2)

figure;
plot3(t_pre:t_post,mean(score_trial(:,FP_long_index,1),2),mean(score_trial(:,FP_long_index,2),2),'.-')
hold on
plot3(t_pre:t_post,mean(score_trial(:,FP_short_index,1),2),mean(score_trial(:,FP_short_index,2),2),'.-')

figure;
plot3(mean(score_trial(:,FP_long_index,1),2),mean(score_trial(:,FP_long_index,2),2),mean(score_trial(:,FP_long_index,4),2),'.-')
hold on
plot3(mean(score_trial(:,FP_short_index,1),2),mean(score_trial(:,FP_short_index,2),2),mean(score_trial(:,FP_short_index,4),2),'.-')
