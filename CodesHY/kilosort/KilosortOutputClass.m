classdef KilosortOutputClass<handle
    %SpikeSortingOutput Data and figures after spike sorting 
    %    
    
    properties
        SpikeTable
        ChanMap
        ParamsKilosort
    end
    
    methods(Static)
        function KilosortOutput = BuildFromDir(dir_name_kilosort, dir_name_spikeTable)
            if nargin<=0
                dir_name_kilosort = './kilosort2_5_output';
            end
            if nargin<=1
                dir_name_spikeTable = './';
            end
            chanMap = load(fullfile(dir_name_kilosort,'chanMap.mat'));
            load(fillfile(dir_name_kilosort,'ops.mat'));
            load(fullfile(dir_name_spikeTable,'spikeTable.mat'));
            KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
        end  
    end
    
    methods(Access=private)
        function sortSpikeTable(obj)
            obj.SpikeTable = sortrows(obj.SpikeTable,{'ch','group'});
        end        
    end
        
    
    methods
        function obj = KilosortOutputClass(spikeTable, chanMap, ops)
            obj.SpikeTable = spikeTable;
            obj.ChanMap = chanMap;
            obj.ParamsKilosort = ops;
        end

%             buildR() Example:
%             For Kormblum: 
%             KilosortOutput.buildR(...
%                 'KornblumStyle', true,...
%                 'Subject', 'West',...
%                 'blocks', {'datafile001.nev','datafile002.nev'},...
%                 'Version', 'Version5',...
%                 'BpodProtocol', 'OptoRecording',...
%                 'Experimenter', 'HY');
% 
%             For 2FPs (500/1000): 
%             KilosortOutput.buildR(...
%                 'KornblumStyle', false,...
%                 'Subject', 'West',...
%                 'blocks', {'datafile001.nev','datafile002.nev'},...
%                 'Version', 'Version5',...
%                 'BpodProtocol', 'OptoRecording',...
%                 'Experimenter', 'HY');
%
%             For 2FPs (750/1500): 
%             KilosortOutput.buildR(...
%                 'KornblumStyle', false,...
%                 'Subject', 'West',...
%                 'blocks', {'datafile001.nev','datafile002.nev'},...
%                 'Version', 'Version4',...
%                 'BpodProtocol', 'OptoRecording',...
%                 'Experimenter', 'HY');
        function r = buildR(obj, varargin)
            KornblumStyle = true;
            ProbeStyle = false;
            Subject = 'West';
            blocks = {'datafile001.nev','datafile002.nev'};
            Version = 'Version5';
            BpodProtocol = 'OptoRecording';
            Experimenter = 'HY';
            NS6all = [];
            ephys_block_start = 'datafile001.nev';
            behavior_block_start = NaN;
            addForce = false;
            addLaser = false;
            b = [];
            BehaviorClass = [];
            saveWaveMean = false;
            
            if nargin>=2
                for i=1:2:size(varargin,2)
                    switch varargin{i}
                        case 'KornblumStyle'
                            KornblumStyle = varargin{i+1};
                        case 'ProbeStyle'
                            ProbeStyle = varargin{i+1};
                        case 'Subject'
                            Subject = varargin{i+1};
                        case 'Version'
                            Version =  varargin{i+1};
                        case 'BpodProtocol'
                            BpodProtocol =  varargin{i+1};    
                        case 'blocks'
                            blocks =  varargin{i+1}; 
                        case 'ephys_block_start'
                            ephys_block_start = varargin{k+1};
                        case 'behavior_block_start'
                            behavior_block_start = varargin{k+1};
                        case 'Experimenter'
                            Experimenter =  varargin{i+1}; 
                        case 'NS6all'
                            NS6all = varargin{i+1};
                        case 'addForce'
                            addForce = varargin{i+1};
                        case 'addLaser'
                            addLaser = varargin{i+1};
                        case 'b'
                            b = varargin{i+1};
                        case 'BehaviorClass'
                            BehaviorClass = varargin{i+1};
                        case 'saveWaveMean'
                            saveWaveMean = varargin{i+1};
                        otherwise
                            errordlg('unknown argument')
                    end
                end
            end

            if isnan(behavior_block_start)
                behavior_block_start = blocks{1};
            end
            if ~exist(ephys_block_start,'file')
                ephys_block_start = blocks{1};
            end

            % Read NS6 file.
            if isempty(NS6all)
                for i = 1:length(blocks)
                    if i == 1
                        openNSx([blocks{i}(1:end-3),'ns6'], 'read', 'report')
                        NS6all = NS6;
                    else
                        openNSx([blocks{i}(1:end-3),'ns6'], 'read', 'report')
                        NS6all(i) = NS6;
                    end
                end
            end

            if strcmp(behavior_block_start, ephys_block_start)
                t_start = 0;
            else
                % load behavior start time
                start_idx = strcmp(blocks, behavior_block_start);
                t0 = NS6all(start_idx).MetaTags.DateTimeRaw;
                
                % load ephys (spike sorting output) start time
                start_idx = strcmp(blocks, ephys_block_start);
                t1 = NS6all(start_idx).MetaTags.DateTimeRaw;
                
                % compute dt
                dt = t0-t1;
                t_start = dt(end)+dt(end-1)*1000+dt(end-2)*1000*60+dt(end-3)*1000*60*60;  % in ms
            end

            % Check spks
            units = {};
            k = 1;
            while k<=height(obj.SpikeTable)
                channel = obj.SpikeTable(k,:).ch{1};
                j = k+1;
                while j<=height(obj.SpikeTable) && obj.SpikeTable(j,:).ch{1} == channel
                    j = j+1;
                end
                IndNew=size(units, 1)+1;
                type = '';
                for i = k:j-1
                    if strcmp(obj.SpikeTable(i,:).group{1},'good')
                        type = [type, 's'];
                    else
                        type = [type, 'm'];
                    end
                end
                units{IndNew, 1} = channel;
                units{IndNew, 2} = type;
                units{IndNew, 3} = [];
                
                k = j;
            end
            
            if isempty(b) || isempty(BehaviorClass)
                MEDFile = dir('*Subject*.txt');
    
                if KornblumStyle
                    % Note: my (JY's) codes are stored in packages, e.g.,
                    % track_training_progress_advanced_KornblumStyle can be
                    % found in Behavior.MED.track_training_progress_advanced_KornblumStyle
                    b = Behavior.MED.track_training_progress_advanced_KornblumStyle(MEDFile.name);
                    BehaviorClass = Behavior.Timing.KornblumClass(MEDFile.name);
                elseif ProbeStyle
                    [b, BehaviorClass] = Behavior.MED.track_training_probe(MEDFile.name);
                else
                    [b, BehaviorClass] = Behavior.MED.track_training_progress_advanced(MEDFile.name);
                end
                
                behfile= dir('B_*mat');
                load(behfile.name)
            end
            BehaviorClass.Plot();
            BehaviorClass.Save();
            BehaviorClass.Print();
            % return FP if there is no FP (wait 1/2 sessions)
            
            if isempty(b.FPs)  
                b = UpdateWaitB(b); % add FP
            end

            EventOutCombined = []; % this one combines all event times and difference in time between blocks.

            % a name for saving the r array
            aGoodName   = ['RTarray_', b.Metadata.SubjectName, '_' b.Metadata.Date '.mat'];
            dBlockOnset = 0;
            % calculate time difference between different blocks
            
            for ib=1:length(blocks)
                nevfile = blocks{ib};
                if ~exist([nevfile(1:11) '.mat'],'file')
                    openNEV(nevfile, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
                end
                load([nevfile(1:11) '.mat'])
                switch Version
                    case 'Version4'
                        EventOut = DIO_Events4(NEV); % create
                    case 'Version5'
                        EventOut = DIO_Events5(NEV); % create
                        % Poke signals are incorrect. Update poke from bpod.  10/4/2022
                        EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                        EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                end
            
                if ib ==1
                    RecordingOnset = NS6all(1).MetaTags.DateTimeRaw;
                end
            
                if ib>1
                    dt_i = NS6all(ib).MetaTags.DateTimeRaw-RecordingOnset;
                    dBlockOnset(ib) = dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
                end
                %  update poke information in EventOut with bpod events
            
                EventOut.Meta.Subject = Subject;
                EventOut.Meta.Experimenter = Experimenter;
            
                if isfield(EventOut, 'Subject')
                    EventOut = rmfield(EventOut, 'Subject');
                end
                if isfield(EventOut, 'Experimenter')
                    EventOut = rmfield(EventOut, 'Experimenter');
                end
            
                if ib ==1
                    EventOutCombined = EventOut;
                    EventOutCombined = rmfield(EventOutCombined, 'TimeEvents');
                else
                    EventOutCombined.Meta(ib) = EventOut.Meta;
                    for k = 1:length(EventOutCombined.EventsLabels)
                        EventOutCombined.Onset{k} = [EventOutCombined.Onset{k}; EventOut.Onset{k}+dBlockOnset(ib)];
                        EventOutCombined.Offset{k} = [EventOutCombined.Offset{k}; EventOut.Offset{k}+dBlockOnset(ib)];
                    end
                end
            end
            
            BpodFile = dir([Subject '_Med*.mat']);
            BpodFilenames = {BpodFile.name};
            for i_file = 1:length(BpodFilenames)
                load(BpodFilenames{i_file});
    
                % Align Events
                switch BpodProtocol
                    case 'OptoRecording'
                        %  read bpod events
                        BpodEvents = Bpod_Events_MedOptoRecording(SessionData);
                        % Update poke based on data from Bpod events
                        EventOutCombined = UpdatePokeFromBpodEvents(EventOutCombined, BpodEvents);
                    case {'OptoRecordingMix',  'MedOptoRecMixKB'}  % optogenetic stimulation was applied at the onset of different events, we need to extract those times, and align them to blackrock's time
                        %  read bpod events
                        BpodEvents = Bpod_Events_MedOptoRecMix(SessionData);
                        EventOutCombined = UpdateDIOMedOptoRecMix(EventOutCombined, BpodEvents);
                    case 'OptoRecordingSelfTimed'
                        %  read bpod events
                        BpodEvents = Bpod_Events_MedOptoRecordingSelfTimed(SessionData);
                        % Update poke based on data from Bpod events
                        EventOutCombined = UpdatePokeFromBpodEvents(EventOutCombined, BpodEvents);
                end
            end
            
            EventOutCombined = AlignBehaviorClassToBR(EventOutCombined, BehaviorClass);
            
            %% construct an array (r) with aligned behavior, spikes and LFP data.
            % name is r
            
            % turn everything in minutes
            % single unit: 1; multiunit: 2
            r=[];
            r.BehaviorClass = BehaviorClass; % added 2023
            r.Meta = EventOutCombined.Meta;
            
            r.Behavior.Labels={
                'FrameOn',...
                'FrameOff', ...
                'LeverPress', ...
                'Trigger',...
                'LeverRelease',...
                'ValveOnset', ...
                'ValveOffset',...
                'PokeOnset',...
                'OptoStimOn',...
                'OptoStimOff'};
            
            r.Behavior.LabelMarkers = 1:length(r.Behavior.Labels);
            
            r.Behavior.Outcome                        = EventOutCombined.OutcomeEphys;
            % the followings are redundant but are listed so that other
            % programs still work. 
            r.Behavior.CorrectIndex                 =      find(strcmp(r.Behavior.Outcome, 'Correct'));
            r.Behavior.PrematureIndex            =      find(strcmp(r.Behavior.Outcome, 'Premature'));
            r.Behavior.LateIndex                      =      find(strcmp(r.Behavior.Outcome, 'Late'));
            r.Behavior.DarkIndex                     =      find(strcmp(r.Behavior.Outcome, 'Dark'));
            r.Behavior.Foreperiods                  =      EventOutCombined.FP_Ephys;
            r.Behavior.CueIndex                      =      EventOutCombined.CueEphys;
            
            r.Behavior.EventTimings = [];
            r.Behavior.EventMarkers = [];
            % add frame signal: 1 on, 2 off
            indframe = find(strcmp(EventOutCombined.EventsLabels, 'Frame'));
            eventonset = EventOutCombined.Onset{indframe};
            eventoffset = EventOutCombined.Offset{indframe};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2]; % frame onset  1; frame offset 2
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add leverpress onset and offset signal: 3 and 5
            indleverpress= find(strcmp(EventOutCombined.EventsLabels, 'LeverPress'));
            eventonset = EventOutCombined.Onset{indleverpress};
            eventoffset = EventOutCombined.Offset{indleverpress};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset),1)*5];
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add trigger stimulus signal: 4
            indtriggers= find(strcmp(EventOutCombined.EventsLabels, 'Trigger'));
            eventonset = EventOutCombined.Onset{indtriggers};
            triggeronset =EventOutCombined.Onset{indtriggers};
            if size(eventonset, 1)<size(eventonset, 2)
                eventonset = eventonset';
            end
            indevent = ones(length(eventonset), 1)*4;
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];
            
            figure(11); clf
            axes('nextplot', 'add', 'ylim', [0 10])
            
            plot(triggeronset, 4, 'go')
            text(triggeronset(1), 4.2, 'trigger')
            
            % add valve onset and offset signals: 6 and 7
            indvalve= find(strcmp(EventOutCombined.EventsLabels, 'Valve'));
            eventonset = EventOutCombined.Onset{indvalve};
            eventoffset = EventOutCombined.Offset{indvalve};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1)*6; ones(length(eventoffset), 1)*7]; % frame onset  1; frame offset 2
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            plot(eventoffset, 8, 'm^')
            text(eventoffset(1), 8.2, 'valve')
            
            % add poke onset signals: 8
            indpoke= strcmp(EventOutCombined.EventsLabels, 'Poke');
            eventonset = EventOutCombined.Onset{indpoke};
            eventmix = eventonset;
            indeventmix = ones(length(eventonset), 1)*8; 
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add optostim, if there is any. 9 on, 10 off
            indopto = find(strcmp(EventOutCombined.EventsLabels, 'OptoStim'));
            if ~isempty(indopto)
                eventonset = EventOutCombined.Onset{indopto};
                eventoffset = EventOutCombined.Offset{indopto}+BpodEvents.OptoStimDur;
                eventmix = [eventonset; eventoffset];
                indeventmix = [9*ones(length(eventonset), 1); 10*ones(length(eventoffset), 1)]; %
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            end
            
            % sort timing
            [r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
            r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);
            
            %% Add spikes
            r.Units.Channels = 1:obj.ParamsKilosort.Nchan;
            r.Units.Profile = units;
            r.Units.Definition = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
            r.Units.SpikeNotes = [];
            for i = 1:size(units, 1)
                sorting_code = units{i, 2};
                for k = 1:length(sorting_code)
                    switch sorting_code(k)
                        case 'm'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                        case 's'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                    end
                end
            end
            
            % put spikes
            for i = 1:size(r.Units.SpikeNotes, 1)
                if saveWaveMean
                    r.Units.SpikeTimes(i) = struct('timings',  [], 'wave', [], 'wave_mean', [], 'spk_id', []);
                    r.Units.SpikeTimes(i).wave_mean = obj.SpikeTable(i,:).waveforms_mean{1};
                else
                    r.Units.SpikeTimes(i) = struct('timings',  [], 'wave', [], 'spk_id', []);
                end
            
                % load spike time:
                r.Units.SpikeTimes(i).timings = obj.SpikeTable(i,:).spike_times_r{1} - t_start;
                r.Units.SpikeTimes(i).wave = obj.SpikeTable(i,:).waveforms{1};
            
                % remove  90% of spike waveforms to reduce file size
                % index spk train
                r.Units.SpikeTimes(i).spk_id = 1:length(r.Units.SpikeTimes(i).timings);
                if length(r.Units.SpikeTimes(i).timings)>10000
                    remove_percentage = 0.9;
                else
                    remove_percentage = 1-1000/length(r.Units.SpikeTimes(i).timings);
                end
            
                if remove_percentage>0
                    ind_to_remove = randperm(length(r.Units.SpikeTimes(i).timings), round(length(r.Units.SpikeTimes(i).timings)*remove_percentage));
                    r.Units.SpikeTimes(i).spk_id(ind_to_remove) = [];
                    r.Units.SpikeTimes(i).wave(ind_to_remove, :) = [];
                end
            end
            
             %% check if analog signal should be added to r
            if addForce
                x1 = dir('Force*.mat');
                if ~isempty(x1)
                    fdata = load(x1.name);
                    tnew = (1:length(fdata.index))*1000/30000 - t_start;
                    r.Analog.Force = [tnew; fdata.data]';
                    % resample data to 1000/sec
                    downsample_ratio = 30000/1000;                    
                    r.Analog.Force = downsample(r.Analog.Force, downsample_ratio);
                end
            end
            
            if addLaser
                x2 = dir('Laser*.mat');
                if ~isempty(x2)
                    odata = load(x2.name);
                    tnew = (1:length(odata.index))*1000/30000 - t_start;
                    r.Analog.Opto = [tnew; odata.data]';
                    % resample data to 1000/sec
                    downsample_ratio = 30000/1000;
                    r.Analog.Opto = downsample(r.Analog.Opto, downsample_ratio);
                end
            end
            
            % make sure UIAxesBehav and UIAxesRaster have the same width
            % Final touch double check the alignment. 
            % Check if it is kornblum class
            if KornblumStyle
                CorrectBehaviorEphysMapping(r,  r.BehaviorClass); % this also save r in the current directory
            end
            
            tic
            save(aGoodName,'r', '-v7.3');
            toc
            
            clc
            disp('~~~~~~~~~~~~~~~~~~')
            disp('~~~~~R is ready~~~~~')
            disp('~~~~~~~~~~~~~~~~~~') 
        end
        
        function r = buildRNeuropixels(obj, varargin)
            KornblumStyle = false;
            ProbeStyle = false;
            Subject = 'Neymar';
            BpodProtocol = 'OptoRecording';
            Experimenter = 'HY';
            b = [];
            BehaviorClass = [];
            
            if nargin>=2
                for i=1:2:size(varargin,2)
                    switch varargin{i}
                        case 'KornblumStyle'
                            KornblumStyle = varargin{i+1};
                        case 'ProbeStyle'
                            ProbeStyle = varargin{i+1};
                        case 'Subject'
                            Subject = varargin{i+1};
                        case 'BpodProtocol'
                            BpodProtocol =  varargin{i+1};    
                        case 'Experimenter'
                            Experimenter =  varargin{i+1}; 
                        case 'b'
                            b = varargin{i+1};
                        case 'BehaviorClass'
                            BehaviorClass = varargin{i+1};
                        otherwise
                            errordlg('unknown argument')
                    end
                end
            end

            % Check spks
            units = {};
            k = 1;
            while k<=height(obj.SpikeTable)
                channel = obj.SpikeTable(k,:).ch{1};
                j = k+1;
                while j<=height(obj.SpikeTable) && obj.SpikeTable(j,:).ch{1} == channel
                    j = j+1;
                end
                IndNew=size(units, 1)+1;
                type = '';
                for i = k:j-1
                    if strcmp(obj.SpikeTable(i,:).group{1},'good')
                        type = [type, 's'];
                    else
                        type = [type, 'm'];
                    end
                end
                units{IndNew, 1} = channel;
                units{IndNew, 2} = type;
                units{IndNew, 3} = [];
                
                k = j;
            end
            
            if isempty(b) || isempty(BehaviorClass)
                MEDFile = dir('*Subject*.txt');
    
                if KornblumStyle
                    % Note: my (JY's) codes are stored in packages, e.g.,
                    % track_training_progress_advanced_KornblumStyle can be
                    % found in Behavior.MED.track_training_progress_advanced_KornblumStyle
                    b = Behavior.MED.track_training_progress_advanced_KornblumStyle(MEDFile.name);
                    BehaviorClass = Behavior.Timing.KornblumClass(MEDFile.name);
                elseif ProbeStyle
                    [b, BehaviorClass] = Behavior.MED.track_training_probe(MEDFile.name);
                else
                    [b, BehaviorClass] = Behavior.MED.track_training_progress_advanced(MEDFile.name);
                end
                
                behfile= dir('B_*mat');
                load(behfile.name)
            end
            BehaviorClass.Plot();
            BehaviorClass.Save();
            BehaviorClass.Print();
            % return FP if there is no FP (wait 1/2 sessions)
            
            if isempty(b.FPs)  
                b = UpdateWaitB(b); % add FP
            end

            % a name for saving the r array
            aGoodName   = ['RTarray_', b.Metadata.SubjectName, '_' b.Metadata.Date '.mat'];
            
            load ./EventOut.mat;

            % Poke signals are incorrect. Update poke from bpod.  10/4/2022
            EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
            EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
            

            %  update poke information in EventOut with bpod events
            EventOut.Meta.Subject = Subject;
            EventOut.Meta.Experimenter = Experimenter;

            EventOutCombined = EventOut;
            EventOutCombined = rmfield(EventOutCombined, 'TimeEvents');
            
            
            BpodFile = dir([Subject '_Med*.mat']);
            BpodFilenames = {BpodFile.name};
            for i_file = 1:length(BpodFilenames)
                load(BpodFilenames{i_file});
    
                % Align Events
                switch BpodProtocol
                    case 'OptoRecording'
                        %  read bpod events
                        BpodEvents = Bpod_Events_MedOptoRecording(SessionData);
                        % Update poke based on data from Bpod events
                        EventOutCombined = UpdatePokeFromBpodEvents(EventOutCombined, BpodEvents);
                    case {'OptoRecordingMix',  'MedOptoRecMixKB'}  % optogenetic stimulation was applied at the onset of different events, we need to extract those times, and align them to blackrock's time
                        %  read bpod events
                        BpodEvents = Bpod_Events_MedOptoRecMix(SessionData);
                        EventOutCombined = UpdateDIOMedOptoRecMix(EventOutCombined, BpodEvents);
                    case 'OptoRecordingSelfTimed'
                        %  read bpod events
                        BpodEvents = Bpod_Events_MedOptoRecordingSelfTimed(SessionData);
                        % Update poke based on data from Bpod events
                        EventOutCombined = UpdatePokeFromBpodEvents(EventOutCombined, BpodEvents);
                end
            end
            
            EventOutCombined = AlignBehaviorClassToBR(EventOutCombined, BehaviorClass);
            
            %% construct an array (r) with aligned behavior, spikes and LFP data.
            % name is r
            
            % turn everything in minutes
            % single unit: 1; multiunit: 2
            r=[];
            r.BehaviorClass = BehaviorClass; % added 2023

            % update meta
            r.Meta = EventOutCombined.Meta;
            d = datetime(r.Meta.fileCreateTime);
            r.Meta.DateTime = datestr(d);
            r.Meta.DateTimeRaw = [d.Year, d.Month, 0, d.Day, d.Hour, d.Minute, d.Second, 0];

            r.Behavior.Labels={
                'FrameOn',...
                'FrameOff', ...
                'LeverPress', ...
                'Trigger',...
                'LeverRelease',...
                'ValveOnset', ...
                'ValveOffset',...
                'PokeOnset',...
                'OptoStimOn',...
                'OptoStimOff'};
            
            r.Behavior.LabelMarkers = 1:length(r.Behavior.Labels);
            
            r.Behavior.Outcome                        = EventOutCombined.OutcomeEphys;
            % the followings are redundant but are listed so that other
            % programs still work. 
            r.Behavior.CorrectIndex                 =      find(strcmp(r.Behavior.Outcome, 'Correct'));
            r.Behavior.PrematureIndex            =      find(strcmp(r.Behavior.Outcome, 'Premature'));
            r.Behavior.LateIndex                      =      find(strcmp(r.Behavior.Outcome, 'Late'));
            r.Behavior.DarkIndex                     =      find(strcmp(r.Behavior.Outcome, 'Dark'));
            r.Behavior.Foreperiods                  =      EventOutCombined.FP_Ephys;
            r.Behavior.CueIndex                      =      EventOutCombined.CueEphys;
            
            r.Behavior.EventTimings = [];
            r.Behavior.EventMarkers = [];
            % add frame signal: 1 on, 2 off
            indframe = find(strcmp(EventOutCombined.EventsLabels, 'Frame'));
            eventonset = EventOutCombined.Onset{indframe};
            eventoffset = EventOutCombined.Offset{indframe};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2]; % frame onset  1; frame offset 2
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add leverpress onset and offset signal: 3 and 5
            indleverpress= find(strcmp(EventOutCombined.EventsLabels, 'LeverPress'));
            eventonset = EventOutCombined.Onset{indleverpress};
            eventoffset = EventOutCombined.Offset{indleverpress};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset),1)*5];
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add trigger stimulus signal: 4
            indtriggers= find(strcmp(EventOutCombined.EventsLabels, 'Trigger'));
            eventonset = EventOutCombined.Onset{indtriggers};
            triggeronset =EventOutCombined.Onset{indtriggers};
            if size(eventonset, 1)<size(eventonset, 2)
                eventonset = eventonset';
            end
            indevent = ones(length(eventonset), 1)*4;
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];
            
            figure(11); clf
            axes('nextplot', 'add', 'ylim', [0 10])
            
            plot(triggeronset, 4, 'go')
            text(triggeronset(1), 4.2, 'trigger')
            
            % add valve onset and offset signals: 6 and 7
            indvalve= find(strcmp(EventOutCombined.EventsLabels, 'Valve'));
            eventonset = EventOutCombined.Onset{indvalve};
            eventoffset = EventOutCombined.Offset{indvalve};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1)*6; ones(length(eventoffset), 1)*7]; % frame onset  1; frame offset 2
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            plot(eventoffset, 8, 'm^')
            text(eventoffset(1), 8.2, 'valve')
            
            % add poke onset signals: 8
            indpoke= strcmp(EventOutCombined.EventsLabels, 'Poke');
            eventonset = EventOutCombined.Onset{indpoke};
            eventmix = eventonset;
            indeventmix = ones(length(eventonset), 1)*8; 
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add optostim, if there is any. 9 on, 10 off
            indopto = find(strcmp(EventOutCombined.EventsLabels, 'OptoStim'));
            if ~isempty(indopto)
                eventonset = EventOutCombined.Onset{indopto};
                eventoffset = EventOutCombined.Offset{indopto}+BpodEvents.OptoStimDur;
                eventmix = [eventonset; eventoffset];
                indeventmix = [9*ones(length(eventonset), 1); 10*ones(length(eventoffset), 1)]; %
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            end
            
            % sort timing
            [r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
            r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);
            
            %% Add spikes
%             r.Units.Channels = 1:obj.ParamsKilosort.Nchan;
            r.Units.Profile = units;
            r.Units.Definition = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
            r.Units.SpikeNotes = [];
            for i = 1:size(units, 1)
                sorting_code = units{i, 2};
                for k = 1:length(sorting_code)
                    switch sorting_code(k)
                        case 'm'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                        case 's'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                    end
                end
            end
            
            % put spikes
            for i = 1:size(r.Units.SpikeNotes, 1)
                r.Units.SpikeTimes(i) = struct('timings',  [], 'wave', [], 'wave_mean', [], 'spk_id', []);
                r.Units.SpikeTimes(i).wave_mean = obj.SpikeTable(i,:).waveforms_mean{1};
            
                % load spike time:
                r.Units.SpikeTimes(i).timings = reshape(obj.SpikeTable(i,:).spike_times_r{1}, 1, []);
                r.Units.SpikeTimes(i).wave = obj.SpikeTable(i,:).waveforms{1};

                if any(strcmpi(obj.SpikeTable.Properties.VariableNames, 'spike_ID'))
                    disp('spike_ID found! Escape reducing waveforms step!');
                    % the spike waveforms are already reduced
                    r.Units.SpikeTimes(i).spk_id = obj.SpikeTable(i,:).spike_ID{1};
                else
                    % remove 90% of spike waveforms to reduce file size
                    % index spk train
                    r.Units.SpikeTimes(i).spk_id = 1:length(r.Units.SpikeTimes(i).timings);
                    if length(r.Units.SpikeTimes(i).timings)>10000
                        remove_percentage = 0.9;
                    else
                        remove_percentage = 1-1000/length(r.Units.SpikeTimes(i).timings);
                    end
                
                    if remove_percentage>0
                        ind_to_remove = randperm(length(r.Units.SpikeTimes(i).timings), round(length(r.Units.SpikeTimes(i).timings)*remove_percentage));
                        r.Units.SpikeTimes(i).spk_id(ind_to_remove) = [];
                        r.Units.SpikeTimes(i).wave(ind_to_remove, :) = [];
                    end
                end
            end
            
            % make sure UIAxesBehav and UIAxesRaster have the same width
            % Final touch double check the alignment. 
            % Check if it is kornblum class
            if KornblumStyle
                CorrectBehaviorEphysMapping(r,  r.BehaviorClass); % this also save r in the current directory
            end
            
            tic
            save(aGoodName,'r', '-v7.3');
            toc
            
            clc
            disp('~~~~~~~~~~~~~~~~~~')
            disp('~~~~~R is ready~~~~~')
            disp('~~~~~~~~~~~~~~~~~~')         
        end

        function r = buildSingleR(obj, bpod_file, med_file, varargin)
            KornblumStyle = true;
            ProbeStyle = true;
            Subject = 'West';
            blocks = {'datafile001.nev','datafile002.nev'};
            Version = 'Version5';
            BpodProtocol = 'OptoRecording';
            Experimenter = 'HY';
            NS6all = [];
            saveWaveMean = false;
            
            if nargin>=4
                for i=1:2:size(varargin,2)
                    switch varargin{i}
                        case 'KornblumStyle'
                            KornblumStyle = varargin{i+1};
                        case 'ProbeStyle'
                            ProbeStyle = varargin{i+1};
                        case 'Subject'
                            Subject = varargin{i+1};
                        case 'Version'
                            Version =  varargin{i+1};
                        case 'BpodProtocol'
                            BpodProtocol =  varargin{i+1};    
                        case 'blocks'
                            blocks =  varargin{i+1}; 
                        case 'Experimenter'
                            Experimenter =  varargin{i+1}; 
                        case 'NS6all'
                            NS6all = varargin{i+1};
                        case 'saveWaveMean'
                            saveWaveMean = varargin{i+1};
                        otherwise
                            error('unknown argument!');
                    end
                end
            end

            % Read NS6 file.
            if isempty(NS6all)
                for i = 1:length(blocks)
                    if i == 1
                        openNSx([blocks{i}(1:end-3),'ns6'], 'read', 'report')
                        NS6all = NS6;
                    else
                        openNSx([blocks{i}(1:end-3),'ns6'], 'read', 'report')
                        NS6all(i) = NS6;
                    end
                end
            end

            if KornblumStyle
                % Note: my (JY's) codes are stored in packages, e.g.,
                % track_training_progress_advanced_KornblumStyle can be
                % found in Behavior.MED.track_training_progress_advanced_KornblumStyle
                b = Behavior.MED.track_training_progress_advanced_KornblumStyle(med_file);
                BehaviorClass = Behavior.Timing.KornblumClass(med_file);
                BehaviorClass.Plot();
                BehaviorClass.Save()
                BehaviorClass.Print()
            elseif ProbeStyle
                [b, BehaviorClass] = Behavior.MED.track_training_probe(med_file);
            else
                [b, BehaviorClass] = Behavior.MED.track_training_progress_advanced(med_file);
                BehaviorClass.Plot();
            end
            
            behfile= dir('B_*mat');
            load(behfile.name)
            % return FP if there is no FP (wait 1/2 sessions)
            
            if isempty(b.FPs)  
                b = UpdateWaitB(b); % add FP
            end
            
            load(bpod_file);

            EventOutCombined = []; % this one combines all event times and difference in time between blocks.

            % a name for saving the r array
            dBlockOnset = 0;
            % calculate time difference between different blocks
            
            for ib=1:length(blocks)
                nevfile = blocks{ib};
                openNEV(nevfile, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
                load([nevfile(1:11) '.mat'])
                switch Version
                    case 'Version4'
                        EventOut = DIO_Events4(NEV); % create
                    case 'Version5'
                        EventOut = DIO_Events5(NEV); % create
                end

                % Poke signals are incorrect. Update poke from bpod.  10/4/2022
                EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
            
                if ib ==1
                    RecordingOnset = NS6all(1).MetaTags.DateTimeRaw;
                end
            
                if ib>1
                    dt_i = NS6all(ib).MetaTags.DateTimeRaw-RecordingOnset;
                    dBlockOnset(ib) = dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
                end
                %  update poke information in EventOut with bpod events
            
                EventOut.Meta.Subject = Subject;
                EventOut.Meta.Experimenter = Experimenter;
            
                if isfield(EventOut, 'Subject')
                    EventOut = rmfield(EventOut, 'Subject');
                end
                if isfield(EventOut, 'Experimenter')
                    EventOut = rmfield(EventOut, 'Experimenter');
                end
            
                if ib ==1
                    EventOutCombined = EventOut;
                    EventOutCombined = rmfield(EventOutCombined, 'TimeEvents');
                else
                    EventOutCombined.Meta(ib) = EventOut.Meta;
                    for k = 1:length(EventOutCombined.EventsLabels)
                        EventOutCombined.Onset{k} = [EventOutCombined.Onset{k}; EventOut.Onset{k}+dBlockOnset(ib)];
                        EventOutCombined.Offset{k} = [EventOutCombined.Offset{k}; EventOut.Offset{k}+dBlockOnset(ib)];
                    end
                end
            end
            
            % Align Events
            switch BpodProtocol
                case 'OptoRecording'
                    %  read bpod events
                    BpodEvents = Bpod_Events_MedOptoRecording(SessionData);
                    % Update poke based on data from Bpod events
                    EventOutCombined = UpdatePokeFromBpodEvents(EventOutCombined, BpodEvents);
                case 'OptoRecordingMix'  % optogenetic stimulation was applied at the onset of different events, we need to extract those times, and align them to blackrock's time
                    %  read bpod events
                    BpodEvents = Bpod_Events_MedOptoRecMix(SessionData);
                    EventOutCombined = UpdateDIOMedOptoRecMix(EventOutCombined, BpodEvents);
            end
            
            EventOutCombined = AlignBehaviorClassToBR(EventOutCombined, BehaviorClass);
            
            %% construct an array (r) with aligned behavior, spikes and LFP data.
            % name is r
            
            % turn everything in minutes
            % single unit: 1; multiunit: 2
            r=[];
            r.BehaviorClass = BehaviorClass; % added 2023
            r.Meta = EventOutCombined.Meta;
            
            r.Behavior.Labels={
                'FrameOn',...
                'FrameOff', ...
                'LeverPress', ...
                'Trigger',...
                'LeverRelease',...
                'ValveOnset', ...
                'ValveOffset',...
                'PokeOnset',...
                'OptoStimOn',...
                'OptoStimOff'};
            
            r.Behavior.LabelMarkers = 1:length(r.Behavior.Labels);
            
            r.Behavior.Outcome                        = EventOutCombined.OutcomeEphys;
            % the followings are redundant but are listed so that other
            % programs still work. 
            r.Behavior.CorrectIndex                 =      find(strcmp(r.Behavior.Outcome, 'Correct'));
            r.Behavior.PrematureIndex            =      find(strcmp(r.Behavior.Outcome, 'Premature'));
            r.Behavior.LateIndex                      =      find(strcmp(r.Behavior.Outcome, 'Late'));
            r.Behavior.DarkIndex                     =      find(strcmp(r.Behavior.Outcome, 'Dark'));
            r.Behavior.Foreperiods                  =      EventOutCombined.FP_Ephys;
            r.Behavior.CueIndex                      =      EventOutCombined.CueEphys;
            
            r.Behavior.EventTimings = [];
            r.Behavior.EventMarkers = [];
            % add frame signal: 1 on, 2 off
            indframe = find(strcmp(EventOutCombined.EventsLabels, 'Frame'));
            eventonset = EventOutCombined.Onset{indframe};
            eventoffset = EventOutCombined.Offset{indframe};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2]; % frame onset  1; frame offset 2
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add leverpress onset and offset signal: 3 and 5
            indleverpress= find(strcmp(EventOutCombined.EventsLabels, 'LeverPress'));
            eventonset = EventOutCombined.Onset{indleverpress};
            eventoffset = EventOutCombined.Offset{indleverpress};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset),1)*5];
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add trigger stimulus signal: 4
            indtriggers= find(strcmp(EventOutCombined.EventsLabels, 'Trigger'));
            eventonset = EventOutCombined.Onset{indtriggers};
            triggeronset =EventOutCombined.Onset{indtriggers};
            if size(eventonset, 1)<size(eventonset, 2)
                eventonset = eventonset';
            end
            indevent = ones(length(eventonset), 1)*4;
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];
            
            figure(11); clf
            axes('nextplot', 'add', 'ylim', [0 10])
            
            plot(triggeronset, 4, 'go')
            text(triggeronset(1), 4.2, 'trigger')
            
            % add valve onset and offset signals: 6 and 7
            indvalve= find(strcmp(EventOutCombined.EventsLabels, 'Valve'));
            eventonset = EventOutCombined.Onset{indvalve};
            eventoffset = EventOutCombined.Offset{indvalve};
            eventmix = [eventonset; eventoffset];
            indeventmix = [ones(length(eventonset), 1)*6; ones(length(eventoffset), 1)*7]; % frame onset  1; frame offset 2
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            plot(eventoffset, 8, 'm^')
            text(eventoffset(1), 8.2, 'valve')
            
            % add poke onset signals: 8
            indpoke= strcmp(EventOutCombined.EventsLabels, 'Poke');
            eventonset = EventOutCombined.Onset{indpoke};
            eventmix = eventonset;
            indeventmix = ones(length(eventonset), 1)*8; 
            r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            
            % add optostim, if there is any. 9 on, 10 off
            indopto = find(strcmp(EventOutCombined.EventsLabels, 'OptoStim'));
            if ~isempty(indopto)
                eventonset = EventOutCombined.Onset{indopto};
                eventoffset = EventOutCombined.Offset{indopto}+BpodEvents.OptoStimDur;
                eventmix = [eventonset; eventoffset];
                indeventmix = [9*ones(length(eventonset), 1); 10*ones(length(eventoffset), 1)]; %
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
            end
            
            % sort timing
            [r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
            r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);
        end
        
        function r = buildRMultiSessions(obj, bpod_files, med_files, idx_blocks, varargin)
            KornblumStyle = true;
            ProbeStyle = true;
            Subject = 'West';
            blocks = {'datafile001.nev','datafile002.nev'};
            Version = 'Version5';
            BpodProtocol = 'OptoRecording';
            Experimenter = 'HY';
            NS6all = [];
            behavior_blocks = blocks;
            addForce = false;
            addLaser = false;
            saveWaveMean = false;
            
            if nargin>=5
                for i=1:2:size(varargin,2)
                    switch varargin{i}
                        case 'KornblumStyle'
                            KornblumStyle = varargin{i+1};
                        case 'ProbeStyle'
                            ProbeStyle = varargin{i+1};
                        case 'Subject'
                            Subject = varargin{i+1};
                        case 'Version'
                            Version =  varargin{i+1};
                        case 'BpodProtocol'
                            BpodProtocol =  varargin{i+1};    
                        case 'blocks'
                            blocks =  varargin{i+1}; 
                        case 'behavior_blocks'
                            behavior_blocks = varargin{k+1};
                        case 'Experimenter'
                            Experimenter =  varargin{i+1}; 
                        case 'NS6all'
                            NS6all = varargin{i+1};
                        case 'addForce'
                            addForce = varargin{i+1};
                        case 'addLaser'
                            addLaser = varargin{i+1};
                        case 'saveWaveMean'
                            saveWaveMean = varargin{i+1};
                        otherwise
                            errordlg('unknown argument')
                    end
                end
            end

            r_all = cell(length(bpod_files),1);
            for k = 1:length(r_all)
                r_all{k} = obj.buildSingleR(bpod_files{k}, med_files{k},...
                    'KornblumStyle', KornblumStyle,...
                    'ProbeStyle', ProbeStyle,...
                    'Subject', Subject,...
                    'Version', Version,...
                    'BpodProtocol', BpodProtocol,...
                    'blocks', blocks(idx_blocks{k}),...
                    'Experimenter', Experimenter,...
                    'NS6all', NS6all(idx_blocks{k}),...
                    'saveWaveMean', saveWaveMean...
                    );
            end

            if isempty(NS6all)
                ns6_files = cell(1,length(blocks));
                for k = 1:length(ns6_files)
                    ns6_files{k} = [extractBefore(blocks{k},'.nev'),'.ns6'];
                end
                for i_file =1:length(ns6_files)
                    if i_file ==1
                        openNSx(ns6_files{i_file}, 'read', 'report')
                        NS6all= NS6;
                    else
                        openNSx(ns6_files{i_file}, 'read', 'report')
                        NS6all(i_file)= NS6;
                    end
                end
            end

            for k = 1:length(r_all)
                if k==1
                    r = r_all{k};
                    continue
                end
                i0 = idx_blocks{1}(1);
                ik = idx_blocks{k}(1);
                dt_i = NS6all(ik).MetaTags.DateTimeRaw-NS6all(i0).MetaTags.DateTimeRaw; % start time of this session relative to the first session
                dt=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
                
                r2 = r_all{k};
                r.Meta(end+1:end+length(r2.Meta)) = r2.Meta;
                r.BehaviorClass(k) = r2.BehaviorClass;

                press_num = sum(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverPress')));
                r2.Behavior.CorrectIndex = r2.Behavior.CorrectIndex+press_num;
                r2.Behavior.PrematureIndex = r2.Behavior.PrematureIndex+press_num;
                r2.Behavior.LateIndex = r2.Behavior.LateIndex+press_num;
                r2.Behavior.DarkIndex = r2.Behavior.DarkIndex+press_num;
                r2.Behavior.CueIndex(:,1) = r2.Behavior.CueIndex(:,1)+press_num;
                r2.Behavior.EventTimings = r2.Behavior.EventTimings+dt;
                
                r.Behavior.Outcome = [r.Behavior.Outcome, r2.Behavior.Outcome];
                r.Behavior.CorrectIndex = [r.Behavior.CorrectIndex, r2.Behavior.CorrectIndex];
                r.Behavior.PrematureIndex = [r.Behavior.PrematureIndex, r2.Behavior.PrematureIndex];
                r.Behavior.LateIndex = [r.Behavior.LateIndex, r2.Behavior.LateIndex];
                r.Behavior.DarkIndex = [r.Behavior.DarkIndex, r2.Behavior.DarkIndex];
                r.Behavior.CueIndex = [r.Behavior.CueIndex; r2.Behavior.CueIndex];
                r.Behavior.EventTimings = [r.Behavior.EventTimings; r2.Behavior.EventTimings];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; r2.Behavior.EventMarkers];
                r.Behavior.Foreperiods = [r.Behavior.Foreperiods; r2.Behavior.Foreperiods];
            end


            % Check spks
            units = {};
            k = 1;
            while k<=height(obj.SpikeTable)
                channel = obj.SpikeTable(k,:).ch{1};
                j = k+1;
                while j<=height(obj.SpikeTable) && obj.SpikeTable(j,:).ch{1} == channel
                    j = j+1;
                end
                IndNew=size(units, 1)+1;
                type = '';
                for i = k:j-1
                    if strcmp(obj.SpikeTable(i,:).group{1},'good')
                        type = [type, 's'];
                    else
                        type = [type, 'm'];
                    end
                end
                units{IndNew, 1} = channel;
                units{IndNew, 2} = type;
                units{IndNew, 3} = [];
                
                k = j;
            end

            %% Add spikes
            r.Units.Channels = 1:obj.ParamsKilosort.Nchan;
            r.Units.Profile = units;
            r.Units.Definition = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
            r.Units.SpikeNotes = [];
            for i = 1:size(units, 1)
                sorting_code = units{i, 2};
                for k = 1:length(sorting_code)
                    switch sorting_code(k)
                        case 'm'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                        case 's'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                    end
                end
            end
            
            % put spikes
            for i = 1:size(r.Units.SpikeNotes, 1)
                if saveWaveMean
                    r.Units.SpikeTimes(i) = struct('timings',  [], 'wave', [], 'wave_mean', [], 'spk_id', []);
                    r.Units.SpikeTimes(i).wave_mean = obj.SpikeTable(i,:).waveforms_mean{1};
                else
                    r.Units.SpikeTimes(i) = struct('timings',  [], 'wave', [], 'spk_id', []);
                end
            
                % load spike time:
                r.Units.SpikeTimes(i).timings = obj.SpikeTable(i,:).spike_times_r{1};
                r.Units.SpikeTimes(i).wave = obj.SpikeTable(i,:).waveforms{1};
            
                % remove  90% of spike waveforms to reduce file size
                % index spk train
                r.Units.SpikeTimes(i).spk_id = 1:length(r.Units.SpikeTimes(i).timings);
                if length(r.Units.SpikeTimes(i).timings)>10000
                    remove_percentage = 0.9;
                else
                    remove_percentage = 1-1000/length(r.Units.SpikeTimes(i).timings);
                end
            
                if remove_percentage>0
                    ind_to_remove = randperm(length(r.Units.SpikeTimes(i).timings), round(length(r.Units.SpikeTimes(i).timings)*remove_percentage));
                    r.Units.SpikeTimes(i).spk_id(ind_to_remove) = [];
                    r.Units.SpikeTimes(i).wave(ind_to_remove, :) = [];
                end
            end
            
             %% check if analog signal should be added to r
            if addForce
                x1 = dir('Force*.mat');
                if ~isempty(x1)
                    fdata = load(x1.name);
                    tnew = (1:length(fdata.index))*1000/30000;
                    r.Analog.Force = [tnew; fdata.data]';
                    % resample data to 1000/sec
                    downsample_ratio = 30000/1000;                    
                    r.Analog.Force = downsample(r.Analog.Force, downsample_ratio);
                end
            end
            
            if addLaser
                x2 = dir('Laser*.mat');
                if ~isempty(x2)
                    odata = load(x2.name);
                    tnew = (1:length(odata.index))*1000/30000;
                    r.Analog.Opto = [tnew; odata.data]';
                    % resample data to 1000/sec
                    downsample_ratio = 30000/1000;
                    r.Analog.Opto = downsample(r.Analog.Opto, downsample_ratio);
                end
            end
            
%             % make sure UIAxesBehav and UIAxesRaster have the same width
%             % Final touch double check the alignment. 
%             % Check if it is kornblum class
%             if KornblumStyle
%                 CorrectBehaviorEphysMapping(r,  r.BehaviorClass); % this also save r in the current directory
%             end
            
            % a name for saving the r array
            aGoodName   = ['RTarray_', r.BehaviorClass(1).Subject, '_', r.BehaviorClass(1).Date, '.mat'];

            tic
            save(aGoodName,'r', '-v7.3');
            toc
            
            clc
            disp('~~~~~~~~~~~~~~~~~~')
            disp('~~~~~R is ready~~~~~')
            disp('~~~~~~~~~~~~~~~~~~') 
        end

        function setGroup(obj, unit_num, group)
            if ~strcmp(group,'mua') && ~strcmp(group,'good')
                error('Wrong group name. Group name should be "mua" or "good"')
            end
            obj.SpikeTable(unit_num,:).group{1} = group;
            obj.sortSpikeTable();
        end
        
        function setChannel(obj, unit_num, channel)
            obj.SpikeTable(unit_num,:).ch{1} = channel;
            obj.sortSpikeTable();
        end
        
        function out = getUnitInfo(obj, unit_num)
            out = obj.SpikeTable(unit_num,:);
        end
        
        function waveforms = getAllWaveforms(obj, unit_num)
            % waveforms: NspikesxNchannelxLengthWaveform
            [filepath,name,ext] = fileparts(obj.ParamsKilosort.fproc);
            gwfparams.dataDir = filepath;    % KiloSort/Phy output folder
            gwfparams.fileName = [name, ext];         % .dat file containing the raw 
            gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
            gwfparams.nCh = obj.ParamsKilosort.Nchan;                      % Number of channels that were streamed to disk in .dat file
            gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
            gwfparams.nWf = length(obj.SpikeTable(unit_num,:).spike_times{1});                    % Number of waveforms per unit to pull out
            gwfparams.spikeTimes = obj.SpikeTable(unit_num,:).spike_times{1}; % Vector of cluster spike times (in samples) same length as .spikeClusters
            gwfparams.spikeClusters = ones(length(obj.SpikeTable(unit_num,:).spike_times{1}),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes

            wf = getWaveforms(gwfparams);
            waveforms = squeeze(wf.waveForms);
        end
        
        function waveforms = getWaveforms(obj, unit_num, n_waveforms)
            % waveforms: NspikesxNchannelxLengthWaveform
            [filepath,name,ext] = fileparts(obj.ParamsKilosort.fproc);
            gwfparams.dataDir = filepath;    % KiloSort/Phy output folder
            gwfparams.fileName = [name, ext];         % .dat file containing the raw 
            gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
            gwfparams.nCh = obj.ParamsKilosort.Nchan;                      % Number of channels that were streamed to disk in .dat file
            gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
            gwfparams.nWf = n_waveforms;                    % Number of waveforms per unit to pull out
            gwfparams.spikeTimes = obj.SpikeTable(unit_num,:).spike_times{1}; % Vector of cluster spike times (in samples) same length as .spikeClusters
            gwfparams.spikeClusters = ones(length(obj.SpikeTable(unit_num,:).spike_times{1}),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes

            wf = getWaveforms(gwfparams);
            waveforms = squeeze(wf.waveForms);
        end
        
        function save(obj, dir_name)
            if nargin <= 1
                dir_name = './';
            end
            KilosortOutput = obj;
            save(fullfile(dir_name,'KilosortOutput.mat'), 'KilosortOutput');
        end
        
        function plotWaveformsMean(obj, unit_num)
            N_waveforms_std = 100;
            
            h = figure('Units','centimeters','Position',[10,10,10,10]);
            ax = axes(h,'NextPlot','add');
            x = obj.ChanMap.xcoords;
            y = obj.ChanMap.ycoords;
            
            waveforms = obj.SpikeTable(unit_num,:).waveforms_mean{1};
            
            waveforms_example = obj.getWaveforms(unit_num, N_waveforms_std);
            
            max_amp = max(max(waveforms,[],2)-min(waveforms,[],2));
            y_scale = 50/max_amp;
            x_scale = 0.5;
            
            x_plot = ((1:size(waveforms,2))-size(waveforms,2)/2)*x_scale;

            
            for k = 1:size(waveforms,1)
                plot(x_plot+x(k),-waveforms(k,:)*y_scale+y(k),'k-','LineWidth',2);
            end
            ylim_ax = ax.YLim;
            cla;
            
            for k = 1:size(waveforms,1)
                for j = 1:N_waveforms_std
                    plot(x_plot+x(k),-squeeze(waveforms_example(j,k,:))*y_scale+y(k),'-','Color',[0.8,0.8,0.8]);
                end
            end
            
            for k = 1:size(waveforms,1)
                plot(x_plot+x(k),-waveforms(k,:)*y_scale+y(k),'k-','LineWidth',2);
            end            
            ylim(ax, ylim_ax)
            
            xlabel('x')
            ylabel('depth (\mum)')
            ax.YDir = 'Reverse';  
            
            % add shadow (std err)
            
        end
        
        function plotWaveform(obj, unit_num)
            N = min(1000,length(obj.SpikeTable(unit_num,:).spike_times{1}));
            ch = obj.SpikeTable(unit_num,:).ch{1};
            
            waveforms = obj.SpikeTable(unit_num,:).waveforms{1};
            waveforms_mean = obj.SpikeTable(unit_num,:).waveforms_mean{1}(ch,:);
            idx = randperm(size(waveforms,1),N);
            figure;
            plot(waveforms(idx,:)','Color',[0.7,0.7,0.7])
            hold on
            plot(waveforms_mean','LineWidth',3,'Color','k')
            ylim([min(waveforms_mean)*1.5, max(waveforms_mean)*3])
        end

        function plotWaveformTetrodes(obj, unit_num)
            N = min(1000,length(obj.SpikeTable(unit_num,:).spike_times{1}));
            
            waveforms = obj.SpikeTable(unit_num,:).waveforms{1};
            waveforms_mean = mean(obj.SpikeTable(unit_num,:).waveforms{1});
            idx = randperm(size(waveforms,1),N);
            figure;
            plot(waveforms(idx,:)','Color',[0.7,0.7,0.7])
            hold on
            plot(waveforms_mean','LineWidth',3,'Color','k')
            ylim([min(waveforms_mean)*1.5, max(waveforms_mean)*3])
        end            
        
        function plotCorrelogram(obj, unit_nums, window)
            if nargin < 3
                window = 50;
            end
            binwidth = 1; % ms
            
            s = cell(length(unit_nums),1);
            for k = 1:length(unit_nums)
                s{k} = bin_timings(obj.SpikeTable(unit_nums(k),:).spike_times_r{1}, binwidth);
            end
            
            figure;
            for k = 1:length(unit_nums)
                for j = 1:length(unit_nums)
                    subplot(length(unit_nums),length(unit_nums),length(unit_nums)*(k-1)+j);
                    [auto_cor, lag] = xcorr(s{k},s{j},round(window/binwidth));
                    auto_cor(lag==0)=0;

                    bar(lag, auto_cor)
                    xline(-2);
                    xline(2);
                    if k==j
                        xlabel(['Unit#',num2str(k)])
                    else
                        xlabel(['Unit#',num2str(k),' vs ',num2str(j)]);
                    end
                end
            end
        end
        
        function plotISI(obj, unit_num, limit)
            if nargin < 3
                limit = 100;
            end
            spike_times = obj.SpikeTable(unit_num, :).spike_times_r{1};
            isi = diff(spike_times);
            figure;
            histogram(isi,'BinLimits',[0,limit],'BinWidth',1)
            xlim([0,limit])
            xlabel('ISI (ms)')
        end
        
        function plotProbe(obj)
            h = figure('Units','centimeters','Position',[10,10,5,5]);
            ax = axes(h);
            x = obj.ChanMap.xcoords;
            y = obj.ChanMap.ycoords;
            scatter(x,y,'o','filled','MarkerFaceColor','black')
            for k = 1:length(x)
                text(x(k)+5,y(k),num2str(k));
            end
            xlabel('x')
            ylabel('depth (\mum)')
            ax.YDir = 'Reverse';
        end
        
        function plotCorrelation(obj)
            bin_width = 1;
            c = zeros(height(obj.SpikeTable));
            for k = 1:height(obj.SpikeTable)
                for j = k:height(obj.SpikeTable)
                    if j == k
                        c(k,j)=1;
                        continue;
                    end
                    s1 = bin_timings(obj.SpikeTable(k,:).spike_times_r{1},bin_width);
                    s2 = bin_timings(obj.SpikeTable(j,:).spike_times_r{1},bin_width);
                    if length(s1)>length(s2)
                        s1 = s1(1:length(s2));
                    else
                        s2 = s2(1:length(s1));
                    end
                    c(k,j) = corr(s1',s2');
                    c(j,k) = c(k,j);
                end
            end
            figure;
            imagesc(c)
            colormap(plasma)
            clim([0,1])
        end

        function plotChannelActivity(obj)
            fig = EasyPlot.figure();
            ax = EasyPlot.axes(fig);
            x_range = range(obj.ChanMap.xcoords);
            y_range = range(obj.ChanMap.ycoords);
            width = 8;
            height = 8;
            if x_range > y_range
                height = width/x_range*y_range;
            else
                width = height/y_range*x_range;
            end
            EasyPlot.set(ax, 'Width', width, 'Height', height,...
                'MarginLeft', 0.5,...
                'XAxisVisible', 'off',...
                'YAxisVisible', 'off');

            n_channel = length(obj.ChanMap.chanMap);
            good_unit_channel = zeros(1,n_channel);
            all_channels = cell2mat(obj.SpikeTable(:,:).ch);
            for k = 1:n_channel
                good_unit_channel(k) = sum(all_channels==k);
            end
            colormap_this = jet(max(good_unit_channel)+1);
            colors = zeros(n_channel,3);
            for k = 1:n_channel
                colors(k,:) = colormap_this(sum(all_channels==k)+1,:);
            end
            scatter(ax, obj.ChanMap.xcoords,obj.ChanMap.ycoords,2,colors,"filled","o");
            ylim(ax, [min(obj.ChanMap.ycoords), max(obj.ChanMap.ycoords)]);
            xlim(ax, [min(obj.ChanMap.xcoords), max(obj.ChanMap.xcoords)]);

            ticks_all = linspace(0, 1, 2*size(colormap_this, 1)+1);
            ticks = ticks_all(2:2:length(ticks_all));
            tick_labels = 0:length(ticks)-1;
            EasyPlot.colorbar(ax,...
                'label', 'Unit number',...
                'colormap', colormap_this,...
                'Ticks', ticks,...
                'TickLabels', tick_labels,...
                'Height', height/2);

            sc = EasyPlot.scalebar(ax, 'Y', 'location', 'southwest',...
                'yBarLabel', '1 mm', 'yBarLength', 1000, 'yBarRatio', 1);
            EasyPlot.move(sc, 'dx', -0.5);

            EasyPlot.cropFigure(fig);
            EasyPlot.exportFigure(fig, 'channelActivity');
        end
        
    end
end

