function [bnew,bpod_to_MED] =  getBehaviorApproach(isession, ibpodsession)

i=1;
  bAllFPsBpod(i)=my_track_training_progress_advanced(isession);
    load(ibpodsession);
    sd = SessionData;
    b = bAllFPsBpod(i);
    
    press_time_bpod = [];
    press_stim = [];
    app_press_time_bpod= [];
    for j =1 : length(sd.RawEvents.Trial)
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1))  
            press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
            app_press_time_bpod = [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)-sd.RawEvents.Trial{j}.States.Masking(1)];
            press_stim = [press_stim 0];
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))  
            press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
            press_stim = [press_stim 1];
            app_press_time_bpod = [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)-sd.RawEvents.Trial{j}.States.Masking(1)];
        else
        end
    end
    
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
        if dmin<0.05
            bpod_to_MED(k) = ind_dmin; % the kth press in bpod corresponds to the ind_dmin press in MED
            dt_record = [dt_record dmin];
            press_time_bpod2 = press_time_bpod2 - press_time_bpod2(k);
            MED_Press_Time = MED_Press_Time - MED_Press_Time(ind_dmin);
        end
    end
      
%     figure;
%     subplot(2, 1, 1)
%     plot([0 dt_record])
%     subplot(2, 1, 2)
%     plot(press_time_bpod2Org, 5, 'ko');
%     hold on
%     plot(MED_Press_TimeOrg(bpod_to_MED), 5.2, 'ro')
%     set(gca, 'ylim', [4.5 5.5])
    
    
    if length(bpod_to_MED) > length(press_time_bpod)
        error('Mismatch')
    elseif length(bpod_to_MED) < length(press_time_bpod)
        nmiss=  length(press_time_bpod) - length(bpod_to_MED); 
        press_time_bpod( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
        press_stim( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
    end
    
    
    bnew.Metadata = b;
    bnew.SessionName = b.SessionName;
    bnew.MedIndex = bpod_to_MED; % index of Bpod-presses in MED
    bnew.PressTime = b.PressTime(bpod_to_MED);
    bnew.ReleaseTime = b.ReleaseTime(bpod_to_MED);
    bnew.AppPressTime = app_press_time_bpod;
    
    [~,bnew.Correct] = intersect(bnew.MedIndex, intersect(b.Correct, bpod_to_MED));
    [~,bnew.Premature] = intersect(bnew.MedIndex, intersect(b.Premature, bpod_to_MED));
    [~,bnew.Late] = intersect(bnew.MedIndex, intersect(b.Late, bpod_to_MED));
    [~,bnew.Dark] = intersect(bnew.MedIndex, intersect(b.Dark, bpod_to_MED));
    
    bnew.FPs = b.FPs(bpod_to_MED);
    bnew.Stim = press_stim;
    
    bnew.Performance_Definition = {'N_correct', 'N_premature', 'N_late', 'Perc_Correct',  'Perc_Premature',  'Perc_Late'};
    
    bnew.Performance_Nostim = [length(intersect(bnew.Correct, find(bnew.Stim==0)));
        length(intersect(bnew.Premature, find(bnew.Stim==0)));
        length(intersect(bnew.Late, find(bnew.Stim==0))) ];
    
    bnew.Performance_Nostim(4)= bnew.Performance_Nostim(1)/sum(bnew.Performance_Nostim(1:3));
    bnew.Performance_Nostim(5)= bnew.Performance_Nostim(2)/sum(bnew.Performance_Nostim(1:3));
    bnew.Performance_Nostim(6)= bnew.Performance_Nostim(3)/sum(bnew.Performance_Nostim(1:3));
    
    bnew.Performance_Stim = [length(intersect(bnew.Correct, find(bnew.Stim==1)));
        length(intersect(bnew.Premature, find(bnew.Stim==1)));
        length(intersect(bnew.Late, find(bnew.Stim==1))) ];
    bnew.Performance_Stim(4)= bnew.Performance_Stim(1)/sum(bnew.Performance_Stim);
    bnew.Performance_Stim(5)= bnew.Performance_Stim(2)/sum(bnew.Performance_Stim(1:3));
    bnew.Performance_Stim(6)= bnew.Performance_Stim(3)/sum(bnew.Performance_Stim(1:3));
    

    
    

