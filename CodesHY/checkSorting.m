function checkSorting(r)
fig = EasyPlot.figure();
n_channel = 2^ceil(log2(max(r.Units.SpikeNotes(:,1))));
n_col = 8;
n_row = n_channel/n_col;
axes = EasyPlot.createGridAxes(fig,n_row,n_col,...
    'MarginLeft',0.8,...
    'XAxisVisible','off');
channels = r.Units.SpikeNotes(:,1);
colors = varycolor(max(r.Units.SpikeNotes(r.Units.SpikeNotes(:,3)==1,2)));
for k = 1:length(r.Units.SpikeTimes)
    if r.Units.SpikeNotes(k,3) == 2
        continue
    end
    mean_waveform = mean(r.Units.SpikeTimes(k).wave,1)/4;
    row_this = ceil(channels(k)/n_col);
    col_this = mod(channels(k)-1,n_col)+1;
    plot(axes{row_this, col_this}, mean_waveform);
    title(axes{row_this, col_this}, ['#',num2str(channels(k))])
    
end

EasyPlot.setXLim(axes,[0,size(r.Units.SpikeTimes(1).wave,2)]);

EasyPlot.cropFigure(fig);

end