data_path_unit = {...
    'D:\Ephys\ANMs\Russo\Sessions\20210821\RTarrayAll.mat',     [1,2,3,5,6,7,9,10,11,13,15,17]...
    'D:\Ephys\ANMs\Russo\Sessions\r_all_20210906_20210910.mat', []...
    'D:\Ephys\ANMs\Eli\Sessions\r_all.mat',                     []...
    'D:\Ephys\ANMs\Urey\Sessions\r_all_20211123_20211128.mat',  []...
    };
t_pre = -1500;
t_post = 2400;
t_len = t_post-t_pre+1;
%%
average_spikes_long_all = [];
average_spikes_short_all = [];
for data_idx = 1:2:length(data_path_unit)
temp = load(data_path_unit{data_idx});
unit_of_interest = data_path_unit{data_idx+1};
if isfield(temp,'r')
    [average_spikes_long, average_spikes_short] = get_average_spikes(temp.r, unit_of_interest,t_pre,t_post,'normalized','zscore');
    average_spikes_long_all = [average_spikes_long_all;average_spikes_short];
    average_spikes_short_all = [average_spikes_short_all;average_spikes_short];
elseif isfield(temp,'r_all')
    r_all = temp.r_all;
    trial_num = zeros(length(r_all.r),1);
    unit_of_interest_all = cell(length(r_all.r),1);
    for k = 1:length(r_all.r)
        trial_num(k) = length(r_all.r{k}.Behavior.CorrectIndex);
        unit_of_interest_all{k} = [];
    end
    for k = 1:height(r_all.UnitsCombined)
        temp = r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1};
        [~,r_idx] = max(trial_num(temp(:,1)));
        unit_of_interest_all{temp(r_idx,1)} = [unit_of_interest_all{temp(r_idx,1)}; temp(r_idx,2:3)];
    end
    for k = 1:length(r_all.r)
        [average_spikes_long, average_spikes_short] = get_average_spikes(r_all.r{k}, unit_of_interest_all{k},t_pre,t_post,'normalized','zscore');
        average_spikes_long_all = [average_spikes_long_all,average_spikes_long];
        average_spikes_short_all = [average_spikes_short_all,average_spikes_short];
    end    
else
    error('Wrong r');
end
end
%%
data_all = [average_spikes_long_all;average_spikes_short_all];
[coeff, score, ~, ~, explained] = pca(data_all);

h_explained = figure;
bar(h_explained,explained,'b')
title('explained')
saveas(h_explained,'explained.png')

FP_long_index = 1:t_len;
FP_short_index = t_len+1:2*t_len;
%%
% h_PC = figure;
figure();
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
saveas(gcf,'PC.png');

%%
h = figure;
interval = 80;
axes1 = axes(h);
hold(axes1,'on');
plot3(axes1,score(1:t_len,1),score(1:t_len,2),score(1:t_len,3),'b-','lineWidth',1)
plot3(axes1,score(1:interval:t_len,1),score(1:interval:t_len,2),score(1:interval:t_len,3),'b.','MarkerSize',8)
hold on
plot3(axes1,score(1-t_pre,1),score(1-t_pre,2),score(1-t_pre,3),'bo','MarkerSize',10)
plot3(axes1,score(1501-t_pre,1),score(1501-t_pre,2),score(1501-t_pre,3),'bo','MarkerSize',10)
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')

plot3(axes1,score(t_len+1:end,1),score(t_len+1:end,2),score(t_len+1:end,3),'r-','lineWidth',1)
plot3(axes1,score(t_len+1:interval:end,1),score(t_len+1:interval:end,2),score(t_len+1:interval:end,3),'r.','MarkerSize',8)

plot3(axes1,score(t_len+1-t_pre,1),score(t_len+1-t_pre,2),score(t_len+1-t_pre,3),'ro','MarkerSize',10)
plot3(axes1,score(t_len+751-t_pre,1),score(t_len+751-t_pre,2),score(t_len+751-t_pre,3),'ro','MarkerSize',10)

% view(axes1,[3.70000027033802 -16.0447472526573]);
hold(axes1,'off');
saveas(h,'PC_traj.png')

%%
for k = 1:4
    subplot(4,1,k)
    histogram(coeff(:,k))
end
xlabel('Loadings')
saveas(gcf,'Loadings.png');

% [a,ind_sort] = sort(coeff(:,1),'descend');
