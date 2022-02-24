%% get t_press_sort & t_press_sort_all
clear;
data_path = 'C:/Users/jiumao/Desktop/Eli20210921';
set(groot,'defaultfigurerenderer','opengl')
if ~exist('r','var')
    load([data_path, '/RTarrayAll.mat'])
end
%%
t_pre = r.VideoInfos(1).t_pre;
t_post = r.VideoInfos(1).t_post;

t_len = t_post - t_pre + 1;

correct_index = find(strcmp({r.VideoInfos.Performance},'Correct'));
t_press_sort_all = round([r.VideoInfos.Time]);
t_press_sort_all = t_press_sort_all(correct_index);

%% compute firing rate of each unit
spike_times = cell(length(r.Units.SpikeTimes),1);

max_spike_time = 0;
for k = 1:length(spike_times)
    spike_times{k} = r.Units.SpikeTimes(k).timings;
    if r.Units.SpikeTimes(k).timings(end)>max_spike_time
        max_spike_time = r.Units.SpikeTimes(k).timings(end);
    end
end

unit_of_interest = 1:length(r.Units.SpikeTimes);

% binned
spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

% gaussian kernel
spikes = smoothdata(spikes','gaussian',500)';

spikes_trial_flattened = zeros(length(unit_of_interest),t_len*length(t_press_sort_all));

for k = 1:length(t_press_sort_all)
    spikes_trial_flattened(:,t_len*(k-1)+1:t_len*k) = spikes(:,t_press_sort_all(k)+t_pre:t_press_sort_all(k)+t_post);
end

mean_neurons = mean(spikes_trial_flattened,2);
std_neurons = std(spikes_trial_flattened,0,2);
spikes_trial_flattened = zscore(spikes_trial_flattened,0,2);
[coeff, score, latent, tsquared, explained] = pca(spikes_trial_flattened');

figure;
bar(explained)
title('explained')

score_trial = reshape(score,t_len,length(t_press_sort_all),length(unit_of_interest));

FP_all = [r.VideoInfos.Foreperiod];
FP_all = FP_all(correct_index);

FP_long_index = find(FP_all==1500);
FP_short_index = find(FP_all==750);

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
xlabel('time (ms)')
ylabel('PC1')
zlabel('PC2')

figure;
plot3(mean(score_trial(:,FP_long_index,1),2),mean(score_trial(:,FP_long_index,2),2),mean(score_trial(:,FP_long_index,3),2),'.-')
hold on
plot3(mean(score_trial(:,FP_short_index,1),2),mean(score_trial(:,FP_short_index,2),2),mean(score_trial(:,FP_short_index,3),2),'.-')
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')

%% relabel to video
pc_num = 1;

figure;
bar(coeff(:,pc_num))
xlabel('Units')
ylabel('Loadings')
title(['Loadings on PC',num2str(pc_num)])

%% cross correlation

p_threshold = 0.99;
index_nose = find(contains(r.VideoInfos(1).Tracking.BodyParts,'left_nose'));
x_nose_all = zeros(length(correct_index),length(r.VideoInfos(1).VideoFrameTime));
y_nose_all = zeros(length(correct_index),length(r.VideoInfos(1).VideoFrameTime));
p_nose_all = zeros(length(correct_index),length(r.VideoInfos(1).VideoFrameTime));
for k = correct_index
    x_nose_all(k,:) = r.VideoInfos(k).Tracking.Coordinates_x{index_nose};
    y_nose_all(k,:) = r.VideoInfos(k).Tracking.Coordinates_y{index_nose};
    p_nose_all(k,:) = r.VideoInfos(k).Tracking.Coordinates_p{index_nose};
    x_nose_all(k,p_nose_all(k,:)<p_threshold) = NaN;
    y_nose_all(k,p_nose_all(k,:)<p_threshold) = NaN;
end

x_nose_all = x_nose_all(correct_index,:);
y_nose_all = y_nose_all(correct_index,:);

t_pre_cor = -200;
t_post_cor = 200;
t_range_cor = t_pre_cor:t_post_cor;

ind = linspace(1,3901,391);
score_trial = score_trial(ind,:,:);
y_nose_all = -(y_nose_all - mean(y_nose_all(:),'omitnan'))./std(y_nose_all(:),'omitnan');

temp = score_trial(:,:,pc_num);
score_trial_pcnum = (temp - mean(temp(:),'omitnan'))./std(temp(:),'omitnan');
cor = zeros(length(t_range_cor),1);
for k = 1:length(t_range_cor)
    for j = 1:size(score_trial,2)
        cor(k) = cor(k) + sum(...
            score_trial_pcnum(max(1,1+t_range_cor(k)):min(size(score_trial,1),size(score_trial,1)+t_range_cor(k)),j) .* y_nose_all(j,max(1,-t_range_cor(k)+1):min(size(score_trial,1),size(score_trial,1)-t_range_cor(k)))'...
            ,'omitnan')./sum(isnan(y_nose_all(j,max(1,-t_range_cor(k)+1):min(size(score_trial,1),size(score_trial,1)-t_range_cor(k)))));
    end
end

figure;
plot(t_range_cor,cor)
%% Use pca output to get scores of all trials
t_press_sort_all = round([r.VideoInfos.Time]);
FP_all = [r.VideoInfos.Foreperiod];
FP_long_index = find(FP_all==1500);
FP_short_index = find(FP_all==750);

spikes_trial_flattened = zeros(length(unit_of_interest),t_len*length(t_press_sort_all));

for k = 1:length(t_press_sort_all)
    spikes_trial_flattened(:,t_len*(k-1)+1:t_len*k) = spikes(:,t_press_sort_all(k)+t_pre:t_press_sort_all(k)+t_post);
end

spikes_trial_flattened = (spikes_trial_flattened-mean_neurons)./std_neurons;

score = spikes_trial_flattened'*inv(coeff');
score_trial = reshape(score,t_len,length(t_press_sort_all),length(unit_of_interest));


%% relabelling
dir_name = [data_path,'/VideoFrames/RelabelledPC',num2str(pc_num),'Video_zscore'];
if ~exist(dir_name,'dir')
    mkdir(dir_name);
end
for k = 1:length(r.VideoInfos)
    raw_video_filename = [r.VideoInfos(k).Event,num2str(r.VideoInfos(k).Index,'%03d'),'.avi'];
    output_filename = [dir_name,'/',raw_video_filename(1:end-4),'_PC',num2str(pc_num),'.avi'];
    vidObj_in = VideoReader([data_path,'/VideoFrames/RawVideo/',raw_video_filename]);
    vidObj_out = VideoWriter(output_filename);
    vidObj_out.FrameRate=20;
    open(vidObj_out);
    for i_frame = 1:vidObj_in.NumFrames
        temp_frame = vidObj_in.read(i_frame);
        
        height_video = vidObj_in.Height;
        width_video = vidObj_in.Width;
        % add pc
        plot_height = 200;
        
        scale = (plot_height/2)/max(max(abs(score_trial(:,:,pc_num))));
        score_trial_plot = score_trial*scale;
        plot_x = round(linspace(1,t_len,width_video));
        plot_y = round(score_trial_plot(plot_x,k,pc_num)+height_video+plot_height/2);
        
        temp_frame(height_video+1:height_video+plot_height,:,:) = uint8(zeros(plot_height,width_video,3));
        temp_frame(height_video+plot_height/2,:,:) = uint8(100);
        
        for j = 1:width_video
            temp_frame(plot_y(j),j,:) = uint8(255);
        end
        
        temp_frame(height_video+1:height_video+plot_height,round(width_video*i_frame/vidObj_in.NumFrames),:) = uint8(128);
        temp_frame(height_video+1:height_video+plot_height,...
            round(width_video*(-t_pre/10)/vidObj_in.NumFrames),:) = reshape(repmat(uint8([255,0,0]),plot_height,1),plot_height,1,3);
        temp_frame(height_video+1:height_video+plot_height,...
            round(width_video*((FP_all(k)-t_pre)/10)/vidObj_in.NumFrames),:) = reshape(repmat(uint8([0,255,0]),plot_height,1),plot_height,1,3);
        text_title = [num2str(i_frame*10+t_pre),'ms   Performance: ',r.VideoInfos(k).Performance,...
            '   RT:',num2str(r.VideoInfos(k).ReactTime),'ms'];
        temp_frame = insertText(temp_frame,[10,10],text_title,'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        temp_frame = insertText(temp_frame,[10,height_video+10],['PC',num2str(pc_num)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        
        writeVideo(vidObj_out,temp_frame);
    end
    close(vidObj_out);
end

