function plotMatchingResults(seq_mom, seq_son, idx_match)

fig = EasyPlot.figure();
ax = EasyPlot.axes(fig,...
    'Width', 25,...
    'Height', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 2);

seq_mom_aligned = seq_mom - seq_mom(idx_match(1));
seq_son_aligned = seq_son - seq_son(1);

x_plot = [];
y_plot = [];
for k = 1:length(idx_match)
    x_plot = [x_plot, seq_son_aligned(k), seq_mom_aligned(idx_match(k)), NaN];
    y_plot = [y_plot, 1, 2, NaN];
end

plot(ax, seq_mom_aligned, 2, 'ro');
plot(ax, seq_son_aligned, 1, 'bo');
plot(ax, x_plot, y_plot, 'k-', 'LineWidth', 0.5);

ylim(ax, [0.8, 2.2]);
EasyPlot.setYTicksAndLabels(ax, [1,2], {'SeqSon', 'SeqMon'});
EasyPlot.cropFigure(fig);

EasyPlot.set(ax, 'Units', 'Normalized');

end