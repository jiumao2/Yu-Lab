function EventOut = UpdateDIOMedOpto(EventOut, BpodEvents)
% 2/20/2021
% using information from Bpod to update event stamping 
% 3/4/2021
N_events = length(EventOut.EventsLabels);

poke_ind =   find(strcmp(EventOut.EventsLabels, 'Poke'));
release_id = find(strcmp(EventOut.EventsLabels, 'GoodRelease'));

% bad poke in bpod
% events.BadPokeInFirst = bad_pokein;
% events.BadPokeOutFirst = bad_pokeout;
badpokein_time_bpod = BpodEvents.BadPokeInFirst*1000;
badpokeout_time_bpod = BpodEvents.BadPokeOutFirst*1000;

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
plot(badpokein_time_bpod, 1.3, 'k*', 'linewidth', 1.5)
plot(badpokeout_time_bpod, 1.3, 'k^', 'linewidth', 1.5)

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
ind_bpod_new = find(bpod_new_release_time>=release_time_blackrock(1)-100 & bpod_new_release_time<= release_time_blackrock(end)+200)
bpod_new_release_time_matched = bpod_new_release_time(ind_bpod_new);

plot(bpod_new_release_time_matched, 1.4, 'r*')
text(bpod_new_release_time_matched(end), 1.7, 'bpod matched responses', 'color', 'r')
bpod_adjusted_release = [];
ephys_matching_bpod = [];

for i =1:length(bpod_new_release_time_matched)
    [mindt, indmin]=min(abs(release_time_blackrock - bpod_new_release_time_matched(i)));
    
    if mindt<500
        bpod_adjusted_release = [bpod_adjusted_release bpod_new_release_time_matched(i)];
        ephys_matching_bpod = [ephys_matching_bpod release_time_blackrock(indmin)];
        line([bpod_new_release_time_matched(i); release_time_blackrock(indmin)], [1.4; 0.5], 'color', 'k', 'linewidth', 1.5)      
    end;
end;

subplot(4, 1, 4)
plot(bpod_adjusted_release-ephys_matching_bpod, 'ko-')

timerange_bpod_old = [release_time_bpod(ind_bpod_new(1)) release_time_bpod(ind_bpod_new(end))];
badpokeintime = badpokein_time_bpod(badpokein_time_bpod>=timerange_bpod_old(1)-100 & badpokein_time_bpod<=timerange_bpod_old(2)+200);
badpokeouttime = badpokeout_time_bpod(badpokein_time_bpod>=timerange_bpod_old(1)-100  & badpokein_time_bpod<=timerange_bpod_old(2)+200);
axes(ha1)
if ~isempty(badpokeintime)
plot(badpokeintime, 1.25, 'm*')
plot(badpokeouttime, 1.25, 'm*')
end
badpokeintime_new = [];
badpokeouttime_new = [];

% bpod_adjusted_release  
% ephys_matching_bpod  

for i=1:length(badpokeintime)
    ipokeintime = badpokeintime(i);
    ipokeouttime = badpokeintime(i);
    
    ind_releasebpod = find(release_time_bpod<ipokeintime, 1, 'last');
    t_releasebpod = release_time_bpod(ind_releasebpod);
    
    t_releasebpod_map = t_releasebpod-dt_bpod_blackrock;
    [~, ind_match]= intersect(bpod_adjusted_release, t_releasebpod_map);
    
    if ~isempty(ind_match)
        
        time_in_ephys      =    ephys_matching_bpod(ind_match);
        newpokein            =     ipokeintime - t_releasebpod + time_in_ephys;
        newpokeout          =     ipokeouttime - t_releasebpod + time_in_ephys;
        
        badpokeintime_new       = [badpokeintime_new newpokein];
        badpokeouttime_new     = [badpokeouttime_new newpokeout];
        
    end;
end;
    
axes(ha3)
if ~isempty(badpokeintime_new)
    plot(badpokeintime_new, 1.3, 'r^')
end;

% update EventOut
EventOut.EventsLabels{N_events+1} = 'BadPoke';
EventOut.Onset{N_events+1} =badpokeintime_new';
EventOut.Offset{N_events+1} = badpokeouttime_new';


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
