function bUpdated =  GetOptoBehMix(isession, ibpodsession)
% Jianing Yu 
% 7/10/2021
% Simple version, no DLC is involved. 
% goal is to check success rate and reaction time when optogenetics is
% applied at different phases. 

b=track_training_progress_advanced(isession);

load(ibpodsession);
sd = SessionData;

Ntrials = length(sd.RawEvents.Trial); % number of trials

press_time_bpod = []; % press time

% These are the stim index for each bpod trial (1-5: stim, 0: no stim)
StimTypeLabels     =        {'NoStim', 'Approach',  'Press', 'Trigger', 'Release'};

StimTypes              =        zeros(1, Ntrials);  %0, No stim 1. Approach Stim 2. DLC detection stim 3. Press stim, etc. 
StimPattern             =       zeros(Ntrials,  4); 
StimTime                =        zeros(1, Ntrials); 
AllTrials                   =       [1:Ntrials];

% For each trial (defined in Bpod), we need to extract the following
% critical moments. 
AppTime = zeros(1, Ntrials); % we might have multiple app time in a single trial 
App2PressLatency = NaN*ones(1, Ntrials); % Nan: no press after approach, 0: approach not detected, pressed. -1: no idea what happens
PressTime = NaN*ones(1, Ntrials); % probably only one press in a single trial
TriggerTime = NaN*ones(1, Ntrials); % if an entry is NaN, trigger never arrived. 
ReleaseTime = zeros(1, Ntrials); % one release per trial. release time can only be derived from MED data
MedTTLTime = NaN*ones(1, Ntrials);
PokeTime =  NaN*ones(1, Ntrials); % this is the poke time following a succesful release. 

TrialOnset = zeros(1, Ntrials);

for j =1 : length(sd.RawEvents.Trial)
    
    TrialTimeStamp = sd.TrialStartTimestamp(j);
    TrialOnset(j) = TrialTimeStamp;
    
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))  % if this state exists, it is a stim trial following approach
        StimTypes(j)        =       1; % 1. stim once approach is detected.
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPressStim(1);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))  % if this state exists, it is a stim trial following press
        StimTypes(j)        =       2; % 3. stim is delivered once lever is pressed
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1))  % if this state exists, it is a stim trial following trigger signal
        StimTypes(j)        =      3; % 3. stim is delivered once trigger stimulus is given
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.ReleaseStim(1))  % if this state exists, it is a stim trial following release
        StimTypes(j)        =      4; % 4. stim is delivered once lever is released
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1);
    else
        StimTypes(j)        =      0; % 0. no stimulation
        StimPattern(j, :)   =     NaN*ones(1, 4);
        StimTime(j)         =       NaN;
    end;
    
    % check if there is approach
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.Masking(1)) % approach detected
        AppTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForApproach(end, 2); % Note that BNC2low signals the detection of animal approaching
        %
        % check if there is a press followed and what is the latency.
        
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
            App2PressLatency(j) =  sd.RawEvents.Trial{j}.States.WaitForTrigger(1) - sd.RawEvents.Trial{j}.States.WaitForApproach(end, 2);
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))
            App2PressLatency(j) =  sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1) - sd.RawEvents.Trial{j}.States.WaitForApproach(end, 2);
        else
            App2PressLatency(j) = NaN;
        end;
        
    elseif sd.RawEvents.Trial{j}.States.WaitForApproach(end) == sd.RawEvents.Trial{j}.States.WaitForTrigger(1) || sd.RawEvents.Trial{j}.States.WaitForApproach(end) == sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1)
        App2PressLatency(j) = 0;
    else
        App2PressLatency(j) = -1;
    end;
    
    %     if App2PressLatency(j)>5
    %         pause
    %     end;
    
    % check the press signal (waitforpress must be followed by waitfortrigger)
    % if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1)) || ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))
    %     if sd.RawEvents.Trial{j}.States.WaitForPress(1, 2) == sd.RawEvents.Trial{j}.States.WaitForTrigger(1, 1)  ||  sd.RawEvents.Trial{j}.States.WaitForPress(1, 2) == sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1, 1)
    %         PressTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPress(1, 2);
    %     elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(end)) && sd.RawEvents.Trial{j}.States.WaitForPressStim(1, 2) == sd.RawEvents.Trial{j}.States.WaitForTrigger(1, 1)
    %         PressTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPressStim(1, 2);
    %     end;
    % elseif ~isnan(sd.RawEvents.Trial{j}.WaitForTrigger(1))  || ~isnan(sd.RawEvents.Trial{j}.WaitForTriggerStim(1))
    %     if  ~isnan(sd.RawEvents.Trial{j}.WaitForTrigger(1))
    %         PressTime(j) = sd.RawEvents.Trial{j}.WaitForTrigger(1);
    %     else
    %         PressTime(j) = sd.RawEvents.Trial{j}.WaitForTriggerStim(1);
    %     end
    % end;
    
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
        PressTime(j) =  TrialTimeStamp +sd.RawEvents.Trial{j}.States.WaitForTrigger(1);
    elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))
        PressTime(j) =  TrialTimeStamp +sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1);
    end
    
    
    % check the trigger signal
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))  || ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))
        if sd.RawEvents.Trial{j}.States.WaitForTrigger(1, 2) == sd.RawEvents.Trial{j}.States.WaitForMedTTL(1, 1)  ||  sd.RawEvents.Trial{j}.States.WaitForTrigger(1, 2) == sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1, 1)
            TriggerTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForTrigger(1, 2);
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1)) && sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1, 2) == sd.RawEvents.Trial{j}.States.WaitForMedTTL(1, 1)
            TriggerTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1, 2);
        end;
    end;
    
    % check the Med TTL signal (correct release)
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(2)) && ~isnan(sd.RawEvents.Trial{j}.States.Release(1)) || ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(2)) && ~isnan(sd.RawEvents.Trial{j}.States.ReleaseStim(1))  
        MedTTLTime(j)        =        TrialTimeStamp +sd.RawEvents.Trial{j}.States.WaitForMedTTL(2);
    elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(2)) && ~isnan(sd.RawEvents.Trial{j}.States.Release(1))
        MedTTLTime(j)        =        TrialTimeStamp +sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(2);
    end;
    
    % check poke-reward delivery time
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPokedInHigh(1))
        PokeTime(j) = TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPokedInHigh(end);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPokedInLow(1))
        PokeTime(j) = TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPokedInLow(end);
    end;
    
end;

% Plot the whole session to verify behavioral performance
figure(26); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 13], 'paperpositionmode', 'auto');

ha=axes('unit','centimeters', 'position', [2 2 12 10], 'nextplot', 'add', 'xlim', [0 Ntrials], 'ylim', [-1 5], 'ytick', [0 1 2 3 4], 'yticklabel', {'NoStim', 'Appr', 'Press', 'Trigger', 'Release'});

plot(AllTrials(StimTypes == 0), StimTypes(StimTypes ==0), 'ko', 'markerfacecolor', 'k')
plot(AllTrials(StimTypes == 1), StimTypes(StimTypes ==1), 'ko', 'markerfacecolor', [0 184 255]/255)
plot(AllTrials(StimTypes == 2), StimTypes(StimTypes ==2), 'ko', 'markerfacecolor', [0 184 255]/255)
plot(AllTrials(StimTypes == 3), StimTypes(StimTypes ==3), 'ko', 'markerfacecolor', [0 184 255]/255)
plot(AllTrials(StimTypes == 4), StimTypes(StimTypes ==4), 'ko', 'markerfacecolor', [0 184 255]/255)


xlabel('Trial #')
ylabel('Trial types');

BpodPressTime = PressTime(~isnan(PressTime));
BpodPressTrials = find(~isnan(PressTime));

%% map bpod to MED  %  indout = findseqmatch2(seqmom, seqson, 'manual', 1, 'toprint', 1, 'printname', 'NewData')

IndMatch = findseqmatch2(b.PressTime, BpodPressTime, 'manual', 0, 'threshold', 8, 'toprint', 1, 'printname', isession(1:end-4));
Bpod2MedIndex = [1:Ntrials];
Bpod2MedIndex(isnan(PressTime)) = NaN;
Bpod2MedIndex(BpodPressTrials) = IndMatch;

% Figure out the performance 
FPs = unique(b.FPs(50:end));

PerformanceLabels = {'AllTrials', 'SuccessTrials', 'PrematureTrials', 'LateTrials', 'AbortedTrials'};

TrialsNoStim             =       zeros(2, 5);  % alltrials, success, premature, late
RTNoStim                 =       cell(1, length(FPs));  % reaction time
PrTNoStim                =       cell(1, length(FPs));  % press duration

% stim type = 1
TrialsApproachStim         =       zeros(2, 5);  
RTApproachStim             =       cell(1, length(FPs)); % reaction time
PrTApproachStim            =       cell(1, length(FPs));  % press duration
PrTApproachPressLatency            =       cell(1, length(FPs));  % press duration

% stim type = 2
TrialsPressStim         =       zeros(2, 4);  
RTPressStim             =       cell(1, length(FPs)); % reaction time
PrTPressStim            =       cell(1, length(FPs));  % press duration

% stim type = 3
TrialsTriggerStim         =       zeros(2, 4);  
RTTriggerStim             =       cell(1, length(FPs));  % reaction time
PrTTriggerStim            =       cell(1, length(FPs)); % press duration

for i =1:length(Bpod2MedIndex)
    if ~isnan(Bpod2MedIndex(i))
        iFP = b.FPs(Bpod2MedIndex(i));
        FPindx = find(FPs == iFP)
        
        i_App2PressLatency = App2PressLatency(i);
        
        if ~isempty(FPindx)
            switch StimTypes(i)
                case 0
                    
                    TrialsNoStim(FPindx, 1) = TrialsNoStim(FPindx, 1) + 1;
                    
                    if isnan(App2PressLatency(i))
                           TrialsNoStim(FPindx, 5) = TrialsNoStim(FPindx, 5) + 1;
                    end;
                    
                    if ~isempty(find(b.Correct == Bpod2MedIndex(i)))  % correct
                        TrialsNoStim(FPindx, 2) = TrialsNoStim(FPindx, 2) + 1;
                        RTNoStim{FPindx} = [RTNoStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))-iFP];
                        PrTNoStim{FPindx} = [PrTNoStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                    elseif  ~isempty(find(b.Premature == Bpod2MedIndex(i)))  % premature
                        TrialsNoStim(FPindx, 3) = TrialsNoStim(FPindx, 3) + 1;
                        PrTNoStim{FPindx} = [PrTNoStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))]; % press duration for premature trials
                    elseif  ~isempty(find(b.Late == Bpod2MedIndex(i))) % late
                        TrialsNoStim(FPindx, 4) = TrialsNoStim(FPindx, 4) + 1;
                        PrTNoStim{FPindx} = [PrTNoStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                    else
                        TrialsNoStim(FPindx, 1) = TrialsNoStim(FPindx, 1) - 1;
                    end;
                    
                case 1 % stim after approach is detected
                    
                    TrialsApproachStim(FPindx, 1) = TrialsApproachStim(FPindx, 1) + 1;
                    if ~isempty(find(b.Correct == Bpod2MedIndex(i)))  % correct
                        TrialsApproachStim(FPindx, 2) = TrialsApproachStim(FPindx, 2) + 1;
                        RTApproachStim{FPindx} = [RTApproachStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))-iFP];
                        PrTApproachStim{FPindx} = [PrTApproachStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                        PrTApproachPressLatency{FPindx} = [PrTApproachPressLatency{FPindx} i_App2PressLatency];
                    elseif  ~isempty(find(b.Premature == Bpod2MedIndex(i))) % premature
                        TrialsApproachStim(FPindx, 3) = TrialsApproachStim(FPindx, 3) + 1;
                        PrTApproachStim{FPindx} = [PrTApproachStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))]; % press duration for premature trials
                        PrTApproachPressLatency{FPindx} = [PrTApproachPressLatency{FPindx} i_App2PressLatency];
                    elseif  ~isempty(find(b.Late == Bpod2MedIndex(i)))
                        TrialsApproachStim(FPindx, 4) = TrialsApproachStim(FPindx, 4) + 1;
                        PrTApproachStim{FPindx} = [PrTApproachStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                        PrTApproachPressLatency{FPindx} = [PrTApproachPressLatency{FPindx} i_App2PressLatency];
                    else
                        TrialsApproachStim(FPindx, 1) = TrialsApproachStim(FPindx, 1) - 1;
                    end;
                    
                case 2 % stim during press
                    
                    TrialsPressStim(FPindx, 1) = TrialsPressStim(FPindx, 1) + 1;
                    if ~isempty(find(b.Correct == Bpod2MedIndex(i)))  % correct
                        TrialsPressStim(FPindx, 2) = TrialsPressStim(FPindx, 2) + 1;
                        RTPressStim{FPindx} = [RTPressStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))-iFP];
                        PrTPressStim{FPindx} = [PrTPressStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                    elseif  ~isempty(find(b.Premature == Bpod2MedIndex(i))) % premature
                        TrialsPressStim(FPindx, 3) = TrialsPressStim(FPindx, 3) + 1;
                        PrTPressStim{FPindx} = [PrTPressStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))]; % press duration for premature trials
                    elseif  ~isempty(find(b.Late == Bpod2MedIndex(i)))
                        TrialsPressStim(FPindx, 4) = TrialsPressStim(FPindx, 4) + 1;
                        PrTPressStim{FPindx} = [PrTPressStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                    else
                        TrialsPressStim(FPindx, 1) = TrialsPressStim(FPindx, 1) - 1;
                    end;
                    
                case 3 % stim during trigger
                    
                    TrialsTriggerStim(FPindx, 1) = TrialsTriggerStim(FPindx, 1) + 1;
                    if ~isempty(find(b.Correct == Bpod2MedIndex(i)))  % correct
                        TrialsTriggerStim(FPindx, 2) = TrialsTriggerStim(FPindx, 2) + 1;
                        RTTriggerStim{FPindx} = [RTTriggerStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))-iFP];
                        PrTTriggerStim{FPindx} = [PrTTriggerStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                    elseif  ~isempty(find(b.Premature == Bpod2MedIndex(i))) % premature
                        TrialsTriggerStim(FPindx, 3) = TrialsTriggerStim(FPindx, 3) + 1;
                        PrTTriggerStim{FPindx} = [PrTTriggerStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))]; % press duration for premature trials
                    elseif  ~isempty(find(b.Late == Bpod2MedIndex(i))) % late
                        TrialsTriggerStim(FPindx, 4) = TrialsTriggerStim(FPindx, 4) + 1;
                        PrTTriggerStim{FPindx} = [PrTTriggerStim{FPindx} 1000*(b.ReleaseTime(Bpod2MedIndex(i))-b.PressTime(Bpod2MedIndex(i)))];
                    else
                        TrialsTriggerStim(FPindx, 1) = TrialsTriggerStim(FPindx, 1) - 1;
                    end;
                case 4
                    display('skip')
            end;
        end;
    else
        
    end;
    
end;

%%

bu = b;
bu.Bpod2MedIndex = Bpod2MedIndex;
bu.StimTypeLabels       =       StimTypeLabels;
bu.StimTypeMarkers    =        [0:4];
bu.StimTypes               =        StimTypes;
bu.StimPattern              =       StimPattern;
bu.FPUnique                 =       FPs;
bu.TrialPerformanceLabels       = PerformanceLabels;

bu.TrialsNoStim            =       TrialsNoStim
bu.RTNoStim                =        RTNoStim;
bu.PrTNoStim               =        PrTNoStim;

bu.Approach2Press               =       App2PressLatency;

bu.TrialsApproachStim            =       TrialsApproachStim;
bu.RTApproachStim                =        RTApproachStim;
bu.PrTApproachStim               =        PrTApproachStim;
bu.PrTApproachStimLatency   =  PrTApproachPressLatency;

bu.TrialsPressStim            =       TrialsPressStim;
bu.RTPressStim                =        RTPressStim;
bu.PrTPressStim               =        PrTPressStim;

bu.TrialsTriggerStim            =       TrialsTriggerStim
bu.RTTriggerStim                =        RTTriggerStim;
bu.PrTTriggerStim               =        PrTTriggerStim;

bUpdated = bu;

save bUpdated bUpdated