clear
save_filename_pdf = './ExamplePETH.pdf';
save_filename_png = './ExamplePETH.png';
save_resolution = 1200;

data_path_unit = {...
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 1,... % lift
    'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat', 3,... % lift
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 3,... % press
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 13,... % press
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat', 1,... % release
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 18,... % release
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 7,... % holding
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat', 14,... % holding
    };
data_path_lift = {'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',1};
data_path_press = {'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 3};
data_path_holding = {'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat', 7};
data_path_release = {'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat', 1};
ntrial_raster = 40;

t_pre = -2000;
t_post = 2000;
binwidth_PSTH = 20;
colors_name = {'red','blue'};
linewidth_PSTH  = 1;

color_lift = 'g';
color_press = 'k';
color_release = 'c';

rand('seed',123);
%% Figure Configuration
margin_left = 1;
margin_right = 0.5;
margin_up = 0.5;
margin_bottom = 1;
space_row = 0.7;
space_col = 1;

width_raster = 3;
height_raster = 3;
width_PSTH = 3;
height_PSTH = 3;

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_raster*4 + space_col*3;
figure_height = margin_up + margin_bottom + height_raster*2 + height_PSTH + space_row*2;
h.Position = [10,10,figure_width,figure_height];

ax_raster_lift1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_lift1.Position = [margin_left,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_lift1.YTick = [1,ntrial_raster];
ax_raster_lift1.YLim = [0.5,ntrial_raster+0.5];
ax_raster_lift1.XAxis.Visible = 'off';
xlim(ax_raster_lift1,[t_pre,t_post])
ylabel(ax_raster_lift1,'Trials');

ax_raster_lift2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_lift2.Position = [margin_left,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_lift2.YTick = [1,ntrial_raster];
ax_raster_lift2.YLim = [0.5,ntrial_raster+0.5];
ax_raster_lift2.XAxis.Visible = 'off';
xlim(ax_raster_lift2,[t_pre,t_post])
ylabel(ax_raster_lift2,'Trials');

ax_raster_press1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_press1.Position = [margin_left+space_col+width_raster,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_press1.YTick = [1,ntrial_raster];
ax_raster_press1.YLim = [0.5,ntrial_raster+0.5];
ax_raster_press1.XAxis.Visible = 'off';
ax_raster_press1.YAxis.Visible = 'off';
xlim(ax_raster_press1,[t_pre,t_post])

ax_raster_press2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_press2.Position = [margin_left+space_col+width_raster,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_press2.YTick = [1,ntrial_raster];
ax_raster_press2.YLim = [0.5,ntrial_raster+0.5];
ax_raster_press2.XAxis.Visible = 'off';
ax_raster_press2.YAxis.Visible = 'off';
xlim(ax_raster_press2,[t_pre,t_post])

ax_raster_holding1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_holding1.Position = [margin_left+space_col*2+width_raster*2,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_holding1.YTick = [1,ntrial_raster];
ax_raster_holding1.YLim = [0.5,ntrial_raster+0.5];
ax_raster_holding1.XAxis.Visible = 'off';
ax_raster_holding1.YAxis.Visible = 'off';
xlim(ax_raster_holding1,[t_pre,t_post]);

ax_raster_holding2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_holding2.Position = [margin_left+space_col*2+width_raster*2,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_holding2.YTick = [1,ntrial_raster];
ax_raster_holding2.YLim = [0.5,ntrial_raster+0.5];
ax_raster_holding2.XAxis.Visible = 'off';
ax_raster_holding2.YAxis.Visible = 'off';
xlim(ax_raster_holding2,[t_pre,t_post]);

ax_raster_release1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_release1.Position = [margin_left+space_col*3+width_raster*3,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_release1.YTick = [1,ntrial_raster];
ax_raster_release1.YLim = [0.5,ntrial_raster+0.5];
ax_raster_release1.XAxis.Visible = 'off';
ax_raster_release1.YAxis.Visible = 'off';
xlim(ax_raster_release1,[t_pre,t_post]);

ax_raster_release2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_release2.Position = [margin_left+space_col*3+width_raster*3,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_release2.YTick = [1,ntrial_raster];
ax_raster_release2.YLim = [0.5,ntrial_raster+0.5];
ax_raster_release2.XAxis.Visible = 'off';
ax_raster_release2.YAxis.Visible = 'off';
xlim(ax_raster_release2,[t_pre,t_post]);

ax_PETH_lift = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_lift.Position = [margin_left,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_lift, 'Time from Lift (ms)')
ylabel(ax_PETH_lift, 'Firing Rate (Hz)');

ax_PETH_press = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_press.Position = [margin_left+space_col*1+width_raster*1,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_press, 'Time from Press (ms)')

ax_PETH_holding = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_holding.Position = [margin_left+space_col*2+width_raster*2,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_holding, 'Time from Press (ms)')

ax_PETH_release = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_release.Position = [margin_left+space_col*3+width_raster*3,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_release, 'Time from Release (ms)')
%% Plotting

% lift
load(data_path_lift{1})
unit_num = data_path_lift{2};
FPs = [r.VideoInfos_side.Foreperiod];
correct_index = strcmp({r.VideoInfos_side.Performance},'Correct');
t_lift = [r.VideoInfos_side.LiftStartTime];
t_lift_long_idx = find(FPs == 1500 & ~isnan(t_lift) & correct_index);
t_lift_long = t_lift(t_lift_long_idx);
t_lift_short_idx = find(FPs == 750 & ~isnan(t_lift) & correct_index);
t_lift_short = t_lift(t_lift_short_idx);

rnd = randperm(length(t_lift_long),ntrial_raster);
ind_this = t_lift_long_idx(rnd);
t_press_this = [r.VideoInfos_side(ind_this).Time]-[r.VideoInfos_side(ind_this).LiftStartTime];
[~,sort_idx] = sort(t_press_this);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_lift_long(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_lift_long(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_lift_long(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_lift1,xx,yy,'-','Color',colors_name{1});  
    end
    ind_this = t_lift_long_idx(rnd(k));
    t_press_this = r.VideoInfos_side(ind_this).Time-r.VideoInfos_side(ind_this).LiftStartTime;
    t_release_this = t_press_this + r.VideoInfos_side(ind_this).Foreperiod + r.VideoInfos_side(ind_this).ReactTime;
    plot(ax_raster_lift1,[t_press_this,t_press_this],[-0.5+k,0.5+k],'-','Color','k');
    plot(ax_raster_lift1,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color','c');
    plot(ax_raster_lift1,[t_press_this+1500,t_press_this+1500],[-0.5+k,0.5+k],'-','Color','m');
end

rnd = randperm(length(t_lift_short),ntrial_raster);
ind_this = t_lift_short_idx(rnd);
t_press_this = [r.VideoInfos_side(ind_this).Time]-[r.VideoInfos_side(ind_this).LiftStartTime];
[~,sort_idx] = sort(t_press_this);
rnd = rnd(sort_idx);
for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_lift_short(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_lift_short(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_lift_short(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_lift2,xx,yy,'-','Color',colors_name{2});  
    end
    ind_this = t_lift_short_idx(rnd(k));
    t_press_this = r.VideoInfos_side(ind_this).Time-r.VideoInfos_side(ind_this).LiftStartTime;
    t_release_this = t_press_this + r.VideoInfos_side(ind_this).Foreperiod + r.VideoInfos_side(ind_this).ReactTime;
    plot(ax_raster_lift2,[t_press_this,t_press_this],[-0.5+k,0.5+k],'-','Color','k');
    plot(ax_raster_lift2,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color','c');
    plot(ax_raster_lift2,[t_press_this+750,t_press_this+750],[-0.5+k,0.5+k],'-','Color','m');
end
params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_lift_long', params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_lift_short', params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PETH_lift,tpsth1,psth1,'Color',colors_name{1},'LineWidth',linewidth_PSTH)
plot(ax_PETH_lift,tpsth2,psth2,'Color',colors_name{2},'LineWidth',linewidth_PSTH)

% press
load(data_path_press{1})
unit_num = data_path_press{2};

FPs = [r.VideoInfos_side.Foreperiod];
correct_index = strcmp({r.VideoInfos_side.Performance},'Correct');
t_press = [r.VideoInfos_side.Time];
t_lift = [r.VideoInfos_side.LiftStartTime];
t_press_long_idx = find(FPs == 1500 & ~isnan(t_lift) & correct_index);
t_press_long = t_press(t_press_long_idx);
t_press_short_idx = find(FPs == 750 & ~isnan(t_lift) & correct_index);
t_press_short = t_press(t_press_short_idx);

rnd = randperm(length(t_press_long),ntrial_raster);
ind_this = t_press_long_idx(rnd);
t_press_this = [r.VideoInfos_side(ind_this).Time]-[r.VideoInfos_side(ind_this).LiftStartTime];
[~,sort_idx] = sort(t_press_this);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_press_long(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_press_long(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_press_long(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_press1,xx,yy,'-','Color',colors_name{1});  
    end
    ind_this = t_lift_long_idx(rnd(k));
    t_lift_this = -r.VideoInfos_side(ind_this).Time+r.VideoInfos_side(ind_this).LiftStartTime;
    t_release_this = r.VideoInfos_side(ind_this).Foreperiod+r.VideoInfos_side(ind_this).ReactTime;
    plot(ax_raster_press1,[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','g');
    plot(ax_raster_press1,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color','c');
    plot(ax_raster_press1,[1500,1500],[-0.5+k,0.5+k],'-','Color','m');
end

rnd = randperm(length(t_press_short),ntrial_raster);
ind_this = t_press_short_idx(rnd);
t_press_this = [r.VideoInfos_side(ind_this).Time]-[r.VideoInfos_side(ind_this).LiftStartTime];
[~,sort_idx] = sort(t_press_this);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_press_short(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_press_short(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_press_short(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_press2,xx,yy,'-','Color',colors_name{2});  
    end
    ind_this = t_lift_short_idx(rnd(k));
    t_lift_this =  -r.VideoInfos_side(ind_this).Time+r.VideoInfos_side(ind_this).LiftStartTime;
    t_release_this = r.VideoInfos_side(ind_this).Foreperiod+r.VideoInfos_side(ind_this).ReactTime;
    plot(ax_raster_press2,[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','g');
    plot(ax_raster_press2,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color','c');
    plot(ax_raster_press2,[750,750],[-0.5+k,0.5+k],'-','Color','m');
end
params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_press_long', params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_press_short', params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PETH_press,tpsth1,psth1,'Color',colors_name{1},'LineWidth',linewidth_PSTH)
plot(ax_PETH_press,tpsth2,psth2,'Color',colors_name{2},'LineWidth',linewidth_PSTH)

% holding
load(data_path_holding{1})
unit_num = data_path_holding{2};

FPs = [r.VideoInfos_side.Foreperiod];
correct_index = strcmp({r.VideoInfos_side.Performance},'Correct');
t_press = [r.VideoInfos_side.Time];
t_lift = [r.VideoInfos_side.LiftStartTime];
t_press_long_idx = find(FPs == 1500 & ~isnan(t_lift) & correct_index);
t_press_long = t_press(t_press_long_idx);
t_press_short_idx = find(FPs == 750 & ~isnan(t_lift) & correct_index);
t_press_short = t_press(t_press_short_idx);

rnd = randperm(length(t_press_long),ntrial_raster);
ind_this = t_press_long_idx(rnd);
t_react_time = [r.VideoInfos_side(ind_this).ReactTime];
[~,sort_idx] = sort(t_react_time);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_press_long(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_press_long(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_press_long(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_holding1,xx,yy,'-','Color',colors_name{1});  
    end
    ind_this = t_lift_long_idx(rnd(k));
    t_lift_this = -r.VideoInfos_side(ind_this).Time+r.VideoInfos_side(ind_this).LiftStartTime;
    t_release_this = r.VideoInfos_side(ind_this).Foreperiod+r.VideoInfos_side(ind_this).ReactTime;
    plot(ax_raster_holding1,[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','g');
    plot(ax_raster_holding1,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color','c');
    plot(ax_raster_holding1,[1500,1500],[-0.5+k,0.5+k],'-','Color','m');
end

rnd = randperm(length(t_press_short),ntrial_raster);
ind_this = t_press_short_idx(rnd);
t_react_time = [r.VideoInfos_side(ind_this).ReactTime];
[~,sort_idx] = sort(t_react_time);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_press_short(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_press_short(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_press_short(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_holding2,xx,yy,'-','Color',colors_name{2});  
    end
    ind_this = t_lift_short_idx(rnd(k));
    t_lift_this =  -r.VideoInfos_side(ind_this).Time+r.VideoInfos_side(ind_this).LiftStartTime;
    t_release_this = r.VideoInfos_side(ind_this).Foreperiod+r.VideoInfos_side(ind_this).ReactTime;
    plot(ax_raster_holding2,[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','g');
    plot(ax_raster_holding2,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color','c');
    plot(ax_raster_holding2,[750,750],[-0.5+k,0.5+k],'-','Color','m');
end
params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_press_long', params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_press_short', params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PETH_holding,tpsth1,psth1,'Color',colors_name{1},'LineWidth',linewidth_PSTH)
plot(ax_PETH_holding,tpsth2,psth2,'Color',colors_name{2},'LineWidth',linewidth_PSTH)

% release
load(data_path_release{1})
unit_num = data_path_release{2};
plot_raster_PETH(r,unit_num,ax_raster_release1,ax_raster_release2,ax_PETH_release,t_pre,t_post,'release',linewidth_PSTH,ntrial_raster,binwidth_PSTH)

% annotation
h_annotation1 = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'FP = 1500ms'},...
    'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'FitBoxToText','off');
set(h_annotation1,'Position',[7,11.45,3,0.5]);

h_annotation2 = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'FP = 750ms'},...
    'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'FitBoxToText','off');
set(h_annotation2,'Position',[7,7.75,3,0.5]);

h_annotation3 = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'PETH'},...
    'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'FitBoxToText','off');
set(h_annotation3,'Position',[7,4.05,3,0.5]);
%% Save Figure
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])

%%
function plot_raster_PETH(r,unit_num,ax_raster1,ax_raster2,ax_PETH,t_pre,t_post,event,linewidth_PSTH,ntrial_raster,binwidth_PSTH)
FPs = r.Behavior.Foreperiods;
correct_index = r.Behavior.CorrectIndex;

ind_press = find(strcmp(r.Behavior.Labels, 'LeverPress'));
ind_release = find(strcmp(r.Behavior.Labels, 'LeverRelease'));

t_press = r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_press);
t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_release);
t_release_long_idx = intersect(find(FPs == 1500),correct_index);
t_release_long = t_release(t_release_long_idx);
t_release_short_idx = intersect(find(FPs == 750),correct_index);
t_release_short = t_release(t_release_short_idx);
t_press_long = t_press(t_release_long_idx);
t_press_short = t_press(t_release_short_idx);
FPs_long = FPs(t_release_long_idx);
FPs_short = FPs(t_release_short_idx);

rnd = randperm(length(t_release_long),ntrial_raster);
t_rt = t_release_long(rnd) - FPs_long(rnd) - t_press_long(rnd);
[~,sort_idx] = sort(t_rt);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_release_long(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_release_long(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_release_long(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster1,xx,yy,'-','Color','r');  
    end
    t_press_this = t_press_long(rnd(k))-t_release_long(rnd(k));
    plot(ax_raster1,[t_press_this,t_press_this],[-0.5+k,0.5+k],'-','Color','green');
    plot(ax_raster1,[t_press_this+1500,t_press_this+1500],[-0.5+k,0.5+k],'-','Color','m');
end

rnd = randperm(length(t_release_short),ntrial_raster);
t_rt = t_release_short(rnd) - FPs_short(rnd) - t_press_short(rnd);
[~,sort_idx] = sort(t_rt);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_release_short(rnd(k))+t_pre<=r.Units.SpikeTimes(unit_num).timings & t_release_short(rnd(k))+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_release_short(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster2,xx,yy,'-','Color','b');  
    end
    t_press_this = t_press_short(rnd(k))-t_release_short(rnd(k));
    plot(ax_raster2,[t_press_this,t_press_this],[-0.5+k,0.5+k],'-','Color','green');
    plot(ax_raster2,[t_press_this+750,t_press_this+750],[-0.5+k,0.5+k],'-','Color','m');
end
params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_release_long, params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_release_short, params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PETH,tpsth1,psth1,'Color','r','LineWidth',linewidth_PSTH)
plot(ax_PETH,tpsth2,psth2,'Color','b','LineWidth',linewidth_PSTH)
end