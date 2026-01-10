function plotExtraTriggerResponse(r, idx_unit)
    press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == 3);
    release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == 5);

    idx_none = find(r.Behavior.TriggerTypes == 1);
    idx_tone_500 = find(r.Behavior.TriggerTypes == 2);
    idx_tone_750 = find(r.Behavior.TriggerTypes == 3);
    idx_tone_1000 = find(r.Behavior.TriggerTypes == 4);

    idx_trials = {idx_none, idx_tone_500, idx_tone_750, idx_tone_1000};
    n_trial_max = max(cellfun(@length, idx_trials));
    t_tone = {NaN, 500, 750, 1000};
    colors = lines(length(idx_trials));
    trial_types = {'None', 'Tone500', 'Tone750', 'Tone1000'};

    spike_times = r.Units.SpikeTimes(idx_unit).timings;

    fig = EasyPlot.figure();
    ax_all = EasyPlot.createGridAxes(fig, 2, length(idx_trials),...
        'Width', 5,...
        'Height', 3);
    EasyPlot.set(ax_all(1,:),...
        'XAxisVisible', 'off',...
        'YDir', 'reverse');
    EasyPlot.set(ax_all(2,:),...
        'MarginBottom', 1,...
        'MarginLeft', 1);

    ax_raster = ax_all(1,:);
    ax_PETH = ax_all(2,:);

    ax_PETH_merged = EasyPlot.createAxesAgainstAxes(fig, ax_PETH{end}, 'right',...
        'Width', 8,...
        'MarginLeft', 1);
    EasyPlot.set(ax_PETH_merged, 'Height', 3 + ax_raster{1}.Position(2) -  ax_PETH{1}.Position(2));
    
    t_pre = -500;
    t_post = 2500;
    
    for i_trial = 1:length(idx_trials)
        press_times_this = press_times(idx_trials{i_trial});
        release_times_this = release_times(idx_trials{i_trial});

        press_times_correct = press_times(intersect(idx_trials{i_trial}, r.Behavior.CorrectIndex));

        [~, idx_sort] = sort(release_times_this - press_times_this);
        press_times_this = press_times_this(idx_sort);
        release_times_this = release_times_this(idx_sort);

        x_plot = [];
        y_plot = [];
        x_plot_release = [];
        y_plot_release = [];
        for k = 1:length(press_times_this)
            t_event = press_times_this(k);
            st = spike_times(spike_times > t_event + t_pre & spike_times < t_event + t_post) - t_event;
            for j = 1:length(st)
                x_plot = [x_plot, st(j), st(j), NaN];
                y_plot = [y_plot, k-0.5, k+0.5, NaN];
            end
        
            x_plot_release = [x_plot_release, release_times_this(k)-t_event, release_times_this(k)-t_event, NaN];
            y_plot_release = [y_plot_release, k-0.5, k+0.5, NaN];
        end
        
        params.pre = -t_pre;
        params.post = t_post;
        params.binwidth = 50;
        [peth, tpeth] = jpsth(spike_times, press_times_correct, params);
    
        plot(ax_raster{i_trial}, x_plot, y_plot, 'k-', 'LineWidth', 1);
        plot(ax_raster{i_trial}, x_plot_release, y_plot_release, 'g-', 'LineWidth', 1);
        xline(ax_raster{i_trial}, 0, 'b:', 'LineWidth', 2);
        
        bar(ax_PETH{i_trial}, tpeth, peth, 'BarWidth', 1, 'FaceColor', 'k');
        xline(ax_PETH{i_trial}, 0, 'b:', 'LineWidth', 2);
        
        ylim(ax_raster{i_trial}, [0.5, 0.5+length(press_times_this)]);
        title(ax_raster{i_trial}, trial_types{i_trial});
        
        peth = smoothdata(peth, 'gaussian', 20./params.binwidth*5);
        plot(ax_PETH_merged, tpeth, peth, '-', 'Color', colors(i_trial,:), 'LineWidth', 1.5);
    end
    %%
    
    xline(ax_raster{1}, 1500, 'm:', 'LineWidth', 2);
    xline(ax_PETH{1}, 1500, 'm:', 'LineWidth', 2);
    xline(ax_raster{2}, [500, 1500], 'm:', 'LineWidth', 2);
    xline(ax_PETH{2}, [500, 1500], 'm:', 'LineWidth', 2);
    xline(ax_raster{3}, [750, 1500], 'm:', 'LineWidth', 2);
    xline(ax_PETH{3}, [750, 1500], 'm:', 'LineWidth', 2);
    xline(ax_raster{4}, [1000, 1500], 'm:', 'LineWidth', 2);
    xline(ax_PETH{4}, [1000, 1500], 'm:', 'LineWidth', 2);
    xline(ax_PETH_merged, 0, 'b:', 'LineWidth', 2);
    xline(ax_PETH_merged, [500,1000,1500], 'm:', 'LineWidth', 2);

    for k = 1:4
        EasyPlot.set(ax_raster{k}, 'Height', length(idx_trials{k})/n_trial_max*ax_raster{k}.Position(4));

        xline(ax_raster{k}, 1500, 'm:', 'LineWidth', 2);
        xline(ax_PETH{k}, 1500, 'm:', 'LineWidth', 2);

        xline(ax_raster{k}, t_tone{k}, ':', 'LineWidth', 2, 'Color', colors(k,:));
        xline(ax_PETH{k}, t_tone{k}, ':', 'LineWidth', 2, 'Color', colors(k,:));
        xline(ax_PETH_merged, t_tone{k}, ':', 'LineWidth', 2, 'Color', colors(k,:));
    end
    xline(ax_PETH_merged, 0, 'b:', 'LineWidth', 2);
    xline(ax_PETH_merged, 1500, 'm:', 'LineWidth', 2);

    EasyPlot.setXLim(ax_all, [t_pre, t_post]);
    EasyPlot.setYLim(ax_PETH);

    xlabel(ax_PETH{1}, 'Time from press (ms)');
    ylabel(ax_PETH{1}, 'Firing rate (Hz)');
    xlabel(ax_PETH_merged, 'Time from press (ms)');
    ylabel(ax_PETH_merged, 'Firing rate (Hz)');
    h = EasyPlot.setGeneralTitle(ax_raster, ...
        [r.Meta(1).Subject, ' ', datestr(r.Meta(1).DateTime, 'yyyymmdd'), ' Unit', num2str(idx_unit)],...
        'fontSize', 10,...
        'fontWeight', 'bold');
    EasyPlot.move(h, 'dy', 0.5);

    EasyPlot.cropFigure(fig);
    
    folder_save = fullfile('./Fig/', 'UnitActivityInEachTrialType');
    if ~exist(folder_save, 'dir')
        mkdir(folder_save);
    end
    
    EasyPlot.exportFigure(fig, fullfile(folder_save,...
        [r.Meta(1).Subject, '_', datestr(r.Meta(1).DateTime, 'yyyymmdd'), '_Unit', num2str(idx_unit)]),...
        'dpi', 600);
end