%% get t_press_sort & t_press_sort_all
clear;
data_path = 'c:/Users/jiumao/Desktop/Eli20210923';
set(groot,'defaultfigurerenderer','opengl')
if ~exist('r','var')
    load([data_path, '/RTarrayAll.mat'])
end

t_pre = -1800;
t_post = 3000;

% t_pre = -1500;
% t_post = 1500;

t_len = t_post-t_pre+1;

te=GetEventTimes(r);
camview = 'side';

switch camview
    case 'side'
        indframe = find(strcmp(r.Video.Labels, 'SideFrameOn'));
        t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
    case 'top'
        indframe = find(strcmp(r.Video.Labels, 'TopFrameOn'));
        t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
    otherwise
        disp('Check camera view')
        return;
end

t_press = [te.press_correct{1}; te.press_correct{2}];
RTs = [te.rt{1}; te.rt{2}];
FPs = [ones(1, length(te.rt{1}))*750 ones(1, length(te.rt{2}))*1500];
[t_press, indsort] = sort(t_press);
RTs= RTs(indsort);
FPs= FPs(indsort);
t_release = [te.release_correct{1}; te.release_correct{2}];
[t_release, ~] = sort(t_release);

t_trigger = te.trigger;
t_reward = te.rewards;

ind_break = find(diff(t_frameon)>1000);
t_seg =[];
t_trigger_sort=[];
t_press_sort=[];
t_release_sort=[];

if isempty(ind_break)
    t_seg{1} = t_frameon;
    t_trigger_sort{1} = t_trigger;
    RTs_sort{1} = RTs;
    FPs_sort{1} = FPs;
    if ~isempty(t_press)
        t_press_sort{1} = t_press;
    end
    if ~isempty(t_release)
        t_release_sort{1} = t_release;
    end
    
else
    ind_break = [1 ind_break+1];
    
    for i =1:length(ind_break)
        if i<length(ind_break)
            t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
            t_trigger_sort{i} = t_trigger(t_trigger>=t_seg{i}(1) & t_trigger<=t_seg{i}(end));
            
            if ~isempty(t_press)
                t_press_sort{i} = t_press(t_press>=t_seg{i}(1) & t_press<=t_seg{i}(end));
            end
            if ~isempty(t_release)
                t_release_sort{i} = t_release(t_release>=t_seg{i}(1) & t_release<=t_seg{i}(end));
            end
            RTs_sort{i} = RTs(t_press>=t_seg{i}(1) & t_press<=t_seg{i}(end));
            FPs_sort{i} = FPs(t_press>=t_seg{i}(1) & t_press<=t_seg{i}(end));
        else
            t_seg{i}=t_frameon(ind_break(i):end);
            t_trigger_sort{i} = t_trigger(t_trigger>=t_seg{i}(1));
            if ~isempty(t_press)
                t_press_sort{i} = t_press(t_press>=t_seg{i}(1));
            end
            if ~isempty(t_release)
                t_release_sort{i} = t_release(t_release>=t_seg{i}(1));
            end
            RTs_sort{i} = RTs(t_press>=t_seg{i}(1));
            FPs_sort{i} = FPs(t_press>=t_seg{i}(1));
        end
    end
end

t_press_sort_all = [];
for k = 1:length(t_press_sort)
    t_press_sort_all = [t_press_sort_all, t_press_sort{k}'];
end

close all;
%% compute firing rate of each unit
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

spikes_trial_flattened = zscore(spikes_trial_flattened,0,2);
[coeff, score, latent, tsquared, explained] = pca(spikes_trial_flattened');

figure;
bar(explained)
title('explained')

score_trial = reshape(score,t_len,length(t_press_sort_all),length(unit_of_interest));

FP_all = [];
for k = 1:length(FPs_sort)
    FP_all = [FP_all, FPs_sort{k}];
end

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

filenames_video = dir([data_path,'/VideoFrames/RawVideo/*.avi']);
filenames_video = sort({filenames_video.name});

dir_name = [data_path,'/VideoFrames/RelabelledPC',num2str(pc_num),'Video_zscore_sigma50ms'];
if ~exist(dir_name,'dir')
    mkdir(dir_name);
end

% figure;
for k = 1:length(filenames_video)
    raw_video_filename = filenames_video{k};
    output_filename = [dir_name,'/',raw_video_filename(1:end-4),'_PC',num2str(pc_num),'.avi'];
    vidObj_in = VideoReader([data_path,'/VideoFrames/RawVideo/',raw_video_filename]);
    vidObj_out = VideoWriter(output_filename);
    vidObj_out.FrameRate=20;
    open(vidObj_out);
    for i_frame = 1:vidObj_in.NumFrames
        temp_frame = vidObj_in.read(i_frame);
        
        height_video = vidObj_in.Height;
        width_video = vidObj_in.Width;
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
        temp_frame = insertText(temp_frame,[10,10],[num2str(i_frame*10+t_pre),'ms'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        temp_frame = insertText(temp_frame,[10,height_video+10],['PC',num2str(pc_num)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        
%         imshow(temp_frame)
%         drawnow;
        writeVideo(vidObj_out,temp_frame);
    end
    close(vidObj_out);
end

