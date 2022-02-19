load RTarrayAll.mat
ind_left_ear = find(strcmp(r.VideoInfos(1).Tracking.BodyParts,'left_ear'));
ind_right_ear = find(strcmp(r.VideoInfos(1).Tracking.BodyParts,'right_ear'));
ind_head = find(strcmp(r.VideoInfos(1).Tracking.BodyParts,'head_center'));
bg = ReadJpegSEQ2('20211124-17-37-43.000.seq',1);
figure;
imshow(bg);
hold on

ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
%     imshow(bg);
    hold on;
%     plot(r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_left_ear},r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_left_ear},'.-')
    plot(r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_right_ear},r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_right_ear},'.-')
%     plot(r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_head},r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_head},'.-y')

end    

set(gcf,'Renderer','opengl')
%%
trajectory = {};
count_traj = 0;
while true
    count_traj = count_traj+1;
    is_adding = input('Type 1 to add new trajectory. Type 0 to exit.\n');
    if ~is_adding
        break
    end
    
    count_constraints = 0;
    while true
        count_constraints = count_constraints+1;
        [x,y] = ginput(2);
        if count_constraints == 1
            trajectory{count_traj} = {{[x(1),y(1)],[x(2),y(2)]}};
        else
            trajectory{count_traj}{end+1} = {[x(1),y(1)],[x(2),y(2)]};
        end
        is_adding_constrait = input('Type 1 to add new constraints. Type 0 to exit.\n');
        if ~is_adding_constrait
            break
        end
    end
end
%%
colors = varycolor(length(trajectory));
colors(end+1,:) = [0.5,0.5,0.5];
figure;
imshow(bg);
hold on

cat = [];
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    hold on;

    this_x = r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_right_ear};
    this_y = r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_right_ear};
    this_p = r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_right_ear};
    for j = 1:r.VideoInfos(1).total_frames-1
        flag = true;
        for i = 1:length(trajectory)
            for ii = 1:length(trajectory{i})
                P1 = trajectory{i}{ii}{1};
                P2 = trajectory{i}{ii}{2};
                Q1 = [this_x(j),this_y(j)];
                Q2 = [this_x(j+1),this_y(j+1)];
                if this_p(j)<0.9 || this_p(j)<0.9
                    continue;
                end
                if isIntersect(P1,P2,Q1,Q2)
                    cat = [cat,i];
                    flag = false;
                    break;
                end
            end
            if ~flag
                break
            end
        end
        if ~flag
            break
        end
    end
    if flag
        cat = [cat,length(trajectory)+1];
    end
    hold on
    plot(this_x,this_y,'.-','Color',colors(cat(end),:));
%     drawnow;

end    

%%
for num_unit = 1:length(r.Units.SpikeTimes)
h = figure;
FP_correct = [r.VideoInfos(ind_correct).Foreperiod];
index_long_correct = FP_correct == 1500;
index_short_correct = FP_correct == 750;

ylim_max = 0;
for k = 1:length(trajectory)+1
    ind_traj_long = ind_correct(cat==k & index_long_correct);
    ind_traj_short = ind_correct(cat==k & index_short_correct);
    
    params_long.pre = -r.VideoInfos(k).t_pre;
    params_long.post = r.VideoInfos(k).t_post;
    params_long.binwidth = 20;
    params_short.pre = -r.VideoInfos(k).t_pre;
    params_short.post = r.VideoInfos(k).t_post;
    params_short.binwidth = 20;
    
    subplot(3,length(trajectory)+1,k);
    hold on
    spxtimes_long = [];
    trigtimes_long = [];
    
    for j = 1:length(ind_traj_long)
        spxtimes_long = [spxtimes_long,r.VideoInfos(ind_traj_long(j)).Units.SpikeTimes(num_unit).timings];
        trigtimes_long = [trigtimes_long,r.VideoInfos(ind_traj_long(j)).Time];
        for i = 1:length(r.VideoInfos(ind_traj_long(j)).Units.SpikeTimes(num_unit).timings)
            plot([1,1]*r.VideoInfos(ind_traj_long(j)).Units.SpikeTimes(num_unit).timings(i)-r.VideoInfos(ind_traj_long(j)).Time,[j-0.5,j+0.5],'r-')
        end
    end
    xlim([r.VideoInfos(k).t_pre,r.VideoInfos(k).t_post])
    ylim([0.5,length(ind_traj_long)+0.5])
    xlabel('Time relative to Press (ms)')
    ylabel('Trial')
    title('FP = 1500 ms')
    
    subplot(3,length(trajectory)+1,length(trajectory)+1+k);
    hold on
    spxtimes_short = [];
    trigtimes_short = [];
    
    for j = 1:length(ind_traj_short)
        spxtimes_short = [spxtimes_short,r.VideoInfos(ind_traj_short(j)).Units.SpikeTimes(num_unit).timings];
        trigtimes_short = [trigtimes_short,r.VideoInfos(ind_traj_short(j)).Time];
        for i = 1:length(r.VideoInfos(ind_traj_short(j)).Units.SpikeTimes(num_unit).timings)
            plot([1,1]*r.VideoInfos(ind_traj_short(j)).Units.SpikeTimes(num_unit).timings(i)-r.VideoInfos(ind_traj_short(j)).Time,[j-0.5,j+0.5],'b-')
        end
    end
    xlim([r.VideoInfos(k).t_pre,r.VideoInfos(k).t_post])
    ylim([0.5,length(ind_traj_short)+0.5])
    xlabel('Time relative to Press (ms)')
    ylabel('Trial')
    title('FP = 750 ms')

    subplot(3,length(trajectory)+1,2*(length(trajectory)+1)+k);
    hold on
    [psth_long, tpsth_long] = jpsth(spxtimes_long, trigtimes_long', params_long);
    [psth_short, tpsth_short] = jpsth(spxtimes_short, trigtimes_short', params_short);
    plot(tpsth_long,psth_long,'r-')
    plot(tpsth_short,psth_short,'b-')
    xlabel('Time relative to Press (ms)')
    ylabel('Firing Rate (Hz)')
    title('PSTH')
    temp = get(gca,'YLim');
    if ylim_max < temp(2)
        ylim_max = temp(2);
    end
    
end
for k = 1:length(trajectory)+1
    subplot(3,length(trajectory)+1,2*(length(trajectory)+1)+k);
    ylim([0,ylim_max]);
end
saveas(gcf,['Fig/TrajComparing_Unit ',num2str(num_unit),'.png']);

end

%% save to R
for k = 1:length(ind_correct)
    r.VideoInfos(ind_correct(k)).Trajectory = cat(k);
end

save RTarrayAll.mat r

%% PCA -- two groups
index_su = find(r.Units.SpikeNotes(:,3)==1);
len_spike = length(r.VideoInfos(1).t_pre:r.VideoInfos(1).t_post);
spikes_all = {};
for k = 1:length(trajectory)+1
    index_cat = ind_correct(cat==k);
    spike_this = zeros(length(index_su),length(index_cat)*len_spike);
    for j = 1:length(index_cat)
        for i = 1:length(index_su)
            bin_spike = zeros(1,len_spike);
            bin_spike(ceil(r.VideoInfos(index_cat(j)).Units.SpikeTimes(index_su(i)).timings-r.VideoInfos(index_cat(j)).Time-r.VideoInfos(index_cat(j)).t_pre))=1;
            bin_spike = smoothdata(bin_spike,'gaussian',50);
            spike_this(i,len_spike*(j-1)+1:len_spike*j) = bin_spike;
        end
    end
    spikes_all{k} = spike_this;
end
% zscore
% temp = [];
% for k = 1:length(spikes_all)
%     temp = [temp,spikes_all{k}];
% end
% temp_mean = mean(temp,2);
% temp_std = std(temp,0,2);
% temp = (temp-temp_mean)./temp_std;
% 
% p=1;
% for k = 1:length(spikes_all)
%     spikes_all_zscore{k} = temp(:,p:p+size(spikes_all{k},2)-1);
%     p = p+size(spikes_all{k},2);
% end

for k = 1:length(spikes_all)
    temp_mean = mean(spikes_all{k},2);
    temp_std = std(spikes_all{k},0,2);
    spikes_all_zscore{k} = (spikes_all{k}-temp_mean)./temp_std;  
end

% pca
figure;
for k = 1:length(trajectory)
    [coeff, score, ~, ~, explained] = pca(spikes_all_zscore{k}');
    for j = 1:4
        subplot(5,1,j)
        hold on
        plot(coeff(:,j))
    end
    subplot(5,1,5);hold on;
    plot(explained)
end

%
[coeff1, score1, ~, ~, explained1] = pca(spikes_all_zscore{1}');
[coeff2, score2, ~, ~, explained2] = pca(spikes_all_zscore{2}');

disp(corr(coeff1(:,1),coeff2(:,1)));
disp(corr(coeff1(:,2),coeff2(:,2)));

figure;
subplot(1,2,1)
bar(explained1)
subplot(1,2,2)
bar(explained2)

% score1 = smoothdata(score1,'gaussian',200);
% score2 = smoothdata(score2,'gaussian',200);

score_trial1_pc1 = reshape(score1(:,1),len_spike,[])';
score_trial2_pc1 = reshape(score2(:,1),len_spike,[])';

score_trial1_pc2 = reshape(score1(:,2),len_spike,[])';
score_trial2_pc2 = reshape(score2(:,2),len_spike,[])';

score_trial1_pc3 = reshape(score1(:,3),len_spike,[])';
score_trial2_pc3 = reshape(score2(:,3),len_spike,[])';

FP_correct = [r.VideoInfos(ind_correct).Foreperiod];
index_long_correct = FP_correct == 1500;
index_short_correct = FP_correct == 750;

t_plot = r.VideoInfos(1).t_pre:r.VideoInfos(1).t_post;

[~,ind_temp1]=ismember(find(cat==1 & index_long_correct),find(cat==1));
[~,ind_temp2]=ismember(find(cat==2 & index_long_correct),find(cat==2));
traj1_pc1_mean = mean(score_trial1_pc1(ind_temp1,:));
traj1_pc2_mean = mean(score_trial1_pc2(ind_temp1,:));
traj1_pc3_mean = mean(score_trial1_pc3(ind_temp1,:));
traj2_pc1_mean = mean(score_trial2_pc1(ind_temp2,:));
traj2_pc2_mean = mean(score_trial2_pc2(ind_temp2,:));
traj2_pc3_mean = mean(score_trial2_pc3(ind_temp2,:));

figure;
subplot(3,2,1)
plot(t_plot,traj1_pc1_mean);
hold on
plot(t_plot,traj2_pc1_mean);
subplot(3,2,3)
plot(t_plot,traj1_pc2_mean);
hold on
plot(t_plot,traj2_pc2_mean);
subplot(3,2,5)
plot(t_plot,traj1_pc3_mean);
hold on
plot(t_plot,traj2_pc3_mean);

[~,ind_temp1]=ismember(find(cat==1 & index_short_correct),find(cat==1));
[~,ind_temp2]=ismember(find(cat==2 & index_short_correct),find(cat==2));
traj1_pc1_mean = mean(score_trial1_pc1(ind_temp1,:));
traj1_pc2_mean = mean(score_trial1_pc2(ind_temp1,:));
traj1_pc3_mean = mean(score_trial1_pc3(ind_temp1,:));
traj2_pc1_mean = mean(score_trial2_pc1(ind_temp2,:));
traj2_pc2_mean = mean(score_trial2_pc2(ind_temp2,:));
traj2_pc3_mean = mean(score_trial2_pc3(ind_temp2,:));

% figure;
subplot(3,2,2)
plot(t_plot,traj1_pc1_mean);
hold on
plot(t_plot,traj2_pc1_mean);
subplot(3,2,4)
plot(t_plot,traj1_pc2_mean);
hold on
plot(t_plot,traj2_pc2_mean);
subplot(3,2,6)
plot(t_plot,traj1_pc3_mean);
hold on
plot(t_plot,traj2_pc3_mean);
%
downsample_rate = 100;
figure;
set(gcf,'Renderer','opengl')
plot3(traj1_pc1_mean(1:downsample_rate:end),traj1_pc2_mean(1:downsample_rate:end),traj1_pc3_mean(1:downsample_rate:end))
hold on
plot3(traj2_pc1_mean(1:downsample_rate:end),traj2_pc2_mean(1:downsample_rate:end),traj2_pc3_mean(1:downsample_rate:end))
%
% c = spcrv([traj1_pc1_mean;traj1_pc2_mean;traj1_pc3_mean],4);
% figure;
% plot3(c(1,:),c(2,:),c(3,:))

% Dimension
cov1 = cov(spikes_all_zscore{1}');
cov2 = cov(spikes_all_zscore{2}');
[V1,D1] = eig(cov1);
[V2,D2] = eig(cov2);
d1=diag(D1)./sum(diag(D1));
d2=diag(D2)./sum(diag(D2));
dim1 = 1./sum(d1.^2)
dim2 = 1./sum(d2.^2)
figure;
subplot(1,2,1)
imagesc(cov1);
h1=colorbar();
subplot(1,2,2)
imagesc(cov2);
h2=colorbar();
l1 = get(h1,'Limits');
l2 = get(h2,'Limits');
l_new = [min(l1(1),l2(1)),max(l1(2),l2(2))];
set(h1,'Limits',l_new);
set(h2,'Limits',l_new);