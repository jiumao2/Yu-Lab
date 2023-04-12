function EventOut = DIO_Events4(NEV, trange)
% 2020/08/31
% version 3
% this version contains more data, including frame signal 

% 2020/04/20
% DIO_Events2 doesn't have frame signals
% function TimeEvents = DIO_Events(NEV, trange)
% trange: [t1 t2] in sec
%             Meta: [1×1 struct]
%       TimeEvents: [90586×6 double]
%     EventsLabels: {'Time(ms)'  'Frame'  'Release'  'Valve'  'Poke'  'LeverPress'}
%            Onset: {[45023×1 double]  [25×1 double]  [24×1 double]  [190×1 double]  [43×1 double]}
%           Offset: {[45023×1 double]  [25×1 double]  [24×1 double]  [190×1 double]  [43×1 double]}
% Jianing Yu 2020 Jan 31

if nargin<2
    trange = [];
end;

% NEV.Data.Spikes
%   struct with fields:
% 
%        TimeStamp: [1×176912 uint32]
%        Electrode: [1×176912 uint16]
%             Unit: [1×176912 uint8]
%         Waveform: [48×176912 int16]
%     WaveformUnit: 'raw'

%% These electrodes are live ()

% unique(NEV.Data.Spikes.Electrode)

%   1×22 uint16 row vector

%     2    3    4    6    7    8    9   10   11   12   13   14
%    33   35   37   38   39   43   44   45   46   48

%% Digital events
% NEV.Data.SerialDigitalIO

% InputType: []
% TimeStamp: [1×90586 uint32]
% TimeStampSec: [1×90586 double]
% Type: []
% Value: []
% InsertionReason: [1×90586 uint8]
% UnparsedData: [90586×1 uint16]

figure(20); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 8 12], 'paperpositionmode', 'auto' )

DIO_IndexAll = (NEV.Data.SerialDigitalIO.UnparsedData);
m = cellstr(dec2bin(DIO_IndexAll));
TimeStampSec = NEV.Data.SerialDigitalIO.TimeStampSec*1000;

% DO0 lever press
% DO1 approach
% DO2 valve
% DO3 successful release
% DO4 frame signal   : This is the frame signal
% DO5 lickport poke signal
 
TimeEvents = [TimeStampSec' char(m)-'0'];
EventsLabels = {'Poke', 'Frame', 'GoodRelease', 'Valve', 'Approach', 'LeverPress'};

N_Events = length(EventsLabels);
TimeEvents = TimeEvents(:, [1 end-N_Events+1:end]); % new blackrock system creates lots of '1's because of the baseline 5V difference

%     2.3409       1     1     1     1     1     1     1     1     1     1     1     1     0     0     0     1
%     3.3608       1     1     1     1     1     1     1     1     1     1     1     1     1     0     0     1
%     3.3612       1     1     1     1     1     1     1     1     1     1     1     1     1     0     0     0
%     3.3712       1     1     1     1     1     1     1     1     1     1     1     1     0     0     0     0
%     5.5430       1     1     1     1     1     1     1     1     1     1     1     1     0     0     1     0
                     
          
% Onset and offset of events are here

EventOnset = cell(1, length(EventsLabels)-1);
EventOffset = cell(1, length(EventsLabels)-1);

% column 1 is time
% column 2 is lickport poke
% column 3 is frame signal
% column 4 is successful release
% column 5 is valve time
% column 6 is approach (no longer available 2/18/2021)
% column 7 is lever press

for i = 1:N_Events
    Events = TimeEvents(:, i+1);  % 0s and 1s, transition from 0 to 1 registers onset, transition from 1 to 0 registers offset
    rising = find(diff(Events)>0.5)+1; % index of rising
    falling = find(diff(Events)<-0.5)+1; % index of falling
    
    EventOnset{i}=TimeEvents([rising], 1);  % in ms
    EventOffset{i}=TimeEvents(falling, 1);  % in ms
    if ~isempty(EventOnset{i}) && EventOnset{i}(1)>EventOffset{i}(1)  % caught after onset
        EventOffset{i}(1)=[];
    end;
end;

if isempty(trange)
    trange =[min(TimeEvents(:, 1)) max(TimeEvents(:, 1))-10]/1000;
end;


Ha=subplot(4, 1, [1:3])    
set(Ha, 'nextplot', 'add', 'xlim', [trange], 'ylim', [0 N_Events], 'ytick', [], 'ylabel', []);

% plot the results

for i =1:N_Events
    
    if length(EventOnset{i})>length(EventOffset{i})
        EventOnset{i}=EventOnset{i}(1:length(EventOffset{i}));
    end;
    
    indplot = find(EventOnset{i}>=trange(1)*1000 & EventOnset{i}<=trange(2)*1000);
    
    onset_plot = EventOnset{i}(indplot);
    offset_plot = EventOffset{i}(indplot);
    
    if ~isempty(onset_plot)
        if length(onset_plot)<500
            for k =3:length(onset_plot);
                hfill=fill([onset_plot(k) offset_plot(k) offset_plot(k) onset_plot(k)]/1000, [0 0 .6 .6]+(i-1), [0 0 0]);
                set(hfill, 'edgecolor', 'k')
            end;
        else
            for k =3:10:length(onset_plot);
                hfill=fill([onset_plot(k) offset_plot(k) offset_plot(k) onset_plot(k)]/1000, [0 0 .6 .6]+(i-1), [0 0 0]);
                set(hfill, 'edgecolor', 'k')
            end;        
        end;
    end;
    
    text(mean(trange), 0.8+(i-1), EventsLabels{i}, 'fontsize', 10);
end;

% in some protocols, 'MEDTTL' sends two pulses to Bpod to trigger low or
% high rewards (low, one pulse; high, two pulses). It is necessary to
% remove the second pulses. 
ind_MEDTTL = 3; % 'GoodRelease',
IndShortPulses = 1+find(diff(EventOnset{ind_MEDTTL})<23);

EventOnset{ind_MEDTTL}(IndShortPulses) = [];
EventOffset{ind_MEDTTL}(IndShortPulses) = [];

 
xlabel ('Time (s)')

linkaxes(Ha,'x')
%  'datafile001'
% file name:
nev_name = NEV.MetaTags.Filename;

hainfo = subplot(4, 1, 4);
set(hainfo, 'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10], 'ytick', [], 'ylabel', [])
axis off

text(1, 5, NEV.MetaTags.Filename)
text(1, 3, sprintf('Session length in min: %2.2f',NEV.MetaTags.DataDurationSec/60))
text(1, 1, NEV.MetaTags.DateTime)

print (gcf,'-dpng', ['DIO_Events_' nev_name ])

EventOut.Meta = NEV.MetaTags;
EventOut.TimeEvents= TimeEvents;
EventOut.EventsLabels=EventsLabels;
EventOut.Onset = EventOnset;
EventOut.Offset = EventOffset;

sprintf('Total time: %2.0f min; Number of presses: %2.0d; Number of good release: %2.0d;',...
    NEV.MetaTags.DataDurationSec/60, length(EventOnset{4}), length(EventOnset{2}));


save EventOut EventOut
