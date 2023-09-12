function EventOut = UpdatePokeFromBpodEvents(EventOut, BpodEvents)
% revised 4/2/2023 Jianing Yu
% Update Poke events in EventOut based on BpodEvents

N_events = length(EventOut.EventsLabels);

% all pokes in bpod
allpokein_time_bpod = BpodEvents.AllPokeIns*1000;
allpokeout_time_bpod = BpodEvents.AllPokeOuts*1000;

% good release (medttl) in bpod
press_bpod = BpodEvents.AllPress*1000; % in ms
press_ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')}; % in ms

% align release_time_blackrock and relese_time_bpod
seqmom = press_bpod;
seqson = press_ephys;
% 
% seqmom = press_ephys;
% seqson = press_bpod;

seqmom(seqmom>seqmom(end)) = [];

if length(seqson)>length(seqmom)
    idx_out = findseqmatch(seqson,seqmom);
    press_ephys_new = seqson(idx_out);
    press_ephys_new_toBpod = seqmom;
elseif length(seqson)>=3
    Indout = findseqmatch(seqmom, seqson);
    press_ephys_new                 =   seqson(~isnan(Indout)); % press in ephys not including nan
    press_ephys_new_toBpod    =   seqmom(Indout(~isnan(Indout)));
else
    press_ephys_new                    =            [];
    press_ephys_new_toBpod      =             [];
end

% seqmom2      =       BpodEvents.Reward(1, :)*1000;
% seqson2         =       EventOut.Onset{5};
% Indout2 = findseqmatchrev(seqmom2, seqson2, man, toprint, toprintname);

% everything in bpod time domain can now be mapped to ephys domain using
% the one-to-one relationship between 'press_ephys_to_bpod' and 'press_ephys_matched'
% Update poke time

allpokein_time_mapped2blackrock = to_align(allpokein_time_bpod, press_ephys_new_toBpod, press_ephys_new);
allpokein_time_mapped2blackrock = allpokein_time_mapped2blackrock(allpokein_time_mapped2blackrock>0 & allpokein_time_mapped2blackrock < press_ephys(end)+1000);
allpokeout_time_mapped2blackrock = to_align(allpokeout_time_bpod, press_ephys_new_toBpod, press_ephys_new);
allpokeout_time_mapped2blackrock = allpokeout_time_mapped2blackrock(allpokeout_time_mapped2blackrock>0 & allpokeout_time_mapped2blackrock < press_ephys(end)+1000);

reward_in_fromBpod =  to_align(BpodEvents.Reward(1, :)*1000, press_ephys_new_toBpod, press_ephys_new);
reward_in_fromBpod = reward_in_fromBpod(reward_in_fromBpod>0 & reward_in_fromBpod < press_ephys(end)+2000);
reward_out_fromBpod =  to_align(BpodEvents.Reward(2, :)*1000, press_ephys_new_toBpod, press_ephys_new);
reward_out_fromBpod = reward_out_fromBpod(reward_out_fromBpod>0 & reward_out_fromBpod < press_ephys(end)+2000);

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = allpokein_time_mapped2blackrock;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = allpokeout_time_mapped2blackrock;

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Valve')} = reward_in_fromBpod;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Valve')} = reward_out_fromBpod;


function alignout = to_align(t_domain1, t_domain1_ref, t_domain2_ref)
% map time in domain 1 to time in domain 2 using the reference time
alignout = zeros(length(t_domain1), 1);
for i =1:length(t_domain1)
    it = t_domain1(i);
    % nearest ref
    [~, indref] = min(abs(it - t_domain1_ref));
    alignout(i) = it - t_domain1_ref(indref) + t_domain2_ref(indref);
end;

