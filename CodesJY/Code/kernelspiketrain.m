function kernelspiketrain(r, unit, width)

sigma = width; % in ms

gaussfilter = gausswin(11*sigma+1);
gaussfilter = gaussfilter/sum(gaussfilter);

% data is like this:
%     timings: [39594×1 double]
%        wave: [39594×64 double]

data=r.Units.SpikeTimes(unit);

tsparse = 1:round(max(data.timings))+1000;
spk_sparse = sparse([], [], [], length(tsparse), 1);
spk_sparse(data.timings) =1;

% conv:
spk_conv = conv(full(spk_sparse), gaussfilter, 'same');

figure;

ha1=axes;
set(ha1, 'units', 'normalized', 'position', [0.1 0.1 0.75 0.8], 'yaxislocation', 'right',  'nextplot', 'add','color', 'none', ...
    'xlim', [0 max(r.Behavior.EventTimings/(1000))],'xtick', [], 'ylim', [-2 15], 'ytick', [3:10], 'yticklabel',r.Behavior.Labels(3:end), 'fontsize', 8)
plot([r.Behavior.EventTimings(r.Behavior.EventMarkers>2)/(1000)], [r.Behavior.EventMarkers(r.Behavior.EventMarkers>2)],'o', 'color', 'k','markersize', 3, 'linewidth', 1)
 
ha2=axes('units', 'normalized', 'position', [0.1 0.1 0.75 0.8], 'nextplot', 'add', 'color', 'none',...
    'xtick', [0:100:max(r.Behavior.EventTimings/(1000))], 'yaxislocation', 'left', 'fontsize', 7)
plot(tsparse/1000, 1000*spk_conv, 'r', 'linewidth', 1)
xlabel('Time (s)')
ylabel('Firing rate (Hz)')
linkaxes([ha1, ha2], 'x')
