press_idx_1 = [];
press_idx_2 = [];
for k = 1:length(press_idx)
    for j = 1:length(traj_all{k})
        if roi_pos.inROI(traj_all{k}(1,j),traj_all{k}(2,j))
            press_idx_1 = [press_idx_1,press_idx(k)];
            break;
        end
    end
    press_idx_2 = [press_idx_2,press_idx(k)];
end

PlotComparing(r,unit_num,{press_idx_1,press_idx_2},{'In ROI', 'Not in ROI'},[],...
    't_pre',-1000,...
    't_post',500,...
    'ntrial_raster',2,...
    'video_path','D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\',...
    'save_fig','off');