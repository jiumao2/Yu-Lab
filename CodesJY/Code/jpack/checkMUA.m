function checkMUA(T, spikes, n, varargin)

% 5.4.2015
% T is the overal structure
% spikes are from spike waveform analysis. 
% n is the trial nums

vn=T.trials{n}.spikesTrial.rawSignal; 
licks=T.trials{n}.behavTrial.beamBreakTimes;
aom= T.trials{n}.spikesTrial.AOM;
aom=aom/20;

[b, a]=butter(4, 300*2/10000, 'high');
vn=filtfilt(b, a, vn);
tn=[0:length(vn)-1]/10;
spkn=find(spikes.trialnums==n);
spkn(spikes.choose(spkn)==0)=[];
spkn=spikes.time(spkn);
figure;
set(gcf, 'units', 'centimeters', 'position', [2 2 15 8], 'paperpositionmode', 'auto')

plot(tn, vn, 'k')
hold on
plot(spkn, mean(vn)*ones(1, length(spkn)), 'rx')
if ~isempty(licks)
    plot(licks*1000, -0.2+mean(vn)*ones(1, length(licks)), 'co')
end;

plot(tn, aom-0.5, 'b')

xlabel('ms')
ylabel('mV')

set(gca, 'xlim', [0 5000]);
if nargin>3
    set(gca, 'ylim', varargin{1})
    if nargin>4
        set(gca, 'xlim', varargin{2})
    end;
end;
title([T.cellNum 'trial' num2str(T.trialNums(n))])
export_fig(gcf, 'trace', '-tiff');

