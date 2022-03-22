function Spkout = ExtractPhasicPopulationEvents(r, varargin)

% 9.9.2020
% 4/13/2021
% extract population spikes at time t, pre- and post-t are defined by
% varargin
units = [];

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'units'
                units = varargin{i+1};
            case 't'
                tonset = floor(varargin{i+1});
            case 'tpre'
                tpre = round(varargin{i+1});
            case 'tpost'
                tpost = round(varargin{i+1});
            otherwise
                errordlg('unknown argument')
        end
    end
end

if isempty(units)
    units = 1:length(r.Units.SpikeTimes);
end;


%% collect PSTH from all neurons
Ncell = length(units);
Fs = double(r.Meta(1).SampleRes); % sampling rate

tspk          = tonset - tpre : tonset + tpost; % in ms
tspk_ct     = -tpre : tpost;

spkmat = sparse(Ncell, length(tspk));

spk_chs = zeros(1, Ncell);

for k = 1:Ncell; 
    
    ku = units(k);
    spk_chs(k) = r.Units.SpikeNotes(k, 1); % this is the channel this cell belongs to 
    spktime =  r.Units.SpikeTimes(ku);    
    [~,ind_spk] = intersect(tspk, spktime.timings);
    spkmat(k,ind_spk)=1;
    
end;

tspk = tspk - tonset;
%% plot spike timing 

% hf2=figure(40); clf(hf2)
% set(gcf, 'unit', 'centimeters', 'position', [2 2 12 8], 'paperpositionmode', 'auto' ,'color', 'w')
% 
% ha_raster=axes;
% set(ha_raster, 'nextplot', 'add', 'unit', 'centimeters', 'position', [2 2 8 5]);
% 
% ch_included = unique(spk_chs);
% colorcodes = varycolor(length(ch_included)); % color denotes channel address
% 
% for i=1:Ncell
%     ispktime = tspk_ct(find(spkmat(i, :)));   
%     if ~isempty(ispktime)
%         xx = [ispktime; ispktime];
%         yy =[i; i+0.8]-0.5;
%         plot(xx, yy, 'color', colorcodes(spk_chs(i) == ch_included, :), 'linewidth', 0.5)
%     end;
% end;
% 
% set(gca, 'xlim', [tspk(1) tspk(end)], 'ylim', [0 Ncell])
% % line([0 0], [0 Ncell], 'color', 'k', 'linestyle', ':')
% xlabel('Time (ms)')
% ylabel('Neuron #')
% title(sprintf('t: %2.0f ms', tonset))
% 
% axis off

Spkout.Ncell = Ncell;
Spkout.raster = spkmat;
Spkout.time = tspk;
Spkout.spk_chs = spk_chs;
