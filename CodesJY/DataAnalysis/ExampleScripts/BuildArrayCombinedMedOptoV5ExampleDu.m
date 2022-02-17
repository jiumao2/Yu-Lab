%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% This applies to the new Blackrock system%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %  
% Build behavior array from all blocks.
% with Badpoke information from bpod

name = 'Du';
blocks                                             = { '001', '002'}; % these are different sessions


% % m: multiunits  s: single units
units   =  {
    11      'ss'            []
    };

BpodFile = 'Du_MedOptoRecording_20210204_155517.mat';

%% Extract behavior times from MED
% bout=track_training_progress_advanced('2020-01-23_15h58m_Subject Lucky.txt');

if isempty(dir(['B_*.mat']))
    medfile = dir(['*' name '.txt']);
    track_training_progress_advanced(medfile.name);
end;

behfile= dir('B_*mat');
load(fullfile(behfile.folder, behfile.name))

cfolder = pwd;

EventOutAll = [];

for ib=1:length(blocks)
    
    nevfile = ['datafile' blocks{ib} '.nev'];
    openNEV(nevfile, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
    EventOut = DIO_Events4(NEV) % create
    
%  read bpod events
     load(BpodFile)
     bpodevents = Bpod_Events_MedOptoRecording(SessionData);
     
%  update poke information in EventOut with bpod events
    EventOut = UpdateDIOMedOpto(EventOut, bpodevents);
    
    % update Trigger signal and add a few behavioral events
    EventOut = AlignMED2BR(EventOut, b);
    
    %     EventOut =
    %
    %             Meta: [1×1 struct]
    %       TimeEvents: [363980×7 double]
    %     EventsLabels: {1×7 cell}
    %            Onset: {1×7 cell}
    %           Offset: {1×7 cell}
    %      Performance: {'Correct'  'Premature'  'Late'  'Dark'}
    %        PerfIndex: {1×4 cell}
    %              FPs: [1×128 double]
    
    
    EventOut.Meta.Subject = name;
    EventOut.Meta.Experimenter = 'Jianing Yu';
    
    if isfield(EventOut, 'Subject')
        EventOut = rmfield(EventOut, 'Subject');
    end;
    if isfield(EventOut, 'Experimenter')
        EventOut = rmfield(EventOut, 'Experimenter');
    end;
    
    save EventOut EventOut
    
    if ib ==1
        EventOutAll=EventOut;
    else
        EventOutAll(ib)=EventOut;
    end;
    
end;

EventOutCombined = EventOutAll;

cd(cfolder)
save EventOutCombined EventOutAll
save EventOutAll EventOutAll

%% construct an array (r) with aligned behavior, spikes and LFP data.
% name is r

% turn everything in minutes
% single unit: 1; multiunit: 2
r=[];

for i =1 :length(EventOutAll)
    if i ==1
        r.Meta(i) = EventOutAll(i).Meta;
    else
        r.Meta(i) = EventOutAll(i).Meta;
    end;
end;

dBlockOnset = 0;

% calculate time difference between different blocks
if length(blocks)>1
    dBlockOnset = zeros(1, length(blocks)-1);
    for i=1:length(dBlockOnset)
        dt_i = EventOutAll(i+1).Meta.DateTimeRaw-EventOutAll(1).Meta.DateTimeRaw;
        dBlockOnset(i)=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
    end;
    
    dBlockOnset=[0 dBlockOnset];
end;

 
r.Behavior.Labels={'FrameOn', 'FrameOff', 'LeverPress', 'Trigger', 'LeverRelease', 'GoodPress', 'GoodRelease',...
   'ValveOnset', 'ValveOffset', 'PokeOnset', 'PokeOffset' , 'BadPokeFirstIn', 'BadPokeFirstOut'};
r.Behavior.LabelMarkers = [1:length(r.Behavior.Labels)];

r.Behavior.CorrectIndex                 =      [];
r.Behavior.PrematureIndex            =      [];
r.Behavior.LateIndex                      =      [];
r.Behavior.DarkIndex                     =       [];
r.Behavior.Foreperiods                  =       [];

r.Behavior.EventTimings = [];
r.Behavior.EventMarkers = [];
pressnum = 0;
 
for i = 1:length(EventOutAll)
 
    if i>1
        pressnum = pressnum +  length(EventOutAll(i-1).Onset{strcmp(EventOutAll(i-1).EventsLabels, 'LeverPress')});
    end;
      
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
        r.Behavior.CorrectIndex         = EventOutAll(i).PerfIndex{ find(strcmp(EventOutAll(i).Performance, 'Correct'))};
        r.Behavior.PrematureIndex    = EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Premature'))};
        r.Behavior.LateIndex              = EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Late'))};
        r.Behavior.DarkIndex             = EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Dark'))};
    else
        r.Behavior.CorrectIndex              =   [r.Behavior.CorrectIndex; EventOutAll(i).PerfIndex{ find(strcmp(EventOutAll(i).Performance, 'Correct'))}+pressnum];
        r.Behavior.PrematureIndex            =   [r.Behavior.PrematureIndex; EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Premature'))}+pressnum];
        r.Behavior.LateIndex                     =   [r.Behavior.LateIndex;EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Late'))}+pressnum];
        r.Behavior.DarkIndex                     =   [r.Behavior.DarkIndex; EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Dark'))}+pressnum];
    end;
    
    r.Behavior.Foreperiods                  = [r.Behavior.Foreperiods; EventOutAll(i).FPs'];
    
    % add trigger stimulus signal: 4
    indtriggers= find(strcmp(EventOutAll(i).EventsLabels, 'Trigger'));
    eventonset = EventOutAll(i).Onset{indtriggers}+dBlockOnset(i);
    triggeronset = EventOutAll(i).Onset{indtriggers};
    if size(eventonset, 1)<size(eventonset, 2)
        eventonset = eventonset';
    end;
    
    indevent = [ones(length(eventonset), 1)*4]; 
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
    indevent = [ones(length(eventonset), 1)*7]; % frame onset  1; frame offset 2
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
    end;
    
    eventonset = eventonset_goodpress+dBlockOnset(i);
    indevent = [ones(length(eventonset), 1)*6]; 
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
    
end;

% sort timing
[r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);


%% add spikes and plot stuff

figure; clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )
ha1=subplot(4, 1, [1 2]);
set(ha1, 'nextplot', 'add', 'xlim', [0 max(r.Behavior.EventTimings/(1000))], 'ytick', [1:length(r.Behavior.Labels)], 'yticklabel',r.Behavior.Labels, 'fontsize', 8)
plot([r.Behavior.EventTimings/(1000)], [r.Behavior.EventMarkers],'o', 'color', 'k','markersize', 3, 'linewidth', 1)
line([0 max(r.Behavior.EventTimings/(1000))], [1:length(r.Behavior.Labels); 1:length(r.Behavior.Labels)], 'color', 'k')

r.Units.Channels                                = [1:16 17:32];
r.Units.Profile                                    = units;
r.Units.Definition                               = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
r.Units.SpikeNotes                             = [];

for i                                              = 1:size(units, 1)
    ich = units{i, 1};
    if isnumeric(ich)  % if the first element is a number, no polytrode is invovled.
        sorting_code                             = units{i, 2};
        for k                                              = 1:length(sorting_code)
            switch sorting_code(k)
                case 'm'
                    r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                case 's'
                    r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                otherwise
                    return
            end
        end;
    else
        sorting_code                             = units{i, 2};
        thisch = units{i, 3};
        polytrode_id = str2num(ich(10:end));
        for k                                              = 1:length(sorting_code)
            switch sorting_code(k)
                case 'm'
                    r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; thisch k 2 polytrode_id];
                case 's'
                    r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; thisch k 1 polytrode_id];
                otherwise
                    return
            end
        end;
    end;
end;

 spkchs = unique(r.Units.SpikeNotes(:, 1));
allcolors                                          = varycolor(length(spkchs));
ha2                                                 = subplot(4, 1, [3:4]);
set(ha2, 'xlim', get(ha1, 'xlim'), 'ylim', [0 size(r.Units.SpikeNotes , 1)+1], 'nextplot', 'add', 'fontsize', 8);
linkaxes([ha1, ha2], 'x')
% put spikes

for i                                              = 1:size(r.Units.SpikeNotes, 1)
    channel_id                                         = r.Units.SpikeNotes(i, 1);  % channel id
    cluster_id                                          = r.Units.SpikeNotes(i, 2);  % cluster id
    r.Units.SpikeTimes(i)                             =   struct('timings',  [], 'wave', []);
    
    DataDurationmSec                                   = ceil(r.Meta(ib).DataDurationSec*1000); % in ms
    
        raw                  = load(['chdat_meansub' num2str(channel_id) '.mat']);
        tnew = [1:length(raw.index)]*1000/30000;
       
        % load spike time:
        if r.Units.SpikeNotes(i, 4)==0
            spk_id                                                 = load(['times_chdat_meansub' num2str(channel_id) '.mat']);
        else
            spk_id                                                 = load(['times_polytrode' num2str(r.Units.SpikeNotes(i, 4)) '.mat']);
        end;
        
        spk_in_ms                                           = round((spk_id.cluster_class(spk_id.cluster_class(:, 1)==cluster_id, 2))); % this is not mapped to time in recording
    
    [~, spkindx]                                          =     intersect(tnew, spk_in_ms);
    spk_in_ms_new                                   =    round(raw.index(spkindx));
    
    r.Units.SpikeTimes(i).timings = [r.Units.SpikeTimes(i).timings;  spk_in_ms_new]; % in ms
    
    r.Units.SpikeTimes(i).wave=[r.Units.SpikeTimes(i).wave;  spk_id.spikes(spk_id.cluster_class(:, 1)==cluster_id, :)];
    
    x_plot                                             = r.Units.SpikeTimes(i).timings;
    x_plot                                             = [x_plot]/(1000);
    y_plot                                             =  i -1 + 0.8*rand(1, length(x_plot));
    
        if ~isempty(x_plot)
            plot(ha2, x_plot, y_plot,'.', 'color', allcolors(spkchs ==channel_id, :),'markersize', 4);
        end;
    
end;

set(ha2, 'xlim', [0 max(r.Behavior.EventTimings/(1000))])
   
cd (cfolder)

print (gcf,'-dpng', ['Events_Spikes_Alignment' ])
saveas(gcf, 'Events_Spikes_Alignment', 'fig')
tic
save RTarrayAll r
toc
