function plotHandPreferenceTime(r)

    window = 10; % in minutes
    min_trials = 3; % preference would be NaN if trial number in a window is less than this number

    t_all = [];
    hand_all = [];
    for k = 1:length(r.VideoInfos_side)
        if strcmpi(r.VideoInfos_side(k).Performance, 'Others')
            continue
        end
        hand = r.VideoInfos_side(k).Hand;
        t = r.VideoInfos_side(k).Time;
        if ~isempty(hand)
            if strcmpi(hand, 'Left')
                hand_all = [hand_all, 1];
            else
                hand_all = [hand_all, 0];
            end
            t_all = [t_all, t];
        end
    end

    t_all = t_all/1000/60; % min
    
    t = 0:1:max(t_all);
    left_hand_rate = zeros(size(t));
    for k = 1:length(left_hand_rate)
        t0 = max(0,t(k)-window/2);
        t1 = min(t(end), t(k)+window/2);
        idx = find(t_all>t0 & t_all<t1);
        left_counts = sum(hand_all(idx)==1);
        right_counts = sum(hand_all(idx)==0);

        if left_counts+right_counts<min_trials
            left_hand_rate(k) = NaN;
        else
            left_hand_rate(k) = left_counts/(left_counts+right_counts);
        end
    end
    
    fig = EasyPlot.figure();
    ax = EasyPlot.axes(fig,...
        'MarginLeft',0.8,...
        'Width',6,...
        'Height',3);

    ax_all = cell(1, length(r.Meta));
    plot(ax, t_all, hand_all,'x');
    plot(ax, t, left_hand_rate, 'b-', 'LineWidth', 2);
    ylim(ax, [-0.1, 1.1]);
    xlim(ax, [0, get_t_end_session(r, length(r.Meta))/1000/60]);

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

    EasyPlot.setYLabelRow(ax_all, 'Rate of left-hand press');

    EasyPlot.setGeneralXLabel(ax_all, 'Time from session starts (min)');
    EasyPlot.setGeneralTitle(ax_all, [r.Meta(1).Subject, ' ', datestr(r.Meta(1).DateTime,'yyyymmdd')]);

    EasyPlot.cropFigure(fig);
    EasyPlot.exportFigure(fig, ['HandPreference_', r.Meta(1).Subject, '_', datestr(r.Meta(1).DateTime,'yyyymmdd')]);
end





