function stim_med = get_stim_data(path_med,path_bpod)
    bAllFPsBpod=my_track_training_progress_advanced(path_med);
    load(path_bpod);
    sd = SessionData;
    b = bAllFPsBpod;
    
    % get press time and whether the press is accompanied with stimulus from bpod 
    press_time_bpod = [];
    press_stim = [];
    for j =1 : length(sd.RawEvents.Trial)
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1))
            press_time_bpod = [press_time_bpod, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
            press_stim = [press_stim 0];
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1))
            press_time_bpod = [press_time_bpod, sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1)];
            press_stim = [press_stim 1];
        else
        end;
    end;
    
    % the first press should be the same for bpod and MED
    % every press recorded in bpod can be found in MED, not every press in
    % MED can be found in bpod. (unless the MED is turned off before bpod)
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
        end;
    end;
      
    
    
    if length(bpod_to_MED) > length(press_time_bpod)
        error('Mismatch')
    elseif length(bpod_to_MED) < length(press_time_bpod)
        nmiss=  length(press_time_bpod) - length(bpod_to_MED); 
        press_time_bpod( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
        press_stim( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
    end;
    
    stim_med = 2*ones(length(MED_Press_Time),1);
    stim_med(bpod_to_MED) = press_stim;
    stim_med(stim_med==2) = nan;
    
    stim_med([b.Premature,b.Dark]) = [];
end
    
    
    