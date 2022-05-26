clear
save_filename_pdf = './ExamplePETH_trigger_v2.pdf';
save_filename_png = './ExamplePETH_trigger_v2.png';
save_resolution = 1200;
global colors_name color_press color_release color_trigger linewidth_event linewidth_PSTH t_pre t_post binwidth_PSTH ntrial_raster_correct ntrial_raster_late

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
data_path_trigger1 = {'D:\Ephys\ANMs\Russo\Sessions\20210907\RTarrayAll.mat', 13};
data_path_trigger2 = {'D:\Ephys\ANMs\Davis\Sessions\20220331\RTarrayAll.mat',1};
data_path_trigger3 = {'D:\Ephys\ANMs\Davis\Sessions\20220322\RTarrayAll.mat', 1};
data_path_trigger4 = {'D:\Ephys\ANMs\Davis\Sessions\20220426\RTarrayAll.mat', 5};
data_path_trigger5 = {'D:\Ephys\ANMs\Davis\Sessions\20220505\RTarrayAll.mat', 3};
data_path_trigger6 = {'D:\Ephys\ANMs\Chen\Sessions\20220507\RTarrayAll.mat', 1};
ntrial_raster_correct = 40;
ntrial_raster_late = 5;

t_pre = -500;
t_post = 2000;
binwidth_PSTH = 20;

colors = colororder;
colors_name = {'red','blue'};
linewidth_PSTH  = 1;
linewidth_event = 1;

color_lift = colors(3,:);
color_press = colors(4,:);
color_trigger = colors(5,:);
color_release = colors(6,:);

rand('seed',123);
%% Figure Configuration
margin_left = 1;
margin_right = 0.5+2;
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

ax_raster_trigger1_1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger1_1.Position = [margin_left,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_trigger1_1.YTick = [1,ntrial_raster_correct];
ax_raster_trigger1_1.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger1_1.XAxis.Visible = 'off';
xlim(ax_raster_trigger1_1,[t_pre,t_post])
ylabel(ax_raster_trigger1_1,'Trials');
title(ax_raster_trigger1_1,'A','FontSize',10)

ax_raster_trigger1_2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger1_2.Position = [margin_left,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_trigger1_2.YTick = [1,ntrial_raster_correct];
ax_raster_trigger1_2.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger1_2.XAxis.Visible = 'off';
xlim(ax_raster_trigger1_2,[t_pre,t_post])
ylabel(ax_raster_trigger1_2,'Trials');

ax_raster_trigger2_1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger2_1.Position = [margin_left+space_col+width_raster,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_trigger2_1.YTick = [1,ntrial_raster_correct];
ax_raster_trigger2_1.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger2_1.XAxis.Visible = 'off';
ax_raster_trigger2_1.YAxis.Visible = 'off';
xlim(ax_raster_trigger2_1,[t_pre,t_post])
title(ax_raster_trigger2_1,'B','FontSize',10)

ax_raster_trigger2_2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger2_2.Position = [margin_left+space_col+width_raster,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_trigger2_2.YTick = [1,ntrial_raster_correct];
ax_raster_trigger2_2.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger2_2.XAxis.Visible = 'off';
ax_raster_trigger2_2.YAxis.Visible = 'off';
xlim(ax_raster_trigger2_2,[t_pre,t_post])

ax_raster_trigger3_1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger3_1.Position = [margin_left+space_col*2+width_raster*2,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_trigger3_1.YTick = [1,ntrial_raster_correct];
ax_raster_trigger3_1.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger3_1.XAxis.Visible = 'off';
ax_raster_trigger3_1.YAxis.Visible = 'off';
xlim(ax_raster_trigger3_1,[t_pre,t_post]);
title(ax_raster_trigger3_1,'C','FontSize',10)

ax_raster_trigger3_2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger3_2.Position = [margin_left+space_col*2+width_raster*2,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_trigger3_2.YTick = [1,ntrial_raster_correct];
ax_raster_trigger3_2.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger3_2.XAxis.Visible = 'off';
ax_raster_trigger3_2.YAxis.Visible = 'off';
xlim(ax_raster_trigger3_2,[t_pre,t_post]);

ax_raster_trigger4_1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger4_1.Position = [margin_left+space_col*3+width_raster*3,margin_bottom+space_row*2+height_raster+height_PSTH,width_raster,height_raster];
ax_raster_trigger4_1.YTick = [1,ntrial_raster_correct];
ax_raster_trigger4_1.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger4_1.XAxis.Visible = 'off';
ax_raster_trigger4_1.YAxis.Visible = 'off';
xlim(ax_raster_trigger4_1,[t_pre,t_post]);
title(ax_raster_trigger4_1,'D','FontSize',10)

ax_raster_trigger4_2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster_trigger4_2.Position = [margin_left+space_col*3+width_raster*3,margin_bottom+space_row+height_PSTH,width_raster,height_raster];
ax_raster_trigger4_2.YTick = [1,ntrial_raster_correct];
ax_raster_trigger4_2.YLim = [0.5,ntrial_raster_correct+0.5];
ax_raster_trigger4_2.XAxis.Visible = 'off';
ax_raster_trigger4_2.YAxis.Visible = 'off';
xlim(ax_raster_trigger4_2,[t_pre,t_post]);

ax_PETH_trigger1 = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_trigger1.Position = [margin_left,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_trigger1, 'Time from trigger (ms)')
ylabel(ax_PETH_trigger1, 'Firing rate (Hz)');
xlim(ax_PETH_trigger1,[t_pre,t_post]);

ax_PETH_trigger2 = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_trigger2.Position = [margin_left+space_col*1+width_raster*1,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_trigger2, 'Time from trigger (ms)')
xlim(ax_PETH_trigger2,[t_pre,t_post]);

ax_PETH_trigger3 = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_trigger3.Position = [margin_left+space_col*2+width_raster*2,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_trigger3, 'Time from trigger (ms)')
xlim(ax_PETH_trigger3,[t_pre,t_post]);

ax_PETH_trigger4 = axes(h,'Units','centimeters','NextPlot','add');
ax_PETH_trigger4.Position = [margin_left+space_col*3+width_raster*3,margin_bottom,width_PSTH,height_PSTH];
xlabel(ax_PETH_trigger4, 'Time from trigger (ms)')
xlim(ax_PETH_trigger4,[t_pre,t_post]);
%% Plotting
%% trigger1
make_plot(data_path_trigger2,ax_raster_trigger1_1,ax_raster_trigger1_2,ax_PETH_trigger1);
make_plot(data_path_trigger3,ax_raster_trigger2_1,ax_raster_trigger2_2,ax_PETH_trigger2);
make_plot(data_path_trigger4,ax_raster_trigger3_1,ax_raster_trigger3_2,ax_PETH_trigger3);
make_plot(data_path_trigger5,ax_raster_trigger4_1,ax_raster_trigger4_2,ax_PETH_trigger4);


% annotation
h_annotation1 = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'FP = 1500 ms'},...
    'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'FitBoxToText','off');
set(h_annotation1,'Position',[7,11.45,3,0.5]);

h_annotation2 = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'FP = 750 ms'},...
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
%%
space_annotation = 0.6;

h_annotation_press = annotation(h,'line',[0.5,0.5],[0.5,0.5],'units','centimeters','linewidth',3,'Color',color_press);
set(h_annotation_press,'X',[16.5,17],'Y',[11-space_annotation*0,11-space_annotation*0]);

h_annotation_trigger = annotation(h,'line',[0.5,0.5],[0.5,0.5],'units','centimeters','linewidth',3,'Color',color_trigger);
set(h_annotation_trigger,'X',[16.5,17],'Y',[11-space_annotation*1,11-space_annotation*1]);

h_annotation_release = annotation(h,'line',[0.5,0.5],[0.5,0.5],'units','centimeters','linewidth',3,'Color',color_release);
set(h_annotation_release,'X',[16.5,17],'Y',[11-space_annotation*2,11-space_annotation*2]);


h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'Press'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[17,10.5-space_annotation*0,1,1]);

h_annotation_trigger_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'Trigger'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_trigger_text,'Position',[17,10.5-space_annotation*1,1,1]);

h_annotation_release_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'Release'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_release_text,'Position',[17,10.5-space_annotation*2,1,1]);
%% Save Figure
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])

%%
function make_plot(data_path_trigger,ax_raster_trigger1_1,ax_raster_trigger1_2,ax_PETH_trigger1)
global colors_name color_press color_release color_trigger linewidth_event linewidth_PSTH t_pre t_post binwidth_PSTH ntrial_raster_correct ntrial_raster_late
load(data_path_trigger{1})
unit_num = data_path_trigger{2};
FPs = r.Behavior.Foreperiods;
correct_index = r.Behavior.CorrectIndex;
late_index = r.Behavior.LateIndex;
FPs_correct = FPs(correct_index);
FPs_late = FPs(late_index);

ind_press = find(strcmp(r.Behavior.Labels, 'LeverPress'));
ind_release = find(strcmp(r.Behavior.Labels, 'LeverRelease'));

t_press = r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_press);
t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_release);

t_press_correct = t_press(correct_index);
t_release_correct = t_release(correct_index);
t_press_late = t_press(late_index);
t_release_late = t_release(late_index);
% t_release_long_idx = intersect(find(FPs == 1500),correct_index);
% t_release_long = t_release(t_release_long_idx);
% t_release_short_idx = intersect(find(FPs == 750),correct_index);
% t_release_short = t_release(t_release_short_idx);
% t_press_long = t_press(t_release_long_idx);
% t_press_short = t_press(t_release_short_idx);
% FPs_long = FPs(t_release_long_idx);
% FPs_short = FPs(t_release_short_idx);

rnd = randperm(length(correct_index),ntrial_raster_correct);
t_rt = t_release_correct(rnd) - FPs_correct(rnd) - t_press_correct(rnd);
[~,sort_idx] = sort(t_rt);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_press_correct(rnd(k))+t_pre+FPs_correct(rnd(k))<=r.Units.SpikeTimes(unit_num).timings & t_press_correct(rnd(k))+t_post+FPs_correct(rnd(k))>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_press_correct(rnd(k))-FPs_correct(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_trigger1_1,xx,yy,'-','Color',colors_name{1});  
    end
    t_release_this = t_release_correct(rnd(k)) - t_press_correct(rnd(k)) - FPs_correct(rnd(k));
%     plot(ax_raster_trigger1_1,[-1500,-1500],[-0.5+k,0.5+k],'-','Color',color_press,'LineWidth',linewidth_event);
    plot(ax_raster_trigger1_1,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color',color_release,'LineWidth',linewidth_event);
    plot(ax_raster_trigger1_1,[0,0],[-0.5+k,0.5+k],'-','Color',color_trigger,'LineWidth',linewidth_event);
end

length(late_index)
rnd = randperm(length(late_index),ntrial_raster_late);
t_rt = t_release_late(rnd) - FPs_late(rnd) - t_press_late(rnd);
[~,sort_idx] = sort(t_rt);
rnd = rnd(sort_idx);

for k = 1:length(rnd)
    spk_time = r.Units.SpikeTimes(unit_num).timings(t_press_late(rnd(k))+t_pre+FPs_late(rnd(k))<=r.Units.SpikeTimes(unit_num).timings & t_press_late(rnd(k))+t_post+FPs_late(rnd(k))>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - t_press_late(rnd(k))-FPs_late(rnd(k));
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster_trigger1_2,xx,yy,'-','Color',colors_name{2});  
    end
    t_release_this = t_release_late(rnd(k)) - t_press_late(rnd(k)) - FPs_late(rnd(k));
%     plot(ax_raster_trigger1_2,[-750,-750],[-0.5+k,0.5+k],'-','Color',color_press,'LineWidth',linewidth_event);
    plot(ax_raster_trigger1_2,[t_release_this,t_release_this],[-0.5+k,0.5+k],'-','Color',color_release,'LineWidth',linewidth_event);
    plot(ax_raster_trigger1_2,[0,0],[-0.5+k,0.5+k],'-','Color',color_trigger,'LineWidth',linewidth_event);
end

params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_press(correct_index)+FPs(correct_index), params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, t_press(late_index)+FPs(late_index), params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PETH_trigger1,tpsth1,psth1,'Color',colors_name{1},'LineWidth',linewidth_PSTH)
plot(ax_PETH_trigger1,tpsth2,psth2,'Color',colors_name{2},'LineWidth',linewidth_PSTH)
xline(ax_PETH_trigger1,0,'k--','LineWidth',linewidth_PSTH)
xline(ax_PETH_trigger1,-1500,'r--','LineWidth',linewidth_PSTH)
xline(ax_PETH_trigger1,-750,'b--','LineWidth',linewidth_PSTH)
end
