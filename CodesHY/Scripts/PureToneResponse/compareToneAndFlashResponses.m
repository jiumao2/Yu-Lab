load ../RTarray_Gavi_20251224.mat;
%%
load ./Gavi_SRTL_01_TestToneAndFlashResponse_20251224_204806.mat;

trigger_type_labels = SessionData.TriggerTypeLabels;
idx_flash = find(strcmpi(trigger_type_labels, 'Flash'));
idx_tone = find(strcmpi(trigger_type_labels, 'Tone'));

trigger_times_bpod_sec = zeros(1, SessionData.nTrials);
for k = 1:SessionData.nTrials
    trigger_times_bpod_sec(k) = SessionData.RawEvents.Trial{k}.States.GenerateTone(1) + SessionData.TrialStartTimestamp(k);
end
trigger_types = SessionData.TriggerTypes + 1;

%% match to r
load ../EventOut.mat;
idx_trigger = find(strcmpi(EventOut.EventsLabels, 'Trigger'));
trigger_times_ephys_sec = EventOut.Onset{idx_trigger}./1000;

idx_match = findseqmatch(trigger_times_ephys_sec, trigger_times_bpod_sec);
flash_times = trigger_times_ephys_sec(idx_match(trigger_types == idx_flash))*1000;
tone_times = trigger_times_ephys_sec(idx_match(trigger_types == idx_tone))*1000;

%%
t_response_flash = zeros(1,length(r.Units.SpikeTimes));
t_response_tone = zeros(1,length(r.Units.SpikeTimes));

for k = 1:length(r.Units.SpikeTimes)
    t_response_flash(k) = computeResponseTime(r,k,flash_times);
    t_response_tone(k) = computeResponseTime(r,k,tone_times);
    if mod(k,20) == 1
        fprintf('%d / %d done!\n', k, length(r.Units.SpikeTimes));
    end
end

%%
fig = EasyPlot.figure();
ax = EasyPlot.axes(fig,...
    'Width', 5,...
    'Height', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1,...
    'MarginRight', 1);

colors = lines(2);

h1 = plot(ax, 0, 0, '-', 'Color', colors(1,:));
h2 = plot(ax, 0, 0, '-', 'Color', colors(2,:));

histogram(ax, t_response_flash, 'BinWidth', 20, 'FaceColor', colors(1,:));
histogram(ax, t_response_tone, 'BinWidth', 20, 'FaceColor', colors(2,:));
xlabel(ax, 'Response time from cue (ms)');
ylabel(ax, 'Number of units');
EasyPlot.cropFigure(fig);   

h = EasyPlot.legend(ax, {'Flash', 'Tone'},...
    'location', 'northeastoutside',...
    'lineWidth', 6,...
    'lineLength', 0.2,...
    'selectedPlots', [h1, h2]);
EasyPlot.move(h, 'dx', -1);

EasyPlot.exportFigure(fig, './ResponseToPureCue');

%%

% for k = 1:length(r.Units.SpikeTimes)
%     plotPureTriggerResponse(r, k, {tone_times, flash_times}, {'Tone', 'Flash'});
%     close all;
% end

%%

y_locations = r.Units.ChanMap.ycoords(r.Units.SpikeNotes(:,1));

fig = EasyPlot.figure();
ax = EasyPlot.createGridAxes(fig, 1, 3,...
    'Width', 3,...
    'Height', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1,...
    'MarginRight', 1);

EasyPlot.violinplot(ax{1}, y_locations, 1);
EasyPlot.violinplot(ax{2}, y_locations(~isnan(t_response_tone)), 1);
EasyPlot.violinplot(ax{3}, y_locations(~isnan(t_response_flash)), 1);

ylabel(ax{1}, 'Unit locations (um)');
title(ax{1}, 'All units');
title(ax{2}, 'Tone-responsive units');
title(ax{3}, 'Flash-responsive units');
EasyPlot.setYLim(ax);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, './ResponsiveUnitsLocations.png')







