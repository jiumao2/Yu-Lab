function TrajectoryCell(r,unit_num,press_indexes,bg,varargin)
    save_dir = './';
    n_post_framenum = 0;
    n_pre_framenum = 0;
    binwidth = 1;
    gaussian_kernel = 25;
    color_max_percentage = 1.00;
    color_min_percentage = 0.00;
    save_fig = 'off';
    if nargin>=5
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'save_dir'
                    save_dir = varargin{i+1};
                case 'binwidth'
                    binwidth =  varargin{i+1};
                case 'gaussian_kernel'
                    gaussian_kernel =  varargin{i+1};  
                case 'color_max_percentage'
                    color_max_percentage =  varargin{i+1}; 
                case 'color_min_percentage'
                    color_min_percentage =  varargin{i+1};
                case 'n_pre_framenum'
                    n_pre_framenum =  varargin{i+1}; 
                case 'n_post_framenum'
                    n_post_framenum =  varargin{i+1};
                case 'save_fig'
                    save_fig =  varargin{i+1};
                otherwise
                    errordlg('unknown argument')
            end
        end
    end
    
    save_resolution = 1200;
    bodypart = 'left_paw';
    idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts,bodypart));
    marker_size = 30;
    colors_num = 256;
    colors = parula(256);

    h0 = figure('Renderer','opengl');
    ax0 = axes(h0,'NextPlot','add');
    image(ax0,bg);
    set(ax0,'YDir','reverse','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)])
    title(ax0,'All');
    c0 = colorbar();
    ylabel(c0,'Normalized firing rate','FontSize',10);
    ax0.XAxis.Visible = 'off';ax0.YAxis.Visible = 'off';
    
    h0_realigned = figure('Renderer','opengl');
    ax0_realigned = axes(h0_realigned,'NextPlot','add');
    image(ax0_realigned,bg);
    set(ax0_realigned,'YDir','reverse','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)])
    title(ax0_realigned,'All (realigned)');
    c0_realigned = colorbar();
    ylabel(c0_realigned,'Normalized firing rate','FontSize',10);
    ax0_realigned.XAxis.Visible = 'off';ax0_realigned.YAxis.Visible = 'off';

    h0_yt = figure('Renderer','opengl');
    ax0_yt = axes(h0_yt,'NextPlot','add');
    set(ax0_yt,'YDir','reverse','XDir','reverse')
    title(ax0_yt,'All (y vs t)');
    c0_yt = colorbar();
    ylabel(c0_yt,'Normalized firing rate','FontSize',10);
    ax0_yt.XAxis.Visible = 'off';ax0_yt.YAxis.Visible = 'off';
    
    idx_all = [r.VideoInfos_side.Index];
    vid_press_idx = findSeq(idx_all,press_indexes);

    firing_rate_all_flattened = [];
    firing_rate_all = cell(length(press_indexes),1);
    t_all = cell(length(press_indexes),1);
    traj_all = cell(length(press_indexes),1);
    traj_all_realigned = cell(length(press_indexes),1);
    traj_all_yt = cell(length(press_indexes),1);
    highest_point = zeros(length(press_indexes),2);
    frame_num_all = zeros(1,length(press_indexes));

    firing_rate_threshold = -0.1;
    [spike_counts, t_spike_counts] = bin_timings(r.Units.SpikeTimes(unit_num).timings, binwidth);
    spike_counts_all = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000;
    for k = 1:length(vid_press_idx)
        % deal with bad tracking
        frame_start = max(r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum-n_pre_framenum,1);
        while r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_p{idx_bodypart}(frame_start) < 0.8
            frame_start = frame_start+1;
        end
        frame_end = round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10+n_post_framenum);
        while r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_p{idx_bodypart}(frame_end) < 0.8
            frame_end = frame_end-1;
        end
        
        frame_num_temp = frame_start:frame_end;
        [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp));
        frame_num = frame_num_temp(1:i_maxy+n_post_framenum);
        frame_num_all(k) = length(frame_num);

        times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
        traj_all{k} = [r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
            r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num)]';
        highest_point(k,:) = traj_all{k}(:,end-n_post_framenum)';
        t_all{k} = (0:10:10*(length(frame_num)-1))-10*(i_maxy-1);
        
        firing_rate_this = getFiringRate_spike_train(spike_counts_all,t_spike_counts,times_this,binwidth);
        firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_this];
        firing_rate_all{k} = firing_rate_this;
    end
    mean_highest_point = mean(highest_point);
    for k = 1:length(vid_press_idx)
        traj_all_realigned{k} = traj_all{k}-highest_point(k,:)'+mean_highest_point';
        traj_all_yt{k} = [t_all{k};traj_all{k}(2,:)];
    end

    mean_traj = getMeanTrajectory(traj_all, round(mean(frame_num_all)));

    firing_rate_all_flattened = sort(firing_rate_all_flattened);
    firing_rate_max = firing_rate_all_flattened(floor(length(firing_rate_all_flattened)*color_max_percentage));
    firing_rate_min = firing_rate_all_flattened(ceil(length(firing_rate_all_flattened)*color_min_percentage)+1);

    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax0,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
            traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');
        alpha(s,0.5);
    end

    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax0_realigned,traj_all_realigned{k}(1,firing_rate_this>firing_rate_threshold),...
            traj_all_realigned{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');
        alpha(s,0.5);
    end    
    
    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax0_yt,t_all{k}(firing_rate_this>firing_rate_threshold),...
            traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');
        alpha(s,0.5);
    end  
    %% Confirming Lift-related cell
    h_lift = figure('Renderer','opengl','Units','centimeters','Position',[10,10,12,4]);
    ax_lift_start = axes(h_lift,'NextPlot','add','Units','centimeters','Position',[0.5,0.5,3,3]);
    ax_lift_highest = axes(h_lift,'NextPlot','add','Units','centimeters','Position',[4.5,0.5,3,3]);
    ax_press = axes(h_lift,'NextPlot','add','Units','centimeters','Position',[8.5,0.5,3,3]);

    lift_times = [r.VideoInfos_side(vid_press_idx).LiftStartTime];
    press_times = [r.VideoInfos_side(vid_press_idx).Time];

    lift_highest_times = zeros(1,length(vid_press_idx));
    for k = 1:length(vid_press_idx)
        frame_num_temp = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum:round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10);
        [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp));
        lift_highest_times(k) = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum+i_maxy-1);
    end

    params_lift.pre = 1000;
    params_lift.post = 1000;
    params_lift.binwidth = 20;
    params_press.pre = 2000;
    params_press.post = 0;
    params_press.binwidth = 20;
    [psth_lift,t_psth_lift] = jpsth(r.Units.SpikeTimes(unit_num).timings,lift_times',params_lift);
    [psth_lift_highest,t_psth_lift_highest] = jpsth(r.Units.SpikeTimes(unit_num).timings,lift_highest_times',params_lift);
    [psth_press,t_psth_press] = jpsth(r.Units.SpikeTimes(unit_num).timings,press_times',params_press);
    psth_lift = smoothdata(psth_lift,'gaussian',5);
    psth_lift_highest = smoothdata(psth_lift_highest,'gaussian',5);
    psth_press = smoothdata(psth_press,'gaussian',5);

    plot(ax_lift_start,t_psth_lift,psth_lift)
    title(ax_lift_start,'Lift')
    xlabel(ax_lift_start,'Time from lift (ms)')

    plot(ax_lift_highest,t_psth_lift_highest,psth_lift_highest)
    title(ax_lift_highest,'Lift highest')
    xlabel(ax_lift_highest,'Time from lift highest (ms)')

    plot(ax_press,t_psth_press,psth_press)
    title(ax_press,'Press')
    xlabel(ax_press,'Time from press (ms)')
    ylim_max = max([ax_lift_start.YLim(2),ax_press.YLim(2),ax_lift_highest.YLim(2)]);
    ylim(ax_lift_start,[0,ylim_max]);ylim(ax_press,[0,ylim_max]);ylim(ax_lift_highest,[0,ylim_max]);

    
    gaussian_kernel = 100;

    h_h2_heatmap = figure('Renderer','opengl');
    ax_h2_heatmap = axes(h_h2_heatmap,'NextPlot','add');
    title(ax_h2_heatmap,'Heatmap');
    set(ax_h2_heatmap,'YDir','reverse')
    ax_h2_heatmap.XAxis.Visible = 'off';ax_h2_heatmap.YAxis.Visible = 'off';
    colorbar(ax_h2_heatmap,'Limits',[0,1]);
    x = 1:5:size(bg,2);
    y = 1:5:size(bg,1);
    [X,Y] = meshgrid(x,y);
    z = zeros(length(x),length(y));
    for k = 1:length(x)
        for j = 1:length(y)
            z(k,j) = getGraphFiringRate(x(k),y(j),traj_all,firing_rate_all,gaussian_kernel);
        end
    end
    z = (z-firing_rate_min)./(firing_rate_max-firing_rate_min);
    z(z>1)=1;z(z<0)=0;
    imagesc(ax_h2_heatmap,z','XData',x,'YData',y);
    ax_h2_heatmap.CLim = [0,1];
    
    h_h2_heatmap_realigned = figure('Renderer','opengl');
    ax_h2_heatmap_realigned = axes(h_h2_heatmap_realigned,'NextPlot','add');
    title(ax_h2_heatmap_realigned,'Heatmap (realigned)');
    set(ax_h2_heatmap_realigned,'YDir','reverse')
    ax_h2_heatmap_realigned.XAxis.Visible = 'off';ax_h2_heatmap_realigned.YAxis.Visible = 'off';
    colorbar(ax_h2_heatmap_realigned,'Limits',[0,1]);
    x = 1:5:size(bg,2);
    y = 1:5:size(bg,1);
    [X,Y] = meshgrid(x,y);
    z = zeros(length(x),length(y));
    for k = 1:length(x)
        for j = 1:length(y)
            z(k,j) = getGraphFiringRate(x(k),y(j),traj_all_realigned,firing_rate_all,gaussian_kernel);
        end
    end
    z = (z-firing_rate_min)./(firing_rate_max-firing_rate_min);
    z(z>1)=1;z(z<0)=0;
    imagesc(ax_h2_heatmap_realigned,z','XData',x,'YData',y);
    ax_h2_heatmap_realigned.CLim = [0,1];

    h_h2_heatmap_yt = figure('Renderer','opengl');
    ax_h2_heatmap_yt = axes(h_h2_heatmap_yt,'NextPlot','add');
    title(ax_h2_heatmap_yt,'Heatmap (y vs t)');
    set(ax_h2_heatmap_yt,'YDir','reverse','XDir','reverse');
    ax_h2_heatmap_yt.XAxis.Visible = 'off';ax_h2_heatmap_yt.YAxis.Visible = 'off';
    colorbar(ax_h2_heatmap_yt,'Limits',[0,1]);
    x = ax0_yt.XLim(1):5:ax0_yt.XLim(2);
    y = ax0_yt.YLim(1):5:ax0_yt.YLim(2);
    [X,Y] = meshgrid(x,y);
    z = zeros(length(x),length(y));
    for k = 1:length(x)
        for j = 1:length(y)
            z(k,j) = getGraphFiringRate(x(k),y(j),traj_all_yt,firing_rate_all,gaussian_kernel);
        end
    end
    z = (z-firing_rate_min)./(firing_rate_max-firing_rate_min);
    z(z>1)=1;z(z<0)=0;
    imagesc(ax_h2_heatmap_yt,z','XData',x,'YData',y);
    ax_h2_heatmap_yt.CLim = [0,1];
    xlim(ax_h2_heatmap_yt,ax0_yt.XLim);
    ylim(ax_h2_heatmap_yt,ax0_yt.YLim);

    %% Save Figure
    if strcmp(save_fig,'on')
        if ~exist(save_dir,'dir')
            mkdir(save_dir)
        end
        print(h0,fullfile(save_dir,'traj_all'),'-dpng',['-r',num2str(save_resolution)])
        print(h0_realigned,fullfile(save_dir,'traj_all_realigned'),'-dpng',['-r',num2str(save_resolution)])
        print(h0_yt,fullfile(save_dir,'traj_all_yt'),'-dpng',['-r',num2str(save_resolution)])
        print(h_lift,fullfile(save_dir,'PETH'),'-dpng',['-r',num2str(save_resolution)])
%         print(h_h1,fullfile(save_dir,'time'),'-dpng',['-r',num2str(save_resolution)])
%         print(h_h2,fullfile(save_dir,'position'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h2_heatmap,fullfile(save_dir,'position_heatmap'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h2_heatmap_realigned,fullfile(save_dir,'position_heatmap_realigned'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h2_heatmap_yt,fullfile(save_dir,'position_heatmap_yt'),'-dpng',['-r',num2str(save_resolution)])
%         print(h_h2_2,fullfile(save_dir,'position_points_number'),'-dpng',['-r',num2str(save_resolution)])
%         print(h_h3,fullfile(save_dir,'warped_time'),'-dpng',['-r',num2str(save_resolution)])
%         print(h_h4,fullfile(save_dir,'time (highest)'),'-dpng',['-r',num2str(save_resolution)])
%         print(h_all,fullfile(save_dir,'comparison'),'-dpng',['-r',num2str(save_resolution)])
    end
end

function firing_rate = getGraphFiringRate(x,y,traj_all,firing_rate_all,gaussian_kernel)
    traj_all_flattened = [];
    firing_rate_all_flattened = [];
    for k = 1:length(traj_all)
        traj_all_flattened = [traj_all_flattened,traj_all{k}];
        firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_all{k}];
    end

    gaussian_value = mvnpdf(traj_all_flattened',[x,y],gaussian_kernel*eye(2));
    gaussian_value(gaussian_value<1e-6) = 0;
    if sum(gaussian_value>0) <= 5
        gaussian_value(gaussian_value>0) = 0;
    end
    if sum(gaussian_value) < 1e-5
        firing_rate = 0;
    else
        firing_rate = dot(firing_rate_all_flattened,gaussian_value)./sum(gaussian_value);
    end
end