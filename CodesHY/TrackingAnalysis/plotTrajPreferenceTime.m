function plotTrajPreferenceTime(r, trajNotes)
    if nargin<2
        trajNotes = {'RL', 'LR'}; 
    end

    window = 10; % in minutes
    min_trials = 3; % preference would be NaN if trial number in a window is less than this number
    n_traj = length(trajNotes);

    t_all = [];
    traj_all_pre = [];
    traj_all_post = [];
    for k = 1:length(r.VideoInfos_top)
        traj = r.VideoInfos_top(k).Trajectory;
        t = r.VideoInfos_top(k).Time;
        if ~isempty(traj)
            if traj<=n_traj
                traj_all_pre = [traj_all_pre, trajNotes{traj}(1)=='R'];
                traj_all_post = [traj_all_post, trajNotes{traj}(2)=='L'];
            else
                traj_all_pre = [traj_all_pre, NaN];
                traj_all_post = [traj_all_post, NaN];
            end
            t_all = [t_all, t];
        end
    end

    t_all = t_all/1000/60; % min
    
    t = 0:1:max(t_all);
    left_turn_rate_pre = zeros(size(t));
    left_turn_rate_post = zeros(size(t));
    left_turn_rate_all = zeros(size(t));
    for k = 1:length(left_turn_rate_all)
        t0 = max(0,t(k)-window/2);
        t1 = min(t(end), t(k)+window/2);
        idx = find(t_all>t0 & t_all<t1);
        traj0_counts_pre = sum(traj_all_pre(idx)==0);
        traj0_counts_post = sum(traj_all_post(idx)==0);
        traj1_counts_pre = sum(traj_all_pre(idx)==1);
        traj1_counts_post = sum(traj_all_post(idx)==1);

        traj0_counts = traj0_counts_pre+traj0_counts_post;
        traj1_counts = traj1_counts_pre+traj1_counts_post;

        if traj0_counts_pre+traj1_counts_pre<min_trials
            left_turn_rate_pre(k) = NaN;
        else
            left_turn_rate_pre(k) = traj1_counts_pre/(traj0_counts_pre+traj1_counts_pre);
        end

        if traj0_counts_post+traj1_counts_post<min_trials
            left_turn_rate_post(k) = NaN;
        else
            left_turn_rate_post(k) = traj1_counts_post/(traj0_counts_post+traj1_counts_post);
        end

        if traj0_counts+traj1_counts<min_trials*2
            left_turn_rate_all(k) = NaN;
        else
            left_turn_rate_all(k) = traj1_counts/(traj0_counts+traj1_counts);
        end
    end
    
    fig = EasyPlot.figure();
    ax = EasyPlot.createGridAxes(fig,3,1,...
        'MarginLeft',0.8,...
        'Width',6,...
        'Height',3);
    
    traj_all = {traj_all_pre, traj_all_post, (traj_all_pre+traj_all_post)./2};
    rate_all = {left_turn_rate_pre, left_turn_rate_post, left_turn_rate_all};
    ylabel_all = {'approach', 'leave', 'all'};

    ax_all = cell(length(ax), length(r.Meta));
    for i_ax = 1:length(ax)
        plot(ax{i_ax}, t_all, traj_all{i_ax},'x');
        plot(ax{i_ax}, t, rate_all{i_ax}, 'b-', 'LineWidth', 2);
%         ylim(ax{i_ax}, [-0.1, 1.1]);
        xlim(ax{i_ax}, [0, get_t_end_session(r, length(r.Meta))/1000/60]);

        ax_all{i_ax, 1} = ax{i_ax};
        blk_duration = zeros(1,length(r.Meta));
        for k = 1:length(r.Meta)
            blk_duration(k) = get_t_end_session(r,k) - get_t_start_session(r,k);
        end
        
        for k = 1:length(r.Meta)-1
            [ax_all{i_ax, k}, ax_all{i_ax, k+1}] = EasyPlot.truncAxis(ax_all{i_ax, k},...
                "X", [get_t_end_session(r,k)/1000/60, get_t_start_session(r,k+1)/1000/60],...
                'Xratio', blk_duration(k)./sum(blk_duration(k+1:end)),...
                'truncRatio', 0.2/ax_all{i_ax, k}.Position(3));
        end

        EasyPlot.setYLabelRow(ax_all(i_ax,:), ['Rate of left turn (', ylabel_all{i_ax}, ')']);
    end
    EasyPlot.setGeneralXLabel(ax_all(length(ax),:), 'Time from session starts (min)');
    EasyPlot.setGeneralTitle(ax_all(1,:), [r.Meta(1).Subject, ' ', datestr(r.Meta(1).DateTime,'yyyymmdd')]);
    
    EasyPlot.HideXAxis(ax_all(1:end-1, :));
    EasyPlot.cropFigure(fig);
    EasyPlot.exportFigure(fig, ['TrajPreference_', r.Meta(1).Subject, '_', datestr(r.Meta(1).DateTime,'yyyymmdd')]);
end





