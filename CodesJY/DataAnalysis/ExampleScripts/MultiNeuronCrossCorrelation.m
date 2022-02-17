% %  [psth trialspx] = mpsth(spxtimes,trigtimes,varargin)
% %  [rastmat timevec] = mraster(trialspx,pre,post);
% 
% % events [3 4 6 8]
% 
% figure; plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==3), 3, 'ko')
% 
% 
% %  r.Behavior.Labels={'FrameOn', 'FrameOff', 'LeverPress', 'Trigger', 'LeverRelease', 'GoodPress', 'GoodRelease',...
% %      'ValveOnset', 'ValveOffset', 'PokeOnset', 'PokeOffset' };
% % r.Behavior.LabelMarkers = [1:length(r.Behavior.Labels)];
% %
% % [psth, trialspx ]= mpsth(r.Units.SpikeTimes(1).timings/1000, r.Behavior.EventTimings(r.Behavior.EventMarkers==3)/1000,...
% %     'pre', 1000, 'post', 1000, 'fr', 1, 'binsz', 20, 'chart', 2);
% %
% 
% selected_events = [6 4 7 8];
% event_types = {'Press', 'Trigger',  'GoodRel', 'Reward'};
% 
% figure; plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(1)), 3, 'ko')
% hold on;
% plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(2)), 3.2, 'ro')
% plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(3)), 3.4, 'go')
% plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(4)), 3.6, 'mo')
% set(gca, 'ylim', [2.5 4])
% 
% 
% 
% pre = [5500 1000 1000 2000];
% post = [2000 1000 1000 1000];
% 
% 
% psth = cell(1, length(selected_events));
% rastmat = cell(1, length(selected_events));
% 
% n_unit = length(r.Units.SpikeTimes);
% n_events = length(selected_events);

allcolors                                          = varycolor(length(r.Units.Channels));

figure(25); clf(25)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 22], 'paperpositionmode', 'auto' ,'color', 'w')
  
for ku = 1:n_unit
    
    psth_ku=[];
    
    thiscolor = allcolors(find(r.Units.Channels== r.Units.SpikeNotes(ku, 1)), :);
  
    kutime = r.Units.SpikeTimes(ku).timings;
    
    kutime2 = zeros(1, max(kutime));
    kutime2(kutime)=1;
    
    
    % plot spike waveform
    ha00=subplot(n_unit+1, n_unit+1, (ku)*(n_unit+1)+1)
    set(ha00, 'nextplot', 'add', 'xtick', [], 'ytick', [])
    
    allwaves = r.Units.SpikeTimes(ku).wave;
    
    if size(allwaves, 1)>100
        nplot = randperm(size(allwaves, 1), 100);
    else
        nplot=[1:size(allwaves, 1)];
    end;
    
    wave2plot = allwaves(nplot, :);
    
    plot([1:64], wave2plot, 'color', [0.8 .8 0.8]);
    plot([1:64], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)
    axis([0 65 min(wave2plot(:)) max(wave2plot(:))])
    title(['#' num2str(ku) '/C' num2str(r.Units.SpikeNotes(ku, 1))]);
    
    axis off
    
    for ju = 1:n_unit
        
        if ku==1
            
             thiscolor = allcolors(find(r.Units.Channels== r.Units.SpikeNotes(ju, 1)), :);
  
            % plot spike waveform
            ha000=subplot(n_unit+1, n_unit+1, ju+1)
            set(ha000, 'nextplot', 'add', 'xtick', [], 'ytick', [])
            
            allwaves = r.Units.SpikeTimes(ju).wave;
            
            if size(allwaves, 1)>100
                nplot = randperm(size(allwaves, 1), 100);
            else
                nplot=[1:size(allwaves, 1)];
            end;
            
            wave2plot = allwaves(nplot, :);
            
            plot([1:64], wave2plot, 'color', [0.8 .8 0.8]);
            plot([1:64], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)
            axis([0 65 min(wave2plot(:)) max(wave2plot(:))])
            axis off
            
            title(['#' num2str(ju) '/C' num2str(r.Units.SpikeNotes(ju, 1))]);
            
        end
        
        % plot autocorrelation
        jutime = r.Units.SpikeTimes(ju).timings;
    
    jutime2 = zeros(1, max(jutime));
    jutime2(jutime)=1;
    
    if length(jutime2)>length(kutime2)
        kutime2 = [kutime2 zeros(1, length(jutime2)-length(kutime2))];
    else
        jutime2 = [jutime2 zeros(1, length(kutime2)-length(jutime2))];
    end
    
    
    ha0=subplot(n_unit+1, n_unit+1,(n_unit+1)*(ku)+ju+1)
    
    set(ha0, 'nextplot', 'add', 'xtick', [-20:20:20], 'ytick', [], 'xlim', [-20 20])
    [c, lags] = xcorr(kutime2, jutime2, 20); % max lag 100 ms
    
    plot(lags, c, 'k')
    end;
    
end;

uicontrol('style', 'text', 'units', 'normalized', 'position', [.01 .9 .1 .3], 'string', ([r.Meta(1).Subject r.Meta(1).DateTime]), 'BackgroundColor','w', 'fontsize', 10)
print (gcf,'-dpng', ['CrosCorrelation_All' ])
saveas(gcf, 'CrosCorrelation_All', 'fig')

