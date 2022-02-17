function FPvsRTBimodal(bMixedFPs, RTrange, name)

if nargin<3
    RTrange = [250 500];
    if nargin<2
        name = [];
    end;
end; 

RTmin = 50;   % minimal RT
 
FPs                 = cell(1, length(bMixedFPs));
RTs                 = cell(1, length(bMixedFPs));
Performance   = cell(1, length(bMixedFPs)); % 1: correct, 2: ealry, 3: late; 4. Dark 

FPs_accumulated = [];
RTs_accumulated =[];
Performance_accumulated = [];  % 1: correct, 2: ealry, 3: late; 4. Dark 

for i = 1:length(bMixedFPs)
    b = bMixedFPs(i);
    
    total_presses = length(b.FPs(50:end-50));
    
    Performance{i} = zeros(1, length(b.FPs));
    Performance{i}(b.Correct)=1;
    Performance{i}(b.Premature) = 2;
    Performance{i}(b.Late) =3;
    Performance{i}(b.Dark) =4;
    Performance{i} = Performance{i}(50:end-50);
    Performance_accumulated=[Performance_accumulated Performance{i}];
    
    [~, index_correct] = intersect (b.Correct, [50:length(b.FPs)-50])
    
    FPs{i} = b.FPs(b.Correct);
    RTs{i} = b.ReleaseTime(b.Correct) - b.PressTime(b.Correct)-FPs{i} /1000;
    
    RTs{i} = RTs{i}(index_correct)*1000;
    FPs{i}=FPs{i}(index_correct);
    
    RTs_accumulated=[RTs_accumulated RTs{i}];
    FPs_accumulated=[FPs_accumulated FPs{i}];
end;

figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 12 15], 'paperpositionmode', 'auto' )
ha=subplot(3, 1, 1); set(ha, 'nextplot', 'add', 'xlim', [0 3000], 'ylim', [0 600])
title([bMixedFPs(1).Metadata.SubjectName ' '  bMixedFPs(1).Metadata.Date '-' bMixedFPs(end).Metadata.Date])
allcolors = varycolor(length(RTs)+5);

for i =1:length(RTs)
    plot(FPs{i}, RTs{i}, 'o', 'markersize', 3, 'color', allcolors(i+2, :),...
        'markerfacecolor', allcolors(i+2, :), 'markeredgecolor', 'w', 'linewidth', .25)
end;

tstart = 0;
tstep = 100;
twin = 50;

FPcenters = [];
RTmedian = [];
Npress = [];

while tstart+twin <3000
    
    tbin =[tstart tstart + twin];
    FPcenters = [FPcenters mean(tbin)];
    ind_fps = find(FPs_accumulated>=tbin(1) & FPs_accumulated<tbin(2));
    Npress = [Npress length(ind_fps)];
    if length(ind_fps)>10
        iRTs = RTs_accumulated(ind_fps);
        iRTs = iRTs(iRTs>RTmin);
        %     RTmedian = [RTmedian median(iRTs)];
        RTmedian = [RTmedian geomean(iRTs)];
    else
        RTmedian = [RTmedian NaN];
    end;
    tstart = tstart+tstep;
end;

hold on
plot(FPcenters, RTmedian, 'ko-', 'linewidth', 1.5)
    
xlabel ('FP (ms)')
ylabel ('RT (ms)')

%% dividing FPs based on percentiles 
FP_mid = 1350;  % this seperate the short FPs from the long FPs
[FPsorted, indsort] = sort(FPs_accumulated);
RTsorted = RTs_accumulated(indsort);

% short FPs
ind_short_last = find(FPsorted<FP_mid, 1, 'last');
FPs_short = FPsorted(1:ind_short_last);
RTs_short = RTsorted(1:ind_short_last);

FP_short_prctile = 0;
step =5;
win = 20;

FPs_short_bins = [];
RTs_short_bins = [];

i =1;
while FP_short_prctile+win<=100
    
    prctile_now = prctile(FPs_short, [FP_short_prctile FP_short_prctile+win])
    ind_bin = find(FPs_short>=prctile_now(1) & FPs_short<prctile_now(2));
    
    FPs_i = FPs_short(ind_bin); 
    RTs_i = RTs_short(ind_bin);
    
    FPs_short_bins(i) = median(FPs_i);
    RTs_short_bins(i) = geomean(RTs_i(RTs_i>RTmin));
    
    i = i+1;
    FP_short_prctile=FP_short_prctile + step;
end;

%% linear regression
pfit = polyfit(FPs_short_bins, RTs_short_bins, 1);
xsim = [400:2500];
ysim = polyval(pfit, xsim);

% long FPs
ind_long_first = find(FPsorted>FP_mid, 1, 'first');
FPs_long = FPsorted(ind_long_first:end);
RTs_long=RTsorted(ind_long_first:end);

FP_long_prctile = 0;

FPs_long_bins = [];
RTs_long_bins = [];

i =1;

while FP_long_prctile+win<=100
    
    prctile_now = prctile(FPs_long, [FP_long_prctile FP_long_prctile+win])
    ind_bin = find(FPs_long>=prctile_now(1) & FPs_long<prctile_now(2));
    
    FPs_i = FPs_long(ind_bin); 
    RTs_i = RTs_long(ind_bin);
    
    FPs_long_bins(i) = median(FPs_i);
    RTs_long_bins(i) = geomean(RTs_i(RTs_i>RTmin));
    
    i = i+1;
    FP_long_prctile=FP_long_prctile + step;
end;

plot(FPs_short_bins, RTs_short_bins, 'g*-', 'linewidth', 1.5)
plot(FPs_long_bins, RTs_long_bins, '*-', 'linewidth', 1.5, 'color', [0 .6  .2])
plot(xsim, ysim, 'g--', 'linewidth', 1);

ha=subplot(3, 1, 2); set(ha, 'nextplot', 'add', 'xlim', [0 3000], 'ylim', [240 310])
% plot(FPcenters, RTmedian, 'ko-', 'linewidth', 1.5)

plot(FPs_short_bins, RTs_short_bins, 'g*-', 'linewidth', 1.5)
plot(FPs_long_bins, RTs_long_bins, '*-', 'linewidth', 1.5, 'color', [0 .6  .2])
plot(xsim, ysim, 'g--', 'linewidth', 1);

axis 'auto y'
xlabel ('FP (ms)')
ylabel ('RT (ms)')

% load two-FP only condition
x=dir('*Center.mat')
if ~isempty(x)
    load(x.name)
end;

plot(RTMixed.FPs, RTMixed.RTmean_geo, 'ro', 'markersize', 6, 'linewidth', 1);

for i = 1:length(RTMixed.FPs)
    line([RTMixed.FPs(i) RTMixed.FPs(i)], [RTMixed.RTci_geo(i, :)], 'linewidth', 0.5)
end;

if diff(get(gca, 'ylim'))<50
    ylimorg = get(gca, 'ylim');
    set(gca, 'ylim', mean(ylimorg)+[-25 25])
    
end;

ha=subplot(3, 1, 3); set(ha, 'nextplot', 'add', 'xlim', [0 3000], 'ylim', [0 100])
tbins =[0:50:3000];
tcenters = (tbins(1:end-1)+tbins(2:end))/2;
npress = histcounts(FPs_accumulated, tbins);

hbar = bar(tcenters, npress)

axis 'auto y'    
xlabel ('FP (ms)')
ylabel ('# of presses')


rt_early = RTs_accumulated(FPs_accumulated<1500);
rt_late = RTs_accumulated(FPs_accumulated>1500);

[P, H]=ranksum(rt_early, rt_late)

sprintf('early-FP RT is %2.0f, late-FP RT is %2.0f',  median(rt_early), median(rt_late))


savename = ['BimodalFPs'  upper(bMixedFPs(1).Metadata.SubjectName)];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

saveas(gcf, savename, 'fig')

% savename = ['RTBimodal_' upper(bMixedFPs(1).Metadata.SubjectName) name];
% save (savename, 'RTbimodal')
