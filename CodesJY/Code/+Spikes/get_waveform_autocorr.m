function spkout = get_waveform_autocorr(r, ch_id, unit_id)

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

spkout = struct('waveform', [], 't_isi', [],'isi', [], 't_lag', [], 'auto',[], 'violation_3ms_percent', []);

for k =1:length(ich_r)

    spkwave = median(r.Units.SpikeTimes(ich_r(k)).wave, 1);
    spkout(k).waveform = spkwave/4;
    spktimes   = r.Units.SpikeTimes(ich_r(k)).timings; % in ms
    spk_intervals = diff(spktimes);
    % compute spike density function of the interval distribution
    [f, xi]=ksdensity(spk_intervals, bin_edges);
    spkout(k).t_isi = xi;
    spkout(k).isi = f;
    % compute auto correlation
    % plot autocorrelation
    kutime = round(spktimes);
    kutime2 = zeros(1, max(kutime));
    kutime2(kutime)=1;
    [c, lags] = xcorr(kutime2, 100); % max lag 100 ms
    c(lags==0)=0;
    spkout(k).t_lag = lags;
    spkout(k).auto = c;
    % compute violation 
    vio = 100*sum(diff(spktimes)<3)/length(spktimes);
    spkout(k).violation_3ms_percent = vio;


 end; 