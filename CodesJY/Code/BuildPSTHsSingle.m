function BuildPSTHsSingle(r, iunit)

% i is unit index
selected_events = [6 4 7 8];
event_types = {'Press', 'Trigger',  'GoodRel', 'Reward'};

pre = [2000 1000 1000 1000];
post = [2000 1000 1000 1000];


psth = cell(1, length(selected_events));
rastmat = cell(1, length(selected_events));

% n_unit = length(r.Units.SpikeTimes);
n_unit = iunit;
n_events = length(selected_events);

allcolors                                          = varycolor(length(r.Units.Channels));

figure(25); clf(25)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 8], 'paperpositionmode', 'auto' ,'color', 'w')

ku = n_unit

psth_ku=[];

thiscolor = allcolors(find(r.Units.Channels== r.Units.SpikeNotes(ku, 1)), :);

ncols = n_events+3;

% plot spike waveform
ha0=subplot(2, ncols, [1 2])
set(ha0, 'nextplot', 'add')

allwaves = r.Units.SpikeTimes(ku).wave;
allwaves= allwaves(:, [1:64]);

if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot=[1:size(allwaves, 1)];
end;

wave2plot = allwaves(nplot, :);

plot([1:64], wave2plot, 'color', [0.8 .8 0.8]);
plot([1:64], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)
axis([0 65 min(wave2plot(:)) max(wave2plot(:))])
set (gca, 'ylim', [-800 400])
axis tight

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


ha00=subplot(2, ncols,  [ncols+1 ncols+2])
if max(c)>1
    set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 median(c)])
else
    set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 1], 'ylim', [0 1])
end;

hbar = bar(lags, c);
set(hbar, 'facecolor', 'k')

if ku==n_unit
    xlabel('Lag(ms)')
end;

for i = 1:n_events
    
    binz = 10;
    
    [psth, trialspx ]= mpsth(r.Units.SpikeTimes(ku).timings/1000, r.Behavior.EventTimings(r.Behavior.EventMarkers==(selected_events(i)))/1000,...
        'pre', pre(i), 'post', post(i), 'fr', 1, 'binsz', binz, 'chart', 0);
    psth(:, 2) = smoothdata (psth(:, 2), 'gaussian', 5);
    psth(:, 1)= psth(:, 1)/1000;
    
    binz = binz/1000;
    
    if i==1
        ha(i)=subplot(2, n_events+3,i+ncols+[2 3])
    else
        ha(i)=subplot(2, n_events+3, i+3+ncols)
    end;
    
    if i==1
        haraster(i)=subplot(2, n_events+3,i+ [2 3])
    else
        haraster(i)=subplot(2, n_events+3, i+3 )
    end;
     
    axes(ha(i))
    set(ha(i), 'nextplot', 'add')
    
    plot((psth(:,1)+binz),psth(:,2), 'color', 'k', 'linewidth',1)
    
    axis([min(psth(:,1))-binz max(psth(:,1))+binz 0 max(psth(:,2))+1])
    
    if min(psth(:, 1))<-2
        set(ha(i), 'xtick', [-5:1:2])
    end;
    
    psth_ku = [psth_ku; psth(:, 2)];
    
        title(event_types{i})
 
    axes(haraster(i))
    set(haraster(i), 'ylim', [0, 10], 'ytick', [0 10], 'xtick', [], 'xlim', [-pre(i) post(i)], 'nextplot', 'add')
    
    if length(trialspx)>10
        indraster = randperm(length(trialspx), 10);
    else
        indraster = [1:length(trialspx)];
    end;
    
    for j = 1:length(indraster)
        spktime = trialspx{indraster(j)};
        xx =[spktime; spktime];
        yy = [(j-1) j-1+0.8];
        if ~isempty(xx)
            plot(xx, yy, 'k', 'linewidth', 1)
        end;
    end;
    
    line([0 0], [0 10], 'color', 'r','linewidth', 1, 'linestyle', ':')
    
    
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
 
    else
        set(ha(i), 'ylim', [0, max(psth_ku)+5], 'ytick', [0 floor(max(psth_ku)+5)],...
            'xtick', [-5:2], 'xgrid', 'on')
        line([0 0], [0 max(psth_ku)+5], 'color', 'r','linewidth', 1, 'linestyle', ':')
 
    end;
    
    if ku==n_unit
        xlabel('Time (s)')
    end;
    
end; 

uicontrol('style', 'text', 'units', 'normalized', 'position', [.01 .4 .1 .3], 'string', ([r.Meta(1).Subject r.Meta(1).DateTime]), 'BackgroundColor','w', 'fontsize', 10)
print (gcf,'-dpng', ['PSTH_Unit' num2str(iunit)])
saveas(gcf,  ['PSTH_Unit' num2str(iunit)], 'fig')

