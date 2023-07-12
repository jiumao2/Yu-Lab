function spkout = get_waveform_autocorr(r, ch_id, unit_id)

% Jianing Yu 4/17/2023
% get waveform and autocorrelation of spike train.
if nargin<3
    ich_r = find(r.Units.SpikeNotes(:, 1) == ch_id);
else
    ich_r = find(r.Units.SpikeNotes(:, 1) == ch_id & r.Units.SpikeNotes(:, 2) == unit_id);
end;
max_lag = 200; % 200 ms
binsize = 5;

spkout = struct('waveform', [], 'autocorr', []);

for k =1:length(ich_r)

    spkwave = median(r.Units.SpikeTimes(ich_r(k)).wave, 1);
    spkout(k).waveform = spkwave;

    spktimes   = r.Units.SpikeTimes(ich_r(k)).timings; % in ms

    spktrain = zeros(spktimes(end),1);
    spktrain(spktimes) = 1;

    indx = [1:length(spktrain)];
    n_bins =  floor(length(indx)/binsize);
    spktrain2 = sum(reshape(spktrain(1:n_bins*binsize), binsize, []), 1);
   
    [c, lags] = xcorr(spktrain2, spktrain2, max_lag/binsize);
    c=c(lags>0);
    lags=lags(lags>0);
    spkout(k).autocorr = [binsize*lags' c'];

    % compute cross-correlation

%     figure(22); clf(22)
%     set(22, 'units', 'centimeters', 'position', [2 2 12 6],'Visible', 'on')
%     subplot(1, 2, 1)
%     plot(spkwave,'linewidth', 2);
%     subplot(1, 2, 2)
%     plot(lags(lags~=0), c(lags~=0))
%     set(gca, 'xlim', [0 500]);
 end; 