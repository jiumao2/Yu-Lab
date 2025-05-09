function PlotComparingTrajPSTHAll(r_path,r_all,num_unit,varargin)
    event = 'Press';
    t_pre = r.VideoInfos(1).t_pre;
    t_post = r.VideoInfos(1).t_post;
    binwidth = 20;

    if nargin>=3
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'event'
                    event = varargin{i+1};
                case 't_pre'
                    t_pre = varargin{i+1};
                case 't_post'
                    t_post =  varargin{i+1};
                case 'binwidth'
                    binwidth =  varargin{i+1};    
                otherwise
                    errordlg('unknown argument')
            end
        end
    end

    reference_time = zeros(length(r_path,1));
    for k = 1:length(r_path)
        load(['TrackingAnalysis/',r_path{k}])
        reference_time(k) = getReferenceTime(r); % ms
    end
    % Merge r.Units & r.VideoInfos
    r_new = r;


    ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
    cat = [r.VideoInfos.Trajectory];
    num_traj = max(cat(:))-1;
    colors = colororder;
    colors(num_traj+1,:) = [0.5,0.5,0.5];

    % parameters
    rasterheight = 0.04; % cm
    line_width = 1;
    axes_width = 10;
    axes_height = 5;

    h = figure;
    ax_group = cell(2*(num_traj+2),1);
    for k = 1:2*(num_traj+2)
        ax = axes('Units','centimeters','Position',[1+mod(k,2)*axes_width,1+ceil(k/2-1)*axes_height,axes_width-1,axes_height-1]);
        hold(ax,'on');
        ax_group{2*(num_traj+2)+1-k} = ax;
    end

    FP_correct = [r.VideoInfos(ind_correct).Foreperiod];
    index_long_correct = FP_correct == 1500;
    index_short_correct = FP_correct == 750;

    ylim_max = 0;
    for k = 1:num_traj+1
        ind_traj_long = ind_correct(cat==k & index_long_correct);
        ind_traj_short = ind_correct(cat==k & index_short_correct);

        params_long.pre = -t_pre;
        params_long.post = t_post;
        params_long.binwidth = binwidth;
        params_short.pre = -t_pre;
        params_short.post = t_post;
        params_short.binwidth = binwidth;

        ax = ax_group{2*k-1};
        hold on
        spxtimes_long = [];
        trigtimes_long = [];

        for j = 1:length(ind_traj_long)
            if strcmp(event,'Press')
                trigtimes_long = [trigtimes_long,r.VideoInfos(ind_traj_long(j)).Time];
            elseif strcmp(event,'Release')
                trigtimes_long = [trigtimes_long,r.VideoInfos(ind_traj_long(j)).Time+r.VideoInfos(ind_traj_long(j)).ReactTime];
            end
            temp_spktime = getPlotSpikeTime(r.Units.SpikeTimes(num_unit).timings,trigtimes_long(end),t_pre,t_post);
            for i = 1:length(temp_spktime)
                plot(ax,[1,1]*temp_spktime(i),[j-0.5,j+0.5],'-','Color',colors(k,:))
            end
        end
        xlim(ax,[r.VideoInfos(k).t_pre,r.VideoInfos(k).t_post])
        ylim(ax,[0.5,length(ind_traj_long)+0.5])
        yticks(ax,length(ind_traj_long));
        if k == 1
            ylabel(ax,'Trial')
            title(ax,'FP = 1500 ms')
        end
        ax.Units = 'centimeters';
        ax.Position(4) = length(ind_traj_long)*rasterheight;

        ax = ax_group{2*k};
        hold on
        spxtimes_short = [];
        trigtimes_short = [];

        for j = 1:length(ind_traj_short)
            if strcmp(event,'Press')
                trigtimes_short = [trigtimes_short,r.VideoInfos(ind_traj_short(j)).Time];
            elseif strcmp(event,'Release')
                trigtimes_short = [trigtimes_short,r.VideoInfos(ind_traj_short(j)).Time+r.VideoInfos(ind_traj_short(j)).ReactTime];
            end
            temp_spktime = getPlotSpikeTime(r.Units.SpikeTimes(num_unit).timings,trigtimes_short(end),t_pre,t_post);
            for i = 1:length(temp_spktime)
                plot(ax,[1,1]*temp_spktime(i),[j-0.5,j+0.5],'-','Color',colors(k,:))
            end
        end
        xlim(ax,[r.VideoInfos(k).t_pre,r.VideoInfos(k).t_post])
        ylim(ax,[0.5,length(ind_traj_short)+0.5])
        yticks(ax,length(ind_traj_short));
        if k == 1
            title(ax,'FP = 750 ms')
        end

        ax.Units = 'centimeters';
        ax.Position(4) = length(ind_traj_short)*rasterheight;

        ax = ax_group{2*(num_traj+1)+1};
        hold on
        [psth_long, tpsth_long] = jpsth(r.Units.SpikeTimes(num_unit).timings, trigtimes_long', params_long);
        psth_long = smoothdata(psth_long,'gaussian',5);

        plot(ax,tpsth_long,psth_long,'LineWidth',line_width,'Color',colors(k,:))
        xlabel(ax,['Time relative to ',event,' (ms)'])
        ylabel(ax,'Firing Rate (Hz)')
        title(ax,'PSTH')
        xlim(ax,[r.VideoInfos(k).t_pre,r.VideoInfos(k).t_post])
        temp = get(ax,'YLim');
        if ylim_max < temp(2)
            ylim_max = temp(2);
        end

        ax.Units = 'centimeters';

        ax =ax_group{2*(num_traj+1)+2};
        hold on
        [psth_short, tpsth_short] = jpsth(r.Units.SpikeTimes(num_unit).timings, trigtimes_short', params_short);
        psth_short = smoothdata(psth_short,'gaussian',5);

        plot(ax,tpsth_short,psth_short,'LineWidth',line_width,'Color',colors(k,:))
        xlabel(ax,['Time relative to ',event,' (ms)'])
        title(ax,'PSTH')
        xlim(ax,[r.VideoInfos(k).t_pre,r.VideoInfos(k).t_post])
        temp = get(ax,'YLim');
        if ylim_max < temp(2)
            ylim_max = temp(2);
        end

        ax.Units = 'centimeters';

    end

    ax = ax_group{2*(num_traj+1)+1};
    ylim(ax,[0,ylim_max]);
    ax = ax_group{2*(num_traj+1)+2};
    ylim(ax,[0,ylim_max]);

    % reorder
    ax = ax_group{2*(num_traj+1)+1};
    ax.Units = 'centimeters';
    h1 = ax.Position(2) + ax.Position(4) + 1;
    h2 = ax.Position(2) + ax.Position(4) + 1;
    for k = num_traj+1:-1:1
        ax1 = ax_group{2*k-1};
        ax1.Units = 'centimeters';
        ax1.Position(2) = h1;
        h1 = h1 + ax1.Position(4) + 0.5;

        ax2 = ax_group{2*k};
        ax2.Units = 'centimeters';
        ax2.Position(2) = h2;
        h2 = h2 + ax2.Position(4) + 0.5;
    end

    h.Units = 'Centimeters';
    h.Position(3) = 2*axes_width+1;
    h.Position(4) = max(h1,h2)+0.5;
    saveas(gcf,['Fig/TrajComparing_Unit',num2str(num_unit),'_',event,'.png']);
end