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
    marker_size = 50;
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

    idx_all = [r.VideoInfos_side.Index];
    vid_press_idx = findSeq(idx_all,press_indexes);

    firing_rate_all_flattened = [];
    firing_rate_all = cell(length(press_indexes),1);
    traj_all = cell(length(press_indexes),1);
    frame_num_all = zeros(1,length(press_indexes));

    firing_rate_threshold = -0.1;
    [spike_counts, t_spike_counts] = bin_timings(r.Units.SpikeTimes(unit_num).timings, binwidth);
    spike_counts_all = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000;
    for k = 1:length(vid_press_idx)
        frame_num_temp = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum-n_pre_framenum:round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10);
        [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp));
        frame_num = frame_num_temp(1:i_maxy+n_post_framenum);
        frame_num_all(k) = length(frame_num);

        times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
        traj_all{k} = [r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
            r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num)]';

        firing_rate_this = getFiringRate_spike_train(spike_counts_all,t_spike_counts,times_this,binwidth);
        firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_this];
        firing_rate_all{k} = firing_rate_this;
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
    % plot(ax0,mean_traj(1,:),mean_traj(2,:),'r.-','MarkerSize',20)
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
    %% Hypothesis 1: fire at a fixed duration from lift (same information as PETH)
    h_h1 = figure('Renderer','opengl');
    ax_h1 = axes(h_h1,'NextPlot','add','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)]);
    title(ax_h1,'PETH')
    image(ax_h1,bg);
    set(ax_h1,'YDir','reverse')
    ax_h1.XAxis.Visible = 'off';ax_h1.YAxis.Visible = 'off';
    c_h1 = colorbar(ax_h1);
    ylabel(c_h1,'Normalized firing rate','FontSize',10);

    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax_h1,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
            traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');  
        alpha(s,0.1);
    end

    firing_rate_all_mat = nan*zeros(length(firing_rate_all),round(mean(frame_num_all)));
    for k = 1:length(firing_rate_all)
        if length(firing_rate_all{k})>round(mean(frame_num_all))
            firing_rate_all_mat(k,:) = firing_rate_all{k}(1:round(mean(frame_num_all)));
        else
            firing_rate_all_mat(k,1:length(firing_rate_all{k})) = firing_rate_all{k};
        end
    end
    firing_rate_all_mat_mean = mean(firing_rate_all_mat,'omitnan');
    firing_rate_all_mat_mean = (firing_rate_all_mat_mean-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_all_mat_mean(firing_rate_all_mat_mean>1)=1;firing_rate_all_mat_mean(firing_rate_all_mat_mean<0)=0;
    scatter(ax_h1,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_all_mat_mean*(colors_num-1)+1),:),'filled');

    disp(['Hypothesis 1: ',num2str(max(firing_rate_all_mat_mean))]);
    %% Hypothesis 2: fire at a certain position (heat map)
    h_h2 = figure('Renderer','opengl');
    ax_h2 = axes(h_h2,'NextPlot','add','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)]);
    image(ax_h2,bg);
    title(ax_h2,'Position')
    set(ax_h2,'YDir','reverse','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)])
    ax_h2.XAxis.Visible = 'off';ax_h2.YAxis.Visible = 'off';
    colorbar(ax_h2);
    c_h2 = colorbar(ax_h2);
    ylabel(c_h2,'Normalized firing rate','FontSize',10);

    gaussian_kernel = 100;

    h_h2_heatmap = figure('Renderer','opengl');
    ax_h2_heatmap = axes(h_h2_heatmap,'NextPlot','add');
    set(ax_h2_heatmap,'YDir','reverse')
    ax_h2_heatmap.XAxis.Visible = 'off';ax_h2_heatmap.YAxis.Visible = 'off';
    colorbar(ax_h2_heatmap,'Limits',[0,1]);
    x = 1:5:904;
    y = 1:5:800;
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

    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax_h2,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
            traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');  
        alpha(s,0.1)
    end

    firing_rate_pos = zeros(1,round(mean(frame_num_all)));
    pos_length = zeros(1,round(mean(frame_num_all)));
    % for k = 1:round(mean(frame_num_all))
    %     firing_rate_pos(k) = getGraphFiringRate(mean_traj(1,k),mean_traj(2,k),traj_all,firing_rate_all,gaussian_kernel);
    % end

    firing_rate_pos_cell = cell(1,round(mean(frame_num_all)));
    for k = 1:round(mean(frame_num_all))
        firing_rate_pos_cell{k} = [];
    end
    for k = 1:length(traj_all)
        for j = 1:length(traj_all{k})
            [~,idx] = min(sum((mean_traj-traj_all{k}(:,j)).^2));
            firing_rate_pos_cell{idx} = [firing_rate_pos_cell{idx},firing_rate_all{k}(j)];
        end
    end
    for k = 1:round(mean(frame_num_all))
        pos_length(k) = length(firing_rate_pos_cell{k});
        if isempty(firing_rate_pos_cell{k})
            firing_rate_pos(k) = firing_rate_pos(k-1);
        else
            firing_rate_pos(k) = mean(firing_rate_pos_cell{k});
        end
    end

    firing_rate_pos = (firing_rate_pos-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_pos(firing_rate_pos>1)=1;firing_rate_pos(firing_rate_pos<0)=0;
    scatter(ax_h2,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_pos*(colors_num-1)+1),:),'filled');   

    h_h2_2 = figure();
    ax_h2_2 = axes(h_h2_2,'NextPlot','add');
    yyaxis(ax_h2_2,'left');
    bar(ax_h2_2,pos_length);
    ylabel('Number of points')
    set(ax_h2_2,'ycolor','k');
    yyaxis(ax_h2_2,'right');
    plot(ax_h2_2,firing_rate_pos,'x-');
    ylabel('Normalized firing rate');
    set(ax_h2_2,'ycolor','k');

    disp(['Hypothesis 2: ',num2str(max(firing_rate_pos))]);
    %% Hypothesis 3: fire at a percentage of trajectory (warped PETH)
    h_h3 = figure('Renderer','opengl');
    ax_h3 = axes(h_h3,'NextPlot','add','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)]);
    colorbar(ax_h3);
    c_h3 = colorbar(ax_h3);
    ylabel(c_h3,'Normalized firing rate','FontSize',10);
    image(ax_h3,bg);
    title(ax_h3,'warped PETH')
    set(ax_h3,'YDir','reverse')
    ax_h3.XAxis.Visible = 'off';ax_h3.YAxis.Visible = 'off';

    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax_h3,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
            traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');
        alpha(s,0.1)
    end

    [~, traj_all_resized, firing_rate_all_resized] = getMeanTrajectory(traj_all, round(mean(frame_num_all)), firing_rate_all);
    firing_rate_all_resized_mean = mean(firing_rate_all_resized,2);    

    firing_rate_all_resized_mean = (firing_rate_all_resized_mean-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_all_resized_mean(firing_rate_all_resized_mean>1)=1;firing_rate_all_resized_mean(firing_rate_all_resized_mean<0)=0;
    scatter(ax_h3,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_all_resized_mean*(colors_num-1)+1),:),'filled');    
    disp(['Hypothesis 3: ',num2str(max(firing_rate_all_resized_mean))]);
    %% Hypothesis 4: fire at a fixed duration from lift highest
    h_h4 = figure('Renderer','opengl');
    ax_h4 = axes(h_h4,'NextPlot','add','XLim',[0,size(bg,2)],'YLim',[0,size(bg,1)]);
    title(ax_h4,'PETH (highest)')
    image(ax_h4,bg);
    set(ax_h4,'YDir','reverse')
    ax_h4.XAxis.Visible = 'off';ax_h4.YAxis.Visible = 'off';
    c_h4 = colorbar(ax_h4);
    ylabel(c_h4,'Normalized firing rate','FontSize',10);

    for k = 1:length(vid_press_idx)
        firing_rate_this = firing_rate_all{k};
        firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
        firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
        colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
        s = scatter(ax_h4,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
            traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
            marker_size,...
            colors_this(firing_rate_this>firing_rate_threshold,:),'filled');  
        alpha(s,0.1);
    end

    firing_rate_all_mat2 = nan*zeros(length(firing_rate_all),round(mean(frame_num_all)));
    for k = 1:length(firing_rate_all)
        if length(firing_rate_all{k})>round(mean(frame_num_all))
            firing_rate_all_mat2(k,:) = firing_rate_all{k}(end-round(mean(frame_num_all))+1:end);
        else
            firing_rate_all_mat2(k,end-length(firing_rate_all{k})+1:end) = firing_rate_all{k};
        end
    end
    firing_rate_all_mat_mean2 = mean(firing_rate_all_mat2,'omitnan');
    firing_rate_all_mat_mean2 = (firing_rate_all_mat_mean2-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_all_mat_mean2(firing_rate_all_mat_mean2>1)=1;firing_rate_all_mat_mean2(firing_rate_all_mat_mean2<0)=0;
    scatter(ax_h4,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_all_mat_mean2*(colors_num-1)+1),:),'filled');

    disp(['Hypothesis 4: ',num2str(max(firing_rate_all_mat_mean2))]);
    %% Comparing
    [max_h1,idx_max_h1] = max(firing_rate_all_mat_mean);
    [max_h2,idx_max_h2] = max(firing_rate_pos);
    [max_h3,idx_max_h3] = max(firing_rate_all_resized_mean);
    [max_h4,idx_max_h4] = max(firing_rate_all_mat_mean2);
    max_h1_points = firing_rate_all_mat(:,idx_max_h1);
    max_h2_points = firing_rate_pos_cell{idx_max_h2};
    max_h3_points = firing_rate_all_resized(idx_max_h3,:);
    max_h4_points = firing_rate_all_mat2(:,idx_max_h4);
    max_h1_points = (max_h1_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
    max_h2_points = (max_h2_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
    max_h3_points = (max_h3_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
    max_h4_points = (max_h4_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
    max_h1_points(max_h1_points>1)=1;
    max_h2_points(max_h2_points>1)=1;
    max_h3_points(max_h3_points>1)=1;
    max_h4_points(max_h4_points>1)=1;
    h_all = figure('Renderer','opengl','Units','centimeters','Position',[10,10,22,9]);
    ax_all_fr = axes(h_all,'NextPlot','add','Units','centimeters','Position',[1,5,3,3]);
    bar([max_h1,max_h2,max_h3,max_h4])
    title(ax_all_fr,'Max firing rate');
    ylim(ax_all_fr,[0,1]);
    ylabel(ax_all_fr,'Normalized firing rate')
    set(ax_all_fr,'XTick',[1,2,3],'XTickLabel',{'H1','H2','H3','H4'})

    ax_all_h1 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[5,1,3,3]);
    histogram(ax_all_h1,max_h1_points,'BinWidth',0.1);
    xlim([0,1])
    title(ax_all_h1,'H1');

    ax_all_h2 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[9,1,3,3]);
    histogram(ax_all_h2,max_h2_points,'BinWidth',0.1);
    xlim([0,1])
    title(ax_all_h2,'H2');

    ax_all_h3 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[13,1,3,3]);
    histogram(ax_all_h3,max_h3_points,'BinWidth',0.1);
    xlim([0,1])
    title(ax_all_h3,'H3');

    ax_all_h4 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[17,1,3,3]);
    histogram(ax_all_h4,max_h4_points,'BinWidth',0.1);
    xlim([0,1])
    title(ax_all_h4,'H4');

    ylim_max = max([ax_all_h1.YLim(2),ax_all_h2.YLim(2),ax_all_h3.YLim(2),ax_all_h4.YLim(2)]);
    ylim(ax_all_h1,[0,ylim_max]);ylim(ax_all_h2,[0,ylim_max]);ylim(ax_all_h3,[0,ylim_max]);ylim(ax_all_h4,[0,ylim_max]);

    ax_all_fr_h1 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[5,5,3,3]);
    plot(10*(0:length(firing_rate_all_mat_mean)-1),firing_rate_all_mat_mean,'b-')
    title(ax_all_fr_h1,'H1');

    ax_all_fr_h2 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[9,5,3,3]);
    plot(10*(0:length(firing_rate_pos)-1),smoothdata(firing_rate_pos,'gaussian',5),'b-')
    title(ax_all_fr_h2,'H2');

    ax_all_fr_h3 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[13,5,3,3]);
    plot(10*(0:length(firing_rate_all_resized_mean)-1),firing_rate_all_resized_mean,'b-')
    title(ax_all_fr_h3,'H3');

    ax_all_fr_h4 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[17,5,3,3]);
    plot(10*(0:length(firing_rate_all_resized_mean)-1),firing_rate_all_resized_mean,'b-')
    title(ax_all_fr_h4,'H4');

    ylim_max = max([ax_all_fr_h1.YLim(2),ax_all_fr_h2.YLim(2),ax_all_fr_h3.YLim(2),ax_all_fr_h4.YLim(2)]);
    ylim(ax_all_fr_h1,[0,ylim_max]);ylim(ax_all_fr_h2,[0,ylim_max]);ylim(ax_all_fr_h3,[0,ylim_max]);ylim(ax_all_fr_h4,[0,ylim_max]);
    %% Save Figure
    if strcmp(save_fig,'on')
        print(h0,fullfile(save_dir,'traj_all'),'-dpng',['-r',num2str(save_resolution)])
        print(h_lift,fullfile(save_dir,'PETH'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h1,fullfile(save_dir,'time'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h2,fullfile(save_dir,'position'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h2_heatmap,fullfile(save_dir,'position_heatmap'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h2_2,fullfile(save_dir,'position_points_number'),'-dpng',['-r',num2str(save_resolution)])
        print(h_h3,fullfile(save_dir,'warped_time','-dpng'),['-r',num2str(save_resolution)])
        print(h_h4,fullfile(save_dir,'time (highest)'),'-dpng',['-r',num2str(save_resolution)])
        print(h_all,fullfile(save_dir,'comparison'),'-dpng',['-r',num2str(save_resolution)])
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