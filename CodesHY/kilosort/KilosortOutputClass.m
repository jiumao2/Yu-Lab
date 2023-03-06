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
        function buildR(obj, varargin)
            KornblumStyle = true;
            Subject = 'West';
            blocks = {'datafile001.nev','datafile002.nev'};
            Version = 'Version5';
            BpodProtocol = 'OptoRecording';
            Experimenter = 'HY';
            
            if nargin>=2
                for i=1:2:size(varargin,2)
                    switch varargin{i}
                        case 'KornblumStyle'
                            KornblumStyle = varargin{i+1};
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
            
            MEDFile = dir('*Subject*.txt');

            if KornblumStyle
                kb = KornblumClass(MEDFile.name);
                kb.plot();
                kb.print();
                kb.save();                
                track_training_progress_advanced_KornblumStyle(MEDFile.name);
            else
                track_training_progress_advanced(MEDFile.name);
            end
            
            behfile= dir('B_*mat');
            load(behfile.name)
%             BlankOut = [];
%             if ~isempty(app.BlankoutEditField.Value)
%                 BlankOut = str2num(app.BlankoutEditField.Value);
%                 BlankOut = reshape(BlankOut, 2, []);
%             end
            % return FP if there is no FP (wait 1/2 sessions)

            if isempty(b.FPs)  
                b = UpdateWaitB(b); % add FP
            end
            
            BpodFile = dir([Subject '*.mat']);
            load(BpodFile.name);
            
            EventOutAll = [];
            %% 

            for ib=1:length(blocks)

                nevfile = blocks{ib};
                openNEV(nevfile, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
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

                %  update poke information in EventOut with bpod events
                switch BpodProtocol
                    case 'OptoRecording'
                        %  read bpod events
                        bpodevents = Bpod_Events_MedOptoRecording(SessionData);
                        EventOut = UpdateDIOMedOpto(EventOut, bpodevents);
                    case 'OptoRecordingMix'  % optogenetic stimulation was applied at the onset of different events, we need to extract those times, and align them to blackrock's time
                        %  read bpod events                
                            bpodevents = Bpod_Events_MedOptoRecMix(SessionData);
                            EventOut = UpdateDIOMedOptoRecMix(EventOut, bpodevents);
                end
                % update Trigger signal and add a few behavioral events

                EventOut = AlignMED2BR(EventOut, b);

                EventOut.Meta.Subject = Subject;
                EventOut.Meta.Experimenter = Experimenter;

                if isfield(EventOut, 'Subject')
                    EventOut = rmfield(EventOut, 'Subject');
                end
                if isfield(EventOut, 'Experimenter')
                    EventOut = rmfield(EventOut, 'Experimenter');
                end
                if ib ==1
                    EventOutAll=EventOut;
                else
                    EventOutAll(ib)=EventOut;
                end
            end

            save EventOutAll EventOutAll

            %% construct an array (r) with aligned behavior, spikes and LFP data.
            % name is r

            % turn everything in minutes
            % single unit: 1; multiunit: 2
            r=[];

            dBlockOnset = 0;
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
            
            for i =1 :length(EventOutAll)
                r.Meta(i) = EventOutAll(i).Meta;
                r.Meta(i).DateTime = NS6all(i).MetaTags.DateTime;
                r.Meta(i).DateTimeRaw = NS6all(i).MetaTags.DateTimeRaw;
                r.Meta(i).DataDurationSec = NS6all(i).MetaTags.DataDurationSec;
            end
            
            % calculate time difference between different blocks
            if length(blocks)>1
                dBlockOnset = zeros(1, length(blocks)-1);
                for i=1:length(dBlockOnset)
                    dt_i = NS6all(i+1).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw; % start time of this session relative to the first session
                    dBlockOnset(i)=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
                end
                
                dBlockOnset=[0 dBlockOnset];
            end

            r.Behavior.Labels={'FrameOn', 'FrameOff', 'LeverPress', 'Trigger', 'LeverRelease', 'GoodPress', 'GoodRelease',...
                'ValveOnset', 'ValveOffset', 'PokeOnset', 'PokeOffset' , 'BadPokeFirstIn', 'BadPokeFirstOut'};
            r.Behavior.LabelMarkers = 1:length(r.Behavior.Labels);

            r.Behavior.CorrectIndex                 =      [];
            r.Behavior.PrematureIndex            =      [];
            r.Behavior.LateIndex                      =      [];
            r.Behavior.DarkIndex                     =       [];
            r.Behavior.Foreperiods                  =       [];
            r.Behavior.EventTimings = [];
            r.Behavior.EventMarkers = [];
            pressnum = 0;
            r.Behavior.CueIndex                      =       [];

            for i = 1:length(EventOutAll)

                if i>1
                    pressnum = pressnum +  length(EventOutAll(i-1).Onset{strcmp(EventOutAll(i-1).EventsLabels, 'LeverPress')});
                end

                % add frame signal: 1 on, 2 off
                indframe = find(strcmp(EventOutAll(i).EventsLabels, 'Frame'));
                eventonset = EventOutAll(i).Onset{indframe}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indframe}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
                EventNames{1} = 'FrameOn';
                EventNames{2} =  'FrameOff';

                % add leverpress onset and offset signal: 3 and 5
                indleverpress= find(strcmp(EventOutAll(i).EventsLabels, 'LeverPress'));
                eventonset = EventOutAll(i).Onset{indleverpress}+dBlockOnset(i);
                eventonset_press = EventOutAll(i).Onset{indleverpress};
                eventoffset = EventOutAll(i).Offset{indleverpress}+dBlockOnset(i);
                eventoffset_press =  EventOutAll(i).Offset{indleverpress};
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset),1)*5];
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

                if i==1
                    r.Behavior.CorrectIndex         = EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Correct')};
                    r.Behavior.PrematureIndex    = EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Premature')};
                    r.Behavior.LateIndex              = EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Late')};
                    r.Behavior.DarkIndex             = EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Dark')};
                    r.Behavior.CueIndex              =        transpose(EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Cue')});
                else
                    r.Behavior.CorrectIndex              =   [r.Behavior.CorrectIndex; EventOutAll(i).PerfIndex{ strcmp(EventOutAll(i).Performance, 'Correct')}+pressnum];
                    r.Behavior.PrematureIndex            =   [r.Behavior.PrematureIndex; EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Premature')}+pressnum];
                    r.Behavior.LateIndex                     =   [r.Behavior.LateIndex;EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Late')}+pressnum];
                    r.Behavior.DarkIndex                     =   [r.Behavior.DarkIndex; EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Dark')}+pressnum];
                    r.Behavior.CueIndex              =          [ r.Behavior.CueIndex; transpose(EventOutAll(i).PerfIndex{strcmp(EventOutAll(i).Performance, 'Cue')})];
                end

                r.Behavior.Foreperiods                  = [r.Behavior.Foreperiods; EventOutAll(i).FPs'];

                % add trigger stimulus signal: 4
                indtriggers= find(strcmp(EventOutAll(i).EventsLabels, 'Trigger'));
                eventonset = EventOutAll(i).Onset{indtriggers}+dBlockOnset(i);
                triggeronset = EventOutAll(i).Onset{indtriggers};
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

                % add good press and release signal: 6 and 7
                indgoodrelease= find(strcmp(EventOutAll(i).EventsLabels, 'GoodRelease'));
                eventonset = EventOutAll(i).Onset{indgoodrelease}+dBlockOnset(i);
                eventonset_goodrelease = EventOutAll(i).Onset{indgoodrelease};
                indevent = ones(length(eventonset), 1)*7; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];
                plot(eventonset_goodrelease, 7, 'ko')
                text(eventonset_goodrelease(1), 7.2, 'good release')


                eventonset_goodpress = zeros(length(eventonset_goodrelease), 1);
                for in=1:length(EventOutAll(i).Onset{indgoodrelease})
                    time_of_goodrelease = eventonset_goodrelease(in);
                    [~, index] = min(abs(time_of_goodrelease-eventoffset_press));
                    % find the onset
                    ind_onset = find(eventonset_press-eventoffset_press(index)<0, 1, 'last'); % the last onset that is less than the off time
                    if ~isempty(ind_onset)
                        eventonset_goodpress(in) = eventonset_press(ind_onset);
                    end
                end

                eventonset = eventonset_goodpress+dBlockOnset(i);
                indevent = ones(length(eventonset), 1)*6;
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];

                plot(eventonset_goodpress, 6, 'k*')
                text(eventonset_goodpress(1), 6.2, 'good press')

                % add valve onset and offset signals: 8 and 9
                indvalve= find(strcmp(EventOutAll(i).EventsLabels, 'Valve'));
                eventonset = EventOutAll(i).Onset{indvalve}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indvalve}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1)*8; ones(length(eventoffset), 1)*9]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

                plot(EventOutAll(i).Onset{indvalve}, 8, 'm^')
                text(EventOutAll(i).Onset{indvalve}(1), 8.2, 'valve')

                % add poke onset and offset signals: 10 and 11
                indpoke= find(strcmp(EventOutAll(i).EventsLabels, 'Poke'));
                eventonset = EventOutAll(i).Onset{indpoke}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indpoke}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1)*10; ones(length(eventoffset),1)*11]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

                % add badpoke signal: 12 on, 13 off
                indbadpoke = find(strcmp(EventOutAll(i).EventsLabels, 'BadPoke'));
                eventonset = EventOutAll(i).Onset{indbadpoke}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indbadpoke}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [12*ones(length(eventonset), 1); 13*ones(length(eventoffset), 1)]; % bad poke onset  12; badpoke offset 13
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

            end

            % sort timing
            [r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
            r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);

%%      plot behavior data
            figure; clf
            set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )
            ha1=subplot(4, 1, [1 2]);
            set(ha1, 'nextplot', 'add', 'xlim', [0 max(r.Behavior.EventTimings/(1000))], 'ytick', 1:length(r.Behavior.Labels), 'yticklabel',r.Behavior.Labels, 'fontsize', 8)
            plot(r.Behavior.EventTimings/(1000), r.Behavior.EventMarkers,'o', 'color', 'k','markersize', 3, 'linewidth', 1)
            line([0 max(r.Behavior.EventTimings/(1000))], [1:length(r.Behavior.Labels); 1:length(r.Behavior.Labels)], 'color', [0.8 0.8 0.8])


            r.Units.Channels                                = 1:obj.ParamsKilosort.Nchan;
            r.Units.Profile                                    = units;
            r.Units.Definition                               = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
            r.Units.SpikeNotes                             = [];

            for i                                              = 1:size(units, 1)
                sorting_code                             = units{i, 2};
                for k                                              = 1:length(sorting_code)
                    switch sorting_code(k)
                        case 'm'
                            r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                        case 's'
                            r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                    end
                end
            end

            spkchs = unique(r.Units.SpikeNotes(:, 1));
            allcolors                                          = varycolor(length(spkchs));

            ha2                                                 = subplot(4, 1, 3:4);
            set(ha2, 'xlim', get(ha1, 'xlim'), 'ylim', [0 size(r.Units.SpikeNotes , 1)+1], 'nextplot', 'add', 'fontsize', 8);
            linkaxes([ha1, ha2], 'x')

            % put spikes

            for i = 1:size(r.Units.SpikeNotes, 1)
                channel_id                                         = r.Units.SpikeNotes(i, 1);  % channel id
                r.Units.SpikeTimes(i)                             =   struct('timings',  [], 'wave', []);

                r.Units.SpikeTimes(i).timings = obj.SpikeTable(i,:).spike_times_r{1};

                r.Units.SpikeTimes(i).wave = obj.SpikeTable(i,:).waveforms{1};

                x_plot                                             = r.Units.SpikeTimes(i).timings;
                x_plot                                             = (x_plot)/(1000);
                y_plot                                             =  i -1 + 0.8*rand(1, length(x_plot));

                if ~isempty(x_plot)
                    plot(ha2, x_plot, y_plot,'.', 'color', allcolors(spkchs ==channel_id, :),'markersize', 4);
                end

            end

            % make sure UIAxesBehav and UIAxesRaster have the same width
%             app.UIAxesBehav.Position=[450 50 660 352];
%             app.UIAxesRaster.Position=[530 340 580 352];
            
            set(ha2, 'xlim', [0 max(r.Behavior.EventTimings/(1000))])

            close all
            tic
            save RTarrayAll r
            toc

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
            waveforms = waveforms(:,16:end);
            
            waveforms_example = obj.getWaveforms(unit_num, N_waveforms_std);
            waveforms_example = waveforms_example(:,:,16:end);
            
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
        
        function plotCorrelogram(obj, unit_nums)
            binwidth = 1; % ms
            window = 50;
            
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
        
        function plotISI(obj, unit_num)
            spike_times = obj.SpikeTable(unit_num, :).spike_times_r{1};
            isi = diff(spike_times);
            figure;
            histogram(isi,'BinLimits',[0,100],'BinWidth',1)
            xlim([0,100])
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
            bin_width = 10;
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
        end
        
    end
end

