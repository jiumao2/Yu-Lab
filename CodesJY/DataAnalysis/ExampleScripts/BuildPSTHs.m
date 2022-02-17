%  [psth trialspx] = mpsth(spxtimes,trigtimes,varargin)
%  [rastmat timevec] = mraster(trialspx,pre,post);

% events [3 4 6 8]

figure; plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==3), 3, 'ko')


%  r.Behavior.Labels={'FrameOn', 'FrameOff', 'LeverPress', 'Trigger', 'LeverRelease', 'GoodPress', 'GoodRelease',...
%      'ValveOnset', 'ValveOffset', 'PokeOnset', 'PokeOffset' };
% r.Behavior.LabelMarkers = [1:length(r.Behavior.Labels)];
%
% [psth, trialspx ]= mpsth(r.Units.SpikeTimes(1).timings/1000, r.Behavior.EventTimings(r.Behavior.EventMarkers==3)/1000,...
%     'pre', 1000, 'post', 1000, 'fr', 1, 'binsz', 20, 'chart', 2);
%

selected_events = [6 4 7 8];
event_types = {'Press', 'Trigger',  'GoodRel', 'Reward'};

figure; plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(1)), 3, 'ko')
hold on;
plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(2)), 3.2, 'ro')
plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(3)), 3.4, 'go')
plot(r.Behavior.EventTimings(r.Behavior.EventMarkers==selected_events(4)), 3.6, 'mo')
set(gca, 'ylim', [2.5 4])



pre = [5500 1000 1000 2000];
post = [2000 1000 1000 1000];


psth = cell(1, length(selected_events));
rastmat = cell(1, length(selected_events));

n_unit = length(r.Units.SpikeTimes);
n_events = length(selected_events);

allcolors                                          = varycolor(length(r.Units.Channels));

figure(25); clf(25)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 3*n_unit+1.5], 'paperpositionmode', 'auto' ,'color', 'w')

ha=axes('unit', 'centimeters', 'position', [2 2 20 15]);

for ku = 1:n_unit
    
    psth_ku=[];
    
    thiscolor = allcolors(find(r.Units.Channels== r.Units.SpikeNotes(ku, 1)), :);
    
    % plot spike waveform
    ha0=subplot(n_unit, n_events+2, (ku-1)*(n_events+2)+1)
    set(ha0, 'nextplot', 'add', 'xtick', [], 'ytick', [])
    
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
    axis off
    
    switch r.Units.SpikeNotes(ku, 3)
        case 1
            title(['#' num2str(ku) '/Ch' num2str(r.Units.SpikeNotes(ku, 1)) '/unit' num2str(r.Units.SpikeNotes(ku, 2))  '/SU']);
        case 2
            title(['#' num2str(ku) '/Ch' num2str(r.Units.SpikeNotes(ku, 1)) '#' num2str(ku) '/unit' num2str(r.Units.SpikeNotes(ku, 2))  '/MU']);
        otherwise
    end
    
    % plot autocorrelation
    kutime = r.Units.SpikeTimes(ku).timings;
    
    kutime2 = zeros(1, max(kutime));
    kutime2(kutime)=1;
    
    [c, lags] = xcorr(kutime2, 25); % max lag 100 ms
    
    c(lags==0)=0;
    
    ha00=subplot(n_unit, n_events+2, (ku-1)*(n_events+2)+2)
    set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 median(c)])
    
    hbar = bar(lags, c);
    set(hbar, 'facecolor', 'k')
    
    if ku==n_unit
        xlabel('Lag(ms)')
    end;
    
    for i = 1:n_events
        
        binz = 10;
        
        [psth, trialspx ]= mpsth(r.Units.SpikeTimes(ku).timings/1000, r.Behavior.EventTimings(r.Behavior.EventMarkers==(selected_events(i)))/1000,...
            'pre', pre(i), 'post', post(i), 'fr', 1, 'binsz', binz, 'chart', 0);
        psth(:, 2) = smoothdata (psth(:, 2), 'gaussian', 10);
        psth(:, 1)= psth(:, 1)/1000;
        
        binz = binz/1000;
        
        ha(i)=subplot(n_unit, n_events+2, (ku-1)*(n_events+2)+i+2)
        set(ha(i), 'nextplot', 'add')
        
        plot((psth(:,1)+binz),psth(:,2), 'color', 'k', 'linewidth',1)
        
        axis([min(psth(:,1))-binz max(psth(:,1))+binz 0 max(psth(:,2))+1])
        
        if min(psth(:, 1))<-2
            set(ha(i), 'xtick', [-5:1:2])
        end;
        
        psth_ku = [psth_ku; psth(:, 2)];
        
        if ku ==1;
            title(event_types{i})
        end;
        
    end;
    
    for i =1:n_events
        axes(ha(i))
        set(ha(i), 'ylim', [0, max(psth_ku)+5], 'ytick', [0 floor(max(psth_ku)+5)], 'xtick', [])
        
        if i>1
            
            pos1 = get(ha(1), 'position');
            pos = get(ha(i), 'position'); pos(4)= pos1(4); pos(2)=pos1(2);
            set(ha(i), 'position', pos);
            
        end;
        
        if min(get(ha(i),'xlim'))>-2
            set(ha(i), 'ylim', [0, max(psth_ku)+5], 'ytick', [0 floor(max(psth_ku)+5)],...
                'xtick', [-1500:500:1500]/1000, 'xgrid','on')
            line([0 0], [0 max(psth_ku)+5], 'color', 'r','linewidth', 1, 'linestyle', ':')
            %             line([0 0]-0.500, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
            %             line([0 0]-1.000, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
            %             line([0 0]-1.500, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
            %             line([0 0]+0.500, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
            %             line([0 0]+1.000, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
        else
            set(ha(i), 'ylim', [0, max(psth_ku)+5], 'ytick', [0 floor(max(psth_ku)+5)],...
                'xtick', [-5:2], 'xgrid', 'on')
            line([0 0], [0 max(psth_ku)+5], 'color', 'r','linewidth', 1, 'linestyle', ':')
            %             line([0 0]-1.000, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
            %             line([0 0]+1.000, [0 max(psth_ku)+5], 'color', 'k','linewidth', 0.5, 'linestyle', ':')
        end;
        
        if ku==n_unit
            xlabel('Time (s)')
        end;
        
    end;
    
    
end;
print (gcf,'-dpng', ['PSTH_All' ])
saveas(gcf, 'PSTH_All', 'fig')

%% plot spikes across the whole session


figure(30); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 n_unit*2+6], 'paperpositionmode', 'auto' , 'color', 'w')
 

ha1= axes;
set(ha1, 'units', 'centimeters', 'position', [2 1.5 12 3.5], 'nextplot', 'add', 'xlim', [0 max(r.Behavior.EventTimings/(1000))],'ytick', [3 11], 'ytick', [3:11], 'yticklabel',r.Behavior.Labels(3:end), 'fontsize', 8)

plot([r.Behavior.EventTimings(r.Behavior.EventMarkers>2)/(1000)], [r.Behavior.EventMarkers(r.Behavior.EventMarkers>2)],'o', 'color', 'w','markersize', 3, 'linewidth', 0.5, 'markerfacecolor', 'k')
xlabel('Time(s)')

units = r.Units.Profile;
ha2                                                 = axes;
set(ha2, 'units', 'centimeters', 'position', [2 5.2 12 n_unit*2], 'xlim', get(ha1, 'xlim'), 'ylim', [0.5 size(r.Units.SpikeNotes , 1)+0.5], 'ytick', [1:1:40],'ydir', 'reverse', 'nextplot', 'add', 'fontsize', 8);
linkaxes([ha1, ha2], 'x')

% put spikes

for ku                                              = 1:size(r.Units.SpikeNotes, 1)
    channel_id                                         = r.Units.SpikeNotes(ku, 1);  % channel id
    cluster_id                                          = r.Units.SpikeNotes(ku, 2);  % cluster id
    thiscolor = allcolors(find(r.Units.Channels== r.Units.SpikeNotes(ku, 1)), :);
    
    
    x_plot                                             = r.Units.SpikeTimes(ku).timings;
    x_plot                                             = [x_plot]/(1000);
    y_plot                                             =  ku -1 + 0.8*rand(1, length(x_plot))+0.5;
    
    if ~isempty(x_plot)
        plot(ha2, x_plot, y_plot,'.', 'color', thiscolor,'markersize', 4);
    end;
    
end;

set(ha2, 'xlim', [0 max(r.Behavior.EventTimings/(1000))], 'xtick', [])
 

print (gcf,'-dpng', ['Events_Spikes_All' ])
% saveas(gcf, 'Events_Spikes_All, 'fig')
