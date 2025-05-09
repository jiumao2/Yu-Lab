function PlotComparing(r, unit_num, comparing_type_indexes, comparing_type_names, example_indexes, varargin)
% comparing_type_indexes: 1xn cell
% comparing_type_names: 1xn cell
% example_indexes: 1xn cell (optional)
    save_filename_png = ['Fig/HandComparing_Unit',num2str(unit_num),'.png'];
    save_resolution = 1200;
    t_pre = -1000;
    t_post = 500;
    binwidth_PSTH = 20;
    gaussian_kernel_width = 25;   
    ntrial_raster = NaN; 
    video_path = '.\VideoFrames_side\RawVideo\';
    save_fig = 'on';
    if nargin>=6
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 't_pre'
                    t_pre = varargin{i+1};
                case 't_post'
                    t_post =  varargin{i+1};
                case 'binwidth_PSTH'
                    binwidth_PSTH =  varargin{i+1};  
                case 'ntrial_raster'
                    ntrial_raster =  varargin{i+1}; 
                case 'save_filename_png'
                    save_filename_png =  varargin{i+1};
                case 'save_fig'
                    save_fig =  varargin{i+1};
                case 'gaussian_kernel_width'
                    gaussian_kernel_width =  varargin{i+1};
                case 'video_path'
                    video_path =  varargin{i+1};
                otherwise
                    errordlg('unknown argument')
            end
        end
    end
    if isnan(ntrial_raster)
        type_length = zeros(1,length(comparing_type_indexes));
        for k = 1:length(comparing_type_indexes)
            type_length(k) = length(comparing_type_indexes{k});
        end
        ntrial_raster = min(type_length);
    end

    if isempty(example_indexes)
        example_indexes = zeros(length(comparing_type_names),1);
        for k = 1:length(comparing_type_names)
            example_indexes(k) = comparing_type_indexes{k}(1);
        end
    end
    bg = cell(length(example_indexes),1);
    for k = 1:length(example_indexes)
        vid_this = VideoReader(fullfile(video_path,['Press',num2str(example_indexes(k),'%03d'),'.avi']));
        bg{k} = vid_this.read(-r.VideoInfos_side(1).t_pre/10);
    end 
    
    % markersize, linewidth ...
    markersize_top = 0.1;
    markersize_side = 1;
    colors = colororder;
    colors = colors(1:length(comparing_type_names),:);
    linewidth_PSTH = 1;
    %% Figure Configuration
    margin_left = 1;
    margin_right = 0.5;
    margin_up = 0.5;
    margin_bottom = 1;
    space_col_traj = 1;
    space_row_raster = 0.2;
    space_row_traj = 0.2;
    space_col_raster = 1;

    width_traj = 3;
    height_traj = 3;
    width_raster = 3;
    height_raster = 3;
    width_PSTH = 3;
    height_PSTH = 3;

    h = figure('Units','centimeters');
    figure_width = margin_left + margin_right + width_traj*length(comparing_type_names) + space_col_traj*(length(comparing_type_names)-1);
    figure_height = margin_up + margin_bottom + height_traj + height_raster + height_PSTH + space_row_raster + space_row_traj;
    h.Position = [10,10,figure_width,figure_height];
    
    ax_sideview = cell(length(comparing_type_names),1);
    for k = 1:length(comparing_type_names)
        ax_sideview{k} = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
        ax_sideview{k}.Position = [...
            margin_left+width_traj*(k-1)+space_col_traj*(k-1),...
            margin_bottom+space_row_raster+space_row_traj+height_raster+height_PSTH,...
            width_traj,...
            height_traj];
        ax_sideview{k}.XAxis.Visible = 'off';ax_sideview{k}.YAxis.Visible = 'off';
        title(ax_sideview{k},comparing_type_names{k});
        image(ax_sideview{k},bg{k});
        xlim(ax_sideview{k},[0,size(bg{k},2)])
        ylim(ax_sideview{k},[0,size(bg{k},2)])
    end
    
    ax_raster = cell(length(comparing_type_names),1);
    for k = 1:length(comparing_type_names)
        ax_raster{k} = axes(h,'Units','centimeters','NextPlot','add');
        ax_raster{k}.Position = [...
            margin_left+space_col_raster*(k-1)+width_raster*(k-1),...
            margin_bottom+space_row_raster+height_PSTH,...
            width_raster,...
            height_raster];
        ax_raster{k}.YTick = [1,ntrial_raster];
        ax_raster{k}.YLim = [0.5,ntrial_raster+0.5];
        ax_raster{k}.XAxis.Visible = 'off';
        if k == 1
            ylabel(ax_raster{k},'Trials');
        else
            ax_raster{k}.YAxis.Visible = 'off';
        end
        xline(ax_raster{k},0,'-k','LineWidth',1);
    end
    
    ax_PSTH = cell(length(comparing_type_names),1);
    for k = 1:length(comparing_type_names)
        ax_PSTH{k} = axes(h,'Units','centimeters','NextPlot','add');
        ax_PSTH{k}.Position = [...
            margin_left+space_col_raster*(k-1)+width_raster*(k-1),...
            margin_bottom,...
            width_PSTH,...
            height_PSTH];
        if k == 1
            ylabel(ax_PSTH{k},'Firing rate (Hz)');
        else
            ax_PSTH{k}.YAxis.Visible = 'off';
        end
        xlim(ax_PSTH{k},[t_pre,t_post])
        xline(ax_PSTH{k},0,'-k','LineWidth',1);
    end

    annotation(h,'textbox',[0.3,0,.4,.05],'String','Time from press (ms)','EdgeColor','none','FontSize',8.25,'HorizontalAlignment','center','VerticalAlignment','middle');
    %% Plotting
    rand('seed',123);
    % raster
    idx_all = [r.VideoInfos_side.Index];
    rnd_cat = zeros(length(comparing_type_names),ntrial_raster);
    for k = 1:length(comparing_type_names)
        disp(['Length of type ',num2str(k),': ',num2str(length(comparing_type_indexes{k}))])
        temp = randperm(length(comparing_type_indexes{k}));
        rnd_cat(k,:) = comparing_type_indexes{k}(temp(1:ntrial_raster));
    end
    
    for idx_type = 1:length(comparing_type_names)
        rnd_cat_this = rnd_cat(idx_type,:);
        for k = 1:length(rnd_cat_this)
            ind_this = find(idx_all==rnd_cat_this(k));
            spk_time = r.Units.SpikeTimes(unit_num).timings(r.VideoInfos_side(ind_this).Time+t_pre<=r.Units.SpikeTimes(unit_num).timings & r.VideoInfos_side(ind_this).Time+t_post>=r.Units.SpikeTimes(unit_num).timings);
            spk_time = spk_time - r.VideoInfos_side(ind_this).Time;
            if ~isempty(spk_time)
                numspikes=length(spk_time);
                xx=ones(3*numspikes,1)*nan;
                yy=ones(3*numspikes,1)*nan;

                yy(1:3:3*numspikes)=-0.5+k;
                yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
                xx(1:3:3*numspikes)=spk_time;
                xx(2:3:3*numspikes)=spk_time;

                plot(ax_raster{idx_type},xx,yy,'-','Color',colors(idx_type,:)); 
            end
            if isfield(r.VideoInfos_side(ind_this),'LiftStartTime') && ~isnan(r.VideoInfos_side(ind_this).LiftStartTime)
                t_lift_this = r.VideoInfos_side(ind_this).LiftStartTime-r.VideoInfos_side(ind_this).Time;
                plot(ax_raster{idx_type},[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','green');
            end
        end
        xlim(ax_raster{idx_type},[t_pre t_post]);
    end

    % PSTH
    params.pre = -t_pre;
    params.post = t_post;
    params.binwidth = binwidth_PSTH;
    psth = cell(length(comparing_type_names),1);
    tpsth = cell(length(comparing_type_names),1);
    ylim_all = zeros(length(comparing_type_names),1);
    for k = 1:length(comparing_type_names)
        temp_idx = findSeq(idx_all,comparing_type_indexes{k});
        trigtimes = [r.VideoInfos_side(temp_idx).Time];
        [psth{k}, tpsth{k}] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes', params);
        psth{k} = smoothdata (psth{k}, 'gaussian', round(gaussian_kernel_width/5));
        plot(ax_PSTH{k},tpsth{k},psth{k},'Color',colors(k,:),'LineWidth',linewidth_PSTH);
        ylim_all(k) = ax_PSTH{k}.YLim(2);
    end

    ylim_max = max(ylim_all);
    for k = 1:length(comparing_type_names)
        ax_PSTH{k}.YLim = [0,ylim_max];
    end
    
    %% Annotation
    h_annotation_press_text = annotation(h,'textbox',...
        [0.5,0.5,0.5,0.5],...
        'EdgeColor','none',...
        'Units','centimeters',...
        'VerticalAlignment','middle',...
        'String',{'A'},...
        'FontWeight','bold',...
        'HorizontalAlignment','left',...
        'FitBoxToText','off');
    set(h_annotation_press_text,'Position',[-0.1,10.3,0.5,0.5]);

    h_annotation_press_text = annotation(h,'textbox',...
        [0.5,0.5,0.5,0.5],...
        'EdgeColor','none',...
        'Units','centimeters',...
        'VerticalAlignment','middle',...
        'String',{'B'},...
        'FontWeight','bold',...
        'HorizontalAlignment','left',...
        'FitBoxToText','off');
    set(h_annotation_press_text,'Position',[-0.1,6.8,0.5,0.5]);

    h_annotation_press_text = annotation(h,'textbox',...
        [0.5,0.5,0.5,0.5],...
        'EdgeColor','none',...
        'Units','centimeters',...
        'VerticalAlignment','middle',...
        'String',{'C'},...
        'FontWeight','bold',...
        'HorizontalAlignment','left',...
        'FitBoxToText','off');
    set(h_annotation_press_text,'Position',[-0.1,3.6,0.5,0.5]);
    
    %% Save Figure
    switch save_fig
        case 'on'
            if ~exist('./Fig/','dir')
                mkdir('./Fig/');
            end
            print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
    end
end