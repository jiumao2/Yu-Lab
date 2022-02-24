data_path = {...
    'c:/Users/jiumao/Desktop/Russo20210910'...
    'c:/Users/jiumao/Desktop/Russo20210820'...
    'c:/Users/jiumao/Desktop/data'...
    'c:/Users/jiumao/Desktop/Eli20210923'...
    };

t_pre = -2000;
t_post = 10000;
data_all_long = [];
data_all_short = [];
SpikeNotes_all = [];
for k = 1:length(data_path)
    pca_neuron_trial(data_path{k},t_pre,t_post);
    close all;
    load([data_path{k},'/average_spikes.mat'])
    data_all_long = [data_all_long,average_spikes_long];
    data_all_short = [data_all_short,average_spikes_short];
    SpikeNotes_all = [SpikeNotes_all;SpikeNotes];
end

t_len = t_post-t_pre+1;

data_all = [data_all_long;data_all_short];
SpikeNotes_all(:,5) = (1:size(SpikeNotes_all,1))';

[coeff, score, ~, ~, explained] = pca(data_all);

figure;
bar(explained)
title('explained')

FP_long_index = 1:t_len;
FP_short_index = t_len+1:2*t_len;
%%
figure;
for k = 1:4
    subplot(2,2,k)
    plot(t_pre:t_post,score(FP_long_index,k),'b-','lineWidth',3)
    hold on
    plot(t_pre:t_post,score(FP_short_index,k),'r-','lineWidth',3)
    legend('FP=1500ms','FP=750ms')
    hold on
    xline(0,'k--','HandleVisibility','off')
    xline(1500,'b--','HandleVisibility','off')
    xline(750,'r--','HandleVisibility','off')
    xlabel('time (ms)')
    ylabel(['PC',num2str(k)])
end

%%
% figure;
% plot3(t_pre:t_post,score(1:t_len,1),score(1:t_len,2),'b.-')
% hold on
% plot3(0,score(1-t_pre,1),score(1-t_pre,2),'bx','MarkerSize',10)
% plot3(1500,score(1501-t_pre,1),score(1501-t_pre,2),'bx','MarkerSize',10)
% 
% plot3(t_pre:t_post,score(t_len+1:end,1),score(t_len+1:end,2),'r.-')
% plot3(0,score(t_len+1-t_pre,1),score(t_len+1-t_pre,2),'rx','MarkerSize',10)
% plot3(750,score(t_len+751-t_pre,1),score(t_len+751-t_pre,2),'rx','MarkerSize',10)
% xlabel('time (ms)')
% ylabel('PC1')
% zlabel('PC2')

f = figure;
interval = 80;
axes1 = axes('Parent',f);
hold(axes1,'on');
plot3(score(1:t_len,1),score(1:t_len,2),score(1:t_len,3),'b-','lineWidth',1)
plot3(score(1:interval:t_len,1),score(1:interval:t_len,2),score(1:interval:t_len,3),'b.','MarkerSize',8)
hold on
plot3(score(1-t_pre,1),score(1-t_pre,2),score(1-t_pre,3),'bo','MarkerSize',10)
plot3(score(1501-t_pre,1),score(1501-t_pre,2),score(1501-t_pre,3),'bo','MarkerSize',10)
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')

plot3(score(t_len+1:end,1),score(t_len+1:end,2),score(t_len+1:end,3),'r-','lineWidth',1)
plot3(score(t_len+1:interval:end,1),score(t_len+1:interval:end,2),score(t_len+1:interval:end,3),'r.','MarkerSize',8)

plot3(score(t_len+1-t_pre,1),score(t_len+1-t_pre,2),score(t_len+1-t_pre,3),'ro','MarkerSize',10)
plot3(score(t_len+751-t_pre,1),score(t_len+751-t_pre,2),score(t_len+751-t_pre,3),'ro','MarkerSize',10)

% view(axes1,[3.70000027033802 -16.0447472526573]);
hold(axes1,'off');

%%
figure;
for k = 1:4
    subplot(4,1,k)
    histogram(coeff(:,k))
end

[a,ind_sort] = sort(coeff(:,1),'descend');