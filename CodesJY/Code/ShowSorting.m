function ShowSorting

% Check all sorting results from wave_clus
% This gives us an overview of what't coming
% Jianing Yu 2022/10/2


if  isempty(dir('times_polytrode*.mat'))
    poly = 0
else
    poly =1;
end;

allcolors = [
    0 0.3 1
    1 0 0.4    
    0.1 1 0
    0 1 1
    1 0.4 0
    0.5 0 1
    1 0 0.4
    1 0.4 0
    0.1 1 0
    0 1 1
    0 0.3 1
    0.5 0 1
    1 0 0.4
    ];

tDiv = [0:1:100];
tCents = [tDiv(1:end-1) + tDiv(2:end)]/2;

%         allcolors =  allcolors(2:end-1, :);

if poly
    %      IndPolySpikes = dir('polytrode*_spikes.mat');
    IndPoly = dir('times_polytrode*.mat');

    hf = figure(16); clf(hf)
    hmax = 12;
    ht = 2;
    wt = 3.5;
    ht2=1;
    set(hf, 'units', 'Centimeters', 'Position', [4 4 20 hmax]);
    for i = 1:length(IndPoly)
        if i <=4
            ha(i) = axes('units', 'centimeters', 'position', [2+4.5*(i-1)  8 wt, ht], 'xlim', [0 3], 'ylim', [-150 50], 'nextplot', 'add');
            title(['tetrode#' num2str(i)])
            ha2(i) = axes('units', 'centimeters', 'position', [2+4.5*(i-1)  6.5 wt, ht2], 'xlim', [0 50], 'nextplot', 'add');
        else
            ha(i) = axes('units', 'centimeters', 'position', [2+4.5*(i-5)  3 wt, ht], 'xlim', [0 3], 'ylim', [-150 50],'nextplot', 'add');
            title(['tetrode#' num2str(i)])
            ha2(i) = axes('units', 'centimeters', 'position', [2+4.5*(i-5)  1.5 wt, ht2], 'xlim', [0 50], 'nextplot', 'add');
        end;
        ind = cell2mat(extractBetween(IndPoly(i).name, 'polytrode', '.mat'));
        tSpikes = load(IndPoly(i).name);
        %          tSpikes =
        %               par: [1×1 struct]
        %            spikes: [226099×256 double]
        %             inspk: [226099×31 double]
        %           ipermut: [209629 18689 295 64652 71164 166673 91080 108535 55646 16629 6174 19055 68378 … ]
        %              Temp: [16 16]
        %            forced: [1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 … ]
        %        gui_status: [1×1 struct]
        %     cluster_class: [226099×2 double]
        clus = tSpikes.cluster_class(:, 1);
        clus_types = unique(clus);    % e.g., 0, 1, 2

        if length(clus_types)>1
            for k =1:length(clus_types)-1
                ind_spikes = clus == clus_types(k+1);
                spike_waves = tSpikes.spikes(ind_spikes, :)/4;
                spike_mean = mean(spike_waves, 1);
                spike_sd       = std(spike_waves, 0, 1);
                tSpkwav = [1:length(spike_mean)]/30;
                set(ha(i), 'xlim', [0 tSpkwav(end)]);
%                 plotshaded(tSpk, [spike_mean-spike_sd; spike_mean+spike_sd], allcolors(k, :))
                plot(ha(i), tSpkwav, spike_mean, 'linewidth', 1, 'color', allcolors(k, :))

                timeSpikes = tSpikes.cluster_class(ind_spikes, 2);
                ISI_Hist = histcounts(diff(timeSpikes), tDiv);                
                plot(ha2(i), tCents, ISI_Hist, 'linewidth',1,'color', allcolors(k, :));

            end;
        end;
    end;
else
   %      IndPolySpikes = dir('polytrode*_spikes.mat');
    IndPoly = dir('times_chdat*.mat');

    hf = figure(16); clf(hf)
    hmax = 18;
    ht = 2;
    wt = 2.8;
    ht2=1;
    set(hf, 'units', 'Centimeters', 'Position', [4 4 33 hmax]);
    for k = 1:length(IndPoly)

        ind = cell2mat(extractBetween(IndPoly(k).name, 'times_chdat', '.mat'));

        i = str2double(ind);
        if rem(i, 8)~=0
            ind_row            =        floor(i/8)+1;
            ind_column      =         rem(i, 8);
        else
            ind_row            =        floor(i/8);
            ind_column      =        8;
        end;

        ha(i) = axes('units', 'centimeters', 'position', [1.5+4*(ind_column-1)  1.5+4*(ind_row-1)+ht2+0.5 wt, ht], 'xlim', [0 3], 'ylim', [-200 100], 'nextplot', 'add');
        title(['#' ind])
        ha2(i) = axes('units', 'centimeters', 'position', [1.5+4*(ind_column-1)  1.5+4*(ind_row-1) wt, ht2], 'xlim', [0 50], 'nextplot', 'add');

        if ind_row>1
            set(ha(i),'xtick', []);
            set(ha2(i), 'xtick', []);
        end;

        tSpikes = load(IndPoly(k).name);
        %          tSpikes =
        %               par: [1×1 struct]
        %            spikes: [226099×256 double]
        %             inspk: [226099×31 double]
        %           ipermut: [209629 18689 295 64652 71164 166673 91080 108535 55646 16629 6174 19055 68378 … ]
        %              Temp: [16 16]
        %            forced: [1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 … ]
        %        gui_status: [1×1 struct]
        %     cluster_class: [226099×2 double]
        clus = tSpikes.cluster_class(:, 1);
        clus_types = unique(clus);    % e.g., 0, 1, 2

        if length(clus_types)>1
            for k =1:length(clus_types)-1
                if k >10
                    continue
                end;
                ind_spikes = clus == clus_types(k+1);
                spike_waves = tSpikes.spikes(ind_spikes, :)/4;
                spike_mean = mean(spike_waves, 1);
                spike_sd       = std(spike_waves, 0, 1);
                tSpkwav = [1:length(spike_mean)]/30;
                set(ha(i), 'xlim', [0 tSpkwav(end)]);
%                 plotshaded(tSpk, [spike_mean-spike_sd; spike_mean+spike_sd], allcolors(k, :))
                plot(ha(i), tSpkwav, spike_mean, 'linewidth', 1, 'color', allcolors(k, :))

                timeSpikes = tSpikes.cluster_class(ind_spikes, 2);
                ISI_Hist = histcounts(diff(timeSpikes), tDiv);                
                plot(ha2(i), tCents, ISI_Hist, 'linewidth',1,'color', allcolors(k, :));

            end;
        end;
    end;
end;

tosavename= 'SortingResults';
print (16,'-dpng', tosavename);



