function spkout = get_waveform(r, ch_id)
ich_r = find(r.Units.SpikeNotes(:, 1) == ch_id);
 max_lag = 200;

spkout = struct('waveform', [], 'autocorr', []);

for k =1:length(ich_r)

    spkwave = median(r.Units.SpikeTimes(ich_r(k)).wave, 1);
    spkout(k).waveform = spkwave;

    spktimes   = r.Units.SpikeTimes(ich_r(k)).timings; % in ms

    spktrain = zeros(spktimes(end),1);
    spktrain(spktimes) = 1;

    [c, lags] = xcorr(spktrain, spktrain, max_lag, 'coeff');
    spkout(k).autocorr = [lags' c];

    % compute cross-correlation

%     figure(22); clf(22)
%     set(22, 'units', 'centimeters', 'position', [2 2 12 6],'Visible', 'on')
%     subplot(1, 2, 1)
%     plot(spkwave,'linewidth', 2);
%     subplot(1, 2, 2)
%     plot(lags(lags~=0), c(lags~=0))
%     set(gca, 'xlim', [0 500]);
 end; 