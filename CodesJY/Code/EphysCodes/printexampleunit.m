function printexampleunit(r, eunit, selected_events, event_types, pre, post)

set(0,'defaultAxesFontSize',6)

n_events = length(event_types);

eu=eunit;

figure(26); clf(26)

set(gcf, 'unit', 'centimeters', 'position',[2 2 15 7], 'paperpositionmode', 'auto' )


%% display spike waveform
ha0=axes('units', 'centimeters', 'position', [1 5 1 1])
set(ha0, 'nextplot', 'add', 'xlim', [0 65]/(30), 'ytick', [])

allwaves = r.Units.SpikeTimes(eunit).wave;

wavestd = std(allwaves, 0, 1);
waveavg = mean(allwaves, 1);

if size(allwaves, 1)>50
    nplot = randperm(size(allwaves, 1), 100);
else
        nplot=[1:size(allwaves, 1)];
    end;
    
    wave2plot = allwaves(nplot, :);
    twave = [1:size(wave2plot, 2)]/30;
    
    plotshaded(twave, -[ waveavg-wavestd; waveavg+wavestd], 'c');
    
    plot(twave,-waveavg, 'color', 'k', 'linewidth', 1)
    
    switch r.Units.SpikeNotes(eu, 3)
        case 1
           title(['#' num2str(eu) 'Ch' num2str(r.Units.SpikeNotes(eu, 1)) 'unit' num2str(r.Units.SpikeNotes(eu, 2))  ': SU']);
        case 2
            title(['#' num2str(eu) 'Ch' num2str(r.Units.SpikeNotes(eu, 1)) '#' num2str(ku) 'unit' num2str(r.Units.SpikeNotes(eu, 2))  ': MU']);
        otherwise
    end
    
    xlabel('ms')

%% display  - interspike intervals
ha00=axes('units', 'centimeters', 'position', [1 3 1 1])
set(ha00, 'nextplot', 'add', 'xlim', [0 65]/(30), 'ytick', [])
spxtimes = r.Units.SpikeTimes(eu).timings/1000;

title('ISI (10ms bins)'),hold on
resol = 0.5;
[n,b]=hist(diff(spxtimes),0.005:0.01:(max(diff(spxtimes))));
bar(b(1:min([resol*1000 numel(b)])),n(1:min([resol*1000 numel(b)])),'b','EdgeColor','b')
axis([0 resol 0 ceil(max(n)*1.1)])
xlabel('interval (s)'),ylabel('frequency')

%%  interspike intervals, zoomed in
ha000=axes('units', 'centimeters', 'position', [1 1 1 1])

title('ISI (1ms bins)'),hold on
resol = 0.05;
[n,b]=hist(diff(spxtimes),0.0005:0.001:(max(diff(spxtimes))));
bar(b(1:resol*1000),n(1:resol*1000),'b','EdgeColor','b')
axis([0 resol 0 ceil(max(n)*1.1)])
xlabel('interval (s)'),ylabel('frequency')
nospx   = 3; % ms - time window in which spikes are not to be expected too often
spx = size(allwaves, 1);
violations = sum(n(1:nospx))/spx;

%% display PSTHs
psth_ku=[];

for i = 1:n_events
        
        binz = 10;
        
        [psth, trialspx ]= mpsth(r.Units.SpikeTimes(eunit).timings/1000, r.Behavior.EventTimings(r.Behavior.EventMarkers==(selected_events(i)))/1000,...
            'pre', pre(i), 'post', post(i), 'fr', 1, 'binsz', binz, 'chart', 0);
        
        psth(:, 2) = smoothdata (psth(:, 2), 'gaussian', 10);
        psth(:, 1)= psth(:, 1)/1000;
        binz = binz/1000;
                
        ha(i)=axes;
        set(ha(i), 'nextplot', 'add','units', 'centimeters', 'position', [4+2.5*(i-1), 1, 5 2])
        plot((psth(:,1)+binz),psth(:,2),'k','linewidth',1)
        axis([min(psth(:,1))-binz max(psth(:,1))+binz 0 max(psth(:,2))+1])
        psth_ku = [psth_ku; psth(:, 2)];
        title(event_types{i}, 'fontsize', 8)
%         
%         line([0 0], [0 max(psth_ku)+5], 'color', 'r','linewidth', 1, 'linestyle', ':')
%         line([0 0]-0.500, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]-1.000, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]-1.500, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]+0.500, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]+1.000, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
        xlabel('time (s)'),ylabel('trials')       
        
        ha2(i)=axes
        set(ha2(i), 'nextplot', 'add' , 'units', 'centimeters', 'position', [4+2.5*(i-1), 5, 5 1])
        
        if i>1
            axis off
        end;
        
        [rastmat timevec] = mraster(trialspx,pre(i),post(i));
        
        if length(rastmat)>20
            index_rand = randperm(size(rastmat, 1), 20);
            index_rand = sort(index_rand);
        else
            index_rand =[1:length(rastmat)];
        end;
        
        
        for ik = 1:numel(index_rand)
%             plot(timevec/1000,rastmat(ik,:)*ik,'Color','k','Marker','.','MarkerSize',2,'LineStyle','none')
%            
            jk = index_rand(ik);
            spktime = timevec(find(rastmat(jk, :)));
            
            xx = [spktime/1000; spktime/1000];
            yy = repmat([ik; ik+0.9], 1, length(spktime));
            plot(xx, yy, 'color', 'k', 'linewidth', 0.5)
            
        end
        
        set(ha2(i), 'xlim', [-pre(i)-10 post(i)+10]/1000, 'ylim', [0.5 numel(index_rand)+1], 'xtick', [])
        
        xlabel('time (s)'),ylabel('trials')
        
%         line([0 0], [0 numel(index_rand)+1], 'color', 'r','linewidth', 1, 'linestyle', ':')
%         line([0 0]-0.500, [0 numel(index_rand)+1], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]-1.000, [0 numel(index_rand)+1], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]-1.500, [0 numel(index_rand)+1], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]+0.500, [0 numel(index_rand)+1], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%         line([0 0]+1.000, [0 numel(index_rand)+1], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
        
end;


ymax = ceil(max(psth_ku)*1.5);

for i =1:n_events
    axes(ha(i))
%     pos1 = get(ha(1), 'position');
%     if i>1
%         
%         pos = get(ha(i), 'position'); pos(4)= pos1(4); pos(2)=pos1(2);
%         set(ha(i), 'position', pos);
%         
%     end;
    
    set(ha(i), 'ylim', [0 ymax], 'ytick', [0 ymax],...
        'xtick', [-1500:500:1500]/1000)
    xlabel('Time from event (s)')
    ylabel ('Spk per s')
    
    line([0 0], [0 ymax], 'color', 'r','linewidth', 1, 'linestyle', ':')
    line([0 0]-0.500, [0 ymax], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
    line([0 0]-1.000, [0 ymax], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
    line([0 0]-1.500, [0 ymax], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
    line([0 0]+0.500, [0 ymax], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
    line([0 0]+1.000, [0 ymax], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
%     
%     posbottom = get(ha(i), 'position');
%     postop= get(ha2(i), 'position'); 
%     postop(1)=posbottom(1);
%     postop(3)=posbottom(3);
%     postop(4)=0.5*posbottom(4);
%      
%     set(ha2(i), 'position', postop);
%     
%     posbottom = get(ha(i), 'position');
%     posbottom(4)=0.75*posbottom(4);
%      
%     set(ha(i), 'position', posbottom);
    
end;
set(gcf,'renderer','Painters')
printname = ['PSTH_' 'ExampleUnit' num2str(eu)];

print (gcf,'-dpng', printname)
saveas(gcf, printname, 'fig')
saveas(gcf, printname, 'epsc')

