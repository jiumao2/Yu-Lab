function bUpdated =  GetOptoBehMixDLC(isession, ibpodsession, DLCsession, VideoFile)

if nargin<4
    VideoFile = [];
end;

b=track_training_progress_advanced(isession);
load(ibpodsession);
sd = SessionData;

load(DLCsession); % this gives PosOut

Ntrials = length(sd.RawEvents.Trial); % number of trials

press_time_bpod = []; % press time

% These are the stim index for each bpod trial (1-5: stim, 0: no stim)
StimTypeLabels     =        {'NoStim', 'Approach', 'DLC', 'Press', 'Trigger', 'Release'};
StimTypes              =        zeros(1, Ntrials);  %0, No stim 1. Approach Stim 2. DLC detection stim 3. Press stim, etc.
StimPattern             =       zeros(Ntrials,  4);
StimTime                =        zeros(1, Ntrials);

% For each trial (defined in Bpod), we need to extract the following
% critical moments.
AppTime = cell(1, Ntrials); % we might have multiple app time in a single trial
DLCTime = cell(1, Ntrials); % DLC might return multiple detections in a single trial
PressTime = NaN*ones(1, Ntrials); % probably only one press in a single trial
TriggerTime = NaN*ones(1, Ntrials); % if an entry is NaN, trigger never arrived.
ReleaseTime = zeros(1, Ntrials); % one release per trial. release time can only be derived from MED data
MedTTLTime = NaN*ones(1, Ntrials);
PokeTime = zeros(1, Ntrials); % this is the poke time following a succesful release.

TrialOnset = zeros(1, Ntrials);

DLCStimTrials = [];
DLCStimTime = [];
DLCStimRankIndex =[]; % rank index of stim-related DLC detection
DLCStim_PressLatency = []; % time of the first press after DLC-stim

DLCNoStimTrials = [];
DLCNoStimTime = [];
DLCNoStimRankIndex =[]; % rank index of nostim-related DLC detection
DLCNoStim_PressLatency = [];

Approach_PressLatency = []; %latency to the first press after approach
ApproachStim_PressLatency=[]; % latency to the first press after approach(stim)

for j =1 : length(sd.RawEvents.Trial)
    
    
    jPressTime = NaN;
    TrialTimeStamp = sd.TrialStartTimestamp(j);
    TrialOnset(j) = TrialTimeStamp;
    
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForDLC(1))
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))  % DLC detected
            StimTypes(j)        =       2; % 1. stim once approach is detected.
            StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
            StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPressStim(1);
            DLCStimTrials = [DLCStimTrials j];
            DLCStimTime = [DLCStimTime  TrialTimeStamp+sd.RawEvents.Trial{j}.States.WaitForDLC(end, 2)];
            DLCStimRankIndex = [DLCStimRankIndex  find(sd.RawEvents.Trial{j}.Events.SoftCode6 == sd.RawEvents.Trial{j}.States.WaitForDLC(end, 2))];
            
            % find out the press situation
            if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
                jPressTime=  sd.RawEvents.Trial{j}.States.WaitForTrigger(1); % Pressed under 4 sec.
                DLCStim_PressLatency = [DLCStim_PressLatency; j jPressTime-sd.RawEvents.Trial{j}.States.WaitForDLC(end)];
                PressTime(j) = jPressTime + TrialTimeStamp;
            elseif  isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
                if isfield(sd.RawEvents.Trial{j}.Events, 'AnalogIn1_1') && ~isempty(find(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPressStim(end)))
                    jPressTime=  sd.RawEvents.Trial{j}.Events.AnalogIn1_1(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPressStim(end)); % Pressed under 4 sec.
                    latency = jPressTime - sd.RawEvents.Trial{j}.Events.SoftCode6(find(sd.RawEvents.Trial{j}.Events.SoftCode6>sd.RawEvents.Trial{j}.States.WaitForApproach(end), 1, 'first'));
                    if latency>0
                        DLCStim_PressLatency = [DLCStim_PressLatency; j latency];
                    else
                        DLCStim_PressLatency = [DLCStim_PressLatency; j NaN];
                    end;
                else
                    DLCStim_PressLatency = [DLCStim_PressLatency; j NaN];
                end
            else
                DLCStim_PressLatency = [DLCStim_PressLatency; j NaN];
                
            end
            
        else
            
            StimTypes(j)        =       NaN; % DLC failed to detect paw movement
            StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
            StimTime(j)         =        NaN;
        end;
    end;
    
    if length(DLCStimTime)~=size(DLCStim_PressLatency)
        pause
    end;
        
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1)) && StimTypes(j)==0  % if this state exists, it is a stim trial following approach
        StimTypes(j)        =       1; % 1. stim once approach is detected.
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPressStim(1);
        
        
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1)) % normal sequence
            jPressTime=  sd.RawEvents.Trial{j}.States.WaitForTrigger(1);
             ApproachStim_PressLatency = [ApproachStim_PressLatency; j jPressTime-sd.RawEvents.Trial{j}.States.WaitForApproach(end)];
            PressTime(j) = jPressTime + TrialTimeStamp;
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1)) && isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1)) % not pressed
            if isfield(sd.RawEvents.Trial{j}.Events, 'AnalogIn1_1') && ~isempty(find(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPressStim(end)))
                jPressTime=  sd.RawEvents.Trial{j}.Events.AnalogIn1_1(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPressStim(end)); % Pressed under 4 sec.
                ApproachStim_PressLatency = [ApproachStim_PressLatency; j jPressTime-sd.RawEvents.Trial{j}.States.WaitForApproach(end)];
                PressTime(j) = jPressTime + TrialTimeStamp;
            else
            ApproachStim_PressLatency = [ApproachStim_PressLatency; j NaN];
            end;
        end;
        
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))  % if this state exists, it is a stim trial following press
        StimTypes(j)        =       3; % 3. stim is delivered once lever is pressed
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1))  % if this state exists, it is a stim trial following trigger signal
        StimTypes(j)        =      4; % 3. stim is delivered once trigger stimulus is given
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.ReleaseStim(1))  % if this state exists, it is a stim trial following release
        StimTypes(j)        =      5; % 4. stim is delivered once lever is released
        StimPattern(j, :)   =       [sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
        StimTime(j)         =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForMedTTLStim(1);
    end;
    
 
    % figure out two things: approach to press and DLC to press
    if StimTypes(j) ~= 1 &&  StimTypes(j) ~= 2  % not a stim trial
        if ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1)) % normal sequence
            jPressTime=  sd.RawEvents.Trial{j}.States.WaitForTrigger(1);
            Approach_PressLatency = [Approach_PressLatency; j jPressTime-sd.RawEvents.Trial{j}.States.WaitForApproach(end)];
            PressTime(j) = jPressTime + TrialTimeStamp;
        elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1)) && isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1)) % not pressed
            if isfield(sd.RawEvents.Trial{j}.Events, 'AnalogIn1_1') && ~isempty(find(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPress(end)))
                    jPressTime=  sd.RawEvents.Trial{j}.Events.AnalogIn1_1(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPress(end)); % Pressed under 4 sec.
                    Approach_PressLatency = [Approach_PressLatency; j jPressTime-sd.RawEvents.Trial{j}.States.WaitForApproach(end)];
                    PressTime(j) = jPressTime + TrialTimeStamp;
            else
            Approach_PressLatency = [Approach_PressLatency; j NaN];
            end;
        end;
    end;
    
    
    if isfield(sd.RawEvents.Trial{j}.Events, 'SoftCode6') &&  StimTypes(j) == 0
        if ~isempty(find(sd.RawEvents.Trial{j}.Events.SoftCode6>sd.RawEvents.Trial{j}.States.WaitForApproach(end))) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1)) % DLC time must be later than approach time
            FirstDLCPostApproach =  TrialTimeStamp+sd.RawEvents.Trial{j}.Events.SoftCode6(find(sd.RawEvents.Trial{j}.Events.SoftCode6>sd.RawEvents.Trial{j}.States.WaitForApproach(end), 1, 'first'));
            DLCNoStimTrials = [DLCNoStimTrials j];
            DLCNoStimTime = [DLCNoStimTime FirstDLCPostApproach];
            DLCNoStimRankIndex = [DLCNoStimRankIndex  find(sd.RawEvents.Trial{j}.Events.SoftCode6 == FirstDLCPostApproach)];
            % find out the press situation
            if ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
                latency = sd.RawEvents.Trial{j}.States.WaitForTrigger(1)-sd.RawEvents.Trial{j}.Events.SoftCode6(find(sd.RawEvents.Trial{j}.Events.SoftCode6>sd.RawEvents.Trial{j}.States.WaitForApproach(end), 1, 'first'));
                if latency>0
                    DLCNoStim_PressLatency = [DLCNoStim_PressLatency; j latency];
                else
                    DLCNoStim_PressLatency = [DLCNoStim_PressLatency; j NaN];
                end;                
            elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1)) && ~isnan(sd.RawEvents.Trial{j}.States.WaitForPress(1)) && isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1)) % not pressed
                if isfield(sd.RawEvents.Trial{j}.Events, 'AnalogIn1_1') && ~isempty(find(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPress(end))) % perhaps pressed after the waitforpress period
                    jPressTime=  sd.RawEvents.Trial{j}.Events.AnalogIn1_1(sd.RawEvents.Trial{j}.Events.AnalogIn1_1>sd.RawEvents.Trial{j}.States.WaitForPress(end)); % Pressed under 4 sec.
                    latency = jPressTime - sd.RawEvents.Trial{j}.Events.SoftCode6(find(sd.RawEvents.Trial{j}.Events.SoftCode6>sd.RawEvents.Trial{j}.States.WaitForApproach(end), 1, 'first'));
                    if latency>0
                        DLCNoStim_PressLatency = [DLCNoStim_PressLatency; j latency];
                    else
                        display('No lever press')
                        DLCNoStim_PressLatency = [DLCNoStim_PressLatency; j NaN];
                    end;
                else
                    display('No lever press')
                    DLCNoStim_PressLatency = [DLCNoStim_PressLatency; j NaN];
                end
            end;
        end;
    end;
    
    if length(DLCNoStimTime)~=size(DLCNoStim_PressLatency)
        pause
    end;
    
    
    % check if there is approach
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForApproach(1))
        AppTime{j}          =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForApproach(:, 2); % Note that BNC2low signals the detection of animal approaching
    end;
    
    % check if there is 'SoftCode6'
    if isfield(sd.RawEvents.Trial{j}.Events, 'SoftCode6')
        DLCTime{j}   = TrialTimeStamp + sd.RawEvents.Trial{j}.Events.SoftCode6;
    end;
    
    
    % check the trigger signal
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForTrigger(1))
        TriggerTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForTrigger(1, 2);
    elseif ~isnan(sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1))
        TriggerTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForTriggerStim(1, 2);
    end;
    
    % check the Med TTL signal (correct release)
    if isfield(sd.RawEvents.Trial{j}.Events, 'BNC1High')
        MedTTLTime(j)        =        TrialTimeStamp + sd.RawEvents.Trial{j}.Events.BNC1High(1);
    end;
    
    % check poke-reward delivery time
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPokedInHigh(1))
        PokeTime(j) = TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPokedInHigh(end);
    elseif  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPokedInLow(1))
        PokeTime(j) = TrialTimeStamp + sd.RawEvents.Trial{j}.States.WaitForPokedInLow(end);
    end;
    
end;


TrialsPressed = setdiff(1: length(sd.RawEvents.Trial), find(isnan(PressTime)));
PressTime = PressTime(TrialsPressed);

% make an index of DLCTime to track the trial number
% TrialIndex = cell2mat(arrayfun(@(IDX)[repmat(IDX, size(DLCTime{IDX}, 1), 2), 1] , 1:length(DLCTime), 'uniform', 0));
TrialIndex = [];
RankIndex = [];
DLCTimeBpod = [];

for i = 1:length(DLCTime)
    
    if ~isempty(DLCTime{i})
        t_DLC = DLCTime{i};
        TrialIndex = [TrialIndex repmat(i, 1, length(t_DLC))];
        RankIndex = [RankIndex 1:length(t_DLC)];
        DLCTimeBpod = [DLCTimeBpod t_DLC];
    end;
end;

DLCTimeBonsai = PosOut.StimTime(:, 1);
DLCTimeBonsai = DLCTimeBonsai -  DLCTimeBonsai(1);

IndMatch = findseqmatch(DLCTimeBonsai*1000', DLCTimeBpod*1000, 0, 0);

ClusInds = zeros(1, size(PosOut.StimPos, 1));

for i = 1:length(PosOut.StimClus)
    ClusInds(PosOut.StimClus{i})=i;
end;

figure(24); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 25], 'paperpositionmode', 'auto' )

ha1 = subplot(4, 1, 1)
set(ha1, 'ylim', [2 5],'nextplot', 'add');

plot(DLCTimeBonsai, 4, 'ko');
plot(DLCTimeBpod, 3, 'c^');
dT = NaN*ones(1, length(IndMatch));
dT0 = DLCTimeBpod(1) - DLCTimeBonsai(IndMatch(1));

for i =1:length(IndMatch)
    if ~isnan(IndMatch(i))
        dT(i) = DLCTimeBpod(i) -  DLCTimeBonsai(IndMatch(i))-dT0;
        line([DLCTimeBpod(i) , DLCTimeBonsai(IndMatch(i))], [3, 4], 'color', 'k', 'linestyle', ':')
    end;
end;

ha2 = subplot(4, 1, 2)
plot([1:length(IndMatch)], dT, 'ko')
set(gca, 'ylim', [-2 2], 'ytick', [-2:2])

DLCMatch = [DLCTimeBpod; IndMatch; TrialIndex; RankIndex; ClusInds(IndMatch)];

ha3 = subplot(4, 1, 3)
plot(DLCStimRankIndex, 'ko')
ylabel('Stim-triggering DLC Rank')
set(ha3, 'ylim', [0 5])

ha4 = subplot(4, 1, 4)
[~, IndStimTime] = intersect(DLCMatch(1, :), DLCStimTime);

plot(DLCMatch(5, IndStimTime), 'mo', 'markerfacecolor', 'm')
set(ha4, 'ylim', [-1 4])
ylabel('Stim-triggering DLC cluster index')


%% plot paw position for Stim-triggering vs NoStim-triggering DLC
% (Note that these must be in the same range. There should not be systematic bias)

hf_DLC = figure(25); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 24 8], 'paperpositionmode', 'auto');
ha=axes('unit','centimeters', 'position', [1 1 6 6], 'nextplot', 'add', 'xlim', [0 400], 'ylim', [0 400], 'ydir', 'reverse')
title(strrep(ibpodsession(1:end-4), '_', '-'));
axis off
%% plot a pic of the frame

if ~isempty(VideoFile)
    vidObj=VideoReader(VideoFile);
    SampleFrame = rgb2gray(read(vidObj, [1000 1000]));
    imagesc(SampleFrame)
    colormap('gray')
end;


ClusColors = {[0.5 0.5 0.5], 'm', 'c'};
DLCStimClus = zeros(1, length(DLCStimTime));
DLCStimPos = zeros(length(DLCStimTime), 2);

for i =1:length(DLCStimTime)
    
    tDLC_Stim = DLCStimTime(i);
    ind_t_Stim = find(DLCTimeBpod == tDLC_Stim);
    this_Clus = DLCMatch(5, ind_t_Stim);
    ind_Bonsai = DLCMatch(2, ind_t_Stim);
    DLCStimClus(i) = this_Clus;
    plot(PosOut.StimPos(ind_Bonsai, 1), PosOut.StimPos(ind_Bonsai, 2), 'o', 'color', 'w', 'markerfacecolor', ClusColors{this_Clus+1}, 'linewidth', 1, 'markersize', 6)
    DLCStimPos(i, :) = [PosOut.StimPos(ind_Bonsai, 1) PosOut.StimPos(ind_Bonsai, 2)];
end;

DLCNoStimClus = zeros(1, length(DLCNoStimTime));
DLCNoStimPos = zeros(length(DLCNoStimTime), 2);

for i =1:length(DLCNoStimTime)
    
    tDLC_NoStim = DLCNoStimTime(i);
    ind_t_NoStim = find(DLCTimeBpod == tDLC_NoStim);
    this_Clus = DLCMatch(5, ind_t_NoStim);
    ind_Bonsai = DLCMatch(2, ind_t_NoStim);
    DLCNoStimClus(i) = this_Clus;
    plot(PosOut.StimPos(ind_Bonsai, 1), PosOut.StimPos(ind_Bonsai, 2), 's', 'color', 'w', 'markerfacecolor', ClusColors{this_Clus+1}, 'linewidth', 1, 'markersize',  6)
    DLCNoStimPos(i, :) = [PosOut.StimPos(ind_Bonsai, 1) PosOut.StimPos(ind_Bonsai, 2)];
end;

ha2=axes('unit','centimeters', 'position', [8 1.5 5 2.5], 'nextplot', 'add', 'xlim', [0 5], 'ylim', [0 1], 'ytick', [], 'ydir', 'reverse', 'box', 'on' , 'xcolor', ClusColors{2}, 'ycolor', ClusColors{2})
plot(DLCNoStim_PressLatency(DLCNoStimClus==1, 2), rand(1, length(find(DLCNoStimClus==1))), 'wo', 'markerfacecolor', 'k', 'markersize', 5);
plot(DLCStim_PressLatency(DLCStimClus==1, 2), rand(1, length(find(DLCStimClus==1))), 'wo', 'markerfacecolor', [0 184 255]/255, 'markersize', 5);

xlabel('Latency DLC-Press (s)')

ha3=axes('unit','centimeters', 'position', [8 5 5 2.5], 'nextplot', 'add', 'xlim', [0 5], 'ylim', [0 1], 'ytick', [], 'ydir', 'reverse',  'box', 'on' , 'xcolor', ClusColors{3}, 'ycolor', ClusColors{3})
plot(DLCNoStim_PressLatency(DLCNoStimClus==2, 2), rand(1, length(find(DLCNoStimClus==2))), 'wo', 'markerfacecolor', 'k', 'markersize', 5);
plot(DLCStim_PressLatency(DLCStimClus==2, 2), rand(1, length(find(DLCStimClus==2))), 'wo', 'markerfacecolor', [0 184 255]/255, 'markersize', 5);
xlabel('Latency DLC-Press (s)')

%% plot approach to press
ha4=axes('unit','centimeters', 'position', [14 1.5 5 2.5], 'nextplot', 'add', 'xlim', [0 5], 'ylim', [0 1], 'ytick', [], 'ydir', 'reverse', 'box', 'on' , 'xcolor', 'k', 'ycolor', 'k')
plot(Approach_PressLatency(find(~isnan(Approach_PressLatency(:, 2))), 2), rand(1, length(find(~isnan(Approach_PressLatency(:, 2))))), 'wo', 'markerfacecolor', 'k', 'markersize', 5);
plot(ApproachStim_PressLatency(find(~isnan(ApproachStim_PressLatency(:, 2))), 2), rand(1, length(find(~isnan(ApproachStim_PressLatency(:, 2))))), 'wo', 'markerfacecolor', [0 184 255]/255, 'markersize', 5);

xlabel('Latency Approach-Press (s)')

thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['DLCApproachMix_' strrep(ibpodsession(1:end-4), '-', '_')]);

saveas (gcf, tosavename, 'fig')
print (gcf,'-dpng', tosavename)
toc

bUpdated = b;
bUpdated.BpodSessionName                            =      ibpodsession;
bUpdated.Approach2PressLatencyNoStim        =     Approach_PressLatency;
bUpdated.Approach2PressLatencyStim            =      ApproachStim_PressLatency; % first row is (Bpod) trial index, second row is time
bUpdated.DLC2PressLatencyNoStim                =      DLCNoStim_PressLatency;
bUpdated.DLC2PressLatencyStim                     =      DLCStim_PressLatency;

bUpdated.DLCStimTime                                     =      DLCStimTime;
bUpdated.DLCStimPos                                       =      DLCStimPos;            
bUpdated.DLCStimClus                                      =      DLCStimClus;   
bUpdated.DLCNoStimTime                                =      DLCNoStimTime;
bUpdated.DLCNoStimPos                                  =      DLCNoStimPos;            
bUpdated.DLCNoStimClus                                 =      DLCNoStimClus;   

bUpdated.DLCTimeBpod                                    =   DLCTimeBpod;
bUpdated.DLCTimeBonsai                                  =  DLCTimeBonsai';

bUpdated.DLCMatchLabels                                 = {'DLCTimeBpod', 'Bpod2BonsaiIndex', 'TrialIndex', 'RankIndex', 'ClusterIndex', 'XPos', 'YPos'};
bUpdated.DLCMatch                                           = [DLCMatch; PosOut.StimPos(DLCMatch(2, :), 1)'; PosOut.StimPos(DLCMatch(2, :), 2)']; 



%% get press time from bpod, and match them to MED. One trial one press only
% TrialsPressed = setdiff(1: length(sd.RawEvents.Trial), find(isnan(PressTime)));
% PressTime = PressTime(TrialsPressed);
IndBpod2MED = findseqmatch(b.PressTime*1000, PressTime*1000, 0, 0);

bUpdated.Bpod2MEDLabels                             = {'BpodPressTime', 'BpodPressTrials', 'Bpod2MedIndex'}
bUpdated.BpodPressTimeTrials                        = [PressTime; TrialsPressed; IndBpod2MED];

    
%
% % Plot the whole session to verify behavioral performance
% figure(26); clf
% set(gcf, 'unit', 'centimeters', 'position',[2 2 15 13], 'paperpositionmode', 'auto');
%
% ha=axes('unit','centimeters', 'position', [2 2 12 10], 'nextplot', 'add', 'xlim', [0 20], 'ylim', [0 Ntrials] )
% xlabel('Time in a trial (s)')
% ylabel('Trial #');
