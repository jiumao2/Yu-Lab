function [approach_time_bpod, approach_stim, approach_presstime] = get_stim_data(path_med,path_bpod)
bAllFPsBpod=my_track_training_progress_advanced(path_med);
    load(path_bpod);
    sd = SessionData;
    b = bAllFPsBpod;
    
    % get press time and whether the press is accompanied with stimulus from bpod 
    
    press_time_bpod = [];
    for j =1 : length(sd.RawEvents.Trial)
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1))
            press_time_bpod = [press_time_bpod, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
        end
    end
    
    approach_time_bpod = [];
    approach_stim = [];
    approach_presstime = [];
    for j =1 : length(sd.RawEvents.Trial)
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1))
            approach_time_bpod = [approach_time_bpod, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForPress(1)];
            approach_stim = [approach_stim 0];
            if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1))
                approach_presstime = [approach_presstime, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
            else
                approach_presstime = [approach_presstime, 0];
            end
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))
            approach_time_bpod = [approach_time_bpod, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForPressStim(1)];
            approach_stim = [approach_stim 1];
            if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1))
                approach_presstime = [approach_presstime, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
            else
                approach_presstime = [approach_presstime, 0];
            end
        end
    end
    
    % the first press should be the same for bpod and MED
    % every press recorded in bpod can be found in MED, not every press in
    % MED can be found in bpod. (unless the MED is turned off before bpod)
    
    approach_time_bpod = approach_time_bpod - press_time_bpod(1) + b.PressTime(1);
    approach_presstime(approach_presstime~=0) = approach_presstime(approach_presstime~=0) - press_time_bpod(1) + b.PressTime(1);
    
    bpod_to_MED = []; 
    bpod_to_MED(1) = 1;
    dt_record = [];
    
    press_time_bpod2    =   press_time_bpod-press_time_bpod(1);
    press_time_bpod2Org = press_time_bpod2;
    MED_Press_Time     = b.PressTime-b.PressTime(1);
    MED_Press_TimeOrg = MED_Press_Time;
    
    for k =1 : length(press_time_bpod)
        
        time_MED =press_time_bpod2(k);
        [dmin, ind_dmin] = min(abs(MED_Press_Time - time_MED));
        %sprintf('difference at %2.0d is %2.2f', k, 1000*dmin)

        if dmin<2
            bpod_to_MED(k) = ind_dmin; % the kth press in bpod corresponds to the ind_dmin press in MED
            dt_record = [dt_record dmin];
            press_time_bpod2 = press_time_bpod2 - press_time_bpod2(k);
            MED_Press_Time = MED_Press_Time - MED_Press_Time(ind_dmin);
        end
    end
      
    
    
    if length(bpod_to_MED) > length(press_time_bpod)
        error('Mismatch')
    elseif length(bpod_to_MED) < length(press_time_bpod)
        nmiss=  length(press_time_bpod) - length(bpod_to_MED); 
        press_time_bpod( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
    end
    
    % approach_presstime([b.Premature,b.Dark]) = [];
    
end
    
    
    