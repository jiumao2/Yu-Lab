function EventOut = UpdateDIOMedLick(EventOut, BpodEvents)
% 2/20/2021
% using information from Bpod to update event stamping 
% 3/4/2021
% add poke times to event out

N_events = length(EventOut.EventsLabels);

release_id = find(strcmp(EventOut.EventsLabels, 'GoodRelease'));

% bad poke in bpod
% events.BadPokeInFirst = bad_pokein;
% events.BadPokeOutFirst = bad_pokeout;
pokein_time_bpod        =       BpodEvents.PokeIn*1000;
pokeout_time_bpod      =       BpodEvents.PokeOut*1000;

%release time in DIO
release_time_blackrock = EventOut.Onset{release_id}';
nblackrock = length(release_time_blackrock);

release_time_bpod = BpodEvents.GoodRelease*1000;
nbpod = length(release_time_bpod);  

% nbpod must be larger than nblackrock
figure;

ha1=subplot(4, 1, 1)
plot(release_time_blackrock, 0.5, 'ko')
hold on
plot(release_time_bpod, 1.1, 'bo')
set(gca, 'ylim', [0.5 2])

plot(pokein_time_bpod, 1.3, 'k*', 'linewidth', 0.5)
plot(pokeout_time_bpod, 1.3, 'k^', 'linewidth', 0.5)

dt = [];
release_time_blackrock2 = release_time_blackrock-release_time_blackrock(1);

for i=1:1:nbpod-nblackrock
    
    ireleasebpod = release_time_bpod - release_time_bpod(i);
    ireleasebpod = ireleasebpod(ireleasebpod>=0);
   dt(i) = toaligh (release_time_blackrock2, ireleasebpod);
      
end;

ha2=subplot(4, 1, 2)
plot(dt, 'ko'); hold on
[maxdt, indmax] = max(dt);
plot(indmax, maxdt, 'ro', 'markerfacecolor', 'r', 'markersize', 6)

% use this indmin to update poke information (each poke will be updated
% according to the nearest lever release time because bpod and ephys
% computers run their own time seperately. 
dt_bpod_blackrock = release_time_bpod(indmax) - release_time_blackrock(1);

% new release time from bpod
bpod_new_release_time = release_time_bpod-dt_bpod_blackrock;

ha3=subplot(4, 1, 3)
plot(release_time_blackrock, 0.5, 'ko')
text(release_time_blackrock(end), 0.7, 'blackrock response', 'color', 'k')
hold on
plot(bpod_new_release_time, 1.2, 'co' )
set(gca, 'ylim', [0.5 2])

% time range:
ind_bpod_new = find(bpod_new_release_time>=release_time_blackrock(1)-0.5*1000 & bpod_new_release_time<= release_time_blackrock(end)+0.5*1000);
bpod_new_release_time_matched = bpod_new_release_time(ind_bpod_new);
plot(bpod_new_release_time_matched, 1.4, 'r*')
text(bpod_new_release_time_matched(end), 1.7, 'bpod matched responses', 'color', 'r')

line([bpod_new_release_time_matched; release_time_blackrock], [1.4; 1.2])

subplot(4, 1, 4)
plot(bpod_new_release_time_matched-release_time_blackrock, 'ko-');
xlabel('Reponse #')
ylabel('Diff (ms)')

timerange_bpod_old = [release_time_bpod(ind_bpod_new(1)) release_time_bpod(ind_bpod_new(end))];
pokeintime = pokein_time_bpod(pokein_time_bpod>=timerange_bpod_old(1) & pokein_time_bpod<=timerange_bpod_old(2));
pokeouttime = pokeout_time_bpod(pokeout_time_bpod>=timerange_bpod_old(1) & pokeout_time_bpod<=timerange_bpod_old(2));
axes(ha1)
plot(pokeintime, 1.25, 'm*')
plot(pokeouttime, 1.25, 'g*')

pokeintime_new = [];
pokeouttime_new = [];

for i=1:length(pokeintime)
    ipokeintime = pokeintime(i);
    ipokeouttime = pokeouttime(i);
    
    ind_releasebpod = find(release_time_bpod<ipokeintime, 1, 'last');
    t_releasebpod = release_time_bpod(ind_releasebpod);
    
    t_releasebpod_map = t_releasebpod-dt_bpod_blackrock;
    [~, ind_match]= intersect(bpod_new_release_time_matched, t_releasebpod_map);
    
    if ~isempty(ind_match)
        time_in_ephys = release_time_blackrock(ind_match);
        newpokein       =     ipokeintime - t_releasebpod + time_in_ephys;
        newpokeout     =     ipokeouttime - t_releasebpod + time_in_ephys;
        
        pokeintime_new = [pokeintime_new newpokein];
        pokeouttime_new = [pokeouttime_new newpokeout];
    end;
end;

axes(ha3)
plot(pokeintime_new, 1.3, 'm^')
plot(pokeouttime_new, 1.3, 'g^')

% update EventOut
poke_ind =   find(strcmp(EventOut.EventsLabels, 'Poke'));
EventOut.Onset{poke_ind} =pokeintime_new';
EventOut.Offset{poke_ind} = pokeintime_new';

% Bad pokes not recorded. 


function seqcorr = toaligh(seq1, seq2)
% seq 1 is a subset of seq2
% based on correlation analysis
 
tmax =max([seq1, seq2]);

edges =[0:100:tmax];
% won't assume 

nseq1 = histcounts(seq1, edges);
nseq2 = histcounts(seq2, edges); 
   
seqcorr = sum(nseq1.*nseq2);
% 
% if seqcorr>5
%     
%     figure(47); clf
%     plot(seq1, 5, 'ko');
%     hold on
%     plot(seq2, 5, 'r*');
%     line([edges; edges], [4; 6], 'color', 'k')
%     set(gca, 'ylim', [4 6]);
%     
% end;


