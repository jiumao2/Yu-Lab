%% Plot all trajectories
% load RTarrayAll.mat
bodypart = 'right_ear';
ind_bodypart = find(strcmp(r.VideoInfos(1).Tracking.BodyParts1, bodypart));

% bg = ReadJpegSEQ2('20210908-16-45-35.000.seq',1);
bg = imread('bg.png');
h1 = figure;
ax1 = axes(h1);
imshow(bg);
hold on

p_threshold = 0.95;

h2 = figure;
ax2 = axes(h2);
imshow(bg);
hold on

idx_frame_pre = 1:abs(r.VideoInfos(1).t_pre/10);
idx_frame_post = abs(r.VideoInfos(1).t_pre/10)+1:r.VideoInfos(1).total_frames;

ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
%     imshow(bg);
    hold on;
%     plot(r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_left_ear},r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_left_ear},'.-')
    idx_good = find(r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold);
    idx_pre = intersect(idx_good,idx_frame_pre);
    idx_post = intersect(idx_good,idx_frame_post);
%     colors = varycolor(length(idx_good));
%     for j = 1:length(idx_good)
%         plot(r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_right_ear}(idx_good(j)),r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_right_ear}(idx_good(j)),'.','Color',colors(j,:))
%     end

    plot(ax1,r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_pre),r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_pre),'.-')
    plot(ax2,r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_post),r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_post),'.-')
%     plot(r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_head},r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_head},'.-y')

end    

set(h1,'Renderer','opengl')
set(h2,'Renderer','opengl')
%% Do classification
% Make contraints in traj before press and traj after press respectively
colors = colororder;
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
        
        axes(ax1);
        [x,y] = ginput(2);
        plot(x,y,'-','LineWidth',5,'Color',colors(count_traj,:))
        
        trajectory{count_traj} = {{[x(1),y(1)],[x(2),y(2)]}};
        
        axes(ax2);
        [x,y] = ginput(2);
        plot(x,y,'-','LineWidth',5,'Color',colors(count_traj,:))
        trajectory{count_traj}{end+1} = {[x(1),y(1)],[x(2),y(2)]};
        break
        
%         if count_constraints == 1
%             trajectory{count_traj} = {{[x(1),y(1)],[x(2),y(2)]}};
%         else
%             trajectory{count_traj}{end+1} = {[x(1),y(1)],[x(2),y(2)]};
%         end
%         is_adding_constrait = input('Type 1 to add new constraints. Type 0 to exit.\n');
%         if ~is_adding_constrait
%             break
%         end
    end
end
%% Use above constraints to classify the trajectories
colors = colororder;
colors(length(trajectory)+1,:) = [0.5,0.5,0.5];
figure;
imshow(bg);
hold on

cat = [];
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    hold on;
    
    idx_good = r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold;
    this_x = r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_bodypart};
    this_y = r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_bodypart};
    this_p = r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_bodypart};
    
    flag = true;
    for i = 1:length(trajectory)
        idx_pass = [];
        for j = 1:r.VideoInfos(1).total_frames-1
            for ii = 1:length(trajectory{i})
                if sum(idx_pass == ii)>0
                    continue;
                end
                if (ii==1 && j>=idx_frame_pre(end)) || (ii==2 && j<=idx_frame_pre(end))
                    continue;
                end
                
                P1 = trajectory{i}{ii}{1};
                P2 = trajectory{i}{ii}{2};
                Q1 = [this_x(j),this_y(j)];
                count = 1;
                while j+count < r.VideoInfos(1).total_frames && this_p(j+count)<p_threshold
                    count = count + 1;
                end                
                Q2 = [this_x(j+count),this_y(j+count)];
                
                if this_p(j)<p_threshold || this_p(j+1)<p_threshold
                    break;
                end
                if ~isIntersect(P1,P2,Q1,Q2)
                    continue;
                else
                    idx_pass = [idx_pass,ii];
                    if length(idx_pass) == length(trajectory{i})
                        cat = [cat,i];
                        flag = false;
                        break;
                    end
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
    plot(this_x(idx_good),this_y(idx_good),'.-','Color',colors(cat(end),:));
%     drawnow;

end    
saveas(gcf,'Fig/Traj_classification.png');
%% save to R
for k = 1:length(ind_correct)
    r.VideoInfos(ind_correct(k)).Trajectory = cat(k);
end

save RTarrayAll.mat r
for k = 1:num_traj+1
    drawTraj(r,k);
end
%% Make Figures
for num_unit = 1:length(r.Units.SpikeTimes)
PlotComparingTrajPSTH(r,num_unit,'event','Press');
end

% %% PCA -- two groups
% index_su = find(r.Units.SpikeNotes(:,3)==1);
% len_spike = length(r.VideoInfos(1).t_pre:r.VideoInfos(1).t_post);
% spikes_all = {};
% for k = 1:length(trajectory)+1
%     index_cat = ind_correct(cat==k);
%     spike_this = zeros(length(index_su),length(index_cat)*len_spike);
%     for j = 1:length(index_cat)
%         for i = 1:length(index_su)
%             bin_spike = zeros(1,len_spike);
%             bin_spike(ceil(r.VideoInfos(index_cat(j)).Units.SpikeTimes(index_su(i)).timings-r.VideoInfos(index_cat(j)).Time-r.VideoInfos(index_cat(j)).t_pre))=1;
%             bin_spike = smoothdata(bin_spike,'gaussian',50);
%             spike_this(i,len_spike*(j-1)+1:len_spike*j) = bin_spike;
%         end
%     end
%     spikes_all{k} = spike_this;
% end
% % zscore
% % temp = [];
% % for k = 1:length(spikes_all)
% %     temp = [temp,spikes_all{k}];
% % end
% % temp_mean = mean(temp,2);
% % temp_std = std(temp,0,2);
% % temp = (temp-temp_mean)./temp_std;
% % 
% % p=1;
% % for k = 1:length(spikes_all)
% %     spikes_all_zscore{k} = temp(:,p:p+size(spikes_all{k},2)-1);
% %     p = p+size(spikes_all{k},2);
% % end
% 
% for k = 1:length(spikes_all)
%     temp_mean = mean(spikes_all{k},2);
%     temp_std = std(spikes_all{k},0,2);
%     spikes_all_zscore{k} = (spikes_all{k}-temp_mean)./temp_std;  
% end
% 
% % pca
% figure;
% for k = 1:length(trajectory)
%     [coeff, score, ~, ~, explained] = pca(spikes_all_zscore{k}');
%     for j = 1:4
%         subplot(5,1,j)
%         hold on
%         plot(coeff(:,j))
%     end
%     subplot(5,1,5);hold on;
%     plot(explained)
% end
% 
% %
% [coeff1, score1, ~, ~, explained1] = pca(spikes_all_zscore{1}');
% [coeff2, score2, ~, ~, explained2] = pca(spikes_all_zscore{2}');
% 
% disp(corr(coeff1(:,1),coeff2(:,1)));
% disp(corr(coeff1(:,2),coeff2(:,2)));
% 
% figure;
% subplot(1,2,1)
% bar(explained1)
% subplot(1,2,2)
% bar(explained2)
% 
% % score1 = smoothdata(score1,'gaussian',200);
% % score2 = smoothdata(score2,'gaussian',200);
% 
% score_trial1_pc1 = reshape(score1(:,1),len_spike,[])';
% score_trial2_pc1 = reshape(score2(:,1),len_spike,[])';
% 
% score_trial1_pc2 = reshape(score1(:,2),len_spike,[])';
% score_trial2_pc2 = reshape(score2(:,2),len_spike,[])';
% 
% score_trial1_pc3 = reshape(score1(:,3),len_spike,[])';
% score_trial2_pc3 = reshape(score2(:,3),len_spike,[])';
% 
% FP_correct = [r.VideoInfos(ind_correct).Foreperiod];
% index_long_correct = FP_correct == 1500;
% index_short_correct = FP_correct == 750;
% 
% t_plot = r.VideoInfos(1).t_pre:r.VideoInfos(1).t_post;
% 
% [~,ind_temp1]=ismember(find(cat==1 & index_long_correct),find(cat==1));
% [~,ind_temp2]=ismember(find(cat==2 & index_long_correct),find(cat==2));
% traj1_pc1_mean = mean(score_trial1_pc1(ind_temp1,:));
% traj1_pc2_mean = mean(score_trial1_pc2(ind_temp1,:));
% traj1_pc3_mean = mean(score_trial1_pc3(ind_temp1,:));
% traj2_pc1_mean = mean(score_trial2_pc1(ind_temp2,:));
% traj2_pc2_mean = mean(score_trial2_pc2(ind_temp2,:));
% traj2_pc3_mean = mean(score_trial2_pc3(ind_temp2,:));
% 
% figure;
% subplot(3,2,1)
% plot(t_plot,traj1_pc1_mean);
% hold on
% plot(t_plot,traj2_pc1_mean);
% subplot(3,2,3)
% plot(t_plot,traj1_pc2_mean);
% hold on
% plot(t_plot,traj2_pc2_mean);
% subplot(3,2,5)
% plot(t_plot,traj1_pc3_mean);
% hold on
% plot(t_plot,traj2_pc3_mean);
% 
% [~,ind_temp1]=ismember(find(cat==1 & index_short_correct),find(cat==1));
% [~,ind_temp2]=ismember(find(cat==2 & index_short_correct),find(cat==2));
% traj1_pc1_mean = mean(score_trial1_pc1(ind_temp1,:));
% traj1_pc2_mean = mean(score_trial1_pc2(ind_temp1,:));
% traj1_pc3_mean = mean(score_trial1_pc3(ind_temp1,:));
% traj2_pc1_mean = mean(score_trial2_pc1(ind_temp2,:));
% traj2_pc2_mean = mean(score_trial2_pc2(ind_temp2,:));
% traj2_pc3_mean = mean(score_trial2_pc3(ind_temp2,:));
% 
% % figure;
% subplot(3,2,2)
% plot(t_plot,traj1_pc1_mean);
% hold on
% plot(t_plot,traj2_pc1_mean);
% subplot(3,2,4)
% plot(t_plot,traj1_pc2_mean);
% hold on
% plot(t_plot,traj2_pc2_mean);
% subplot(3,2,6)
% plot(t_plot,traj1_pc3_mean);
% hold on
% plot(t_plot,traj2_pc3_mean);
% %
% downsample_rate = 100;
% figure;
% set(gcf,'Renderer','opengl')
% plot3(traj1_pc1_mean(1:downsample_rate:end),traj1_pc2_mean(1:downsample_rate:end),traj1_pc3_mean(1:downsample_rate:end))
% hold on
% plot3(traj2_pc1_mean(1:downsample_rate:end),traj2_pc2_mean(1:downsample_rate:end),traj2_pc3_mean(1:downsample_rate:end))
% %
% % c = spcrv([traj1_pc1_mean;traj1_pc2_mean;traj1_pc3_mean],4);
% % figure;
% % plot3(c(1,:),c(2,:),c(3,:))
% 
% % Dimension
% cov1 = cov(spikes_all_zscore{1}');
% cov2 = cov(spikes_all_zscore{2}');
% [V1,D1] = eig(cov1);
% [V2,D2] = eig(cov2);
% d1=diag(D1)./sum(diag(D1));
% d2=diag(D2)./sum(diag(D2));
% dim1 = 1./sum(d1.^2)
% dim2 = 1./sum(d2.^2)
% figure;
% subplot(1,2,1)
% imagesc(cov1);
% h1=colorbar();
% subplot(1,2,2)
% imagesc(cov2);
% h2=colorbar();
% l1 = get(h1,'Limits');
% l2 = get(h2,'Limits');
% l_new = [min(l1(1),l2(1)),max(l1(2),l2(2))];
% set(h1,'Limits',l_new);
% set(h2,'Limits',l_new);