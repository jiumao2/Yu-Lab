function pca_video_with_tracking(varargin)
% current path should be set to folder "ANMyyyyMMDD_video"
data_path = '.';
pc_num = 1;
gausian_filter_width = 500;
camview = 'side';
bodypart = 'None';
make_video = false;
unit_of_interest = [];
only_single_unit = false;

if nargin>1
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'data_path'
                data_path = varargin{i+1};
            case 'camview'
                camview = varargin{i+1};
            case 'pc_num'
                pc_num = varargin{i+1};
            case 'gausian_filter_width'
                gausian_filter_width = varargin{i+1};
            case 'bodypart'
                bodypart = varargin{i+1};
            case 'make_video'
                make_video = varargin{i+1};
            case 'unit_of_interest'
                unit_of_interest = varargin{i+1};
            case 'only_single_unit'
                only_single_unit = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end
set(groot,'defaultfigurerenderer','opengl')
load([data_path, '/RTarrayAll.mat'])
if isempty(unit_of_interest)
    if only_single_unit
        unit_of_interest = find(r.Units.SpikeNotes(:,3)==1);
    else
        unit_of_interest = 1:length(r.Units.SpikeTimes);
    end
end
%%
if strcmp(camview,'side')
    VideoInfos_this = r.VideoInfos_side;
else
    VideoInfos_this = r.VideoInfos_top;
end
t_pre = VideoInfos_this(1).t_pre;
t_post = VideoInfos_this(1).t_post;
t_len = t_post - t_pre + 1;

correct_index = find(strcmp({VideoInfos_this.Performance},'Correct'));
t_press_sort_all = round([VideoInfos_this.Time]);
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

% binned
spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

% gaussian kernel
spikes = smoothdata(spikes','gaussian',gausian_filter_width)';

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
saveas(gcf,[data_path,'/Fig/','explained.png'])

score_trial = reshape(score,t_len,length(t_press_sort_all),length(unit_of_interest));

FP_all = [VideoInfos_this.Foreperiod];
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
saveas(gcf,[data_path,'/Fig/','PC.png'])

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
figure;
bar(coeff(:,pc_num))
xlabel('Units')
ylabel('Loadings')
title(['Loadings on PC',num2str(pc_num)])
saveas(gcf,[data_path,'/Fig/','loadings_of_PC',num2str(pc_num),'.png'])

%% cross correlation
if ~strcmp(bodypart,'None') 

    p_threshold = VideoInfos_this(1).Tracking.p_threshold;
    index_nose = find(contains(VideoInfos_this(1).Tracking.BodyParts,bodypart));
    x_nose_all_raw = zeros(length(VideoInfos_this),length(VideoInfos_this(1).VideoFrameTime));
    y_nose_all_raw = zeros(length(VideoInfos_this),length(VideoInfos_this(1).VideoFrameTime));
    p_nose_all_raw = zeros(length(VideoInfos_this),length(VideoInfos_this(1).VideoFrameTime));
    for k = 1:length(VideoInfos_this)
        x_nose_all_raw(k,:) = VideoInfos_this(k).Tracking.Coordinates_x{index_nose};
        y_nose_all_raw(k,:) = VideoInfos_this(k).Tracking.Coordinates_y{index_nose};
        p_nose_all_raw(k,:) = VideoInfos_this(k).Tracking.Coordinates_p{index_nose};
        x_nose_all_raw(k,p_nose_all_raw(k,:)<p_threshold) = NaN;
        y_nose_all_raw(k,p_nose_all_raw(k,:)<p_threshold) = NaN;
    end

    x_nose_all = x_nose_all_raw(correct_index,:);
    y_nose_all = y_nose_all_raw(correct_index,:);

    t_pre_cor = -200;
    t_post_cor = 200;
    t_range_cor = t_pre_cor:t_post_cor;

    ind = linspace(1,3901,391);
    score_trial = score_trial(ind,:,:);
    y_nose_all_raw_zscore = (y_nose_all_raw - mean(y_nose_all_raw(:),'omitnan'))./std(y_nose_all_raw(:),'omitnan');
    y_nose_all = -(y_nose_all - mean(y_nose_all(:),'omitnan'))./std(y_nose_all(:),'omitnan');

    temp = score_trial(:,:,pc_num);
    score_trial_pcnum = (temp - mean(temp(:),'omitnan'))./std(temp(:),'omitnan');
    cor = zeros(length(t_range_cor),1);
    for k = 1:length(t_range_cor)
        for j = 1:size(score_trial,2)
            cor(k) = cor(k) + sum(...
                score_trial_pcnum(max(1,1+t_range_cor(k)):min(size(score_trial,1),size(score_trial,1)+t_range_cor(k)),j) .* y_nose_all(j,max(1,-t_range_cor(k)+1):min(size(score_trial,1),size(score_trial,1)-t_range_cor(k)))'...
                ,'omitnan');
        end
        cor(k) = cor(k)./sum(isnan(y_nose_all(:,max(1,-t_range_cor(k)+1):min(size(score_trial,1),size(score_trial,1)-t_range_cor(k)))),'all');
    end

    figure;
    plot(t_range_cor,cor)
    xlabel('Lag (ms)')
    ylabel('Correlation')
    title(['Cross Correlation with ',bodypart])
    saveas(gcf,[data_path,'/Fig/','Cross_correlation_with_',bodypart,'.png'])
end
%% Use pca output to get scores of all trials
t_press_sort_all = round([VideoInfos_this.Time]);
FP_all = [VideoInfos_this.Foreperiod];
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
if ~make_video
    return
end

dir_name = [data_path,'/VideoFrames_',camview,'/RelabelledPC',num2str(pc_num),'Video_zscore'];
if ~exist(dir_name,'dir')
    mkdir(dir_name);
end
for k = 1:length(VideoInfos_this)
    raw_video_filename = [VideoInfos_this(k).Event,num2str(VideoInfos_this(k).Index,'%03d'),'.avi'];
    output_filename = [dir_name,'/',raw_video_filename(1:end-4),'_PC',num2str(pc_num),'.avi'];
    vidObj_in = VideoReader([data_path,'/VideoFrames_',camview,'/RawVideo/',raw_video_filename]);
    vidObj_out = VideoWriter(output_filename);
    vidObj_out.FrameRate=20;
    open(vidObj_out);
    for i_frame = 1:vidObj_in.NumFrames
        temp_frame = vidObj_in.read(i_frame);
        
        height_video = vidObj_in.Height;
        width_video = vidObj_in.Width;
        % add pc
        plot_height_pc = 200;
        
        scale_pc = (plot_height_pc/2)/max(max(abs(score_trial(:,:,pc_num))));
        y_nose_plot = score_trial*scale_pc;
        plot_x_pc = round(linspace(1,t_len,width_video));
        plot_y_pc = round(y_nose_plot(plot_x_pc,k,pc_num)+height_video+plot_height_pc/2);
        
        temp_frame(height_video+1:height_video+plot_height_pc,:,:) = uint8(zeros(plot_height_pc,width_video,3));
        temp_frame(height_video+plot_height_pc/2,:,:) = uint8(100);
        
        for j = 1:width_video
            temp_frame(plot_y_pc(j),j,:) = uint8(255);
        end
        
        temp_frame(height_video+1:height_video+plot_height_pc,round(width_video*i_frame/vidObj_in.NumFrames),:) = uint8(128);
        temp_frame(height_video+1:height_video+plot_height_pc,...
            round(width_video*(-t_pre/10)/vidObj_in.NumFrames),:) = reshape(repmat(uint8([255,0,0]),plot_height_pc,1),plot_height_pc,1,3);
        temp_frame(height_video+1:height_video+plot_height_pc,...
            round(width_video*((FP_all(k)-t_pre)/10)/vidObj_in.NumFrames),:) = reshape(repmat(uint8([0,255,0]),plot_height_pc,1),plot_height_pc,1,3);
        text_title = [num2str(i_frame*10+t_pre),'ms   Performance: ',VideoInfos_this(k).Performance,...
            '   RT:',num2str(VideoInfos_this(k).ReactTime),'ms'];
        temp_frame = insertText(temp_frame,[10,10],text_title,'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        temp_frame = insertText(temp_frame,[10,height_video+10],['PC',num2str(pc_num)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        
        % add nose tracking
        if ~strcmp(bodypart,'None')
            plot_height_tracking = 200;
            if ~isnan(x_nose_all_raw(k,i_frame))
                for dot_x = -2:2
                    for dot_y = -2:2
                        if round(x_nose_all_raw(k,i_frame))+dot_x <= size(temp_frame,2) ...
                                && round(x_nose_all_raw(k,i_frame))+dot_x >=1 ...
                                && round(y_nose_all_raw(k,i_frame))+dot_y <= size(temp_frame,1) ...
                                && round(y_nose_all_raw(k,i_frame))+dot_y >=1
                        temp_frame(round(y_nose_all_raw(k,i_frame))+dot_y,round(x_nose_all_raw(k,i_frame))+dot_x,:) = uint8([255,0,0]);
                        end
                    end
                end
            end
            scale_tracking = (plot_height_tracking/2)/max(max(y_nose_all_raw_zscore(:)));
            y_nose_plot = y_nose_all_raw_zscore*scale_tracking;
            plot_x_tracking = round(linspace(1,size(y_nose_plot,2),width_video));
            plot_y_tracking = round(y_nose_plot(k,plot_x_tracking)+height_video+plot_height_pc+plot_height_tracking/2);

            temp_frame(height_video+plot_height_pc+1:height_video+plot_height_pc+plot_height_tracking,:,:) = uint8(zeros(plot_height_tracking,width_video,3));
            temp_frame(height_video+plot_height_pc+plot_height_tracking/2,:,:) = uint8(100);

            for j = 1:width_video
                if ~isnan(plot_y_tracking(j))
                    temp_frame(plot_y_tracking(j),j,:) = uint8(255);
                end
            end

            temp_frame(height_video+plot_height_pc+1:height_video+plot_height_pc+plot_height_tracking,round(width_video*i_frame/vidObj_in.NumFrames),:) = uint8(128);
            temp_frame(height_video+plot_height_pc+1:height_video+plot_height_pc+plot_height_tracking,...
                round(width_video*(-t_pre/10)/vidObj_in.NumFrames),:) = reshape(repmat(uint8([255,0,0]),plot_height_tracking,1),plot_height_tracking,1,3);
            temp_frame(height_video+plot_height_pc+1:height_video+plot_height_pc+plot_height_tracking,...
                round(width_video*((FP_all(k)-t_pre)/10)/vidObj_in.NumFrames),:) = reshape(repmat(uint8([0,255,0]),plot_height_tracking,1),plot_height_tracking,1,3);
            temp_frame = insertText(temp_frame,[10,height_video+plot_height_pc+10],bodypart,'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        end
        
        writeVideo(vidObj_out,temp_frame);
    end
    close(vidObj_out);
end

end