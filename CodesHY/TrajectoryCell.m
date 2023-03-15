function TrajectoryCell(r,unit_num,varargin)
    save_dir = './Fig/';
    n_post_framenum = 20;
    n_pre_framenum = 20;
    binwidth = 1;
    gaussian_kernel = 25;
    color_max_percentage = 1.00;
    color_min_percentage = 0.00;
    save_fig = 'on';
    traj = 'All';
    if nargin>2
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
                case 'trajectory'
                    traj = varargin{i+1};
                otherwise
                    error('Unknown argument!')
            end
        end
    end
    
    marker_size = 10;
    colors_num = 256;
    alpha_point = 0.3;
    colors = parula(256);
    %% load firing rate
    idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts, 'left_paw'));
    
    press_indexes = getIndexVideoInfos(r,"LiftStartTimeLabeled","On","Hand","Left","Trajectory",traj);
    example_idx = press_indexes(1);
    vid_path = ['.\VideoFrames_side\RawVideo\Press',num2str(example_idx,'%03d'),'.avi'];

    idx_all = [r.VideoInfos_side.Index];
    vid_press_idx = findSeq(idx_all,press_indexes);
    lift_times = [r.VideoInfos_side(vid_press_idx).LiftStartTime];
    press_times = [r.VideoInfos_side(vid_press_idx).Time];
    
    firing_rate_all_flattened = [];
    firing_rate_all = cell(length(press_indexes),1);
    t_all = cell(length(press_indexes),1);
    traj_all = cell(length(press_indexes),1);
    highest_point = zeros(length(press_indexes),2);
    highest_time = zeros(length(press_indexes),1);
    frame_num_all = zeros(1,length(press_indexes));
    
    [spike_counts, t_spike_counts] = bin_timings(r.Units.SpikeTimes(unit_num).timings, binwidth);
    spike_density = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000;
    for k = 1:length(vid_press_idx)
        % deal with bad tracking
        frame_start = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum;
        while frame_start-1 >= max(r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum-n_pre_framenum,1)...
                && r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_p{idx_bodypart}(frame_start-1) > 0.8
            frame_start = frame_start-1;
        end
    
        frame_end = round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10+n_post_framenum);
        
        frame_num_temp = frame_start:frame_end;
        [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp(1:end-n_post_framenum)));
        frame_num = frame_num_temp(1:(i_maxy+n_post_framenum));
        frame_num_all(k) = length(frame_num);
    
        highest_time(k) = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num(i_maxy));
    
        times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
        traj_all{k} = [r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
            r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num)]';
        highest_point(k,:) = traj_all{k}(:,end-n_post_framenum)';
        t_all{k} = (0:10:10*(length(frame_num)-1))-10*(i_maxy-1);
        
        idx_temp = findSeq(t_spike_counts, times_this, 'ordered');
        firing_rate_all{k} = spike_density(idx_temp);
        firing_rate_all_flattened = [firing_rate_all_flattened, firing_rate_all{k}];
    end
    
    sorted_fr = sort(firing_rate_all_flattened);
    max_fr = sorted_fr(round((length(sorted_fr)-1)*color_max_percentage+1));
    min_fr = sorted_fr(round((length(sorted_fr)-1)*color_min_percentage+1));

    %% Figure A
    fig_peth = EasyPlot.figure();
    ax_lift_start = EasyPlot.createAxesAgainstFigure(fig_peth,'leftTop',...
        'Height',3,...
        'Width',3,...
        'MarginLeft',0.8,...
        'MarginBottom',0.8);
    ax_lift_highest = EasyPlot.createAxesAgainstAxes(fig_peth,ax_lift_start,'right',...
        'MarginLeft',0.5);
    ax_press = EasyPlot.createAxesAgainstAxes(fig_peth,ax_lift_highest,'right',...
        'MarginLeft',0.5);
    ax_raster = EasyPlot.createAxesAgainstAxes(fig_peth,ax_press,'right',...
        'MarginLeft',0.8);

    params_lift.pre = 1000;
    params_lift.post = 1000;
    params_lift.binwidth = 20;
    params_press.pre = 1500;
    params_press.post = 500;
    params_press.binwidth = 20;

    [psth_lift,t_psth_lift] = jpsth(r.Units.SpikeTimes(unit_num).timings,lift_times',params_lift);
    [psth_lift_highest,t_psth_lift_highest] = jpsth(r.Units.SpikeTimes(unit_num).timings,highest_time,params_lift);
    [psth_press,t_psth_press] = jpsth(r.Units.SpikeTimes(unit_num).timings,press_times',params_press);
    psth_lift = smoothdata(psth_lift,'gaussian',5);
    psth_lift_highest = smoothdata(psth_lift_highest,'gaussian',5);
    psth_press = smoothdata(psth_press,'gaussian',5);

    plot(ax_lift_start,t_psth_lift,psth_lift);
    xline(ax_lift_start,0);
    title(ax_lift_start,'Lift')
    xlabel(ax_lift_start,'Time from lift (ms)')
    ylabel(ax_lift_start, 'Firing rate (Hz)')

    plot(ax_lift_highest,t_psth_lift_highest,psth_lift_highest);
    xline(ax_lift_highest,0);
    title(ax_lift_highest,'Lift highest')
    xlabel(ax_lift_highest,'Time from lift highest (ms)')

    plot(ax_press,t_psth_press,psth_press);
    xline(ax_press,0);
    title(ax_press,'Press')
    xlabel(ax_press,'Time from press (ms)')
    EasyPlot.setYLim({ax_lift_start,ax_lift_highest,ax_press});
    
    [~, idx_sorted] = sort(highest_time'-lift_times);
    for k = 1:length(idx_sorted)
        highest_time_this = highest_time(idx_sorted(k));
        start_time_this = lift_times(idx_sorted(k));
        press_time_this = press_times(idx_sorted(k));

        spk_time = r.Units.SpikeTimes(unit_num).timings(start_time_this-params_lift.pre<=r.Units.SpikeTimes(unit_num).timings &...
            start_time_this+params_lift.post>=r.Units.SpikeTimes(unit_num).timings);
        spk_time = spk_time - start_time_this;
        if ~isempty(spk_time)
            numspikes=length(spk_time);
            xx=ones(3*numspikes,1)*nan;
            yy=ones(3*numspikes,1)*nan;
    
            yy(1:3:3*numspikes)=-0.5+k;
            yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
            xx(1:3:3*numspikes)=spk_time;
            xx(2:3:3*numspikes)=spk_time;     
            
            plot(ax_raster,xx,yy,'-k');  
        end
        t_highest_this = highest_time_this-start_time_this;
        t_press_this = press_time_this-start_time_this;
        plot(ax_raster,[t_highest_this,t_highest_this],[-0.5+k,0.5+k],'-','Color','m');
        plot(ax_raster,[t_press_this,t_press_this],[-0.5+k,0.5+k],'-','Color','g');
    end
    xlim(ax_raster, [-params_lift.pre, params_lift.post]);
    ylim(ax_raster, [0.5, length(vid_press_idx)+0.5]);
    ylabel(ax_raster, 'Trials')
    xlabel(ax_raster, 'Time from lift start (ms)')
    title('Raster')

    %% Figure B
    ax_traj = EasyPlot.createAxesAgainstAxes(fig_peth,ax_lift_start,'bottom',...
        'MarginTop',1,...
        'MarginBottom',0.8,...
        "MarginLeft",1,...
        'YDir','reverse',...
        'Height',5,...
        'Width',5);
    ax_traj.XAxis.Visible = 'off';
    ax_traj.YAxis.Visible = 'off';
    
    ax_yt = EasyPlot.createAxesAgainstAxes(fig_peth, ax_traj,'right',...
        'Width',5,...
        'MarginLeft',2.3,...
        'YDir','reverse');
    
    % traj
    vid_obj = VideoReader(vid_path);
    bg = vid_obj.read(round(-r.VideoInfos_side(example_idx).t_pre/10));
    image(ax_traj, bg);
    xlim(ax_traj, [0,size(bg,2)])
    ylim(ax_traj, [0,size(bg,1)])
    title(ax_traj, [...
        r.Meta(1).Subject,' ',...
        datestr(r.Meta(1).DateTime,'yyyymmdd'),...
        ' Unit ',num2str(unit_num)]);
    
    for k = 1:length(vid_press_idx)
        colors_this = colors(fr_mapping(firing_rate_all{k}, max_fr, min_fr, colors_num),:);
        s = scatter(ax_traj,traj_all{k}(1,:),...
            traj_all{k}(2,:),...
            marker_size,...
            colors_this,'filled');
        alpha(s, alpha_point);
    end
    
    % yt
    for k = 1:length(vid_press_idx)
        colors_this = colors(fr_mapping(firing_rate_all{k}, max_fr, min_fr, colors_num),:);
        s = scatter(ax_yt,t_all{k},...
            traj_all{k}(2,:),...
            marker_size,...
            colors_this,'filled');
        alpha(s, alpha_point);
    end

    EasyPlot.colorbar(ax_yt,...
        "label",'Normalized firing rate',...
        'MarginRight',0.8);
    ylabel(ax_yt, 'Y (pixels)');
    xlabel(ax_yt, 'Time from lift highest (ms)');
    ax_yt.Position(3) = 5;
    
    EasyPlot.cropFigure(fig_peth);

    %% Save Figure
    if strcmp(save_fig,'on')
        if ~exist(save_dir,'dir')
            mkdir(save_dir)
        end
        EasyPlot.exportFigure(fig_peth,fullfile(save_dir,['Fig01_LiftPETHUnit',num2str(unit_num)]),'type','png','dpi',1200);
%         EasyPlot.exportFigure(fig_peth,fullfile(save_dir,['Fig01_LiftPETHUnit',num2str(unit_num)]),'type','eps','dpi',1200);
    end

end

function out = fr_mapping(fr, max_fr, min_fr, colors_num)
    out = (fr-min_fr)/(max_fr-min_fr);
    out(out<0) = 0;
    out(out>1) = 1;
    out = round(out*(colors_num-1)+1);
end