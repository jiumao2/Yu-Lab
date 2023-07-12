function spkout = get_waveform_ISI(r, ch_id, unit_id)

% Jianing Yu 4/17/2023
% get waveform and autocorrelation of spike train.
% 4/20/2023 revised
% compute inter-spike interval distribution instead of autocorrelogram

if nargin<3
    ich_r = find(r.Units.SpikeNotes(:, 1) == ch_id);
else
    ich_r = find(r.Units.SpikeNotes(:, 1) == ch_id & r.Units.SpikeNotes(:, 2) == unit_id);
end;
max_lag = 200; % 200 ms
binsize = 5;
bin_edges = [0:binsize:max_lag];

spkout = struct('waveform', [], 'isi', []);

for k =1:length(ich_r)

    spkwave = median(r.Units.SpikeTimes(ich_r(k)).wave, 1);
    spkout(k).waveform = spkwave;

    spktimes   = r.Units.SpikeTimes(ich_r(k)).timings; % in ms

    spk_intervals = diff(spktimes);
    % compute spike density function of the interval distribution

    [f, xi]=ksdensity(spk_intervals, bin_edges);
    spkout(k).isi = [xi', f'];

 end; 