figure;
% a backbround picture should be prepared using the raw video
bg_img = imread('bg.jpg');
imshow(bg_img);

path_csv = './VideoFrames/RawVideo';
dir_output = dir([path_csv,'/*filtered.csv']);
filenames = {dir_output.name};
filenames = sort(filenames); % sort by trial

n_point = zeros(length(filenames),1);
val_trial = [];
y_all = {};
for k = 1:length(filenames)
    
    disp(filenames{k})
    data = xlsread([path_csv,'/',filenames{k}]);

    p_threshold = 0.95;
    
    id = data(:,1);
    
    % The following index should be edited according to the csv file
    x_left_paw = data(:,8);
    y_left_paw = data(:,9);
    p_left_paw = data(:,10);
    n_point(k) = length(find(p_left_paw>p_threshold));
    
    temp_y = y_left_paw(p_left_paw>p_threshold);
    temp_x = x_left_paw(p_left_paw>p_threshold);
    if length(find(find(p_left_paw>p_threshold)<60))>=30 ... % DLC should found at least 10 points before press onset
        && temp_y(1)>500 ... % the initiation position of left paw should be on the ground
        && p_left_paw(60)>p_threshold ... % DLC should find the point when pressing
        && y_left_paw(60)<450 ... % The point when pressing should be on the lever
        && x_left_paw(60)<320

        % only deal with the time from -0.6s to press onset
        range_left = min(id(p_left_paw>p_threshold));
        range_right = 59;
        
        plot_range = range_left:range_right;
        
        % interpolate the points to make the full trajectory
        x_plot = interp1(id(p_left_paw>p_threshold),x_left_paw(p_left_paw>p_threshold),plot_range,'linear');
        y_plot = interp1(id(p_left_paw>p_threshold),y_left_paw(p_left_paw>p_threshold),plot_range,'linear');
        
        hold on
        plot(x_plot,y_plot,'.-')
        drawnow;
        
        % Relabelling
        dir_name = './VideoFrames/RelabelledVideo';
        if ~exist(dir_name,'dir')
            mkdir(dir_name)
        end
        raw_video_name = filenames{k};
        raw_video_filename = [path_csv,'/',raw_video_name(1:41),'.avi'];
        output_filename = [dir_name,'/',raw_video_name(1:41),'_relabelled.avi'];
        vidObj_in = VideoReader(raw_video_filename);
        vidObj_out = VideoWriter(output_filename);
        vidObj_out.FrameRate=10;
        open(vidObj_out);
        for i_frame = 1:60
            temp_frame = vidObj_in.read(i_frame);
            if i_frame >= range_left+3 && i_frame <= range_right+3
                temp_i = i_frame-range_left;
                for x_pixel = round(x_plot(temp_i))-3:round(x_plot(temp_i))+3
                    for y_pixel = round(y_plot(temp_i))-1:round(y_plot(temp_i))+1
                        temp_frame(y_pixel,x_pixel,:)=uint8([255,0,0]);
                    end
                end
            end
            writeVideo(vidObj_out,temp_frame);
        end
        close(vidObj_out);
        
        % postprocess
        y_lever = y_left_paw(60);
        y_ground = max(y_left_paw(p_left_paw(1:60)>p_threshold));
        % set the height of lever to 1, set the height of ground to 0
        y_true = (-y_plot+y_ground)/(-y_lever+y_ground);
        
        y_all{k} = [y_true;plot_range-60]; % set press time as zero        
    else
        y_all{k} = [];
    end
    n_point(k) = length(find(p_left_paw>p_threshold));
    disp(['DLC found ',num2str(n_point(k)),' points in the video. ',num2str(length(find(find(p_left_paw>p_threshold)<60))),...
        ' points are found before press.'])
    
end
if ~exist('Fig','dir')
    mkdir('Fig');
end
saveas(gcf, 'Fig/trajectory.png');

%% get t_press_sort & t_press_sort_all
load('RTarrayAll.mat')
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

%% compute firing rate of each unit
max_cor = zeros(16,1);
for n_neuron = 1:16
    spike_time = r.Units.SpikeTimes(n_neuron).timings;

    % binWidth = 1 ms, no 2 spikes occur in 1ms
    t = 1:max(spike_time);

    spike_time_binned = zeros(1,max(spike_time));
    spike_time_binned(round(spike_time))=1;

    % the kernal width controls the smoothness of the cross correlation
    firing_rate = smoothdata(spike_time_binned,'gaussian',200);

    % figure;
    % plot(firing_rate)
    % xlabel('time(ms)')
    % ylabel('firing rate(Hz)')

    % compute cross correlation

    t_pre_plot = -600; % ms
    
    t_frame = -600;
    t_pre = t_pre_plot + t_frame;
    t_post = 0;
    t_cor = t_pre:t_post;

    cor = zeros(length(t_cor),1);

    y_all_new = [];
    t_range = [];
    firing_rate_plot = [];
    spike_time_plot = [];

    for k = 1:length(y_all)
        if ~isempty(y_all{k})
            temp = y_all{k};
            temp_time = t_press_sort_all(k);
            temp_range = round(temp_time+t_pre):round(temp_time+t_post);
            t_range = [t_range, temp_range];
            firing_rate_plot = [firing_rate_plot;firing_rate(temp_range)];
            spike_time_plot = [spike_time_plot;spike_time_binned(temp_range)];
            temp_idx = temp(2,:);
            temp_y = temp(1,:);
            y_new = [];
            y_new(1,:) = temp_y;
            y_new(2,:) = temp_idx*10+temp_time; % 10ms each frame
            y_all_new = [y_all_new, y_new];
        end
    end

    firing_rate_cor = firing_rate;
    firing_rate_cor(t_range) = zscore(firing_rate(t_range));
    y_all_new(1,:) = zscore(y_all_new(1,:));


    for k = 1:length(cor)
        temp_time = round(y_all_new(2,:)+t_cor(k));
        cor(k) = (firing_rate_cor(temp_time)*y_all_new(1,:)')./length(temp_time);
    end
    [~,max_cor_index] = max(abs(cor));
    max_cor(n_neuron) = cor(max_cor_index);

    figure;
    subplot(224)
    plot(t_cor(end+t_pre_plot:end),cor(end+t_pre_plot:end))
    xlabel('lag(ms)')
    ylabel('correlation')
    title(['cross correlation of Unit #',num2str(n_neuron)])

    % visualize the wave of firing rate and y of each unit
    plot_num = 6;
    colors = varycolor(plot_num);
    
    subplot(221)
    for k = 1:plot_num
        hold on
        plot(t_cor,firing_rate_plot(k,:),'--','color',colors(k,:));
    end
    hold on
    plot(t_cor,mean(firing_rate_plot),'r-')
    xlim([t_pre_plot,0])
    xlabel('time(ms)') 
    ylabel(['f_{Unit ', num2str(n_neuron), '}'])

    subplot(223)
    y_all_plot = nan*zeros(length(y_all),61);

    count = 1;
    for k = 1:length(y_all)
        hold on
        temp = y_all{k};
        if length(temp)>0
            y_all_plot(k,temp(2,:)+61) = temp(1,:);
            if count <= plot_num
                plot(temp(2,:)*10,temp(1,:),'--','color',colors(count,:));
                count = count+1;
            end
        end
    end
    hold on
    plot(-600:10:0,mean(y_all_plot,'omitnan'),'r-')
    xlim([t_pre_plot,0])
    xlabel('time(ms)')
    ylabel('h_{paw}')
    
    subplot(222)
    for k = 1:plot_num
        for j = 1:length(t_cor)
            if spike_time_plot(k,j)>=1
                hold on
                plot([t_cor(j),t_cor(j)],[k-0.8,k-0.2],'-','color',colors(k,:),'lineWidth',1)
            end
        end
    end
    xlim([t_pre_plot,0])
    xlabel('time(ms)')  
    ylabel('Units')
    saveas(gcf,['Fig/Cross-correlation_Unit',num2str(n_neuron),'.png']);
end

figure;
bar(1:16,max_cor)
xlabel('Unit')
ylabel('Max correlation')
title('Correlation with left paw')

saveas(gcf,'Fig/Correlation with left paw.png')
