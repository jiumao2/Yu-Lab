function idx_out = getIndexVideoInfos(r, varargin)
    Foreperiod = 'Short_Long';
    Hand = 'All';
    Trajectory = 'All';
    Performance = 'Correct';
    LiftStartTimeLabeled = 'Off';
    if nargin>=3
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'Foreperiod'
                    Foreperiod = varargin{i+1};
                case 'Hand'
                    Hand = varargin{i+1};
                case 'Trajectory'
                    Trajectory =  varargin{i+1};
                case 'Performance'
                    Performance =  varargin{i+1};    
                case 'LiftStartTimeLabeled'
                    LiftStartTimeLabeled =  varargin{i+1}; 
                otherwise
                    errordlg('unknown argument')
            end
        end
    end
    
    idx_all = [r.VideoInfos_side.Index];
    
    switch Foreperiod
        case 'All'
            Foreperiod_idx = idx_all;
        case 'Short'
            Foreperiod_idx = idx_all([r.VideoInfos_side.Foreperiod]==750);
        case 'Long'
            Foreperiod_idx = idx_all([r.VideoInfos_side.Foreperiod]==1500);
        case 'Short_Long'
            Foreperiod_idx = idx_all([r.VideoInfos_side.Foreperiod]==750 | [r.VideoInfos_side.Foreperiod]==1500);
        otherwise
            errordlg('unknown argument');
    end
    
    if ~isfield(r.VideoInfos_side, 'Hand')
        warning('Hand is not labelled!');
        Hand_idx = idx_all;
    else
        switch Hand
            case 'All'
                Hand_idx = idx_all;
            case 'Left'
                Hand_idx = idx_all(strcmp({r.VideoInfos_side.Hand},'Left'));
            case 'Right'
                Hand_idx = idx_all(strcmp({r.VideoInfos_side.Hand},'Right'));
            case 'Both'
                Hand_idx = idx_all(strcmp({r.VideoInfos_side.Hand},'Both'));
            case 'Right_Both'
                Hand_idx = idx_all(strcmp({r.VideoInfos_side.Hand},'Right') | strcmp({r.VideoInfos_side.Hand},'Both'));
            case 'Left_Both'
                Hand_idx = idx_all(strcmp({r.VideoInfos_side.Hand},'Left') | strcmp({r.VideoInfos_side.Hand},'Both'));
            case 'Left_Right'
                Hand_idx = idx_all(strcmp({r.VideoInfos_side.Hand},'Left') | strcmp({r.VideoInfos_side.Hand},'Right'));
            otherwise
                errordlg('unknown argument');
        end    
    end

    switch Performance
        case 'All'
            Performance_idx = idx_all;
        case 'Correct'
            Performance_idx = idx_all(strcmp({r.VideoInfos_side.Performance},'Correct'));
        case 'Late'
            Performance_idx = idx_all(strcmp({r.VideoInfos_side.Performance},'Late'));
        case 'Premature'
            Performance_idx = idx_all(strcmp({r.VideoInfos_side.Performance},'Premature'));
        case 'Others'
            Performance_idx = idx_all(strcmp({r.VideoInfos_side.Performance},'Others'));
        otherwise
            errordlg('unknown argument');
    end
        
    
    if strcmp(Trajectory,'All')
        Trajectory_idx = idx_all;
    else
        traj_all = nan*zeros(length(r.VideoInfos_top),1);
        for k = 1:length(r.VideoInfos_top)
            if ~isempty(r.VideoInfos_top(k).Trajectory)
                traj_all(k) = r.VideoInfos_top(k).Trajectory;
            end
        end
        if isnumeric(Trajectory)
            Trajectory_idx = idx_all(traj_all == Trajectory);
        else
            Trajectory = str2double(Trajectory);
            Trajectory_idx = idx_all(traj_all == Trajectory);
        end
    end
    
    switch LiftStartTimeLabeled
        case 'Off'
            LiftStartTimeLabeled_idx = idx_all;
        case 'On'
            LiftStartTimeLabeled_idx = idx_all(~isnan([r.VideoInfos_side.LiftStartTime]));
        otherwise
            errordlg('unknown argument');
    end
    
    idx_out = Foreperiod_idx;
    idx_out = intersect(idx_out,Hand_idx);
    idx_out = intersect(idx_out,Performance_idx);
    idx_out = intersect(idx_out,Trajectory_idx);
    idx_out = intersect(idx_out,LiftStartTimeLabeled_idx);
end