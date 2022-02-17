function M1LesionBehavior

% compare behavioral effect before and after M1 lesions
M1sham        = {
    'Tom',          'RTMixedAll_TOMPreLesion.mat'       'RTMixedAll_TOMPostLesion.mat'
    'John'          'RTMixedAll_JOHNPreLesion.mat'      'RTMixedAll_JOHNPostLesion.mat'
    };

M1lesion        = {
    'Steve'         'RTMixedAll_STEVEPreLesion.mat'         'RTMixedAll_STEVEPostLesion.mat'
        'Bob',           'RTMixedAll_BOBPreLesion.mat'            'RTMixedAll_BOBPostLesionD3.mat'
    };

Durs = [0:20:2500]/1000;

% FP = 1000 ms
% compare press duration of Tom before and after the surgery

% pre surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals', M1sham{1, 1}, M1sham{1, 2});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    Tom.Pre.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    Tom.Pre.Prem(j)                   =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    Tom.Pre.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    Tom.Pre.PressDens{j}          =     F;
    Tom.Pre.Durs                       =        Durs;
    RTij                                        =       RTMixed.RT{j};
    Tom.Pre.RTMixed{j}              =       RTij;
    Tom.Pre.FPMixed                 =       RTMixed.FPs;
end;

% post surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals',  M1sham{1, 1},  M1sham{1, 3});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    Tom.Post.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    Tom.Post.Prem(j)               =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    Tom.Post.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    Tom.Post.PressDens{j}          =     F;
    Tom.Post.Durs                       =      Durs;
    RTij                                        =       RTMixed.RT{j};
    Tom.Post.RTMixed{j}              =     RTij;
    Tom.Post.FPMixed                 =      RTMixed.FPs;
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];
 
hf1=figure(28); clf(28)
set(gcf, 'unit', 'centimeters', 'position',[2 2 20 10], 'paperpositionmode', 'auto' )

ha1 = axes;  % for performance
set(ha1, 'units', 'centimeters', 'position', [1.5 7 3.5 2.5], 'xlim', [1 4.5], 'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
ylabel('Fraction')
title('Tom')

j = 2;

% 1 s
n = 1;
hb1=bar(0.75+n, Tom.Pre.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, Tom.Pre.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, Tom.Pre.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);

% 1 s
n = 2.5;
hb1=bar(0.75+n, Tom.Post.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, Tom.Post.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, Tom.Post.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);


ha2= axes;  % for press duration
set(ha2, 'units', 'centimeters', 'position', [6.5 7 3.5 2.5], 'xlim', [0 2.5], 'ylim', [0 0.12], 'ytick', [0:0.1:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
hfill = fill([1 1+0.6 1+0.6 1], [0 0 0.2 0.2], 'c');
set(hfill, 'edgecolor', 'none')
hp2pre  = plot(Tom.Pre.Durs, Tom.Pre.PressDens{j}, 'linewidth', 1, 'color', 'k')
hp2post = plot(Tom.Post.Durs, Tom.Post.PressDens{j}, 'linewidth', 1, 'color', 'r')

xlabel ('Time from lever press')
ylabel ('Probability of lever release')

ha3= axes;  % for reaction time
set(ha3, 'units', 'centimeters', 'position', [11.5 7 3 2.5], 'xlim', [0 2.5], 'ylim', [0 0.65]*1000, 'ytick', [0:0.2:1]*1000,'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

AllRT=cell(1,2);
RTcat=[];

AllRT{1} = 1000*Tom.Pre.RTMixed{j};
RTcat = [RTcat; ones(length(Tom.Pre.RTMixed{j}), 1)];
    
AllRT{2} = 1000*Tom.Post.RTMixed{j};
RTcat = [RTcat; ones( length(Tom.Post.RTMixed{j}), 1)];

plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.5, 'categoryMarkers',{'.','.'},'categoryColors', {'k'})

pre_perc2575=prctile(AllRT{1}, [25 75]);
pre_perc95=prctile(AllRT{1}, [2.5 97.5]);
line([1 1], pre_perc2575, 'linewidth', 2, 'color', 'k')
line([1 1], pre_perc95, 'linewidth',0.5, 'color', 'k')
plot(1, median(AllRT{1}),  'linewidth', 1, 'color', 'k', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')


post_perc2575=prctile(AllRT{2}, [25 75]);
post_perc95=prctile(AllRT{2}, [2.5 97.5]);
line([2 2], post_perc2575, 'linewidth', 2, 'color', 'r')
line([2 2], post_perc95, 'linewidth', 0.5, 'color', 'r')
plot(2, median(AllRT{2}),   'linewidth', 1, 'color', 'r', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')

ylabel ('Reaction time (s)')

% cul distribution
ha4= axes;  % cul distribution
set(ha4, 'units', 'centimeters', 'position', [15 7 3 2.5], 'xlim',  [0 0.65]*1000,  'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

[fpre, xpre]=ecdf(AllRT{1});
Tom.Pre.ecdf = [xpre fpre];
[fpost, xpost]=ecdf(AllRT{2});
Tom.Post.ecdf = [xpost fpost];

plot(xpre, fpre, 'color', 'k');
plot(xpost, fpost, 'color', 'r');


xlabel('Rection time (ms)')
ylabel('Cumulative distribution')



%% plot Steve
% pre surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals', M1lesion{1, 1}, M1lesion{1, 2});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    Steve.Pre.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    Steve.Pre.Prem(j)                   =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    Steve.Pre.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    Steve.Pre.PressDens{j}          =     F;
    Steve.Pre.Durs                       =        Durs;
    RTij                                        =       RTMixed.RT{j};
    Steve.Pre.RTMixed{j}              =       RTij;
    Steve.Pre.FPMixed                 =       RTMixed.FPs;
end;

% post surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals',  M1sham{1, 1},  M1sham{1, 3});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    Steve.Post.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    Steve.Post.Prem(j)               =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    Steve.Post.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    Steve.Post.PressDens{j}          =     F;
    Steve.Post.Durs                       =      Durs;
    RTij                                        =       RTMixed.RT{j};
    Steve.Post.RTMixed{j}              =     RTij;
    Steve.Post.FPMixed                 =      RTMixed.FPs;
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

ha1 = axes;  % for performance
set(ha1, 'units', 'centimeters', 'position', [1.5 2 3.5 2.5], 'xlim', [1 4.5], 'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
ylabel('Fraction')
title('Steve')

j = 2;

% 1 s
n = 1;
hb1=bar(0.75+n, Steve.Pre.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, Steve.Pre.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, Steve.Pre.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);

% 1 s
n = 2.5;
hb1=bar(0.75+n, Steve.Post.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, Steve.Post.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, Steve.Post.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);


ha2= axes;  % for press duration
set(ha2, 'units', 'centimeters', 'position', [6.5 2 3.5 2.5], 'xlim', [0 2.5], 'ylim', [0 0.12], 'ytick', [0:0.1:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
hfill = fill([1 1+0.6 1+0.6 1], [0 0 0.2 0.2], 'c');
set(hfill, 'edgecolor', 'none')
hp2pre  = plot(Steve.Pre.Durs, Steve.Pre.PressDens{j}, 'linewidth', 1, 'color', 'k')
hp2post = plot(Steve.Post.Durs, Steve.Post.PressDens{j}, 'linewidth', 1, 'color', 'r')

xlabel ('Time from lever press')
ylabel ('Probability of lever release')

ha3= axes;  % for reaction time
set(ha3, 'units', 'centimeters', 'position', [11.5 2 3 2.5], 'xlim', [0 2.5], 'ylim', [0 0.65]*1000, 'ytick', [0:0.2:1]*1000,'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

AllRT=cell(1,2);
RTcat=[];

AllRT{1} = 1000*Steve.Pre.RTMixed{j};
RTcat = [RTcat; ones(length(Steve.Pre.RTMixed{j}), 1)];
    
AllRT{2} = 1000*Steve.Post.RTMixed{j};
RTcat = [RTcat; ones( length(Steve.Post.RTMixed{j}), 1)];

plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.5, 'categoryMarkers',{'.','.'},'categoryColors', {'k'})

pre_perc2575=prctile(AllRT{1}, [25 75]);
pre_perc95=prctile(AllRT{1}, [2.5 97.5]);
line([1 1], pre_perc2575, 'linewidth', 2, 'color', 'k')
line([1 1], pre_perc95, 'linewidth',0.5, 'color', 'k')
plot(1, median(AllRT{1}),  'linewidth', 1, 'color', 'k', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')


post_perc2575=prctile(AllRT{2}, [25 75]);
post_perc95=prctile(AllRT{2}, [2.5 97.5]);
line([2 2], post_perc2575, 'linewidth', 2, 'color', 'r')
line([2 2], post_perc95, 'linewidth', 0.5, 'color', 'r')
plot(2, median(AllRT{2}),   'linewidth', 1, 'color', 'r', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')

ylabel ('Reaction time (s)')


% cul distribution
ha4= axes;  % cul distribution
set(ha4, 'units', 'centimeters', 'position', [15 2 3 2.5], 'xlim',  [0 0.65]*1000,  'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

[fpre, xpre]=ecdf(AllRT{1});
Steve.Pre.ecdf = [xpre fpre];
[fpost, xpost]=ecdf(AllRT{2});
Steve.Post.ecdf = [xpost fpost];

plot(xpre, fpre, 'color', 'k');
plot(xpost, fpost, 'color', 'r');


xlabel('Rection time (ms)')
ylabel('Cumulative distribution')


%% plot John

% pre surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals', M1sham{2, 1}, M1sham{2, 2});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    John.Pre.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    John.Pre.Prem(j)                   =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    John.Pre.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    John.Pre.PressDens{j}          =     F;
    John.Pre.Durs                       =        Durs;
    RTij                                        =       RTMixed.RT{j};
    John.Pre.RTMixed{j}              =       RTij;
    John.Pre.FPMixed                 =       RTMixed.FPs;
end;

% post surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals',  M1sham{2, 1},  M1sham{2, 3});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    John.Post.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    John.Post.Prem(j)               =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    John.Post.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    John.Post.PressDens{j}          =     F;
    John.Post.Durs                       =      Durs;
    RTij                                        =       RTMixed.RT{j};
    John.Post.RTMixed{j}              =     RTij;
    John.Post.FPMixed                 =      RTMixed.FPs;
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];
 
hf2=figure(29); clf(29)
set(gcf, 'unit', 'centimeters', 'position',[2 12 20 10], 'paperpositionmode', 'auto' )

ha1 = axes;  % for performance
set(ha1, 'units', 'centimeters', 'position', [1.5 7 3.5 2.5], 'xlim', [1 4.5], 'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
ylabel('Fraction')
title('John')

j = 2;

% 1 s
n = 1;
hb1=bar(0.75+n, John.Pre.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, John.Pre.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, John.Pre.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);

% 1 s
n = 2.5;
hb1=bar(0.75+n, John.Post.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, John.Post.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, John.Post.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);


ha2= axes;  % for press duration
set(ha2, 'units', 'centimeters', 'position', [6.5 7 3.5 2.5], 'xlim', [0 2.5], 'ylim', [0 0.15], 'ytick', [0:0.1:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
hfill = fill([1 1+0.6 1+0.6 1], [0 0 0.2 0.2], 'c');
set(hfill, 'edgecolor', 'none')
hp2pre  = plot(John.Pre.Durs, John.Pre.PressDens{j}, 'linewidth', 1, 'color', 'k')
hp2post = plot(John.Post.Durs, John.Post.PressDens{j}, 'linewidth', 1, 'color', 'r')

xlabel ('Time from lever press')
ylabel ('Probability of lever release')

ha3= axes;  % for reaction time
set(ha3, 'units', 'centimeters', 'position', [11.5 7 3 2.5], 'xlim', [0 2.5], 'ylim', [0 0.65]*1000, 'ytick', [0:0.2:1]*1000,'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

AllRT=cell(1,2);
RTcat=[];

AllRT{1} = 1000*John.Pre.RTMixed{j};
RTcat = [RTcat; ones(length(John.Pre.RTMixed{j}), 1)];
    
AllRT{2} = 1000*John.Post.RTMixed{j};
RTcat = [RTcat; ones( length(John.Post.RTMixed{j}), 1)];

plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.5, 'categoryMarkers',{'.','.'},'categoryColors', {'k'})

pre_perc2575=prctile(AllRT{1}, [25 75]);
pre_perc95=prctile(AllRT{1}, [2.5 97.5]);
line([1 1], pre_perc2575, 'linewidth', 2, 'color', 'k')
line([1 1], pre_perc95, 'linewidth',0.5, 'color', 'k')
plot(1, median(AllRT{1}),  'linewidth', 1, 'color', 'k', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')


post_perc2575=prctile(AllRT{2}, [25 75]);
post_perc95=prctile(AllRT{2}, [2.5 97.5]);
line([2 2], post_perc2575, 'linewidth', 2, 'color', 'r')
line([2 2], post_perc95, 'linewidth', 0.5, 'color', 'r')
plot(2, median(AllRT{2}),   'linewidth', 1, 'color', 'r', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')

ylabel ('Reaction time (s)')

% cul distribution
ha4= axes;  % cul distribution
set(ha4, 'units', 'centimeters', 'position', [15 7 3 2.5], 'xlim',  [0 0.65]*1000,  'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

[fpre, xpre]=ecdf(AllRT{1});
John.Pre.ecdf = [xpre fpre];
[fpost, xpost]=ecdf(AllRT{2});
John.Post.ecdf = [xpost fpost];

plot(xpre, fpre, 'color', 'k');
plot(xpost, fpost, 'color', 'r');


xlabel('Rection time (ms)')
ylabel('Cumulative distribution')


%% plot Bob
% pre surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals', M1lesion{2, 1}, M1lesion{2, 2});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    Bob.Pre.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    Bob.Pre.Prem(j)                   =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    Bob.Pre.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    Bob.Pre.PressDens{j}          =     F;
    Bob.Pre.Durs                       =        Durs;
    RTij                                        =       RTMixed.RT{j};
    Bob.Pre.RTMixed{j}              =       RTij;
    Bob.Pre.FPMixed                 =       RTMixed.FPs;
end;

% post surgery
fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals',  M1sham{2, 1},  M1sham{2, 3});
load(fileloc);
for j = 1:length(RTMixed.FPs)
    Bob.Post.Corr(j)                     =       RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
    Bob.Post.Prem(j)               =      RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
    Bob.Post.Lat(j)                   =       RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
    F                                            =      20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
    Bob.Post.PressDens{j}          =     F;
    Bob.Post.Durs                       =      Durs;
    RTij                                        =       RTMixed.RT{j};
    Bob.Post.RTMixed{j}              =     RTij;
    Bob.Post.FPMixed                 =      RTMixed.FPs;
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

ha1 = axes;  % for performance
set(ha1, 'units', 'centimeters', 'position', [1.5 2 3.5 2.5], 'xlim', [1 4.5], 'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
ylabel('Fraction')
title('Bob')

j = 2;

% 1 s
n = 1;
hb1=bar(0.75+n, Bob.Pre.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, Bob.Pre.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, Bob.Pre.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);

% 1 s
n = 2.5;
hb1=bar(0.75+n, Bob.Post.Corr(j));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+n, Bob.Post.Prem(j));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+n, Bob.Post.Lat(j));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);


ha2= axes;  % for press duration
set(ha2, 'units', 'centimeters', 'position', [6.5 2 3.5 2.5], 'xlim', [0 2.5], 'ylim', [0 0.15], 'ytick', [0:0.1:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')
hfill = fill([1 1+0.6 1+0.6 1], [0 0 0.2 0.2], 'c');
set(hfill, 'edgecolor', 'none')
hp2pre  = plot(Bob.Pre.Durs, Bob.Pre.PressDens{j}, 'linewidth', 1, 'color', 'k')
hp2post = plot(Bob.Post.Durs, Bob.Post.PressDens{j}, 'linewidth', 1, 'color', 'r')

xlabel ('Time from lever press')
ylabel ('Probability of lever release')

ha3= axes;  % for reaction time
set(ha3, 'units', 'centimeters', 'position', [11.5 2 3 2.5], 'xlim', [0 2.5], 'ylim', [0 0.65]*1000, 'ytick', [0:0.2:1]*1000,'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

AllRT=cell(1,2);
RTcat=[];

AllRT{1} = 1000*Bob.Pre.RTMixed{j};
RTcat = [RTcat; ones(length(Bob.Pre.RTMixed{j}), 1)];
    
AllRT{2} = 1000*Bob.Post.RTMixed{j};
RTcat = [RTcat; ones( length(Bob.Post.RTMixed{j}), 1)];

plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.5, 'categoryMarkers',{'.','.'},'categoryColors', {'k'})

pre_perc2575=prctile(AllRT{1}, [25 75]);
pre_perc95=prctile(AllRT{1}, [2.5 97.5]);
line([1 1], pre_perc2575, 'linewidth', 2, 'color', 'k')
line([1 1], pre_perc95, 'linewidth',0.5, 'color', 'k')
plot(1, median(AllRT{1}),  'linewidth', 1, 'color', 'k', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')


post_perc2575=prctile(AllRT{2}, [25 75]);
post_perc95=prctile(AllRT{2}, [2.5 97.5]);
line([2 2], post_perc2575, 'linewidth', 2, 'color', 'r')
line([2 2], post_perc95, 'linewidth', 0.5, 'color', 'r')
plot(2, median(AllRT{2}),   'linewidth', 1, 'color', 'r', 'marker', 'o', 'markersize', 4, 'markerfacecolor', 'w')

ylabel ('Reaction time (s)')

% cul distribution
ha4= axes;  % cul distribution
set(ha4, 'units', 'centimeters', 'position', [15 2 3 2.5], 'xlim',  [0 0.65]*1000,  'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250], 'tickdir', 'out')

[fpre, xpre]=ecdf(AllRT{1});
John.Pre.ecdf = [xpre fpre];
[fpost, xpost]=ecdf(AllRT{2});
John.Post.ecdf = [xpost fpost];

plot(xpre, fpre, 'color', 'k');
plot(xpost, fpost, 'color', 'r');


xlabel('Rection time (ms)')
ylabel('Cumulative distribution')



savefolder = 'C:\Users\jiani\OneDrive\Work\Behavior\Figures';
savename1 = fullfile(savefolder, 'M1LesionTomSteve');
savename2 = fullfile(savefolder, 'M1LesionJohnBob');

print (hf1,'-dpng', [savename1])
saveas(hf1, savename1, 'epsc')

print (hf2,'-dpng', [savename2])
saveas(hf2, savename2, 'epsc')

    