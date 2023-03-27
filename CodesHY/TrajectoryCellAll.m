function TrajectoryCellAll(r,varargin)
    save_dir = './Fig/';
    n_post_framenum = 30;
    n_pre_framenum = 30;
    binwidth = 1;
    gaussian_kernel = 25;
    color_max_percentage = 1.00;
    color_min_percentage = 0.00;
    save_fig = 'on';
    traj = 'All';
    if nargin>1
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

    % load firing rate
    idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts, 'left_paw'));
    
    press_indexes = getIndexVideoInfos(r,"LiftStartTimeLabeled","On","Hand","Left","Trajectory",traj);

    idx_all = [r.VideoInfos_side.Index];
    vid_press_idx = findSeq(idx_all,press_indexes);

    fig = EasyPlot.figure();
    ax_yt = EasyPlot.createAxesAgainstFigure(fig,'leftTop',...
        'Width',30,...
        'Height',3,...
        'YDir','reverse',...
        'MarginLeft',1.3,...
        'MarginBottom',1);
    
    for unit_num = 1:length(r.Units.SpikeTimes)
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
    
        % yt
        for k = 1:length(vid_press_idx)
            colors_this = colors(fr_mapping(firing_rate_all{k}, max_fr, min_fr, colors_num),:);
            s = scatter(ax_yt,t_all{k}+unit_num*max(frame_num_all)*10,...
                traj_all{k}(2,:),...
                marker_size,...
                colors_this,'filled');
            alpha(s, alpha_point);
        end
    end
    
    XTickLabel = cell(1,length(r.Units.SpikeTimes));
    for k = 1:length(r.Units.SpikeTimes)
        XTickLabel{k} = sprintf('Unit %d (%c)',k, 's'*(2-r.Units.SpikeNotes(k,3))-'m'*(1-r.Units.SpikeNotes(k,3)));
    end
    ax_yt.XTick = max(frame_num_all)*10*(1:length(r.Units.SpikeTimes));
    ax_yt.XTickLabel = XTickLabel;
    xlim(ax_yt, [0,(length(r.Units.SpikeTimes)+1)*max(frame_num_all)*10]);

    EasyPlot.colorbar(ax_yt,...
        "label",'Normalized firing rate',...
        'MarginRight',0.8);
    ylabel(ax_yt, 'Y (pixels)');
%     ax_yt.Position(3) = 5;
    
    EasyPlot.cropFigure(fig);

    %% Save Figure
    if strcmp(save_fig,'on')
        if ~exist(save_dir,'dir')
            mkdir(save_dir)
        end
        EasyPlot.exportFigure(fig,fullfile(save_dir,'LiftPETHPopulation'),'type','png','dpi',1200);
    end

end

function out = fr_mapping(fr, max_fr, min_fr, colors_num)
    out = (fr-min_fr)/(max_fr-min_fr);
    out(out<0) = 0;
    out(out>1) = 1;
    out = round(out*(colors_num-1)+1);
end