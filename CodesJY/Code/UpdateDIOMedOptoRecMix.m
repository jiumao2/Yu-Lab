function EventOut = UpdateDIOMedOptoRecMix(EventOut, BpodEvents)
% 2/20/2021
% 9/7/2021 Jianing Yu
% using information (badpoke) from Bpod to update event stamping 
% really just add bad poke event timing

% 3/4/2021
N_events = length(EventOut.EventsLabels);

poke_ind =   find(strcmp(EventOut.EventsLabels, 'Poke'));
release_id = find(strcmp(EventOut.EventsLabels, 'GoodRelease'));
press_id  =  find(strcmp(EventOut.EventsLabels, 'LeverPress'));

% bad poke in bpod
% events.BadPokeInFirst = bad_pokein;
% events.BadPokeOutFirst = bad_pokeout;
badpokein_time_bpod = BpodEvents.BadPokeInFirst*1000;
badpokeout_time_bpod = BpodEvents.BadPokeOutFirst*1000;

%release time in DIO
release_time_blackrock = EventOut.Onset{release_id}'; 
release_time_bpod = BpodEvents.GoodRelease*1000; 

press_time_blackrock = EventOut.Onset{press_id}';
press_time_bpod = BpodEvents.Press*1000;

% nbpod must be larger than nblackrock
figure(12); clf
set(12, 'name', 'Add bad poke time', 'units', 'centimeters', 'position', [32 5 10 20]);
ha1=subplot(3, 1, 1)
plot(press_time_bpod, 1.1, 'ko')
text(press_time_bpod(1), 2, 'press time in bpod')
hold on
if ~isempty(badpokein_time_bpod)
    plot(badpokein_time_bpod, 0, 'r*', 'linewidth', 1, 'markersize', 4)
    text(badpokein_time_bpod(1), -0.5, 'Bad poke time in bpod')
end;
set(ha1, 'ylim', [-1 3])


% this is the index to map each press time recorded in blackrock to event
% timing in bpod

ind_br2bpod = findseqmatchrev(press_time_bpod, press_time_blackrock, 0, 0);

press_time_blackrock2 = press_time_blackrock(~isnan(ind_br2bpod));  % all non-NAN 
press_time_blackrock2bpod = press_time_bpod(ind_br2bpod(~isnan(ind_br2bpod)));

figure(12)
ha2 = subplot(3, 1, 2)
plot(press_time_bpod, 5, 'ko')
text(press_time_bpod(1), 6, 'Press time in bpod')
hold on
plot(press_time_blackrock2bpod, 4, 'b^')
text(press_time_blackrock2bpod(1), 3, 'Release time in blackrock(remapped to bpod)')

set(gca, 'ylim', [2 7])

% find badpoke time within release_time_blackrock2bpod and convert them to
% blackrock time

ind_included = find(badpokein_time_bpod>=press_time_blackrock2bpod(1) & badpokeout_time_bpod <= press_time_blackrock2bpod(end));
newbadpokein = map2br(badpokein_time_bpod(ind_included), press_time_blackrock2bpod, press_time_blackrock2);
newbadpokeout = map2br(badpokeout_time_bpod(ind_included), press_time_blackrock2bpod, press_time_blackrock2);

% remap Poke, approach, and optostim data

% events.Poke              =      events.Poke - t0;
% events.Approach     =       events.Approach-t0;                           % time of approach
% events.Press             =      events.Press-t0;                                    % time of Press
% events.Trigger          =       events.Trigger -t0;                                 % time of trigger
% events.OptoStim     =       events.OptoStim-t0;                            % time of Optostim (it should match one of the above events) 

% 1. Poke
ind_included = find(BpodEvents.Poke*1000 >= press_time_blackrock2bpod(1)-5000 & BpodEvents.Poke*1000<= press_time_blackrock2bpod(end)+5000);
newPokeTime = map2br(BpodEvents.Poke(ind_included)*1000, press_time_blackrock2bpod, press_time_blackrock2);

% 2. Approach
ind_included = find(BpodEvents.Approach*1000 >= press_time_blackrock2bpod(1)-5000 & BpodEvents.Approach*1000<= press_time_blackrock2bpod(end)+5000);
newApproachTime = map2br(BpodEvents.Approach(ind_included)*1000, press_time_blackrock2bpod, press_time_blackrock2);

% 3. OptoStim
ind_included = find(BpodEvents.OptoStimOn*1000 >= press_time_blackrock2bpod(1)-5000 & BpodEvents.OptoStimOn*1000<= press_time_blackrock2bpod(end)+5000);
newOptoStimOnTime = map2br(BpodEvents.OptoStimOn(ind_included)*1000, press_time_blackrock2bpod, press_time_blackrock2);
newOptoStimOffTime = map2br(BpodEvents.OptoStimOff(ind_included)*1000, press_time_blackrock2bpod, press_time_blackrock2);


ha3 = subplot(3, 1, 3)
plot(press_time_blackrock2, 5, 'co')
text(press_time_blackrock2(1), 6, 'Press time in blackrock')
hold on
if ~isempty(newbadpokein)
plot(newbadpokein, 4, 'r*')
text(newbadpokein(1), 3, 'bad poke-in time mapped blackrock')
end;

if ~isempty(newOptoStimOnTime)
    plot(newOptoStimOnTime, 2, 'm^')
    text(newOptoStimOnTime(1), 2, 'optostimulation')
end;


set(gca, 'ylim', [2 7])

% update EventOut
EventOut.EventsLabels{N_events+1} = 'BadPoke';
EventOut.Onset{N_events+1} =newbadpokein';
EventOut.Offset{N_events+1} = newbadpokeout';
 

% Update Pokes in EventOut. This Poke derived from Bpod's Port1In is more accurate
EventOut.EventsLabels{N_events+1} = 'AllPokes';
EventOut.Onset{poke_ind} =newPokeTime';
EventOut.Offset{poke_ind} = newPokeTime';
N_events = length(EventOut.EventsLabels);

EventOut.EventsLabels{N_events+1} = 'Approach';
EventOut.Onset{N_events+1} =newApproachTime';
EventOut.Offset{N_events+1} = newApproachTime';
N_events = length(EventOut.EventsLabels);

if ~isempty(newOptoStimOnTime)
    EventOut.EventsLabels{N_events+1} = 'OptoStim';
    EventOut.Onset{N_events+1} =newOptoStimOnTime';
    EventOut.Offset{N_events+1} = newOptoStimOffTime';
end;


function bpodevents2blackrock = map2br(bpodevents, press_time_blackrock2bpod, press_time_blackrock2);

bpodevents2blackrock=[];

if ~isempty(bpodevents)
    bpodevents2blackrock = zeros(1, length(bpodevents));
    for j =1:length(bpodevents)
        [~, indmin] = min(abs(bpodevents(j)-press_time_blackrock2bpod));  % find nearest bpod press time
        bpodevents2blackrock(j) = bpodevents(j) - press_time_blackrock2bpod(indmin)+press_time_blackrock2(indmin);
    end;
end;




