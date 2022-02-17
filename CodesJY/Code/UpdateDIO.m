function EventOut = UpdateDIO(EventOut, BpodEvents)
% 2/20/2021
% using information from Bpod to update event stamping 

poke_ind =   find(strcmp(EventOut.EventsLabels, 'Poke'));
release_id = find(strcmp(EventOut.EventsLabels, 'GoodRelease'));

% poke time in bpod
poke_time_blackrock = BpodEvents.GoodPokeIn*1000;

%release time in DIO
release_time_blackrock = EventOut.Onset{release_id}';
nblackrock = length(release_time_blackrock);

release_time_bpod = BpodEvents.GoodRelease*1000;
nbpod = length(release_time_bpod);  

% nbpod must be larger than nblackrock
figure;

subplot(3, 1, 1)
plot(release_time_blackrock, 1, 'ko')
hold on
plot(release_time_bpod, 1.1, 'bo')
set(gca, 'ylim', [0 2])

dt = [];
for i=1:1:nbpod-nblackrock
   dt(i) = std(release_time_bpod(i:i+nblackrock-1)-release_time_blackrock);
end;

subplot(3, 1, 2)
plot(dt, 'ko'); hold on
[mindt, indmin] = min(dt);
plot(indmin, mindt, 'ro', 'markerfacecolor', 'r', 'markersize', 6)

dt_bpod_blackrock = release_time_bpod(indmin) - release_time_blackrock(1);

% new release time from bpod
bpod_new_release_time = release_time_bpod-dt_bpod_blackrock;

subplot(3, 1, 3)
plot(release_time_blackrock, 1, 'ko')
hold on
plot(bpod_new_release_time, 1.2, 'co' )

set(gca, 'ylim', [0.5 2])

% new poke time from bpod
new_poke = poke_time_blackrock-dt_bpod_blackrock;
new_poke = new_poke(new_poke>0 & new_poke<release_time_blackrock(end)+2000);
plot(new_poke, 1.5, 'm^' )

% update EventOut
EventOut.Onset{poke_ind} = new_poke';
EventOut.Offset{poke_ind} = new_poke'+200;
