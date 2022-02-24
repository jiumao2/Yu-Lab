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

% unit_of_interest = [2     4     7     8    12    14    15    16];
% unit_of_interest = [1,5,7,8,9,11,12,14,19];
unit_of_interest = 1:length(r.Units.SpikeTimes);

spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

binWidth = 20;
spikes_binned = zeros(length(unit_of_interest),floor(max_spike_time/binWidth));
for k = 1:length(spikes_binned)
    spikes_binned(:,k) = sum(spikes(:,(k-1)*binWidth+1 : k*binWidth),2);
end
%%

spikes_binned = zscore(spikes_binned,0,2);
spikes_binned = smoothdata(spikes_binned','gaussian',15)';

[coeff, score, latent, tsquared, explained] = pca(spikes_binned');

figure;
plot(cumsum(explained))
title('explained')

press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==3);
FP_long_index = r.Behavior.Foreperiods==1500;
FP_short_index = r.Behavior.Foreperiods==750;

t_pre = -4000; % ms
t_post = 4000;
pca_spikes_all = zeros(length(press_times),floor((t_post-t_pre)/binWidth));
pca_spikes_all2 = zeros(length(press_times),floor((t_post-t_pre)/binWidth));
pca_spikes_all3 = zeros(length(press_times),floor((t_post-t_pre)/binWidth));
pca_spikes_all4 = zeros(length(press_times),floor((t_post-t_pre)/binWidth));

for k = 1:length(press_times)
    pca_spikes_all(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,1);
    pca_spikes_all2(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,2);
    pca_spikes_all3(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,3);
    pca_spikes_all4(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,4);
end

figure;
subplot(241)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_long_index,:)))
subplot(242)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all2(FP_long_index,:)))
subplot(243)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all3(FP_long_index,:)))
subplot(244)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all4(FP_long_index,:)))
subplot(245)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_short_index,:)))
subplot(246)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all2(FP_short_index,:)))
subplot(247)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all3(FP_short_index,:)))
subplot(248)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all4(FP_short_index,:)))

figure;
plot3(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_long_index,:)),mean(pca_spikes_all2(FP_long_index,:)),'.-')
hold on
plot3(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_short_index,:)),mean(pca_spikes_all2(FP_short_index,:)),'.-')

figure;
plot3(mean(pca_spikes_all(FP_long_index,:)),mean(pca_spikes_all2(FP_long_index,:)),mean(pca_spikes_all3(FP_long_index,:)),'.-')
hold on
plot3(mean(pca_spikes_all(FP_short_index,:)),mean(pca_spikes_all2(FP_short_index,:)),mean(pca_spikes_all3(FP_short_index,:)),'.-')
%% peak pca
peak_pos = zeros(length(unit_of_interest),1);
spikes_binned2 = zeros(size(spikes_binned));
for k = 1:length(unit_of_interest)
    [~,temp_idx] = max(PSTHOut.PressAll(unit_of_interest(k)+1,151:200));
    peak_pos(k) = 50-temp_idx;
    spikes_binned2(k,:) = circshift(spikes_binned(k,:),peak_pos(k));
end
figure;
plot(peak_pos)
[coeff, score, latent, tsquared, explained] = pca(spikes_binned2');

figure;
plot(cumsum(explained))
title('explained')

t_pre = -4000; % ms
t_post = 4000;
pca_spikes_all = zeros(length(press_times),floor((t_post-t_pre)/binWidth));
pca_spikes_all2 = zeros(length(press_times),floor((t_post-t_pre)/binWidth));
pca_spikes_all3 = zeros(length(press_times),floor((t_post-t_pre)/binWidth));
pca_spikes_all4 = zeros(length(press_times),floor((t_post-t_pre)/binWidth));

for k = 1:length(press_times)
    pca_spikes_all(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,1);
    pca_spikes_all2(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,2);
    pca_spikes_all3(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,3);
    pca_spikes_all4(k,:) = score(floor((press_times(k)+t_pre)/binWidth):floor((press_times(k)+t_post)/binWidth)-1,4);
end

figure;
subplot(241)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_long_index,:)))
subplot(242)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all2(FP_long_index,:)))
subplot(243)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all3(FP_long_index,:)))
subplot(244)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all4(FP_long_index,:)))
subplot(245)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_short_index,:)))
subplot(246)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all2(FP_short_index,:)))
subplot(247)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all3(FP_short_index,:)))
subplot(248)
plot(t_pre:binWidth:t_post-1,mean(pca_spikes_all4(FP_short_index,:)))

figure;
plot3(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_long_index,:)),mean(pca_spikes_all2(FP_long_index,:)),'.-')
hold on
plot3(t_pre:binWidth:t_post-1,mean(pca_spikes_all(FP_short_index,:)),mean(pca_spikes_all2(FP_short_index,:)),'.-')

figure;
plot3(mean(pca_spikes_all(FP_long_index,:)),mean(pca_spikes_all2(FP_long_index,:)),mean(pca_spikes_all3(FP_long_index,:)),'.-')
hold on
plot3(mean(pca_spikes_all(FP_short_index,:)),mean(pca_spikes_all2(FP_short_index,:)),mean(pca_spikes_all3(FP_short_index,:)),'.-')

% %%
% t_pre = -5;
% t_post = 5;
% % cross correlation
% x = zeros(size(spikes,1),size(spikes,1),t_post-t_pre+1);
% for k = 1:size(spikes,1)
%     for j = k:size(spikes,1)
%         for i = t_pre:t_post
%             l1 = max(1,-i+1);
%             r1 = min(size(spikes_binned,2),size(spikes_binned,2)-i);
%             l2 = max(1,i+1);
%             r2 = min(size(spikes_binned,2),size(spikes_binned,2)+i);
% 
%             x(k,j,i-t_pre+1) = spikes_binned(k,l1:r1)*spikes_binned(j,l2:r2)';
%             x(j,k,i-t_pre+1) = x(k,j,i-t_pre+1);
%         end
%     end
%     disp(k)
% end
% %%
% [max_corr1,ind_corr1] = max(x,[],3);
% ind_corr1 = ind_corr1 + t_pre - 1;
% 
% [max_corr2,ind_corr2] = max(-x,[],3);
% ind_corr2 = ind_corr2 + t_pre - 1;
% 
% ind_true = zeros(size(x,1));
% corr_true = zeros(size(x,1));
% max_corr = zeros(size(x,1));
% for k = 1:size(x,1)
%     for j = 1:size(x,1)
%         if abs(ind_corr1(k,j))<abs(ind_corr2(k,j))
% %         if max_corr1(k,j) > max_corr2(k,j)
%             ind_true(k,j) = ind_corr1(k,j);
%             corr_true(k,j) = 1;
%             max_corr(k,j) = max_corr1(k,j);
%         else
%             ind_true(k,j) = ind_corr2(k,j);
%             corr_true(k,j) = -1;
%             max_corr(k,j) = max_corr2(k,j);
%         end
%     end
% end
% 
% figure;
% imagesc(max_corr);
% sum_corr = sum(corr_true,1);
% [~,ind_sort] = sort(sum_corr);
% disp(ind_sort)
% corr2 = zeros(size(x,1));
% for k = 1:size(x,1)
%     for j = 1:size(x,1)
%         corr2(k,j) = corr_true(ind_sort(k),ind_sort(j));
%         corr2(j,k) = corr2(k,j);
%     end
% end
% figure;
% imagesc(corr2)

        








