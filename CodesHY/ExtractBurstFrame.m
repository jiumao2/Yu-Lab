function ExtractBurstFrame(r,unit_num,varargin)
    % eg. ExtractBurstFrame(r,unit_num,'view','side');
    FrameNum = 500; 
    FrameRate = 20; % Output video
    view = 'side';
    correct_only = true;
    plot_longer_clip = false;
    n_frame_pre = -50;
    n_frame_post = 50;

    if nargin>=3
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'FrameNum'
                    FrameNum = varargin{i+1};
                case 'correct_only'
                    correct_only = varargin{i+1};
                case 'FrameRate'
                    FrameRate = varargin{i+1};
                case 'view'
                    view = varargin{i+1};     
                case 'plot_longer_clip'
                    plot_longer_clip = varargin{i+1};
                case 'n_frame_pre'
                    n_frame_pre = varargin{i+1};
                case 'n_frame_post'
                    n_frame_post = varargin{i+1};                
                otherwise
                    errordlg('unknown argument')
            end
        end
    end
    if strcmp(view,'side')
        r.VideoInfos = r.VideoInfos_side;
    elseif strcmp(view,'top')
        r.VideoInfos = r.VideoInfos_top;
    end

    if correct_only
        correct_index = find(strcmp({r.VideoInfos.Performance},'Correct'));
        r.VideoInfos = r.VideoInfos(correct_index);
    else
        correct_index = 1:length(r.VideoInfos);
    end

    spk_time = r.Units.SpikeTimes(unit_num).timings;
    firing_rate_t_post = 50;
    firing_rate_t_pre = -50;

    firing_rate = zeros(length(r.VideoInfos),r.VideoInfos(unit_num).total_frames);
    for k = 1:length(r.VideoInfos)
        for j = 1:r.VideoInfos(unit_num).total_frames
            firing_rate(k,j) = sum(spk_time+firing_rate_t_post>r.VideoInfos(k).VideoFrameTime(j)...
                & spk_time+firing_rate_t_pre<r.VideoInfos(k).VideoFrameTime(j));
        end
    end

    h = figure;
    spike_time = sort(firing_rate(:),'descend');
    threshold = spike_time(FrameNum);
    histogram(spike_time(spike_time>2));
    xline(threshold);
    xlabel('Spike Count')
    title('Spike Count Histogram')
    %%
    dir_name = ['VideoFrames_',view,'\BurstFrames'];
    if ~exist(dir_name,'dir')
        mkdir(dir_name);
    end
    if plot_longer_clip
        vid_out = VideoWriter([dir_name,'/Unit',num2str(unit_num),'_clip.avi']);
    else
        vid_out = VideoWriter([dir_name,'/Unit',num2str(unit_num),'.avi']);
    end
    vid_out.FrameRate = FrameRate;
    open(vid_out);
    for k = 1:length(r.VideoInfos)
        j = 1;
        while j <= r.VideoInfos(1).total_frames
            if firing_rate(k,j) > threshold
                vid_this = VideoReader(['VideoFrames_',view,'\RawVideo\Press',num2str(r.VideoInfos(k).Index,'%03d'),'.avi']);
                if ~plot_longer_clip
                    temp_frame = vid_this.read(j);
                    temp_frame = insertText(temp_frame,[10,10],['Time: ',num2str(round(r.VideoInfos(k).VideoFrameTime(j))),' ms'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                    temp_frame = insertText(temp_frame,[10,50],['Firing Rate: ',num2str(firing_rate(k,j)/(firing_rate_t_post-firing_rate_t_pre)*1000),' Hz'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                    temp_frame = insertText(temp_frame,[10,90],['Press Index: ',num2str(r.VideoInfos(k).Index)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                    if isfield(r,'VideoInfos_top') && isfield(r.VideoInfos_top(correct_index(k)),'Trajectory') && ~isempty(r.VideoInfos_top(correct_index(k)).Trajectory)
                        temp_frame = insertText(temp_frame,[10,130],['Trajectory: No.',num2str(r.VideoInfos_top(correct_index(k)).Trajectory)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                    end

                    vid_out.writeVideo(temp_frame);
                else
                    j_start = max(j+n_frame_pre,1);
                    for i = j:r.VideoInfos(1).total_frames
                        if i == r.VideoInfos(1).total_frames
                            j_end = i;
                        end
                        if firing_rate(k,i) <= threshold
                            j_end = min(r.VideoInfos(1).total_frames,i+n_frame_post);
                            break
                        end
                    end
                    burst_zone = [max(round(j+firing_rate_t_pre/10),1),...
                        min(round(i-1+firing_rate_t_post/10),r.VideoInfos(1).total_frames)];
                    j_this = j;
                    j = i;

                    t_start = r.VideoInfos(k).VideoFrameTime(j_start);
                    t_now = r.VideoInfos(k).VideoFrameTime(j_this);
                    t_end = r.VideoInfos(k).VideoFrameTime(j_end);
                    spike_time = r.VideoInfos(k).Units.SpikeTimes(unit_num).timings(r.VideoInfos(k).Units.SpikeTimes(unit_num).timings<=t_end & r.VideoInfos(k).Units.SpikeTimes(unit_num).timings>t_start);

                    % Raster parameters
                    colors = uint8([255,255,255]);
                    burst_zone_color = uint8([128,0,0]);
                    spike_height = 20;
                    spike_width = 1;
                    line_width = 1;
                    line_color = uint8([255,255,255]);
                    raster_space_top = 20;
                    raster_space_bottom = 20;
                    raster_space_left = 5;
                    raster_space_right = 5;
                    raster_height = spike_height+raster_space_top+raster_space_bottom;
                    raster_width = size(vid_this.read(1),2);
                    % raster_block template
                    blk_raster_template = uint8(zeros(raster_height,raster_width,3));
                    burst_zone = [round((burst_zone(1)-j_start+1)/(j_end-j_start+1)*(raster_width-raster_space_left-raster_space_right)+raster_space_left),...
                        round((burst_zone(2)-j_start+1)/(j_end-j_start+1)*(raster_width-raster_space_left-raster_space_right)+raster_space_left)];
                    for x = 1:raster_height
                        for y = burst_zone(1):burst_zone(2)
                            blk_raster_template(x,y,:) = burst_zone_color;
                        end
                    end

                    p = raster_space_top+1;

                    if ~isempty(spike_time)
                        spike_time = round((spike_time-t_start)/(t_end-t_start)*(raster_width-raster_space_left-raster_space_right)+raster_space_left);
                        for spk = 1:length(spike_time)
                            for y = round(spike_time(spk)-(spike_width-1)/2):round(spike_time(spk)+(spike_width-1)/2)
                                for x = p:p+spike_height-1
                                    blk_raster_template(x,y,:) = colors;
                                end
                            end
                        end
                    end   
                    % x tick block template
                    xtick_height = 50;
                    xtick_line_space_top = 10;
                    xtick_width = raster_width;
                    xtick_color = [255,255,255];
                    xtick_line_width = 1;
                    tick_height = 5;
                    xtick_fontsize = 18;
                    xtick_interval = 200; % ms
                    xtick_space_left = raster_space_left;
                    xtick_space_right = raster_space_right;

                    font_space_top = 1;
                    font_space_left = 5;
                    font_space_per_num = 6;

                    blk_xtick_template = uint8(zeros(xtick_height,xtick_width,3));
                    for x = xtick_space_left:xtick_width-xtick_space_right
                        for y = xtick_line_space_top-round((xtick_line_width-1)/2):xtick_line_space_top+round((xtick_line_width-1)/2)
                            blk_xtick_template(y,x,:) = xtick_color;
                        end
                    end
                    ticks = ceil((t_start-t_now)/xtick_interval)*xtick_interval:xtick_interval:floor((t_end-t_now)/xtick_interval)*xtick_interval;
                    for i_tick = 1:length(ticks)
                        x_this = round((ticks(i_tick)+t_now-t_start)/(t_end-t_start)*(xtick_width-xtick_space_left-xtick_space_right)+raster_space_left);
                        for y = xtick_line_space_top-tick_height:xtick_line_space_top
                            blk_xtick_template(y,x_this,:) = xtick_color;
                        end
                        blk_xtick_template = insertText(blk_xtick_template,[x_this-font_space_left-font_space_per_num*length(num2str(ticks(i_tick))),xtick_line_space_top+font_space_top],num2str(ticks(i_tick)),'FontSize',xtick_fontsize,'TextColor','white','BoxOpacity', 0);                   
                    end


                    for i = j_start:j_end
                        temp_frame = vid_this.read(i);
                        temp_frame = insertText(temp_frame,[10,10],['Time: ',num2str(round(r.VideoInfos(k).VideoFrameTime(j))),' ms'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                        temp_frame = insertText(temp_frame,[10,50],['Firing Rate: ',num2str(firing_rate(k,j)/(firing_rate_t_post-firing_rate_t_pre)*1000),' Hz'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                        temp_frame = insertText(temp_frame,[10,90],['Press Index: ',num2str(r.VideoInfos(k).Index)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                        if isfield(r,'VideoInfos_top') && isfield(r.VideoInfos_top(correct_index(k)),'Trajectory') && ~isempty(r.VideoInfos_top(correct_index(k)).Trajectory)
                            temp_frame = insertText(temp_frame,[10,130],['Trajectory: No.',num2str(r.VideoInfos_top(correct_index(k)).Trajectory)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
                        end

                        % add raster plot
                        % Raster block
                        blk_raster = blk_raster_template;
                        % Xtick block
                        blk_xtick = blk_xtick_template;
                        blk_raster = [blk_raster;blk_xtick];

                        line_pos = round((i-j_start+1)/(j_end-j_start+1)*(raster_width-raster_space_left-raster_space_right)+raster_space_left);
                        for y = round(line_pos-(line_width-1)/2):round(line_pos+(line_width-1)/2)
                            for x = 1:size(blk_raster,1)
                                blk_raster(x,y,:) = line_color;
                            end
                        end                                     

                        % Combine
                        temp_frame = [temp_frame;blk_raster];
                        vid_out.writeVideo(temp_frame); 

                    end
                end
            end
        j = j+1;
        end
    end
    vid_out.close();
    close(h);
end
