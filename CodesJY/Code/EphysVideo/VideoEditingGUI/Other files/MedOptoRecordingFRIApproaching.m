%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2019 Sanworks LLC, Stony Brook, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function MedOptoRecordingFRIApproaching
% This protocl taks a TTL from MED, lights up the lick tube and deliver liquid upon licking
% Written by Jianing Yu, 11/2019
% Modified from MedLick_recording
% Add acquisition of force sensor data

% 2020/07/05 add optogenetic stimulation

% Written by Josh Sanders, 5/2015.
%
% SETUP  
% You will need:
% - A Bpod MouseBox (or equivalent) configured with 3 ports.
% - Place masking tape over the center port (Port 2).

% fast responding incentive: if MED sends back two 10 ms pulsesn(RT<300 ms), give more
% reward

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    % S.GUI.DurShow = 10; % Training level % 1 = Direct Delivery at both ports 2 = Poke for delivery
    S.GUI.RewardAmount  = 0.20; %ul
    S.GUI.StimRatio     = 0.25;
    S.GUI.StimDur       = 4000; % ms
    S.GUI.StimFreq      = 40; % Hz
    S.GUI.StimPulseDur  = 5;% ms
    S.GUI.Scale         = 1;% ms
    S.GUI.Delay         = 0;
    S.GUI.Rand          = 0;
    %     S.GUI.PortOutRegDelay = 0.5; % How long the mouse must remain out before poking back in
end

%% Start analog input
Ain = BpodAnalogIn('COM4'); % create the analog module
Ain.nActiveChannels     = 1;
Ain.InputRange{1}       = '-5V:5V'; 
Ain.SMeventsEnabled     = [1 0 0 0 0 0 0 0];
Ain.SamplingRate        = 1000; % 1 sample per ms
Ain.Thresholds          = [3 10 10 10 10 10 10 10];
Ain.ResetVoltages       = [2 -10  -10 -10 -10 -10 -10 -10];
Ain.startReportingEvents();

%% Initiate wave player
if (isfield(BpodSystem.ModuleUSB, 'WavePlayer1'))
    WavePlayerUSB = BpodSystem.ModuleUSB.WavePlayer1;
else
    error('Error: To run this protocol, you must first pair the AudioPlayer1 module with its USB port. Click the USB config button on the Bpod console.')
end

W=BpodWavePlayer(WavePlayerUSB); % name
W.BpodEvents = {'On', 'On', 'Off', 'Off'};
W.TriggerMode = 'Master';
W.OutputRange = '-5V:5V';
W.SamplingRate = 1000;
%% Define stimuli and send to analog module
SF = W.SamplingRate; % Use max supported sampling rate
StimFreq = S.GUI.StimFreq;
StimDur = S.GUI.StimDur;
PulseDur = S.GUI.StimPulseDur;
Scale = S.GUI.Scale;
Delay = S.GUI.Delay;
OptoRand = S.GUI.Rand;

OptoStim = zeros(1, StimDur);
pulse_num = floor(StimDur*StimFreq/1000); % number of pulses
for k = 1:pulse_num
    OptoStim(1+(k-1)*round(1000/StimFreq):PulseDur+(k-1)*round(1000/StimFreq))= 5*Scale;
end;
if OptoRand
    OptoStim = [zeros(1, round(Delay*rand)) OptoStim];
else
    OptoStim = [zeros(1, round(Delay)) OptoStim];
end;
 
W.loadWaveform (1, OptoStim) 

% alarm sound
% SF = W.SamplingRate; % Use max supported sampling rate
% StimFreq = S.GUI.StimFreq;
% StimDur = S.GUI.StimDur;
% PulseDur = S.GUI.StimPulseDur;
% Scale = S.GUI.Scale;

pulse_num =3; % number of pulses
AlarmStim = 5*ones(1, 100);
AlarmStim = repmat([AlarmStim zeros(1, 10)], 1, 5);

W.loadWaveform (2, AlarmStim) 

pulse_num =1; % number of pulses
PokeStim = 5*ones(1, 10);
PokeStim = repmat([PokeStim zeros(1, 10)], 1, 1);

W.loadWaveform (3, PokeStim) 

% masking flash
MaskStim = zeros(1, 5000); % 2500 ms
pulse_num = floor(5000*20/1000); % number of pulses
for k = 1:pulse_num
    MaskStim(1+(k-1)*round(1000/20):5+(k-1)*round(1000/20))= 5*Scale;
end;
W.loadWaveform (4, MaskStim) 

LoadSerialMessages('WavePlayer1', {['P', 1, 0], ['P',2, 1], ['P', 4, 2],  ['P', 8, 3]});% channel 1 is only for sound; 1: cue, 2: punishment
HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

% 
% PunishSound = ((rand(1,SF*.5)*2) - 1)*0.1;  % 0.5 s of random noise
% 
% % Generate early withdrawal sound
% W1 = GenerateSineWave(SF, 1000, .5); W2 = GenerateSineWave(SF, 1200, .5);
% EarlyWithdrawalSound = W1+W2;
% P = SF/100; Interval = P;
% 
% for x = 1:50 % Gate waveform to create pulses
%     EarlyWithdrawalSound(P:P+Interval) = 0;
%     P = P+(Interval*2);
% end
%  
% % generate tick sound
% TickSound = zeros(size(0:1/SF:0.1));
% inter_tick_interval = 0.025;
% 
% for i=1:1
%     TickSound(1+i*(inter_tick_interval*SF):20+i*(inter_tick_interval*SF))=2;
% %     TickSound(50+i*(inter_tick_interval*SF):20+i*(inter_tick_interval*SF))=-1;
% end;

% Program sound server

%% Define trials
% nSinglePokeTrials = 5;
% nDoublePokeTrials = 5;
% nTriplePokeTrials = 5;
% nRandomTrials = 850;
% MaxTrials = nSinglePokeTrials+nDoublePokeTrials+nTriplePokeTrials+nRandomTrials;
% TrialTypes = [ones(1,nSinglePokeTrials) ones(1,nDoublePokeTrials)*2 ones(1,nTriplePokeTrials)*3 ceil(rand(1,nRandomTrials)*3)];
TrialTypes = ones(1, 10000);
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
MaxTrials = length(TrialTypes);
%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [650 550 1200 500],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot   = axes('Position', [.05 .65 .25 .3]);
BpodSystem.GUIHandles.PressDurPlot     = axes('Position', [.35 .65 .25 .3]);
BpodSystem.GUIHandles.ApproachPlot     = axes('Position', [.65 .65 .25 .3]);
BpodSystem.GUIHandles.MovementPlot  = axes('Position', [.05 .1 .25 .4]);
BpodSystem.GUIHandles.HistoPlot     = axes('Position', [.35 .1 .25 .4]);


MedOptoPlotApproach(BpodSystem.GUIHandles,'init',TrialTypes);

BpodNotebook('init'); %Initialize Bpod notebook (for manual data annotation)
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main trial loop
ValveTime = 0.25;
BpodSystem.Data.Force=struct('x', [], 'y', []);

nvalve = round(ValveTime/0.05);
stimtrial = 0;
laststim = 0;

stimp = S.GUI.StimRatio;
if stimp>0
    seqout = MakeRandSeq(500,S.GUI.StimRatio);
else
    seqout = zeros(1, 500);
end;


for currentTrial = 1:MaxTrials
%     Ain.startLogging();
    if  S.GUI.StimRatio ~= stimp
        if S.GUI.StimRatio>0
            seqout = MakeRandSeq(500,S.GUI.StimRatio);
        else
            seqout = zeros(1, 500);
        end;
        stimp = S.GUI.StimRatio;
    end;
    
    stimtrial = seqout(rem(currentTrial, 500));
    
    if stimtrial ==1;
        nexttrial = 'WaitForPressStim';
    else
        nexttrial = 'WaitForPress';
    end;
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    if S.GUI.RewardAmount ~= ValveTime
        ValveTime = S.GUI.RewardAmount;
    end
    
    OptoRand = S.GUI.Rand;
    if OptoRand==0
        if  S.GUI.StimFreq ~= StimFreq   ||   S.GUI.StimDur ~= StimDur  ||  S.GUI.StimPulseDur ~= PulseDur ||  S.GUI.Delay ~= Delay 
            Scale = S.GUI.Scale;
            StimFreq = S.GUI.StimFreq;
            StimDur = S.GUI.StimDur;
            PulseDur = S.GUI.StimPulseDur;
            OptoStim = zeros(1, StimDur);
            pulse_num = floor(StimDur*StimFreq/1000); % number of pulses
            Delay = S.GUI.Delay;
            OptoRand = S.GUI.Rand;
            
            OptoStim = zeros(1, StimDur);
            pulse_num = floor(StimDur*StimFreq/1000); % number of pulses
            for k = 1:pulse_num
                OptoStim(1+(k-1)*round(1000/StimFreq):PulseDur+(k-1)*round(1000/StimFreq))= 5*Scale;
            end;
            if OptoRand~=0
                OptoStim = [zeros(1, round(Delay*rand)) OptoStim];
            else
                OptoStim = [zeros(1, round(Delay)) OptoStim];
            end;
            
            W.loadWaveform (1, OptoStim)
            LoadSerialMessages('WavePlayer1', {['P', 1, 0]});% channel 1 is only for sound; 1: cue, 2: punishment
        end;
    else
        tic
        Scale = S.GUI.Scale;
        StimFreq = S.GUI.StimFreq;
        StimDur = S.GUI.StimDur;
        PulseDur = S.GUI.StimPulseDur;
        OptoStim = zeros(1, StimDur);
        pulse_num = floor(StimDur*StimFreq/1000); % number of pulses
        Delay = S.GUI.Delay;
        OptoRand = S.GUI.Rand;
        
        OptoStim = zeros(1, StimDur);
        pulse_num = floor(StimDur*StimFreq/1000); % number of pulses
        for k = 1:pulse_num
            OptoStim(1+(k-1)*round(1000/StimFreq):PulseDur+(k-1)*round(1000/StimFreq))= 5*Scale;
        end;
        if OptoRand~=0
            OptoStim = [zeros(1, round(Delay*rand)) OptoStim];
        else
            OptoStim = [zeros(1, round(Delay)) OptoStim];
        end;
        
        W.loadWaveform (1, OptoStim)
        LoadSerialMessages('WavePlayer1', {['P', 1, 0]});% channel 1 is only for sound; 1: cue, 2: punishment
        toc
    end;
    

    
    sma = NewStateMatrix(); % Assemble state matrix
    
    % once approached, next trial could be WairForPress or WaitForPressStim
    sma = AddState(sma, 'Name', 'WaitForApproach', ...
        'Timer', 3600,...
        'StateChangeConditions', {'BNC2Low', 'Masking'},...
        'OutputActions', {});
    
    
    sma = AddState(sma, 'Name', 'Masking', ...
        'Timer', 0.001,...
        'StateChangeConditions', {'Tup',nexttrial},...
        'OutputActions', {'WavePlayer1', 4});
    
    % Wait for press,
    sma = AddState(sma, 'Name', 'WaitForPress', ...
        'Timer', 3600,...
        'StateChangeConditions', {'AnalogIn1_1', 'WaitForMedTTL', 'Port1In', 'BadPortEntry', 'BNC2High', 'WaitForPortExit'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'WaitForPressStim', ...
        'Timer', 3600,...
        'StateChangeConditions', {'AnalogIn1_1', 'WaitForMedTTL', 'Port1In', 'BadPortEntry', 'BNC2High', 'WaitForPortExit'},...
        'OutputActions', {'WavePlayer1', 1});
    %
    sma = AddState(sma, 'Name', 'BadPortEntry', ...
        'Timer', 0.25,...
        'StateChangeConditions', {'Port1Out', 'WaitForPress','Tup', 'WaitForPress'},...
        'OutputActions', {'WavePlayer1', 3});

    sma = AddState(sma, 'Name', 'WaitForMedTTL', ...
        'Timer', 4,...
        'StateChangeConditions', {'BNC1High', 'CheckForAdditionalPulse', 'Tup', 'Late'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'CheckForAdditionalPulse', ...
        'Timer', 0.025,...
        'StateChangeConditions', {'BNC1High', 'WaitForPokedInHigh', 'Tup', 'WaitForPokedInLow'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Late', ...
        'Timer', 1,...
        'StateChangeConditions', { 'Tup', 'exit'},...
        'OutputActions', {'WavePlayer1', 2});
    
    sma = AddState(sma, 'Name', 'InvalidEntry', ...
        'Timer', 0,...
        'StateChangeConditions', {'BNC2High', 'BriefExit'},...
        'OutputActions', {'BNCState', 1});  % invalidpoke --> BNC output 1 high
    
    sma = AddState(sma, 'Name', 'BriefExit', ...
        'Timer', 0.2,...
        'StateChangeConditions', {'BNC2Low', 'InvalidEntry', 'Tup', 'exit'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'WaitForPokedInHigh', ...
        'Timer', 200,...
        'StateChangeConditions', {'Port1In', 'WaterDelayHigh', 'Tup', 'WaterDelayHigh', 'AnalogIn1_1', nexttrial},...
        'OutputActions', {'PWM1', 255, 'BNCState', 1});% BNC1 approach
    
    %夹管阀水流太大加一个delay            
    sma = AddState(sma, 'Name', 'WaterDelayHigh', ...
        'Timer', 0.1,...
        'StateChangeConditions', { 'Tup', 'RewardDeliveryHigh'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'RewardDeliveryHigh', ...
        'Timer', ValveTime*1.5,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'PWM1', 0, 'ValveState', 1, 'BNCState', 2});  % Valve --> BNC output 2 high
    
        sma = AddState(sma, 'Name', 'WaitForPokedInLow', ...
        'Timer', 200,...
        'StateChangeConditions', {'Port1In', 'WaterDelayLow', 'Tup', 'WaterDelayLow', 'AnalogIn1_1', nexttrial},...
        'OutputActions', {'PWM1', 25, 'BNCState', 1});% BNC1 approach
                
     sma = AddState(sma, 'Name', 'WaterDelayLow', ...
        'Timer', 0.1,...
        'StateChangeConditions', { 'Tup', 'RewardDeliveryLow'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'RewardDeliveryLow', ...
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'PWM1', 0, 'ValveState', 1, 'BNCState', 2});  % Valve --> BNC output 2 high
    
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 2,...
        'StateChangeConditions', { 'Port1Out', 'DrinkingGrace', 'AnalogIn1_1', nexttrial, 'Tup',  'WaitForPortExit'},...
        'OutputActions', {'PWM1', 0, 'WavePlayer1', 3});  % , 'WavePlayer1', 3
    
    sma = AddState(sma, 'Name', 'DrinkingGrace', ...
        'Timer', 0.5,...
        'StateChangeConditions', {'Tup', 'WaitForPortExit', 'Port1In', 'Drinking'},...
        'OutputActions', {'PWM1', 0});
    
    sma = AddState(sma, 'Name', 'WaitForPortExit', ...
        'Timer', 0.2,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {'PWM1', 0});
    
    SendStateMatrix(sma);
    SaveProtocolSettings(S); % Saves the default settings to the disk location selected in the launch manager.
    
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        
        force_data.x = [];
        force_data.y = [];
%         force_data      =    Ain.getData();
%         force_data.x    =     force_data.x+BpodSystem.Data.TrialStartTimestamp(currentTrial);
        BpodSystem.Data.Force(currentTrial) = force_data;
        
        UpdateOutcomePlot(BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
%         
        return
    end
end



function UpdateOutcomePlot(Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);

t.MedTTL        =   NaN*ones(1, Data.nTrials);
t.InvalidEntry  =   NaN*ones(1, Data.nTrials);
t.RewardEntry   =   NaN*ones(1, Data.nTrials);
t.PressHistory   =   NaN*ones(1, Data.nTrials);
t.Stim    =    NaN*ones(1, Data.nTrials);
t.Approch_Press  =    NaN*ones(1, Data.nTrials);

t.Outcomes = Outcomes;

for x = 1:Data.nTrials
    TrialOnset = Data.TrialStartTimestamp(x);
    
    % check for TTL
    if ~isnan(Data.RawEvents(1).Trial{x}.States.CheckForAdditionalPulse(1))
        t.MedTTL(x) = TrialOnset + Data.RawEvents(1).Trial{x}.States.CheckForAdditionalPulse(1);
    end
    
    % check for approach-to-press
    if ~isnan(Data.RawEvents(1).Trial{x}.States.WaitForMedTTL(1))
        t.Approch_Press(x) = Data.RawEvents(1).Trial{x}.States.WaitForMedTTL(1)- Data.RawEvents(1).Trial{x}.States.WaitForApproach(end);
    end
    
    % check for invalid entry
    if ~isnan(Data.RawEvents(1).Trial{x}.States.InvalidEntry(1))
        t.InvalidEntry(x) = TrialOnset + Data.RawEvents(1).Trial{x}.States.InvalidEntry(1);
    end
    
    % check for reward entry
    if ~isnan(Data.RawEvents(1).Trial{x}.States.RewardDeliveryLow(1))
        t.RewardEntry(x) = TrialOnset + Data.RawEvents(1).Trial{x}.States.RewardDeliveryLow(1);
    elseif ~isnan(Data.RawEvents(1).Trial{x}.States.RewardDeliveryHigh(1))
        t.RewardEntry(x) = TrialOnset + Data.RawEvents(1).Trial{x}.States.RewardDeliveryHigh(1);
    end
    
    if ~isnan(Data.RawEvents(1).Trial{x}.States.CheckForAdditionalPulse(1))
        if ~isnan(Data.RawEvents(1).Trial{x}.States.WaitForPressStim(1))
            t.Stim(x) = 1;
            t.PressHistory(x) = Data.RawEvents(1).Trial{x}.States.CheckForAdditionalPulse(1)-Data.RawEvents(1).Trial{x}.States.WaitForPressStim(end);
        else
            t.PressHistory(x) = Data.RawEvents(1).Trial{x}.States.CheckForAdditionalPulse(1)-Data.RawEvents(1).Trial{x}.States.WaitForPress(end);
        end;
    end
end;
    
MedOptoPlotApproach(BpodSystem.GUIHandles,'update',t);
