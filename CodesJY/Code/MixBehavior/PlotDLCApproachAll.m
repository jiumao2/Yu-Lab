function PlotDLCApproachAll(bUpAll)

hf_DLC = figure(25); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 29 10], 'paperpositionmode', 'auto');
ha=axes('unit','centimeters', 'position', [1 1 8 8], 'nextplot', 'add', 'xlim', [0 400], 'ylim', [0 400], 'ydir', 'reverse')
axis off
%% plot a pic of the frame
VideoFile = fullfile(pwd, 'DLC_live', 'Vid', 'pineapple2021-06-27T14_30_27.avi')

vidObj=VideoReader(VideoFile);
SampleFrame = rgb2gray(read(vidObj, [1600 1600]));
imagesc(SampleFrame)
colormap('gray')

ClusColors = {[0.5 0.5 0.5], 'm', 'c'};

StimPos = cell(1, 3);
NoStimPos = cell(1, 3);
DLC2PressStim = [];
DLC2PressStimClus = [];
DLC2PressNoStim = [];
DLC2PressNoStimClus = [];
App2PressStim = [];
App2PressNoStim = [];

for k = 1:length(bUpAll)
    
    
    DLC2PressStim = [DLC2PressStim; bUpAll(k).DLC2PressLatencyStim(:, 2)];
    DLC2PressStimClus = [DLC2PressStimClus; bUpAll(k).DLCStimClus'];
    
    DLC2PressNoStim = [DLC2PressNoStim; bUpAll(k).DLC2PressLatencyNoStim(:, 2)];
    DLC2PressNoStimClus = [DLC2PressNoStimClus; bUpAll(k).DLCNoStimClus'];
    
    App2PressStim = [App2PressStim; bUpAll(k).Approach2PressLatencyStim(:, 2)];
    App2PressNoStim = [App2PressNoStim; bUpAll(k).Approach2PressLatencyNoStim(:, 2)];
    
    for i =1:length(bUpAll(k).DLCStimTime)
        StimPos{bUpAll(k).DLCStimClus(i)+1} = [StimPos{bUpAll(k).DLCStimClus(i)+1}; bUpAll(k).DLCStimPos(i, :)];
    end;
    for i =1:length(bUpAll(k).DLCNoStimTime)
        NoStimPos{bUpAll(k).DLCNoStimClus(i)+1} = [NoStimPos{bUpAll(k).DLCNoStimClus(i)+1}; bUpAll(k).DLCNoStimPos(i, :)];
    end;
end;


for j = 2:3
    plot(NoStimPos{j}(:, 1), NoStimPos{j}(:, 2), 's', 'color', 'w', 'markerfacecolor', ClusColors{j}, 'linewidth', 1, 'markersize',  6)
    plot(StimPos{j}(:, 1), StimPos{j}(:, 2), 'o', 'color', 'w', 'markerfacecolor', ClusColors{j}, 'linewidth', 1, 'markersize',  6)
end;

%% find out press vs nont-pressed ratio

ha4=axes('unit','centimeters', 'position', [10 6 5 2.5], 'nextplot', 'add', 'xlim', [0 9], 'xtick', [1.5, 4.5 7.5], 'xticklabel', {'Appr', 'DLC-Close', 'DLC-Far'}, 'ylim', [0 100], 'ytick', [0:20:100],  'xcolor', 'k', 'ycolor', 'k')

NAppNoStim      =    arrayfun(@(x)x.Approach2PressLatencyNoStim(:, 1), bUpAll, 'Uniformoutput', 0); % not pressed after approach
NanAppNoStim      =    arrayfun(@(x)x.Approach2PressLatencyNoStim(find(isnan(x.Approach2PressLatencyNoStim(:, 2))), 1), bUpAll, 'Uniformoutput', 0); % not pressed after approach

NAppStim      =    arrayfun(@(x)x.Approach2PressLatencyStim(:, 1), bUpAll, 'Uniformoutput', 0); % not pressed after approach
NanAppStim      =    arrayfun(@(x)x.Approach2PressLatencyStim(find(isnan(x.Approach2PressLatencyStim(:, 2))), 1), bUpAll, 'Uniformoutput', 0); % not pressed after approach

NDLCNoStimClus1 = arrayfun(@(x)x.DLC2PressLatencyNoStim(x.DLCNoStimClus==1, 1), bUpAll, 'Uniformoutput', 0); 
NanDLCNoStimClus1 = arrayfun(@(x)x.DLC2PressLatencyNoStim(isnan(x.DLC2PressLatencyNoStim(x.DLCNoStimClus==1, 2)), 1), bUpAll, 'Uniformoutput', 0);

NDLCNoStimClus2 = arrayfun(@(x)x.DLC2PressLatencyNoStim(x.DLCNoStimClus==2, 1), bUpAll, 'Uniformoutput', 0); 
NanDLCNoStimClus2 = arrayfun(@(x)x.DLC2PressLatencyNoStim(isnan(x.DLC2PressLatencyNoStim(x.DLCNoStimClus==2, 2)), 1), bUpAll, 'Uniformoutput', 0);

NDLCStimClus1 = arrayfun(@(x)x.DLC2PressLatencyStim(x.DLCStimClus==1, 1), bUpAll, 'Uniformoutput', 0); 
NanDLCStimClus1 = arrayfun(@(x)x.DLC2PressLatencyStim(isnan(x.DLC2PressLatencyStim(x.DLCStimClus==1, 2)), 1), bUpAll, 'Uniformoutput', 0);

NDLCStimClus2 = arrayfun(@(x)x.DLC2PressLatencyStim(x.DLCStimClus==2, 1), bUpAll, 'Uniformoutput', 0); 
NanDLCStimClus2 = arrayfun(@(x)x.DLC2PressLatencyStim(isnan(x.DLC2PressLatencyStim(x.DLCStimClus==2, 2)), 1), bUpAll, 'Uniformoutput', 0);


hbar1= bar([1], [100*(1-length(cell2mat(NanAppNoStim'))/length(cell2mat(NAppNoStim')))])
set(hbar1, 'facecolor', [0 0 0])

hbar2 = bar([2], [100*(1-length(cell2mat(NanAppStim'))/length(cell2mat(NAppStim')))])
set(hbar2, 'facecolor', [0 184 255]/255)

hbar4= bar([4], [100*(1-length(cell2mat(NanDLCNoStimClus1'))/length(cell2mat(NDLCNoStimClus1')))])
set(hbar4, 'facecolor', [0 0 0])

hbar5 = bar([5], [100*(1-length(cell2mat(NanDLCStimClus1'))/length(cell2mat(NDLCStimClus1')))])
set(hbar5, 'facecolor', [0 184 255]/255)

hbar7= bar([7], [100*(1-length(cell2mat(NanDLCNoStimClus2'))/length(cell2mat(NDLCNoStimClus2')))])
set(hbar7, 'facecolor', [0 0 0])

hbar8 = bar([8], [100*(1-length(cell2mat(NanDLCStimClus2'))/length(cell2mat(NDLCStimClus2')))])
set(hbar8, 'facecolor', [0 184 255]/255)

%% Approach
ha4=axes('unit','centimeters', 'position', [10 1.5 3 3], 'nextplot', 'add', 'xlim', [0 3], 'ylim', [-0.5 5], 'ytick', [0:5], 'box', 'on')
% plot the second cluster
bins = [0:0.05:5];
cents = (bins(1:end-1)+bins(2:end))/2;

App2PressNoStim = App2PressNoStim(~isnan(App2PressNoStim));
App2PressStim = App2PressStim(~isnan(App2PressStim));

N_App2PressNoStim = histcounts(App2PressNoStim, bins);
N_App2PressStim = histcounts(App2PressStim, bins);

Data_App = {App2PressNoStim; App2PressStim};
CatIndex_App = [zeros(1, length(App2PressNoStim)) ones(1, length(App2PressStim))];

plotSpread(Data_App, 'categoryIdx', CatIndex_App,  'categoryMarkers',{'.','.'},...
    'categoryColors',{'k',[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim'},'spreadWidth', 0.8, 'binWidth', 0.2)
set(ha4, 'xticklabel', {'NoStim', 'Stim'})
ylabel('Latency Approach-Press (s)')

ha4b=axes('unit','centimeters', 'position', [13.5 1.5 1.5 3], 'nextplot', 'add', 'xlim', [0 0.1], 'ylim', [-0.5 5], 'ytick', [0:5], 'yticklabel', [])
plot(smoothdata(N_App2PressNoStim/sum(N_App2PressNoStim), 'gaussian', 5), cents, 'k', 'linewidth', 1);
plot(smoothdata(N_App2PressStim/sum(N_App2PressStim), 'gaussian', 5), cents, 'color',  [0 184 255]/255, 'linewidth', 1);
xlabel('Probability')


%% plot the first cluster
ha2=axes('unit','centimeters', 'position', [16.5 1.5 3 3], 'nextplot', 'add', 'xlim', [0 5], 'ylim', [-0.5 4], 'ytick', [0:5], 'box', 'on' , 'xcolor', ClusColors{2}, 'ycolor', ClusColors{2})

% plot the first cluster

DLC2PressNoStimClus1 = DLC2PressNoStim(DLC2PressNoStimClus==1);
DLC2PressNoStimClus1 = DLC2PressNoStimClus1(~isnan(DLC2PressNoStimClus1));
N_DLC2PressNoStimClus1 = histcounts(DLC2PressNoStimClus1, bins);
 
DLC2PressStimClus1 = DLC2PressStim(DLC2PressStimClus==1);
DLC2PressStimClus1 = DLC2PressStimClus1(~isnan(DLC2PressStimClus1));
N_DLC2PressStimClus1 = histcounts(DLC2PressStimClus1, bins);

% plot(DLC2PressNoStimClus1, rand(1, length(DLC2PressNoStimClus1)), 'wo', 'markerfacecolor', 'k', 'markersize', 3);
% plot(DLC2PressStimClus1, rand(1, length(DLC2PressStimClus1)), 'wo', 'markerfacecolor',  [0 184 255]/255, 'markersize', 3);

Data_DLCClus1 = {DLC2PressNoStimClus1; DLC2PressStimClus1};
CatIndex_DLCClust1 = [zeros(1, length(DLC2PressNoStimClus1)) ones(1, length(DLC2PressStimClus1))];

plotSpread(Data_DLCClus1, 'categoryIdx', CatIndex_DLCClust1,  'categoryMarkers',{'.','.'},...
    'categoryColors',{'k',[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim'},'spreadWidth', 0.8, 'binWidth', 0.2)
ylabel('Latency DLC-Press (s)')
set(ha2, 'xticklabel', {'NoStim', 'Stim'})

ha2b=axes('unit','centimeters', 'position', [20 1.5 1.5 3], 'nextplot', 'add', 'xlim', [0 0.2], 'ylim', [-0.5 4], 'ytick', [0:1:5], 'yticklabel', [])
plot(smoothdata(N_DLC2PressNoStimClus1/sum(N_DLC2PressNoStimClus1), 'gaussian', 5), cents, 'k', 'linewidth', 1);
plot(smoothdata(N_DLC2PressStimClus1/sum(N_DLC2PressStimClus1), 'gaussian', 5),cents, 'color',  [0 184 255]/255, 'linewidth', 1);
xlabel('Probability')

%% second cluster
ha3=axes('unit','centimeters', 'position', [23 1.5 3 3], 'nextplot', 'add', 'xlim', [0 3], 'ylim', [-0.5 5], 'ytick', [0:5], 'box', 'on' , 'xcolor', ClusColors{3}, 'ycolor', ClusColors{3})

bins = [0:0.05:5];
cents = (bins(1:end-1)+bins(2:end))/2;
% plot the first cluster

DLC2PressNoStimClus2 = DLC2PressNoStim(DLC2PressNoStimClus==2);
DLC2PressNoStimClus2 = DLC2PressNoStimClus2(~isnan(DLC2PressNoStimClus2));
N_DLC2PressNoStimClus2 = histcounts(DLC2PressNoStimClus2, bins);
 
DLC2PressStimClus2 = DLC2PressStim(DLC2PressStimClus==2);
DLC2PressStimClus2 = DLC2PressStimClus2(~isnan(DLC2PressStimClus2));
N_DLC2PressStimClus2 = histcounts(DLC2PressStimClus2, bins);

Data_DLCClus2 = {DLC2PressNoStimClus2; DLC2PressStimClus2};
CatIndex_DLCClust2 = [zeros(1, length(DLC2PressNoStimClus2)) ones(1, length(DLC2PressStimClus2))];

plotSpread(Data_DLCClus2, 'categoryIdx', CatIndex_DLCClust2,  'categoryMarkers',{'.','.'},...
    'categoryColors',{'k',[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim'},'spreadWidth', 0.8, 'binWidth', 0.2)
ylabel('Latency DLC-Press (s)')
set(ha3, 'xticklabel', {'NoStim', 'Stim'})

ha2b=axes('unit','centimeters', 'position', [26.5 1.5 1.5 3], 'nextplot', 'add', 'xlim', [0 0.2], 'ylim', [-0.5 5], 'ytick', [0:1:5], 'yticklabel', [])
plot(smoothdata(N_DLC2PressNoStimClus2/sum(N_DLC2PressNoStimClus2), 'gaussian', 5), cents, 'k', 'linewidth', 1);
plot(smoothdata(N_DLC2PressStimClus2/sum(N_DLC2PressStimClus2), 'gaussian', 5),cents, 'color',  [0 184 255]/255, 'linewidth', 1);
xlabel('Probability')


thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['DLCApproachMixAll']);

saveas (gcf, tosavename, 'fig')
print (gcf,'-dpng', tosavename)