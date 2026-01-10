function plotPureTriggerResponse(r, unit, pure_trigger_times, trigger_types)
    t_pre = -500;
    t_post = 1000;
    binwidth = 30;

    spike_times = r.Units.SpikeTimes(unit).timings;
    
    press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==3);
    release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==5);
    FPs = r.Behavior.Foreperiods;

    if size(FPs, 1) ~= size(press_times, 1)
        FPs = FPs';
    end

    trigger_times = press_times + FPs;
    RTs = release_times - trigger_times;
    
    idx_short = find(FPs == 750);
    idx_long = find(FPs == 1500);
    idx_correct = r.Behavior.CorrectIndex;
    
    trigger_times_short = trigger_times(intersect(idx_correct, idx_short));
    RTs_short = RTs(intersect(idx_correct, idx_short));
    [RTs_short, idx_sort] = sort(RTs_short);
    trigger_times_short = trigger_times_short(idx_sort);
    
    trigger_times_long = trigger_times(intersect(idx_correct, idx_long));
    RTs_long = RTs(intersect(idx_correct, idx_long));
    [RTs_long, idx_sort] = sort(RTs_long);
    trigger_times_long = trigger_times_long(idx_sort);
    
    event_times = [{trigger_times_short}, {trigger_times_long}, pure_trigger_times];
    event_names = [{'FP = 0.75 s'}, {'FP = 1.5 s'}, trigger_types];
    release_times = {RTs_short, RTs_long, [], [], []};
    
    fig = EasyPlot.figure();
    ax_raster = EasyPlot.createGridAxes(fig, 1, length(event_times),...
        'XAxisVisible', 'off',...
        'YAxisVisible', 'off',...
        'Width', 3,...
        'Height', 2);


    ax_PETH = EasyPlot.copyAxes(ax_raster, 'bottom');
    EasyPlot.set(ax_PETH,...
        'Width', 3,...
        'Height', 3,...
        'XAxisVisible', 'on',...
        'YAxisVisible', 'on',...
        'MarginBottom', 1,...
        'MarginLeft', 1);
    EasyPlot.move(ax_PETH, 'dy', -1);

    
    for k = 1:length(event_times)
        event_times_this = event_times{k};
        release_times_this = release_times{k};

        x_plot = [];
        y_plot = [];
        x_plot_rt = [];
        y_plot_rt = [];
        for j = 1:length(event_times_this)
            t_this = event_times_this(j);
            st = spike_times(spike_times > t_this + t_pre ...
                & spike_times < t_this + t_post) - t_this;
            for i = 1:length(st)
                x_plot = [x_plot, st(i), st(i), NaN];
                y_plot = [y_plot, j-0.5, j+0.5, NaN];
            end

            if ~isempty(release_times_this)
                x_plot_rt = [x_plot_rt, release_times_this(j), release_times_this(j), NaN];
                y_plot_rt = [y_plot_rt, j-0.5, j+0.5, NaN];
            end
        end

        plot(ax_raster{k}, x_plot, y_plot, 'k-', 'LineWidth', 1);
        plot(ax_raster{k}, x_plot_rt, y_plot_rt, 'g-', 'LineWidth', 1);

        params.pre = -t_pre;
        params.post = t_post;
        params.binwidth = binwidth;
        [peth, tpeth] = jpsth(spike_times, event_times_this, params);

        bar(ax_PETH{k}, tpeth, peth, 1, 'edgeColor', 'none', 'faceColor', 'k');
        ylim(ax_raster{k}, [0.5, length(event_times_this)+0.5]);

        xline(ax_raster{k}, 0, 'b:', 'LineWidth', 2);
        xline(ax_PETH{k}, 0, 'b:', 'LineWidth', 2);
        
        if k <= 2
            title(ax_raster{k}, event_names{k});
        else
            title(ax_raster{k}, {['t = ', num2str(computeResponseTime(r, unit, event_times{k}))], event_names{k}});
        end
    end

    EasyPlot.setXLim(ax_raster, [t_pre, t_post]);
    EasyPlot.setXLim(ax_PETH, [t_pre, t_post]);
    EasyPlot.setYLim(ax_PETH);

    EasyPlot.xlabel(ax_PETH{1}, 'time from trigger (ms)');
    EasyPlot.ylabel(ax_PETH{1}, 'Firing rate (spk/s)');
    
    h_title = EasyPlot.setGeneralTitle(ax_raster,...
        [r.Meta(1).Subject, ' ', datestr(r.Meta(1).DateTime, 'yyyymmdd'), ' Unit#', num2str(unit)],...
        'fontWeight', 'bold',...
        'fontSize', 10);
    EasyPlot.move(h_title, 'dy', 0.8);

    EasyPlot.cropFigure(fig);

    if ~isfolder('./Fig/')
        mkdir('./Fig/');
    end
    EasyPlot.exportFigure(fig,...
        fullfile('./Fig/', [r.Meta(1).Subject, '_', datestr(r.Meta(1).DateTime, 'yyyymmdd'), '_Unit', num2str(unit)]),...
        'dpi', 300,...
        'type', 'png');
end