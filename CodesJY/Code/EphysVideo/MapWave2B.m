function sout = MapWave2B(sout, bu)

% the point is to map the signal in sout to MED time

% sout time
t_sout = sout.Time; % in ms

% sout triggers
ind_trig = find(contains(sout.Labels, 'Trigger'));
TriggerSignal = sout.Signals(:, ind_trig);


% find out the onset
above_th = find(TriggerSignal > 1);
trigger_beg = above_th([1; find(diff(above_th)>1)+1]);
trigger_end = above_th([find(diff(above_th)>1)+1; length(above_th)]);

figure; plot(TriggerSignal);
hold on
plot(trigger_beg, 1, 'ro')

TriggerTimeWS = t_sout(trigger_beg);
TriggerTimeB = bu.TimeTone*1000;

% find match
Indout = findseqmatch(TriggerTimeB, TriggerTimeWS);  % map trigger time in WS to time in MED

% map time in WS to time in MED

NewSoutTime = MapVidFrameTime2B(TriggerTimeWS,  TriggerTimeB, Indout, sout.Time);

sout.TimeInB = NewSoutTime;
 

save WSData sout 

