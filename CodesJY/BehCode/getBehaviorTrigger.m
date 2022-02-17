function bnew =  getBehaviorTrigger(isession, ibpodsession, ifp)
% This is to deal with the 'Trigger' type of Bpod protocols.
% Premature trials were never influenced by stim. (stim/nostim occurs on trigger stimulus)
 

i=1;
bAllFPsBpod(i)=track_training_progress_advanced(isession);
load(ibpodsession);
sd = SessionData;
b = bAllFPsBpod(i);

press_time_bpod = [];
press_stim = [];
correct_press_bpod = [];
premature_press_bpod = [];
late_press_bpod = [];
triggered_trials_bpod = [];

for j =1 : length(sd.RawEvents.Trial)
    press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.Foreperiod(1)];
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)) % if this state occured, trigger stimulus was delivered
        press_stim = [press_stim 0];
        if ~isnan(sd.RawEvents.Trial{j}.States.Drinking(1))
            correct_press_bpod = [correct_press_bpod 1];
            late_press_bpod = [late_press_bpod 0];
        else
            correct_press_bpod = [correct_press_bpod 0];
            late_press_bpod = [late_press_bpod 1];
        end;
        premature_press_bpod = [premature_press_bpod  0];
        triggered_trials_bpod = [triggered_trials_bpod 1];
    elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1))
        press_stim = [press_stim 1];
        if ~isnan(sd.RawEvents.Trial{j}.States.Drinking(1))
            correct_press_bpod = [correct_press_bpod 1];
            late_press_bpod = [late_press_bpod 0];
        else
            correct_press_bpod = [correct_press_bpod 0];
            late_press_bpod = [late_press_bpod 1];
        end;
        premature_press_bpod = [premature_press_bpod  0];
        triggered_trials_bpod = [triggered_trials_bpod 1];
    else  % premature release
        premature_press_bpod = [premature_press_bpod  1];
        late_press_bpod = [late_press_bpod 0];
        correct_press_bpod = [correct_press_bpod 0];
        triggered_trials_bpod = [triggered_trials_bpod 0];
    end;
end;

    % the first press should be the same for bpod and MED
    % every press recorded in bpod can be found in MED, not every press in
    % MED can be found in bpod. (unless the MED is turned off before bpod)
    ind_trigger = find(triggered_trials_bpod==1);
    press_time_bpod_trigger = press_time_bpod(ind_trigger);
    
    bpod_to_MED = [];
    bpod_to_MED(1) = 1;
    dt_record = []; 
    
    press_time_bpod2    =   press_time_bpod_trigger-press_time_bpod_trigger(1);
    ind_outlet = find(press_time_bpod2>1*10^10);
    press_stim (ind_outlet) = [];
    press_time_bpod2(press_time_bpod2>1*10^10) = [];
    press_time_bpod2Org = press_time_bpod2;
     
    
    ind_count = sort([b.Correct  b.Late]); % in MED
    MED_Press_Time     = b.PressTime(ind_count)-b.PressTime(ind_count(1));
    MED_Press_TimeOrg = MED_Press_Time;
    
    alignment_check = 0;
    
    while ~alignment_check
        
        for k =1 : length(press_time_bpod2)
            
            time_MED =press_time_bpod2(k);
            [dmin, ind_dmin] = min(abs(MED_Press_Time - time_MED));
            sprintf('difference at %2.0d is %2.2f', k, 1000*dmin)
            if dmin<0.04
                
                bpod_to_MED(k) = ind_dmin; % the kth press in bpod corresponds to the ind_dmin press in MED
                dt_record = [dt_record dmin];
                press_time_bpod2 = press_time_bpod2 - press_time_bpod2(k);
                MED_Press_Time = MED_Press_Time - MED_Press_Time(ind_dmin);
         else
%                 error('Something is wrong')
                bpod_to_MED(k) = NaN;
            end;
        end;
        
        if isnan(bpod_to_MED(2))  % someone started MED before bpod
            ind_count = ind_count(2:end);
            MED_Press_Time     = b.PressTime(ind_count)-b.PressTime(ind_count(1));
            MED_Press_TimeOrg = MED_Press_Time;
            press_time_bpod2    =   press_time_bpod_trigger-press_time_bpod_trigger(1);
            press_time_bpod2Org = press_time_bpod2;
            bpod_to_MED = [];
            bpod_to_MED(1) = 1;
            dt_record = [];
        else
            alignment_check = 1;
        end;
        
    end;
    
    bpod_to_MED2 = ind_count(bpod_to_MED);
    % Note: bpod_to_MED matchs press in MED and bpod
    % all these presses are associated with trigger stimulus, in other
    % words, only correct and late responses are included. 
    % if the animal released the lever prematurely, laser stimulus was
    % never delivered. 
      
    figure;
    subplot(2, 1, 1)
    plot([0 dt_record])
    subplot(2, 1, 2)
    plot(press_time_bpod2Org, 5, 'ko');
    hold on
    plot(MED_Press_TimeOrg(bpod_to_MED), 5.2, 'ro')
    set(gca, 'ylim', [4.5 5.5])
    
    
    if length(bpod_to_MED) ~= length(press_time_bpod2)
        error('Mismatch')
%     elseif length(bpod_to_MED) < length(press_time_bpod2)
%         nmiss=  length(press_time_bpod2) - length(bpod_to_MED); 
%         press_time_bpod2( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
%         press_stim( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
    end;
    
    
    bnew.Metadata = b;
    bnew.SessionName = b.SessionName;
    bnew.MedIndex = bpod_to_MED2; % index of Bpod-presses in MED
    bnew.PressTime = b.PressTime(bpod_to_MED2);
    bnew.ReleaseTime = b.ReleaseTime(bpod_to_MED2);
    
    [bnew.Correct] = intersect(b.Correct, bpod_to_MED2);
    [bnew.Premature] = intersect(b.Premature, bpod_to_MED2);
    [bnew.Late] = intersect(b.Late, bpod_to_MED2);
    [bnew.Dark] =intersect(b.Dark, bpod_to_MED2);
    
    bnew.FPs = b.FPs;
    bnew.Stim = zeros(1, length(bnew.FPs));
    bnew.Stim(bpod_to_MED2) = press_stim; 
    bnew.Premature = b.Premature;
    bnew.Dark = b.Dark;
    bnew.Note = 'all index come from original index in MED. Premature responses were never related to laser stimulation.';
    
    bnew.Performance_Definition = {'N_correct', 'N_premature', 'N_late', 'Perc_Correct',  'Perc_Premature',  'Perc_Late'};
    
    bnew.Performance_Control = [length(intersect(bnew.Correct, find(bnew.Stim==0)));
        length(intersect(bnew.Premature, find(bnew.Stim==0)));
        length(intersect(bnew.Late, find(bnew.Stim==0))) ];
    
    bnew.Performance_Control(4)= bnew.Performance_Control(1)/sum(bnew.Performance_Control(1:3));
    bnew.Performance_Control(5)= bnew.Performance_Control(2)/sum(bnew.Performance_Control(1:3));
    bnew.Performance_Control(6)= bnew.Performance_Control(3)/sum(bnew.Performance_Control(1:3));
    
    bnew.Performance_Nostim(1)= bnew.Performance_Control(1)/sum(bnew.Performance_Control([1 3]));
    bnew.Performance_Nostim(2)= bnew.Performance_Control(3)/sum(bnew.Performance_Control([1 3])); 
    
    bnew.Performance_Stim = [length(intersect(bnew.Correct, find(bnew.Stim==1))); 
        length(intersect(bnew.Late, find(bnew.Stim==1))) ];
    bnew.Performance_Stim(3)= bnew.Performance_Stim(1)/sum(bnew.Performance_Stim);
    bnew.Performance_Stim(4)= bnew.Performance_Stim(2)/sum(bnew.Performance_Stim(1:2)); 

    % first short FP
    indbeg = find(bnew.FPs==ifp(1), 1, 'first');
    
    % press duration short FP, nostim (only correct and late responses are counted)
    [Nostim_short_indexMED, Nostim_short_index] = intersect(bnew.MedIndex, intersect([bnew.Correct bnew.Premature bnew.Late], find(bnew.FPs == ifp(1) & bnew.Stim==0))); 
    [Stim_short_indexMED, Stim_short_index] = intersect(bnew.MedIndex, intersect([bnew.Correct bnew.Premature  bnew.Late], find(bnew.FPs == ifp(1)&bnew.Stim==1))); 

    Nostim_Short_PressDur = bnew.ReleaseTime(Nostim_short_index) - bnew.PressTime(Nostim_short_index);
    Stim_Short_PressDur = bnew.ReleaseTime(Stim_short_index) - bnew.PressTime(Stim_short_index); 
    
    data_shortFP = {1000*Nostim_Short_PressDur-ifp(1), 1000*Stim_Short_PressDur-ifp(1)};
    catIdx_short = [ones(length(Nostim_Short_PressDur), 1); 2*ones(length(Stim_Short_PressDur), 1)];
    
    % performance at short FPs:
    bnew.Performance_Nostim_ShortFP = [length(intersect(bnew.Correct, Nostim_short_indexMED))
        length(intersect(bnew.Premature, find(bnew.FPs == ifp(1))))
        length(intersect(bnew.Late, Nostim_short_indexMED))];
    
    bnew.Performance_Stim_ShortFP = [length(intersect(bnew.Correct, Stim_short_indexMED));
        0
        length(intersect(bnew.Late, Stim_short_indexMED)) ];
     
    % press duration long FP, nostim
    [Nostim_long_indexMED, Nostim_long_index] = intersect(bnew.MedIndex, intersect([bnew.Correct bnew.Premature  bnew.Late], find(bnew.FPs == ifp(2) & bnew.Stim==0)));
    [Stim_long_indexMED, Stim_long_index] = intersect(bnew.MedIndex, intersect([bnew.Correct bnew.Premature  bnew.Late], find(bnew.FPs == ifp(2)&bnew.Stim==1)));
     
    Nostim_Long_PressDur = bnew.ReleaseTime(Nostim_long_index)-bnew.PressTime(Nostim_long_index);
    Stim_Long_PressDur = bnew.ReleaseTime(Stim_long_index)-bnew.PressTime(Stim_long_index);
 
    data_longFP = {1000*Nostim_Long_PressDur-ifp(2), 1000*Stim_Long_PressDur-ifp(2)};
    catIdx_long = [4*ones(length(Nostim_Long_PressDur), 1); 5*ones(length(Stim_Long_PressDur), 1)]
    
    data_both = [data_shortFP data_longFP];
    catldx_both = [catIdx_short; catIdx_long];
    
    
    % performance at long FPs:
    bnew.Performance_Nostim_LongFP = [length(intersect(bnew.Correct, Nostim_long_indexMED));
        length(intersect(bnew.Premature, find(bnew.FPs == ifp(2))))
        length(intersect(bnew.Late, Nostim_long_indexMED)) ];
    
    bnew.Performance_Stim_LongFP = [length(intersect(bnew.Correct, Stim_long_index));
        0
        length(intersect(bnew.Late, Stim_long_index)) ];
    

    figure(20); clf(20)
    set(gcf, 'unit', 'centimeters', 'position',[2 2 20 15], 'paperpositionmode', 'auto' )
    
    ha1 = subplot(2, 2, 1);
    set(ha1, 'nextplot', 'add', 'TickDir', 'Out');
    title(bnew.SessionName)
    
    ShortFP_correct =  bnew.Performance_Nostim_ShortFP(1)/sum( bnew.Performance_Nostim_ShortFP);
    ShortFP_premature =  bnew.Performance_Nostim_ShortFP(2)/sum( bnew.Performance_Nostim_ShortFP);
    ShortFP_late=  bnew.Performance_Nostim_ShortFP(3)/sum( bnew.Performance_Nostim_ShortFP);

    hbar1(1) = bar([1], [100*ShortFP_correct], 0.9)
    hbar1(2) = bar([2], [100*ShortFP_premature], 0.9)
    hbar1(3) = bar([3], [100*ShortFP_late], 0.9)
    set(hbar1(1), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
    set(hbar1(2), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
    set(hbar1(3), 'facecolor', 'r', 'edgecolor', 'k', 'linewidth', 1.5)
        
    LongFP_correct =  bnew.Performance_Nostim_LongFP(1)/sum( bnew.Performance_Nostim_LongFP);
    LongFP_premature =  bnew.Performance_Nostim_LongFP(2)/sum( bnew.Performance_Nostim_LongFP);
    LongFP_late=  bnew.Performance_Nostim_LongFP(3)/sum( bnew.Performance_Nostim_LongFP);
    
    hbar1(4) = bar([5], [100*LongFP_correct], 0.9)
    hbar1(5) = bar([6], [100*LongFP_premature], 0.9)
    hbar1(6) = bar([7], [100*LongFP_late], 0.9)
    set(hbar1(4), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
    set(hbar1(5), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
    set(hbar1(6), 'facecolor', 'r', 'edgecolor', 'k', 'linewidth', 1.5)
    line([4 4], [0 100], 'linestyle', '--', 'color', [.5 .5 .5]);
    
    text(2, 95, 'Short')
    text(5, 95, 'Long')
    set(ha1,'xlim', [0 8], 'xtick', [1 2 3], 'xticklabel', {'cr' , 'Prm', 'late'}, 'ylim', [0 100])
    ylabel('Performance')
    
    %%
    ha2 = subplot(2, 2, 2);
    set(ha2, 'nextplot', 'add', 'TickDir', 'Out');
    
    hp2 = plotSpread(data_both, 'CategoryIdx',catldx_both,...
        'categoryMarkers',{'.','.', '.', '.'},'categoryColors',{'k','b', 'k', 'b'}, 'spreadWidth', 0.6)
 
    line([0.5 4.5], [100 100], 'color', 'c', 'linestyle', ':', 'linewidth', 1) 
    line([0.5 4.5], [600 600], 'color', 'c', 'linestyle', ':', 'linewidth', 1) 
    
    set(ha2, 'xlim', [0 5], 'ylim', [0 1000], 'xtick', [1 2 3 4], 'xticklabel', {'Nostim', 'Stim', 'Nostim', 'Stim'})
    ylabel('Press duration (ms)')
    
    % Reaction time
    % 1. Reaction time for short FP
    [~, Nostim_short_index_correct] = intersect(bnew.MedIndex, intersect(bnew.Correct, find(bnew.FPs == ifp(1) & bnew.Stim==0)));
    [~, Stim_short_index_correct] = intersect(bnew.MedIndex, intersect(bnew.Correct, find(bnew.FPs == ifp(1) & bnew.Stim==1)));
    
    RT_short_nostim = bnew.ReleaseTime(Nostim_short_index_correct)-bnew.PressTime(Nostim_short_index_correct)-ifp(1)/1000;
    RT_short_nostim2 = RT_short_nostim(RT_short_nostim>=0.1);
    
    RT_short_stim = bnew.ReleaseTime(Stim_short_index_correct)-bnew.PressTime(Stim_short_index_correct)-ifp(1)/1000;
    RT_short_stim2 = RT_short_stim(RT_short_stim>=0.1);
        
    median_RT_short_nostim = median(RT_short_nostim2);
    median_RT_short_stim = median(RT_short_stim2);
    
    bnew.RT_Short_Nostim = RT_short_nostim;
    bnew.RT_Short_Stim = RT_short_stim;
    
    % 2. Reaction time for long FP
    [~, Nostim_long_index_correct] = intersect(bnew.MedIndex, intersect(bnew.Correct, find(bnew.FPs == ifp(2) & bnew.Stim==0)));
    [~, Stim_long_index_correct] = intersect(bnew.MedIndex, intersect(bnew.Correct, find(bnew.FPs == ifp(2) & bnew.Stim==1)));
    RT_long_nostim = bnew.ReleaseTime(Nostim_long_index_correct)-bnew.PressTime(Nostim_long_index_correct)-ifp(2)/1000;
    RT_long_nostim2 = RT_long_nostim(RT_long_nostim>=0.1);
    
    RT_long_stim = bnew.ReleaseTime(Stim_long_index_correct)-bnew.PressTime(Stim_long_index_correct)-ifp(2)/1000;
    RT_long_stim2 = RT_long_stim(RT_long_stim>=0.1);
    
    median_RT_long_nostim = median(RT_long_nostim2);
    median_RT_long_stim = median(RT_long_stim2);
    
    bnew.RT_Long_Nostim = RT_long_nostim;
    bnew.RT_Long_Stim = RT_long_stim;
    
    RTdata = {1000*RT_short_nostim2, 1000*RT_short_stim2, 1000*RT_long_nostim2, 1000*RT_long_stim2};
    catIdx_RT = [ones(1, length(RT_short_nostim2)) 2*ones(1, length(RT_short_stim2)) 3*ones(1, length(RT_long_nostim2)) 4*ones(1, length(RT_long_stim2))];
        
    ha3 = subplot(2, 2, 3);
    set(ha3, 'nextplot', 'add', 'TickDir', 'Out');
    
    hp3 = plotSpread(RTdata, 'CategoryIdx',catIdx_RT,...
        'categoryMarkers',{'.','.', '.', '.'},'categoryColors',{'k','b', 'k', 'b'}, 'spreadWidth', 0.8)
    set(ha3, 'xlim', [0 5], 'ylim', [0 1000], 'xtick', [1 2 3 4], 'xticklabel', {'Nostim', 'Stim', 'Nostim', 'Stim'})
    
    line([1 1], prctile(RT_short_nostim2, [25 75])*1000, 'color', 'r', 'linewidth', 2)
    line([0.9 1.1], [median_RT_short_nostim median_RT_short_nostim]*1000, 'color', 'r', 'linewidth', 2)
    line([2 2], prctile(RT_short_stim2, [25 75])*1000, 'color', 'r', 'linewidth', 2)
    line([1.9 2.1], [median_RT_short_stim median_RT_short_stim]*1000, 'color', 'r', 'linewidth', 2)
    
    line([3 3], prctile(RT_long_nostim2, [25 75])*1000, 'color', 'r', 'linewidth', 2)
    line([2.9 3.1] , [median_RT_long_nostim median_RT_long_nostim]*1000, 'color', 'r', 'linewidth', 2)
    line([4 4], prctile(RT_long_stim2, [25 75])*1000, 'color', 'r', 'linewidth', 2)
    line([3.9 4.1] , [median_RT_long_stim median_RT_long_stim]*1000, 'color', 'r', 'linewidth', 2)
    ylabel('Reaction time (ms)')
    
    [p_short, h_short] = ranksum(RT_short_nostim2, RT_short_stim2);
    [p_long, h_long] = ranksum(RT_long_nostim2, RT_long_stim2);
    
    text(1, 900, sprintf('p=%2.4f', p_short))
    text(3, 900, sprintf('p=%2.4f', p_long))
    
    
    fprintf('short FP p value is %2.5f\n', p_short)
    fprintf('long FP p value is %2.5f\n', p_long)
    mkdir('Fig');
    
    savename = ['OptoEffect'  upper(bnew.Metadata.Metadata.SubjectName) '_' bnew.Metadata.Metadata.Date];
    savename=fullfile(pwd, 'Fig', savename)
    
    print (gcf,'-dpng', [savename])
    print (gcf,'-dpdf', [savename])
    

