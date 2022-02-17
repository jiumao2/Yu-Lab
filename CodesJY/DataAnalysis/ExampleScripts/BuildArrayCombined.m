% cd('C:\Users\jiani\OneDrive\Work\Physiology\Data\Subjects\Lucky\20200120');
%  
% Build behavior array from all blocks.
% blocks                                             = {'001', '002', '003', '004'}; % these are the folders
blocks                                             = { '003',  '004', '005',  '006'}; % these are different sessions

% datafile005.nev
% datafile006.nev

% % m: multiunits  s: single units
units   =  {
    5   's'
    7   's'
    8   's'
    13  's'
    35  's'
    45  'sm'
    47  's'
    48  's'
     };

%% Extract behavior times from MED
% bout=track_training_progress_advanced('2020-01-23_15h58m_Subject Lucky.txt');

if isempty(dir(['B_*.mat']))
    medfile = dir('*.txt');
    track_training_progress_advanced(medfile.name);
end;

behfile= dir('B_*mat');
load(fullfile(behfile.folder, behfile.name))

% this yields 'b'
all_press_times   = b.PressTime*1000;  % turn press time to ms
all_press_FPs     = b.FPs;
all_release_times = b.ReleaseTime*1000;
all_correct_index = b.Correct;

cfolder = pwd;

EventOutAll = [];

for ib=1:length(blocks)
    
    nevfile = ['datafile' blocks{ib} '.nev'];
    openNEV(nevfile, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
    EventOut = DIO_Events(NEV) % create
   
    leverpress_br                                      = EventOut.Onset{4};
    
    figure(30); clf
    subplot(2, 2, 1)
    plot(all_press_times, 5, 'ro');
    hold on
    plot(leverpress_br, 5, 'ko')
    n_allpress                                         = length(all_press_times);  % presses in MED
    n_pressbr                                          = length(leverpress_br);  % blackrock recorded presses
    dtime                                              = [];
    
    ha2                                                 = subplot(2, 2, 2);
    set(ha2, 'nextplot','add')
    
    for i                                              = 1:n_allpress-1
        if n_pressbr+i-1<n_allpress
            dn(i)=0;
            dtime                                              = [dtime; std(abs(all_press_times(i:n_pressbr+i-1)-all_press_times(i)-leverpress_br'))];
        else
            dn(i) = n_pressbr+i-1-n_allpress;
            dtime                                              = [dtime; std(abs(all_press_times(i:end)-all_press_times(i)-leverpress_br(1:n_pressbr-dn(i))'))];
        end;
        plot(i, dtime(i, :),  'ko')
    end;
    
    [~, ind_offset]                                    = min(dtime);
    
    if dn(ind_offset)>0
        EventOut.Onset{4}=EventOut.Onset{4}(1:end-dn(ind_offset));
        EventOut.Offset{4}=EventOut.Offset{4}(1:length(EventOut.Onset{4}));
    end;
    
    plot(ind_offset, dtime(ind_offset), 'ro', 'markerfacecolor', 'r')
    toffset                                            = all_press_times(ind_offset)-leverpress_br(1);  % offset between first press in datafile### and the corresponding time in MED file
    
    ha3                                                = subplot(2, 2,  3);
    set(ha3, 'nextplot','add')
    plot(leverpress_br,  4, 'ro')
    plot(all_press_times(ind_offset:ind_offset+n_pressbr-1-dn(ind_offset))-toffset, 5, 'k^');
    
    
    set(gca, 'ylim', [2 7]);
    all_tones                                             = b.TimeTone*1000-toffset;
    tonetime_br                                        = all_tones(all_tones>0 & all_tones<leverpress_br(end));
    
    ha4                                                = subplot(2, 2, 4);
    plot(tonetime_br/1000, 2, 'ko');
    hold on
    text(tonetime_br(1)/1000,2.3,  ['trigger' num2str(length(tonetime_br))], 'color', 'k')
    
    plot(leverpress_br/1000,1.8,'r^');
    text(leverpress_br(1)/1000, 1.5, ['press' num2str(length(leverpress_br))], 'color', 'r')
    
    set(gca, 'ylim', [0 4])
    
    EventOut.EventsLabels{6}='Trigger';
    EventOut.Onset{6}=tonetime_br;
 
    
    % Correct, Premature and late  index
    indpress_br                                         = ind_offset:ind_offset+n_pressbr-1-dn(ind_offset);
    [~, ind_correct]                                   = intersect(indpress_br, b.Correct);
    [~, ind_premature]                               = intersect(indpress_br, b.Premature);
    [~, ind_late]                                         = intersect(indpress_br, b.Late);
    
    EventOut.CorrectIndex                        = ind_correct;
    EventOut.PrematureIndex                     = ind_premature;
    EventOut.LateIndex                              = ind_late;
    EventOut.FPs                                        = b.FPs(indpress_br);
    
    EventOut.Meta.Subject = 'Lucky';
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


spkchs                                             = cell2mat(units(:, 1)); % channels with spikes

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

% calculate time difference between different blocks
if length(blocks)>1
    dBlockOnset = zeros(1, length(blocks)-1);
    for i=1:length(dBlockOnset)
        dt_i = EventOutAll(i+1).Meta.DateTimeRaw-EventOutAll(1).Meta.DateTimeRaw;
        dBlockOnset(i)=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
    end; 
end;

dBlockOnset=[0 dBlockOnset];
 
r.Behavior.Labels={'FrameOn', 'FrameOff', 'LeverPress', 'Trigger', 'LeverRelease', 'GoodPress', 'GoodRelease',...
   'ValveOnset', 'ValveOffset', 'PokeOnset', 'PokeOffset' };
r.Behavior.LabelMarkers = [1:length(r.Behavior.Labels)];

r.Behavior.CorrectIndex              =   [];
r.Behavior.PrematureIndex            = [];
r.Behavior.LateIndex                     =   [];
r.Behavior.Foreperiods                  = [];

r.Behavior.EventTimings = [];
r.Behavior.EventMarkers = [];
pressnum = 0;

for i = 1:length(EventOutAll)
 
    if i>1
        pressnum = pressnum +  length(EventOutAll(i-1).Onset{strcmp(EventOutAll(i-1).EventsLabels, 'LeverPress')});
    end;
      
%         % add frame signal: 1 and 2
%     indframe = find(strcmp(EventOutAll(i).EventsLabels, 'Frame'));
%     eventonset = EventOutAll(i).Onset{indframe}+dBlockOnset(i);
%     eventoffset = EventOutAll(i).Offset{indframe}+dBlockOnset(i);
%     eventmix = [eventonset; eventoffset];
%     indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2]; % frame onset  1; frame offset 2
%     r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
%     r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
    
    % add leverpress onset and offset signal: 3 and 5
    indleverpress= find(strcmp(EventOutAll(i).EventsLabels, 'LeverPress'));
    eventonset = EventOutAll(i).Onset{indleverpress}+dBlockOnset(i); 
    eventonset_press = EventOutAll(i).Onset{indleverpress};
    eventoffset = EventOutAll(i).Offset{indleverpress}+dBlockOnset(i); 
    eventoffset_press =  EventOutAll(i).Offset{indleverpress};
    eventmix = [eventonset; eventoffset];
    indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset),1)*5]; % frame onset  1; frame offset 2
    r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
    r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
    
    % add trigger stimulus signal: 4
    indtriggers= find(strcmp(EventOutAll(i).EventsLabels, 'Trigger'));
    eventonset = EventOutAll(i).Onset{indtriggers}+dBlockOnset(i);
    triggeronset = EventOutAll(i).Onset{indtriggers};
    if size(eventonset, 1)<size(eventonset, 2)
        eventonset = eventonset';
    end;
    indevent = [ones(length(eventonset), 1)*4]; % frame onset  1; frame offset 2
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
    
    if i==1
        r.Behavior.CorrectIndex = EventOutAll(i).CorrectIndex;
        r.Behavior.PrematureIndex = EventOutAll(i).PrematureIndex;
        r.Behavior.LateIndex  = EventOutAll(i).LateIndex;
    else
        r.Behavior.CorrectIndex              =   [r.Behavior.CorrectIndex; EventOutAll(i).CorrectIndex+pressnum];
        r.Behavior.PrematureIndex            =   [r.Behavior.PrematureIndex; EventOutAll(i).CorrectIndex+pressnum];
        r.Behavior.LateIndex                     =   [r.Behavior.LateIndex; EventOutAll(i).CorrectIndex+pressnum];
    end;
    
    r.Behavior.Foreperiods                  = [r.Behavior.Foreperiods; EventOutAll(i).FPs'];
end;

% sort timing
[r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);

figure; clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )
ha1=subplot(4, 1, 1);
set(ha1, 'nextplot', 'add', 'xlim', [0 max(r.Behavior.EventTimings/(1000))],'ytick', [0 11], 'ytick', [1:10], 'yticklabel',r.Behavior.Labels, 'fontsize', 8)
plot([r.Behavior.EventTimings/(1000)], [r.Behavior.EventMarkers],'o', 'color', 'k','markersize', 3, 'linewidth', 1)
 
r.Units.Channels                                = [1:16 33:48];
r.Units.Profile                                    = units;
r.Units.Definition                               = {'channel_id cluster_id unit_type', '1: single unit', '2: multi unit'};
r.Units.SpikeNotes                             = [];

for i                                              = 1:size(units, 1)
    
    sorting_code                             = units{i, 2};
    for k                                              = 1:length(sorting_code)
        switch sorting_code(k)
            case 'm'
                r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 2];
            case 's'
                r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 1];
            otherwise
                return
        end
    end;
end;

allcolors                                          = varycolor(length(spkchs));

ha2                                                 = subplot(4, 1, [2:4]);
set(ha2, 'xlim', get(ha1, 'xlim'), 'ylim', [0 size(r.Units.SpikeNotes , 1)+1], 'nextplot', 'add', 'fontsize', 8);
linkaxes([ha1, ha2], 'x')
% put spikes

for i                                                       = 1:size(r.Units.SpikeNotes, 1)
    channel_id                                         = r.Units.SpikeNotes(i, 1);  % channel id
    cluster_id                                          = r.Units.SpikeNotes(i, 2);  % cluster id
    r.Units.SpikeTimes(i)                             =   struct('timings',  [], 'wave', []);
    
    DataDurationmSec                                   = ceil(r.Meta(ib).DataDurationSec*1000); % in ms
    
        raw                  = load(['chdat' num2str(channel_id) '.mat']);
        tnew = [1:length(raw.index)]*1000/30000;
       
    % load spike time:
    spk_id                                                 = load(['times_chdat' num2str(channel_id) '.mat']);
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

 save RTarrayAll r
