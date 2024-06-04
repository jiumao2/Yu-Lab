function PlotComparingTrajPSTH(r,num_unit,varargin)
    event = 'Press';
    t_pre = r.VideoInfos_top(1).t_pre;
    t_post = r.VideoInfos_top(1).t_post;
    binwidth = 20;
    session = -1;

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
                case 'session'
                    session = varargin{i+1};
                otherwise
                    errordlg('unknown argument')
            end
        end
    end

    if session~=-1
        t_start = get_t_start_session(r,session);
        t_end = get_t_end_session(r,session);
    end

    ind_correct = find(strcmp({r.VideoInfos_top.Performance},'Correct'));
    cat = [r.VideoInfos_top.Trajectory];

    t_all = [r.VideoInfos_top(ind_correct).Time];
    if session~=-1
        ind_correct = ind_correct(t_all>t_start & t_all<t_end);
        cat = cat(t_all>t_start & t_all<t_end);
    end
    
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

    FP_correct = [r.VideoInfos_top(ind_correct).Foreperiod];
    index_long_correct = FP_correct == 1500;
    index_short_correct = FP_correct == 750;

    ylim_max = 0;
    for k = 1:num_traj+1
        ind_traj_long = ind_correct(cat==k & index_long_correct);
        ind_traj_short = ind_correct(cat==k & index_short_correct);
        ax_group{2*k-1}.Units = 'centimeters';
        ax_group{2*k}.Units = 'centimeters';
        ax_group{2*k-1}.Position(4) = length(ind_traj_long)*rasterheight;
        ax_group{2*k}.Position(4) = length(ind_traj_short)*rasterheight;

        params_long.pre = -t_pre;
        params_long.post = t_post;
        params_long.binwidth = binwidth;
        params_short.pre = -t_pre;
        params_short.post = t_post;
        params_short.binwidth = binwidth;

        if ~isempty(ind_traj_long) 
            ax = ax_group{2*k-1};
            hold on
            spxtimes_long = [];
            trigtimes_long = [];
            
            
            x = [];
            y = [];
            for j = 1:length(ind_traj_long)
                if strcmp(event,'Press')
                    trigtimes_long = [trigtimes_long,r.VideoInfos_top(ind_traj_long(j)).Time];
                elseif strcmp(event,'Release')
                    trigtimes_long = [trigtimes_long,r.VideoInfos_top(ind_traj_long(j)).Time+r.VideoInfos_top(ind_traj_long(j)).Foreperiod+r.VideoInfos_top(ind_traj_long(j)).ReactTime];
                end
                temp_spktime = getPlotSpikeTime(r.Units.SpikeTimes(num_unit).timings,trigtimes_long(end),t_pre,t_post);
                for i = 1:length(temp_spktime)
                    x = [x,temp_spktime(i),temp_spktime(i),NaN];
                    y = [y,j-0.5,j+0.5,NaN];
                end
            end
            plot(ax,x,y,'-','Color',colors(k,:))
    
            xlim(ax,[r.VideoInfos_top(k).t_pre,r.VideoInfos_top(k).t_post])
            ylim(ax,[0.5,length(ind_traj_long)+0.5])
            yticks(ax,length(ind_traj_long));
            if k == 1
                ylabel(ax,'Trial')
                title(ax,'FP = 1500 ms')
            end
        end

        if ~isempty(ind_traj_short) 
            ax = ax_group{2*k};
            hold on
            spxtimes_short = [];
            trigtimes_short = [];
    
    
            x = [];
            y = [];
            for j = 1:length(ind_traj_short)
                if strcmp(event,'Press')
                    trigtimes_short = [trigtimes_short,r.VideoInfos_top(ind_traj_short(j)).Time];
                elseif strcmp(event,'Release')
                    trigtimes_short = [trigtimes_short,r.VideoInfos_top(ind_traj_short(j)).Time+r.VideoInfos_top(ind_traj_short(j)).Foreperiod+r.VideoInfos_top(ind_traj_short(j)).ReactTime];
                end
                temp_spktime = getPlotSpikeTime(r.Units.SpikeTimes(num_unit).timings,trigtimes_short(end),t_pre,t_post);
                for i = 1:length(temp_spktime)
                    x = [x,temp_spktime(i),temp_spktime(i),NaN];
                    y = [y,j-0.5,j+0.5,NaN];
                end
            end
            plot(ax,x,y,'-','Color',colors(k,:))
    
            xlim(ax,[r.VideoInfos_top(k).t_pre,r.VideoInfos_top(k).t_post])
            ylim(ax,[0.5,length(ind_traj_short)+0.5])
            yticks(ax,length(ind_traj_short));
            if k == 1
                title(ax,'FP = 750 ms')
            end
        end
        
        ax = ax_group{2*(num_traj+1)+1};
        hold on
        [psth_long, tpsth_long] = jpsth(r.Units.SpikeTimes(num_unit).timings, trigtimes_long', params_long);
        psth_long = smoothdata(psth_long,'gaussian',5);

        plot(ax,tpsth_long,psth_long,'LineWidth',line_width,'Color',colors(k,:))
        xlabel(ax,['Time relative to ',event,' (ms)'])
        ylabel(ax,'Firing Rate (Hz)')
        title(ax,[r.Meta(1).Subject, ' ', datestr(r.Meta(1).DateTime,'yyyymmdd'), ' Unit ',num2str(num_unit)]);
        xlim(ax,[r.VideoInfos_top(k).t_pre,r.VideoInfos_top(k).t_post])
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

        xlim(ax,[r.VideoInfos_top(k).t_pre,r.VideoInfos_top(k).t_post])
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
    if session == -1
        saveas(gcf,['Fig/TrajComparing_Unit',num2str(num_unit),'_',event,'.png']);
    else
        saveas(gcf,['Fig/TrajComparing_Unit',num2str(num_unit),'_',event,'_Session_',num2str(session),'.png']);
    end
end