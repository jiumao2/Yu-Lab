load RTarrayAll.mat

press_indexes = getIndexVideoInfos(r,'Hand','Left','LiftStartTimeLabeled','On','Trajectory',1);
unit_num = 1;
vid=VideoReader(['./VideoFrames_side/RawVideo/Press',num2str(press_indexes(1),'%03d'),'.avi']);
bg = vid.read(1);
TrajectoryCell(r,unit_num,press_indexes,bg,'save_fig','on',...
    'color_max_percentage',1.00,...
    'n_post_framenum',20,...
    'n_pre_framenum',20,...
    'save_dir',['./Fig/Lift_cell_unit_',num2str(unit_num)]);
