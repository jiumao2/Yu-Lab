  

function bnew =  getBehavior(isession, ibpodsession, ifp,r,DLC)

i=1;
bAllFPsBpod(i)=track_training_progress_advanced(isession);
load(ibpodsession);
sd = SessionData;
b = bAllFPsBpod(i);



stim_type = [];
press_stim = [];
press_time_bpod = [];
trial_press=[];
app_press_time_bpod= [];
movement_time=[];

for j =1 : length(sd.RawEvents.Trial)
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForDLC(1))
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1)) & ismember(j,DLC(r).BpodIndexHit)
            stim_type = [stim_type 1];
            if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
                press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForTrigger(1)];
                trial_press=[trial_press 1];
                press_stim = [press_stim 1];
                
                if ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayLow(1))
                    movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayLow(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
                elseif ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayHigh(1))
                    movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayHigh(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
                else
                    movement_time=[movement_time NaN];
                end
                
                if isfield(sd.RawEvents.Trial{j}.Events,'BNC2Low')
                    app_press_time_bpod= [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForTrigger(1)-sd.RawEvents.Trial{j}.Events.BNC2Low(1)];
                else
                    app_press_time_bpod= [app_press_time_bpod NaN];
                end
            else
                trial_press=[trial_press 0];
                app_press_time_bpod= [app_press_time_bpod NaN];
            end
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1)) & ~ismember(j,DLC(r).BpodIndexHit)
            stim_type = [stim_type NaN];            
            if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
                press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForTrigger(1)];
                trial_press=[trial_press 1];
                press_stim = [press_stim NaN];
                
                if ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayLow(1))
                    movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayLow(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
                elseif ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayHigh(1))
                    movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayHigh(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
                else
                    movement_time=[movement_time NaN];
                end
                
                if isfield(sd.RawEvents.Trial{j}.Events,'BNC2Low')
                    app_press_time_bpod= [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForTrigger(1)-sd.RawEvents.Trial{j}.Events.BNC2Low(1)];
                else
                    app_press_time_bpod= [app_press_time_bpod NaN];
                end
            else
                trial_press=[trial_press 0];
                app_press_time_bpod= [app_press_time_bpod NaN];
            end
        else
            press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForTrigger(1)];
            trial_press=[trial_press 1];
            stim_type = [stim_type 0];
            press_stim = [press_stim 0];
            
            if isfield(sd.RawEvents.Trial{j}.Events,'BNC2Low')
                app_press_time_bpod= [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForTrigger(1)-sd.RawEvents.Trial{j}.Events.BNC2Low(1)];
            else
                app_press_time_bpod= [app_press_time_bpod NaN];
            end
            
            if ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayLow(1))
                movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayLow(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
            elseif ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayHigh(1))
                movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayHigh(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
            else
                movement_time=[movement_time NaN];
            end
        end
    elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))
        stim_type = [stim_type 2];
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
            press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForTrigger(1)];
            trial_press=[trial_press 1];
            press_stim = [press_stim 2];
            
            if isfield(sd.RawEvents.Trial{j}.Events,'BNC2Low')
                app_press_time_bpod= [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForTrigger(1)-sd.RawEvents.Trial{j}.Events.BNC2Low(1)];
            else
                app_press_time_bpod= [app_press_time_bpod NaN];
            end
            
            if ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayLow(1))
                movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayLow(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
            elseif ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayHigh(1))
                movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayHigh(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
            else
                movement_time=[movement_time NaN];
            end
        else
            trial_press=[trial_press 0];
            app_press_time_bpod= [app_press_time_bpod NaN];
        end
    elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
        press_time_bpod = [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForTrigger(1)];
        trial_press=[trial_press 1];
        stim_type = [stim_type 0];
        press_stim = [press_stim 0];
        
        if isfield(sd.RawEvents.Trial{j}.Events,'BNC2Low')
            app_press_time_bpod= [app_press_time_bpod sd.RawEvents.Trial{j}.States.WaitForTrigger(1)-sd.RawEvents.Trial{j}.Events.BNC2Low(1)];
        else
            app_press_time_bpod= [app_press_time_bpod NaN];
        end
        
        if ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayLow(1))
            movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayLow(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaterDelayHigh(1))
            movement_time=[movement_time sd.RawEvents.Trial{j}.States.WaterDelayHigh(1)-sd.RawEvents.Trial{j}.States.WaitForMedTTL(end)];
        else
            movement_time=[movement_time NaN];
        end
        
    else
        trial_press=[trial_press 0];
        stim_type = [stim_type 0];
        app_press_time_bpod= [app_press_time_bpod NaN];
    end
end

bpod_to_MED = [];
bpod_to_MED(1) = 1;
dt_record = [];

press_time_bpod2    =   press_time_bpod-press_time_bpod(1);
press_time_bpod2Org = press_time_bpod2;
MED_Press_Time     = b.PressTime-b.PressTime(1);
MED_Press_TimeOrg = MED_Press_Time;


alignment_check = 0;

while ~alignment_check
    
    for k =1 : length(press_time_bpod)
        
        time_MED =press_time_bpod2(k);
        [dmin, ind_dmin] = min(abs(MED_Press_Time - time_MED));
        %sprintf('difference at %2.0d is %2.2f', k, 1000*dmin)
        if dmin<0.05
            bpod_to_MED(k) = ind_dmin; % the kth press in bpod corresponds to the ind_dmin press in MED
            dt_record = [dt_record dmin];
            press_time_bpod2 = press_time_bpod2 - press_time_bpod2(k);
            MED_Press_Time = MED_Press_Time - MED_Press_Time(ind_dmin);
        else
            % error('Something is wrong')
            bpod_to_MED(k) = NaN;
        end
    end
    if isnan(bpod_to_MED(2))
        MED_Press_Time(1) = [];
        MED_Press_Time     =  MED_Press_Time- MED_Press_Time(1);
        MED_Press_TimeOrg = MED_Press_Time;
        press_time_bpod2    =   press_time_bpod-press_time_bpod(1);
        press_time_bpod2Org = press_time_bpod2;
        bpod_to_MED = [];
        bpod_to_MED(1) = 1;
        dt_record = [];
    else
        alignment_check = 1;
    end;
    
end

if isnan(bpod_to_MED(end))
    bpod_to_MED(end)=[];
end

figure;
subplot(2, 1, 1)
plot([0 dt_record])
subplot(2, 1, 2)
plot(press_time_bpod2Org, 5, 'ko');
hold on
plot(MED_Press_TimeOrg(bpod_to_MED), 5.2, 'ro')
set(gca, 'ylim', [4.5 5.5])


if length(bpod_to_MED) > length(press_time_bpod)
    error('Mismatch')
elseif length(bpod_to_MED) < length(press_time_bpod)
    nmiss=  length(press_time_bpod) - length(bpod_to_MED);
    press_time_bpod( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
    stim_type( length(bpod_to_MED)+1: length(bpod_to_MED) +nmiss)=[];
end;


bnew.Metadata = b;
bnew.SessionName = b.SessionName;
bnew.MedIndex = bpod_to_MED; % index of Bpod-presses in MED
bnew.PressTime = b.PressTime(bpod_to_MED);
bnew.ReleaseTime = b.ReleaseTime(bpod_to_MED);
bnew.AppPressTime = app_press_time_bpod;
bnew.MovementTime = movement_time;

[~,bnew.Correct] = intersect(bnew.MedIndex, intersect(b.Correct, bpod_to_MED));
[~,bnew.Premature] = intersect(bnew.MedIndex, intersect(b.Premature, bpod_to_MED));
[~,bnew.Late] = intersect(bnew.MedIndex, intersect(b.Late, bpod_to_MED));
[~,bnew.Dark] = intersect(bnew.MedIndex, intersect(b.Dark, bpod_to_MED));

bnew.FPs = b.FPs(bpod_to_MED);
bnew.StimType = stim_type;
bnew.Stim = press_stim;

bnew.Performance_Definition = {'N_correct', 'N_premature', 'N_late', 'Perc_Correct',  'Perc_Premature',  'Perc_Late'};

bnew.Performance_Nostim = [length(intersect(bnew.Correct, find(bnew.Stim==0)));
    length(intersect(bnew.Premature, find(bnew.Stim==0)));
    length(intersect(bnew.Late, find(bnew.Stim==0))) ];

bnew.Performance_Nostim(4)= bnew.Performance_Nostim(1)/sum(bnew.Performance_Nostim(1:3));
bnew.Performance_Nostim(5)= bnew.Performance_Nostim(2)/sum(bnew.Performance_Nostim(1:3));
bnew.Performance_Nostim(6)= bnew.Performance_Nostim(3)/sum(bnew.Performance_Nostim(1:3));

bnew.Performance_App = [length(intersect(bnew.Correct, find(bnew.Stim==2)));
    length(intersect(bnew.Premature, find(bnew.Stim==2)));
    length(intersect(bnew.Late, find(bnew.Stim==2))) ];
bnew.Performance_App(4)= bnew.Performance_App(1)/sum(bnew.Performance_App);
bnew.Performance_App(5)= bnew.Performance_App(2)/sum(bnew.Performance_App(1:3));
bnew.Performance_App(6)= bnew.Performance_App(3)/sum(bnew.Performance_App(1:3));


bnew.Performance_DLC = [length(intersect(bnew.Correct, find(bnew.Stim==1)));
    length(intersect(bnew.Premature, find(bnew.Stim==1)));
    length(intersect(bnew.Late, find(bnew.Stim==1))) ];
bnew.Performance_DLC(4)= bnew.Performance_DLC(1)/sum(bnew.Performance_DLC);
bnew.Performance_DLC(5)= bnew.Performance_DLC(2)/sum(bnew.Performance_DLC(1:3));
bnew.Performance_DLC(6)= bnew.Performance_DLC(3)/sum(bnew.Performance_DLC(1:3));

AppTrial = app_press_time_bpod(find(stim_type==2));
AppSuccessTrialNum = length(AppTrial(~isnan(AppTrial) & AppTrial<2.2));
DLCTrial = app_press_time_bpod(find(stim_type==1));
DLCSuccessTrialNum = length(DLCTrial(~isnan(DLCTrial) & DLCTrial<2.2));
NoStimTrial = app_press_time_bpod(find(stim_type==0));
NoStimSuccessNum = length(NoStimTrial(~isnan(NoStimTrial)));
bnew.AppSuccessRate=AppSuccessTrialNum/length(find(stim_type==2));
bnew.DLCSuccessRate=DLCSuccessTrialNum/length(find(stim_type==1));
bnew.NoStimSuccessRate=NoStimSuccessNum/length(find(stim_type==0));

% press duration short FP, nostim
Nostim_short_index = find(bnew.FPs == ifp(1)&bnew.Stim==0);
DLC_short_index = find(bnew.FPs == ifp(1)&bnew.Stim==1);
App_short_index = find(bnew.FPs == ifp(1)&bnew.Stim==2);

Nostim_Short_PressDur = bnew.ReleaseTime(Nostim_short_index)-bnew.PressTime(Nostim_short_index);
DLC_Short_PressDur = bnew.ReleaseTime(DLC_short_index)-bnew.PressTime(DLC_short_index);
App_Short_PressDur = bnew.ReleaseTime(App_short_index)-bnew.PressTime(App_short_index);

data_shortFP = {1000*Nostim_Short_PressDur, 1000*DLC_Short_PressDur, 1000*App_Short_PressDur};
catIdx_short = [ones(length(Nostim_Short_PressDur), 1); 2*ones(length(DLC_Short_PressDur), 1);3*ones(length(App_Short_PressDur), 1)];

% performance at short FPs:

bnew.Performance_Nostim_ShortFP = [length(intersect(bnew.Correct, Nostim_short_index));
    length(intersect(bnew.Premature, Nostim_short_index));
    length(intersect(bnew.Late, Nostim_short_index)) ];

bnew.Performance_Nostim_ShortFP(4)= bnew.Performance_Nostim_ShortFP(1)/sum(bnew.Performance_Nostim_ShortFP(1:3));
bnew.Performance_Nostim_ShortFP(5)= bnew.Performance_Nostim_ShortFP(2)/sum(bnew.Performance_Nostim_ShortFP(1:3));
bnew.Performance_Nostim_ShortFP(6)= bnew.Performance_Nostim_ShortFP(3)/sum(bnew.Performance_Nostim_ShortFP(1:3));

bnew.Performance_DLC_ShortFP = [length(intersect(bnew.Correct, DLC_short_index));
    length(intersect(bnew.Premature, DLC_short_index));
    length(intersect(bnew.Late, DLC_short_index)) ];

bnew.Performance_DLC_ShortFP(4)= bnew.Performance_DLC_ShortFP(1)/sum(bnew.Performance_DLC_ShortFP(1:3));
bnew.Performance_DLC_ShortFP(5)= bnew.Performance_DLC_ShortFP(2)/sum(bnew.Performance_DLC_ShortFP(1:3));
bnew.Performance_DLC_ShortFP(6)= bnew.Performance_DLC_ShortFP(3)/sum(bnew.Performance_DLC_ShortFP(1:3));

bnew.Performance_App_ShortFP = [length(intersect(bnew.Correct, App_short_index));
    length(intersect(bnew.Premature, App_short_index));
    length(intersect(bnew.Late, App_short_index)) ];

bnew.Performance_App_ShortFP(4)= bnew.Performance_App_ShortFP(1)/sum(bnew.Performance_App_ShortFP(1:3));
bnew.Performance_App_ShortFP(5)= bnew.Performance_App_ShortFP(2)/sum(bnew.Performance_App_ShortFP(1:3));
bnew.Performance_App_ShortFP(6)= bnew.Performance_App_ShortFP(3)/sum(bnew.Performance_App_ShortFP(1:3));

% press duration long FP, nostim

Nostim_long_index = find(bnew.FPs == ifp(2)&bnew.Stim==0);
DLC_long_index = find(bnew.FPs == ifp(2)&bnew.Stim==1);
App_long_index = find(bnew.FPs == ifp(2)&bnew.Stim==2);

Nostim_long_PressDur = bnew.ReleaseTime(Nostim_long_index)-bnew.PressTime(Nostim_long_index);
DLC_long_PressDur = bnew.ReleaseTime(DLC_long_index)-bnew.PressTime(DLC_long_index);
App_long_PressDur = bnew.ReleaseTime(App_long_index)-bnew.PressTime(App_long_index);

data_longFP = {1000*Nostim_long_PressDur, 1000*DLC_long_PressDur, 1000*App_long_PressDur};
catIdx_long = [4*ones(length(Nostim_long_PressDur), 1); 5*ones(length(DLC_long_PressDur), 1);6*ones(length(App_long_PressDur), 1)];

data_both = [data_shortFP data_longFP];
catldx_both = [catIdx_short; catIdx_long];


% performance at long FPs:

bnew.Performance_Nostim_LongFP = [length(intersect(bnew.Correct, Nostim_long_index));
    length(intersect(bnew.Premature, Nostim_long_index));
    length(intersect(bnew.Late, Nostim_long_index)) ];

bnew.Performance_Nostim_LongFP(4)= bnew.Performance_Nostim_LongFP(1)/sum(bnew.Performance_Nostim_LongFP(1:3));
bnew.Performance_Nostim_LongFP(5)= bnew.Performance_Nostim_LongFP(2)/sum(bnew.Performance_Nostim_LongFP(1:3));
bnew.Performance_Nostim_LongFP(6)= bnew.Performance_Nostim_LongFP(3)/sum(bnew.Performance_Nostim_LongFP(1:3));

bnew.Performance_DLC_LongFP = [length(intersect(bnew.Correct, DLC_long_index));
    length(intersect(bnew.Premature, DLC_long_index));
    length(intersect(bnew.Late, DLC_long_index)) ];

bnew.Performance_DLC_LongFP(4)= bnew.Performance_DLC_LongFP(1)/sum(bnew.Performance_DLC_LongFP(1:3));
bnew.Performance_DLC_LongFP(5)= bnew.Performance_DLC_LongFP(2)/sum(bnew.Performance_DLC_LongFP(1:3));
bnew.Performance_DLC_LongFP(6)= bnew.Performance_DLC_LongFP(3)/sum(bnew.Performance_DLC_LongFP(1:3));

bnew.Performance_App_LongFP = [length(intersect(bnew.Correct, App_long_index));
    length(intersect(bnew.Premature, App_long_index));
    length(intersect(bnew.Late, App_long_index)) ];

bnew.Performance_App_LongFP(4)= bnew.Performance_App_LongFP(1)/sum(bnew.Performance_App_LongFP(1:3));
bnew.Performance_App_LongFP(5)= bnew.Performance_App_LongFP(2)/sum(bnew.Performance_App_LongFP(1:3));
bnew.Performance_App_LongFP(6)= bnew.Performance_App_LongFP(3)/sum(bnew.Performance_App_LongFP(1:3));


figure(20); clf(20);
set(gcf, 'unit', 'centimeters', 'position',[2 2 20 15], 'paperpositionmode', 'auto' );

ha1 = subplot(2, 2, 1);
set(ha1, 'nextplot', 'add', 'TickDir', 'Out');
title(bnew.SessionName);

hbar1(1) = bar([1], [100*bnew.Performance_Nostim_ShortFP(4) ], 0.9);
hbar1(2) = bar([2], [100*bnew.Performance_Nostim_ShortFP(5) ], 0.9);
hbar1(3) = bar([3], [100*bnew.Performance_Nostim_ShortFP(6) ], 0.9);

set(hbar1(1), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar1(2), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar1(3), 'facecolor', 'r', 'edgecolor', 'k', 'linewidth', 1.5);

hbar2(1) = bar([5], [100*bnew.Performance_DLC_ShortFP(4)], 0.9);
hbar2(2) = bar([6], [100*bnew.Performance_DLC_ShortFP(5)], 0.9);
hbar2(3) = bar([7], [100*bnew.Performance_DLC_ShortFP(6)], 0.9);

set(hbar2(1), 'facecolor', [55 255 0]/255, 'edgecolor', 'b', 'linewidth', 1.5);
set(hbar2(2), 'facecolor', [153 51 0]/255, 'edgecolor', 'b', 'linewidth', 1.5);
set(hbar2(3), 'facecolor', 'r', 'edgecolor', 'b', 'linewidth', 1.5);

hbar3(1) = bar([9], [100*bnew.Performance_App_ShortFP(4)], 0.9);
hbar3(2) = bar([10], [100*bnew.Performance_App_ShortFP(5)], 0.9);
hbar3(3) = bar([11], [100*bnew.Performance_App_ShortFP(6)], 0.9);

set(hbar3(1), 'facecolor', [55 255 0]/255, 'edgecolor', 'b', 'linewidth', 1.5);
set(hbar3(2), 'facecolor', [153 51 0]/255, 'edgecolor', 'b', 'linewidth', 1.5);
set(hbar3(3), 'facecolor', 'r', 'edgecolor', 'b', 'linewidth', 1.5);

hbar1(4) = bar([13], [100*bnew.Performance_Nostim_LongFP(4) ], 0.9);
hbar1(5) = bar([14], [100*bnew.Performance_Nostim_LongFP(5) ], 0.9);
hbar1(6) = bar([15], [100*bnew.Performance_Nostim_LongFP(6) ], 0.9);
set(hbar1(4), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar1(5), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar1(6), 'facecolor', 'r', 'edgecolor', 'k', 'linewidth', 1.5);

hbar2(4) = bar([17], [100*bnew.Performance_DLC_LongFP(4) ], 0.9);
hbar2(5) = bar([18], [100*bnew.Performance_DLC_LongFP(5) ], 0.9);
hbar2(6) = bar([19], [100*bnew.Performance_DLC_LongFP(6) ], 0.9);
set(hbar2(4), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar2(5), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar2(6), 'facecolor', 'r', 'edgecolor', 'b', 'linewidth', 1.5);

hbar3(4) = bar([21], [100*bnew.Performance_App_LongFP(4) ], 0.9);
hbar3(5) = bar([22], [100*bnew.Performance_App_LongFP(5) ], 0.9);
hbar3(6) = bar([23], [100*bnew.Performance_App_LongFP(6) ], 0.9);
set(hbar3(4), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar3(5), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5);
set(hbar3(6), 'facecolor', 'r', 'edgecolor', 'b', 'linewidth', 1.5);


line([12 12], [0 100], 'linestyle', '--', 'color', [.5 .5 .5]);

text(1, 95, 'Short');
text(13, 95, 'Long');

set(ha1,'xlim', [0 24], 'xtick', [2 6 10 14 18 22], 'xticklabel', {'Nostim', 'DLC', 'App','Nostim', 'DLC', 'App'}, 'ylim', [0 100])
ylabel('Performance')

ha2 = subplot(2, 2, 2);
set(ha2, 'nextplot', 'add', 'TickDir', 'Out');

hp2 = plotSpread(data_both, 'CategoryIdx',catldx_both,...
    'categoryMarkers',{'.','^', 'o', '.','^','o'},'categoryColors',{'k','b','b', 'k', 'b','b'}, 'spreadWidth', 0.6);

line([0.5 3.5], [ifp(1) ifp(1)], 'color', [0.8 0.8 0.8], 'linestyle', '--', 'linewidth', 1)
line([0.5 3.5], [ifp(1)+600 ifp(1)+600], 'color', [0.8 0.8 0.8], 'linestyle', ':','linewidth', 1)

line([3.5 6.5], [ifp(2) ifp(2)], 'color', [0.8 0.8 0.8], 'linestyle', '--', 'linewidth', 1)
line([3.5 6.5], [ifp(2)+600 ifp(2)+600], 'color', [0.8 0.8 0.8], 'linestyle', ':', 'linewidth', 1)

set(ha2, 'xlim', [0 7], 'ylim', [0 4000], 'xtick', [1 2 3 4 5 6], 'xticklabel', {'Nostim', 'DLC', 'App','Nostim', 'DLC', 'App'})
ylabel('Press duration (ms)')

% Reaction time
% 1. Reaction time for short FP
Nostim_short_index_correct = intersect(Nostim_short_index, bnew.Correct);
DLC_short_index_correct = intersect(DLC_short_index, bnew.Correct);
App_short_index_correct = intersect(App_short_index, bnew.Correct);

RT_short_nostim = bnew.ReleaseTime(Nostim_short_index_correct)-bnew.PressTime(Nostim_short_index_correct)-ifp(1)/1000;
RT_short_DLC = bnew.ReleaseTime(DLC_short_index_correct)-bnew.PressTime(DLC_short_index_correct)-ifp(1)/1000;
RT_short_App = bnew.ReleaseTime(App_short_index_correct)-bnew.PressTime(App_short_index_correct)-ifp(1)/1000;

median_RT_short_nostim = median(RT_short_nostim);
median_RT_short_DLC = median(RT_short_DLC);
median_RT_short_App = median(RT_short_App);

bnew.RT_Short_Nostim = RT_short_nostim;
bnew.RT_Short_DLC = RT_short_DLC;
bnew.RT_Short_App = RT_short_App;

% 2. Reaction time for long FP
Nostim_long_index_correct = intersect(Nostim_long_index, bnew.Correct);
DLC_long_index_correct = intersect(DLC_long_index, bnew.Correct);
App_long_index_correct = intersect(App_long_index, bnew.Correct);

RT_long_nostim = bnew.ReleaseTime(Nostim_long_index_correct)-bnew.PressTime(Nostim_long_index_correct)-ifp(2)/1000;
RT_long_DLC = bnew.ReleaseTime(DLC_long_index_correct)-bnew.PressTime(DLC_long_index_correct)-ifp(2)/1000;
RT_long_App = bnew.ReleaseTime(App_long_index_correct)-bnew.PressTime(App_long_index_correct)-ifp(2)/1000;

median_RT_long_nostim = median(RT_long_nostim);
median_RT_long_DLC = median(RT_long_DLC);
median_RT_long_App = median(RT_long_App);

bnew.RT_Long_Nostim = RT_long_nostim;
bnew.RT_Long_DLC = RT_long_DLC;
bnew.RT_Long_App = RT_long_App;

RTdata = {1000*RT_short_nostim, 1000*RT_short_DLC, 1000*RT_short_App,1000*RT_long_nostim, 1000*RT_long_DLC, 1000*RT_long_App};
catIdx_RT = [ones(1, length(RT_short_nostim)) 2*ones(1, length(RT_short_DLC)) 3*ones(1, length(RT_short_App)) 4*ones(1, length(RT_long_nostim)) 5*ones(1, length(RT_long_DLC)) 6*ones(1, length(RT_long_App))];

ha3 = subplot(2, 2, 3);
set(ha3, 'nextplot', 'add', 'TickDir', 'Out');

catNum=unique(catIdx_RT);

hp3 = plotSpread(RTdata, 'CategoryIdx',catIdx_RT,...
        'categoryMarkers',{'.','^', 'o', '.','^','o'},'categoryColors',{'k','b','b', 'k', 'b','b'}, 'spreadWidth', 0.8);

set(ha3, 'xlim', [0 7], 'ylim', [0 600], 'xtick', [1 2 3 4 5 6], 'xticklabel', {'Nostim', 'DLC', 'App','Nostim', 'DLC', 'App'})
line([1 1], prctile(RT_short_nostim, [25 75])*1000, 'color', 'r', 'linewidth', 2)
line([0.9 1.1], [median_RT_short_nostim median_RT_short_nostim]*1000, 'color', 'r', 'linewidth', 2)
line([2 2], prctile(RT_short_DLC, [25 75])*1000, 'color', 'r', 'linewidth', 2)
line([1.9 2.1], [median_RT_short_DLC median_RT_short_DLC]*1000, 'color', 'r', 'linewidth', 2)
line([3 3], prctile(RT_short_App, [25 75])*1000, 'color', 'r', 'linewidth', 2)
line([2.9 3.1], [median_RT_short_App median_RT_short_App]*1000, 'color', 'r', 'linewidth', 2)

line([4 4], prctile(RT_long_nostim, [25 75])*1000, 'color', 'r', 'linewidth', 2)
line([3.9 4.1], [median_RT_long_nostim median_RT_long_nostim]*1000, 'color', 'r', 'linewidth', 2)
line([5 5], prctile(RT_long_DLC, [25 75])*1000, 'color', 'r', 'linewidth', 2)
line([4.9 5.1], [median_RT_long_DLC median_RT_long_DLC]*1000, 'color', 'r', 'linewidth', 2)
line([6 6], prctile(RT_long_App, [25 75])*1000, 'color', 'r', 'linewidth', 2)
line([5.9 6.1], [median_RT_long_App median_RT_long_App]*1000, 'color', 'r', 'linewidth', 2)

ylabel('Reaction time (ms)')

% if length(catNum)==4
%     [p_short, h_short] = ranksum(RT_short_nostim, RT_short_stim);
%     [p_long, h_long] = ranksum(RT_long_nostim, RT_long_stim);
%     
%     text(1, 900, sprintf('p=%2.4f', p_short))
%     text(3, 900, sprintf('p=%2.4f', p_long))
% elseif ~ismember(catNum,4)
%     [p_short, h_short] = ranksum(RT_short_nostim, RT_short_stim);
%     
%     text(1, 900, sprintf('p=%2.4f', p_short))
%     text(3, 900, sprintf('p=NaN'))
% elseif ~ismember(catNum,2)
%     [p_long, h_long] = ranksum(RT_long_nostim, RT_long_stim);
%     
%     text(1, 900, sprintf('p=NaN', p_short))
%     text(3, 900, sprintf('p=%2.4f', p_long))
% end


%fprintf('short FP p value is %2.5f\n', p_short)
%fprintf('long FP p value is %2.5f\n', p_long)
mkdir('Fig');

savename = ['OptoEffect'  upper(bnew.Metadata.Metadata.SubjectName) '_' bnew.Metadata.Metadata.Date];
savename=fullfile(pwd, 'Fig', savename);

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])


