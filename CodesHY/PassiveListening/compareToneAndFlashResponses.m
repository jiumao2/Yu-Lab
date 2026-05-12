%% find input files
session_dir = '../';
mat_files = dir(fullfile('./*.mat'));
session_data_files = {mat_files.name};
if length(session_data_files) ~= 1
    error('Expected exactly one SessionData MAT file, found %d: %s', ...
        length(session_data_files), strjoin(session_data_files, ', '));
end
load(session_data_files{1}, 'SessionData');

mat_files = dir(fullfile('../RTarray_*.mat'));
r_files = {mat_files.name};
event_out_files = {fullfile('EventOut.mat')};
if length(r_files) ~= 1
    error('Expected exactly one r MAT file, found %d: %s', ...
        length(r_files), strjoin(r_files, ', '));
end
if length(event_out_files) ~= 1
    error('Expected exactly one EventOut MAT file, found %d: %s', ...
        length(event_out_files), strjoin(event_out_files, ', '));
end
load(fullfile(session_dir, r_files{1}), 'r');
load(fullfile(session_dir, event_out_files{1}), 'EventOut');

%% get Bpod trigger times
trigger_type_labels = cellstr(string(SessionData.TriggerTypeLabels));
trigger_types = SessionData.TriggerTypes(:)';

trigger_times_bpod_sec = nan(1, SessionData.nTrials);
for k = 1:SessionData.nTrials
    if iscell(SessionData.RawEvents.Trial)
        trial_states = SessionData.RawEvents.Trial{k}.States;
    else
        trial_states = SessionData.RawEvents.Trial(k).States;
    end

    state_names = fieldnames(trial_states);
    idx_generate = find(startsWith(state_names, 'Generate', 'IgnoreCase', true));
    if isempty(idx_generate)
        error('Trial %d has no Generate* cue state.', k);
    end

    candidate_times = nan(1, length(idx_generate));
    for j = 1:length(idx_generate)
        state_times = trial_states.(state_names{idx_generate(j)});
        if ~isempty(state_times) && isfinite(state_times(1))
            candidate_times(j) = state_times(1);
        end
    end
    if all(isnan(candidate_times))
        error('Trial %d has Generate* cue states, but none has a valid onset time.', k);
    end
    trigger_times_bpod_sec(k) = min(candidate_times) + SessionData.TrialStartTimestamp(k);
end

%% match to r
event_labels = cellstr(string(EventOut.EventsLabels));
idx_trigger = find(strcmpi(event_labels, 'Trigger'));
if length(idx_trigger) ~= 1
    error('Expected exactly one Trigger event in EventOut, found %d.', length(idx_trigger));
end
trigger_times_ephys_sec = EventOut.Onset{idx_trigger}./1000;

idx_match = findseqmatch(trigger_times_ephys_sec, trigger_times_bpod_sec);
plotMatchingResults(trigger_times_ephys_sec, trigger_times_bpod_sec, idx_match);

valid_match = isfinite(idx_match) & idx_match > 0 & idx_match <= length(trigger_times_ephys_sec);
matched_trigger_times_ms = nan(size(trigger_types));
matched_trigger_times_ms(valid_match) = trigger_times_ephys_sec(idx_match(valid_match))*1000;

%% save cue times to r
analyze_cue_names = {};
analyze_cue_times = {};
for k = 1:length(trigger_type_labels)
    cue_name = trigger_type_labels{k};
    cue_field = matlab.lang.makeValidName([cue_name 'Times']);
    cue_times = matched_trigger_times_ms(trigger_types == k & valid_match);
    r.Behavior.(cue_field) = cue_times;

    if ~strcmpi(cue_name, 'Both') && ~isempty(cue_times)
        analyze_cue_names{end+1} = cue_name; %#ok<SAGROW>
        analyze_cue_times{end+1} = cue_times; %#ok<SAGROW>
    end
end

%% save to r
save(fullfile(session_dir, r_files{1}), 'r', '-nocompression');

if isempty(analyze_cue_names)
    warning('No non-Both cue trials were found. Saved cue times to r and skipped response analysis figures.');
    return
end

%% compute response times
n_units = length(r.Units.SpikeTimes);
t_response = cell(1, length(analyze_cue_names));
for j = 1:length(analyze_cue_names)
    t_response{j} = nan(1, n_units);
end

for k = 1:n_units
    for j = 1:length(analyze_cue_names)
        t_response{j}(k) = computeResponseTime(r, k, analyze_cue_times{j});
    end
    if mod(k, 20) == 1
        fprintf('%d / %d done!\n', k, n_units);
    end
end

%% plot response time histograms
fig = EasyPlot.figure();
ax = EasyPlot.axes(fig,...
    'Width', 5,...
    'Height', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1,...
    'MarginRight', 1);

colors = lines(length(analyze_cue_names));
legend_plots = gobjects(1, length(analyze_cue_names));
hold(ax, 'on');
for j = 1:length(analyze_cue_names)
    legend_plots(j) = plot(ax, nan, nan, '-', 'Color', colors(j,:));
    histogram(ax, t_response{j}, 'BinWidth', 20, 'FaceColor', colors(j,:), 'FaceAlpha', 0.6);
end
xlabel(ax, 'Response time from cue (ms)');
ylabel(ax, 'Number of units');
EasyPlot.cropFigure(fig);

h = EasyPlot.legend(ax, analyze_cue_names,...
    'location', 'northeastoutside',...
    'lineWidth', 6,...
    'lineLength', 0.2,...
    'selectedPlots', legend_plots);
EasyPlot.move(h, 'dx', -1);

EasyPlot.exportFigure(fig, fullfile('./ResponseLatency'));

%% plot responsive unit locations
y_locations = r.Units.ChanMap.ycoords(r.Units.SpikeNotes(:,1));

fig = EasyPlot.figure();
ax = EasyPlot.createGridAxes(fig, 1, length(analyze_cue_names)+1,...
    'Width', 3,...
    'Height', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1,...
    'MarginRight', 1);

EasyPlot.violinplot(ax{1}, y_locations, 1);
ylabel(ax{1}, 'Unit locations (um)');
title(ax{1}, 'All units');

for j = 1:length(analyze_cue_names)
    responsive = ~isnan(t_response{j});
    if any(responsive)
        EasyPlot.violinplot(ax{j+1}, y_locations(responsive), 1);
    else
        plot(ax{j+1}, nan, nan);
    end
    title(ax{j+1}, sprintf('%s-responsive units', analyze_cue_names{j}));
end
EasyPlot.setYLim(ax);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, fullfile('./ResponsiveUnitLocations'));
