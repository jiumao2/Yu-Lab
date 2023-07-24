function plotTrajPreferenceTime(r)
    window = 10; % in minutes
    min_trials = 3; % preference would be NaN if trial number in a window is less than this number

    t_all = [];
    traj_all = [];
    for k = 1:length(r.VideoInfos_top)
        traj = r.VideoInfos_top(k).Trajectory;
        t = r.VideoInfos_top(k).Time;
        if ~isempty(traj)
            traj_all = [traj_all, traj];
            t_all = [t_all, t];
        end
    end
    
    traj_all(traj_all==2) = 0;
    traj_all(traj_all==3) = NaN;
    t_all = t_all/1000/60; % min
    
    t = 0:1:max(t_all);
    traj_rate = zeros(size(t));
    for k = 1:length(traj_rate)
        t0 = max(0,t(k)-window/2);
        t1 = min(t(end), t(k)+window/2);
        idx = find(t_all>t0 & t_all<t1);
        traj0_counts = sum(traj_all(idx)==0);
        traj1_counts = sum(traj_all(idx)==1);
        if traj0_counts+traj1_counts<min_trials
            traj_rate(k) = NaN;
        else
            traj_rate(k) = traj1_counts/(traj0_counts+traj1_counts);
        end
    end
    
    fig = EasyPlot.figure();
    ax = EasyPlot.axes(fig,...
        'MarginBottom',0.8,...
        'MarginLeft',0.8,...
        'MarginTop', 0.8,...
        'Width',6,...
        'Height',3);
    
    plot(ax, t_all, traj_all,'x');
    plot(ax, t, traj_rate, 'b-', 'LineWidth', 2);
    ylim(ax, [-0.1, 1.1]);
    xlim(ax, [0, get_t_end_session(r, length(r.Meta))/1000/60]);
    ax_all = cell(1,length(r.Meta));
    ax_all{1} = ax;
    blk_duration = zeros(1,length(r.Meta));
    for k = 1:length(r.Meta)
        blk_duration(k) = get_t_end_session(r,k) - get_t_start_session(r,k);
    end
    
    for k = 1:length(r.Meta)-1
        [ax_all{k}, ax_all{k+1}] = EasyPlot.truncAxis(ax_all{k},...
            "X", [get_t_end_session(r,k)/1000/60, get_t_start_session(r,k+1)/1000/60],...
            'Xratio', blk_duration(k)./sum(blk_duration(k+1:end)),...
            'truncRatio', 0.2/ax_all{k}.Position(3));
    end
    
    EasyPlot.setGeneralXLabel(ax_all, 'Time from session starts (min)');
    EasyPlot.setYLabelRow(ax_all, 'Traj. Preference');
    EasyPlot.setGeneralTitle(ax_all, [r.Meta(1).Subject, ' ', datestr(r.Meta(1).DateTime,'yyyymmdd')]);
    
    EasyPlot.cropFigure(fig);
    EasyPlot.exportFigure(fig, 'TrajPreference');
end





