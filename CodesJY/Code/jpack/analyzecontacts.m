function analyzecontacts(T, type, cind)
% 9.24.2013
% modified the code so now it works on manually analyzing touch

contacts=[];
ntrials=T.trialNums;
% first deal with hit trials



% ind is everything that will be plotted.
cind=1;
u.T=T;
u.ind=ind;
u.cind=cind;
updatefigure(u);



function updatefigure(u)
% given the trialnum, please plot a few whisker traces, together with Vm
% trace, pole profile, licks etc in order to determine the contact time. 
T=u.T;
ctrial=T.trials{u.ind(u.cind)};
hf=figure(125); clf(hf)
set(hf, 'Position',[62 40 800 900]*1, 'name', [T.mouseName '/' T.sessionName '/' T.cellNum T.cellCode]);
set(hf, 'userdata', u);

ht = uitoolbar(hf);

hei=900;
colorind={'r', 'g', 'b'}; % three whiskers, labeled in the same color codes as the whisker gui

% first plot, just behavior
ha1=axes; 
set(ha1, 'units', 'pixels','position', [90 hei-100 500 50]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-10 2], 'fontsize', 8);

if ~isa(ctrial.behavTrial, 'Solo.BehavSilenceTrial')
    if ~isempty(ctrial.whiskerTrial)
        title(['<Behav trial #' num2str(ctrial.trialNum),'>', '<Whisker trial #', num2str(ctrial.whiskerTrial.trialNum), '>', ' ', ctrial.trialOutcome])
    end;
else
    if ~isempty(ctrial.whiskerTrial)
        title(['<' strrep(ctrial.behavTrial. trialTypeorg, '_', '-') '>' '<Behav trial #' num2str(ctrial.trialNum),'>', '<Whisker trial #', num2str(ctrial.whiskerTrial.trialNum), '>', ' ', ctrial.trialOutcome])
    end;
end;

cb=ctrial.behavTrial;

line([cb.pinDescentOnsetTime cb.pinDescentOnsetTime+0.3]*1000, [0 -5], 'linewidth', 2, 'color', [.7 .7 .7]);
line([cb.pinDescentOnsetTime+0.3 cb.pinAscentOnsetTime]*1000, [-5 -5], 'linewidth', 2, 'color', [0 0 0]);
line([cb.pinAscentOnsetTime cb.pinAscentOnsetTime+0.3]*1000, [-5 0], 'linewidth', 2, 'color', [.7 .7 .7]);

% plot licktime
if ~isempty(cb.beamBreakTimes)
    plot(cb.beamBreakTimes*1000, -7*ones(size(cb.beamBreakTimes)), 'm.', 'markersize', 6)
end;
% plot reward time
if ~isempty(cb.rewardTime)
    plot(cb.rewardTime*1000, -7, 'mo');
end;
% plot answerPeriods
if ~isempty(cb.answerPeriodTime)
    plot(cb.answerPeriodTime*1000, [-6 -6], 'k', 'linewidth', 1.5);
end;

% second to fifth plot, distance to pole, all three whiskers will be plotted
ha2=axes; % distance to pole
set(ha2, 'units', 'pixels','position', [90 hei-250 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-1 2], 'fontsize', 8);
ylabel('distance')
ha3=axes; % theta at base
set(ha3, 'units', 'pixels','position', [90 hei-400 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-90 90], 'fontsize', 8);
ylabel('theta-base')
ha4=axes; % theta at contact
set(ha4, 'units', 'pixels','position', [90 hei-550 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-90 90], 'fontsize', 8);
ylabel('theta-contact')
ha5=axes; % kappa
set(ha5, 'units', 'pixels','position', [90 hei-700 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-.2 .4], 'fontsize', 8);
ylabel('kappa')

toff=T.whiskerTrialTimeOffset*1000;
cw=ctrial.whiskerTrial;

if ~isempty(cw)
    tid=cw.trajectoryIDs;
    for i=1:length(tid)
        ctid=tid(i);
        time{i}=cw.get_time(ctid); time{i}=time{i}*1000+toff;
        distance{i}=cw.get_distanceToPoleCenter(ctid);
        thetaAtBase{i}=cw.get_thetaAtBase(ctid);
        thetaAtContact{i}=cw.get_thetaAtContact(ctid);
        kappa{i}=cw.get_curvature(ctid);
        
        plot(ha2, time{i}, distance{i}, 'color', colorind{i}, 'marker','.', 'markersize', 6);
        plot(ha2, time{i}, distance{i}, 'color', 'k', 'linewidth', .25);
        plot(ha3, time{i}, thetaAtBase{i}, 'color', colorind{i});
        plot(ha4, time{i}, thetaAtContact{i}, 'color', colorind{i});
        plot(ha5, time{i}, kappa{i}, 'color', colorind{i});
    end;
end;

ha6=axes; % Vm
set(ha6, 'units', 'pixels','position', [90 hei-850 500 100]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-60 -30], 'fontsize', 8);
ylabel('mV')
cphy=ctrial.spikesTrial;
vm=cphy.rawSignal;
tvm=[1:length(vm)]/10; % in ms
% vm=removelicks(vm, 10000, 1, 4, -30);
plot(ha6, tvm, vm, 'k');
set(ha6, 'ylim', [min(vm(1:50000))-2 max(vm(1:50000))+2])
linkaxes([ha1 ha2 ha3 ha4 ha5 ha6],'x');

ha(1)=ha1;
ha(2)=ha2;
ha(3)=ha3;
ha(4)=ha4;
ha(5)=ha5;
ha(6)=ha6;

u.ha=ha;

set(hf, 'userdata', u);

icon_right = imread('arrow-right.png');
icon_left  = imread('arrow-left.png');

bbutton = uipushtool(ht,'CData', icon_left, 'TooltipString','Back');
fbutton = uipushtool(ht,'CData',icon_right,'TooltipString','Forward','Separator','on');

set(fbutton,'ClickedCallback',@movenext)
set(bbutton,'ClickedCallback',@movelast)

a = rand(20,20,3);
rsbutton = uipushtool(ht,'CData', a ,'TooltipString','resize','Separator','on');
set(rsbutton, 'ClickedCallback', @figuresize);

b=rand(12, 12, 3);
replotbutton = uipushtool(ht,'CData', b ,'TooltipString','Vm vs Angle','Separator','on');
set(replotbutton, 'ClickedCallback', @replotdata)
    
c=rand(12, 12, 3);
replotbutton = uipushtool(ht,'CData', c ,'TooltipString','Vm vs Amp','Separator','on');
set(replotbutton, 'ClickedCallback', @replotdata2)

d=rand(12, 12, 3);
replotbutton = uipushtool(ht,'CData', c ,'TooltipString','Vm vs kappa','Separator','on');
set(replotbutton, 'ClickedCallback', @replotdata3)


function movenext(hobj, eventdata) 

u=get(gcbf, 'userdata');
if u.cind+1<length(u.ind)
    u.cind=u.cind+1;
else
    display('The End')
    return
end;
updatefigure(u)

function movelast(hobj, eventdata)
u=get(gcbf, 'userdata');
if u.cind-1>0
    u.cind=u.cind-1;
else
    display ('This is the first one!')
    return
end;
updatefigure(u)

function figuresize(hobj, eventdata)

u=get(gcbf, 'userdata');
ha=u.ha;
hei=get(gcbf, 'position'); hei=hei(4);

set(ha(1), 'units', 'pixels','position', [90 hei-100 500 50]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-10 2], 'fontsize', 8);
set(ha(2), 'units', 'pixels','position', [90 hei-250 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-1 2], 'fontsize', 8);
set(ha(3), 'units', 'pixels','position', [90 hei-400 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-60 60], 'fontsize', 8);
set(ha(4), 'units', 'pixels','position', [90 hei-550 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-60 60], 'fontsize', 8);
set(ha(5), 'units', 'pixels','position', [90 hei-700 500 120]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [-.2 .4], 'fontsize', 8);

vm=get(get(ha(6), 'children'), 'ydata');
set(ha(6), 'units', 'pixels','position', [90 hei-850 500 100]*1, 'nextplot', 'add', 'xlim', [0 5000], 'ylim', [min(vm(1:50000))-2 max(vm(1:50000))+2], 'fontsize', 8);

function replotdata(hobj, eventdata)

u=get(gcbf, 'userdata');
ha=u.ha;

whisk_angle=[];
hawhisk=get(ha(3), 'children');

for i=1:length(hawhisk)
    whisk_angle{i}=get(hawhisk(i), 'ydata');
    t_whisk{i}=get(hawhisk(i), 'xdata');
end;

vm=get(get(ha(6), 'children'), 'ydata');
tvm=get(get(ha(6), 'children'), 'xdata');

figure(100); clf(100)
set(gcf, 'position', [162 100 700 600], 'color', [1  1 1], 'paperpositionmode', 'auto');

if isempty(get(gcf, 'userdata'))
    wid=0;
    set(gcf, 'userdata', wid);
else
    wid=get(gcf, 'userdata')
    wid=rem(wid+1, 3);
    set(gcf, 'userdata', wid);
end;

wid=wid+1;

whisk_c={'b', 'g', 'r'};
 widcolor=whisk_c{wid};
[ha1, h1, h2]=plotyy(tvm, vm, t_whisk{wid}, whisk_angle{wid});

set(h1, 'color', 'k');
set(h2, 'color', widcolor);

set(ha1(1), 'xlim', [min(tvm) max(tvm)],'YLim', [min(vm)-2 max(vm)+2], 'ytick', [-100:10:100], 'position', [0.1 0.4 0.8 0.58], 'xgrid', 'on', 'color', 'none', 'ycolor', 'k');
axes(ha1(1)); box off; ylabel('Vm')
set(ha1(2), 'xlim', [min(tvm) max(tvm)], 'position', [0.1 0.4 0.8 0.44], 'xgrid', 'on', 'ycolor', widcolor, 'nextplot', 'add');
axes(ha1(2)); box off; ylabel('Whisker angle (deg)')

poleonset=u.T.trials{u.cind}.behavTrial.pinDescentOnsetTime;
poleoffset=u.T.trials{u.cind}.behavTrial.pinAscentOnsetTime;

ylim=get(ha1(2), 'ylim');
axes(ha1(2))
plot(poleonset*1000, ylim(2)-10, 'r*', 'markersize', 10);
plot(poleoffset*1000, ylim(2)-10, 'r^', 'markersize', 10);
aom=u.T.trials{u.cind}.spikesTrial.AOM/2;
taom=[0:length(aom)-1]/10;

plot(taom, aom+ylim(1)+2, 'b');
set(gcf, 'children', [ha1(1) ha1(2)])

ha2=axes;
set(ha2, 'nextplot', 'add', 'xlim', [min(tvm), max(tvm)],  'position', [0.1 0.1 0.8 0.25], 'xgrid', 'on');

for i=1:length(whisk_angle)
    plot(t_whisk{i}, whisk_angle{i}, 'color', whisk_c{i});
end;
 
xlabel('ms')
ylabel('Angle')

linkaxes([ha1, ha2], 'x')

% get AOM signal and plot it

% check whisking frequency
whiskfreq(t_whisk{wid}, whisk_angle{wid})
vmfreq(tvm,vm)
spktime=u.T.trials{u.cind}.spikesTrial.spikeTimes/10000;
% check the coherence
[whisk, t_whisk]=u.T.get_whisker_position(wid, u.T.trialNums(u.cind));
[fvw, Cvw, fpw, Cpw]=cohneuralwhisk(tvm, vm, spktime,t_whisk, whisk)
figure(23); clf;
plot(fvw, Cvw, 'b');hold on; plot(fpw, Cpw, 'r'); xlabel('Hz'); ylabel('Coherence'); legend('Vm-whisk', 'Spk-whisk')

function replotdata2(hobj, eventdata)

u=get(gcbf, 'userdata');
ha=u.ha;

whisk_angle=[];
hawhisk=get(ha(3), 'children');

for i=1:length(hawhisk)
    whisk_angle{i}=get(hawhisk(i), 'ydata');
   [hh amplitude  filteredSignal setpoint amplitudeS amplitudeDS setpointS setpointDS phaseDS] =  LeoWhiskerDecomposition_2(whisk_angle{i});
   [b, a]=butter(4, 5*2/1000, 'low');
  % amplitude=filtfilt(b, a, amplitude);
   whisk_amp{i}=amplitude;
    t_whisk{i}=get(hawhisk(i), 'xdata');
end;


vm=get(get(ha(6), 'children'), 'ydata');
tvm=get(get(ha(6), 'children'), 'xdata');

figure(150); clf(150)
set(gcf, 'position', [786 381 801 584], 'color', [1  1 1]);

if isempty(get(gcf, 'userdata'))
    wid=0;
    set(gcf, 'userdata', wid);
else
    wid=get(gcf, 'userdata')
    wid=rem(wid+1, 3);
    set(gcf, 'userdata', wid);
end;

wid=wid+1;
whisk_c={'b', 'g', 'r'};
widcolor=whisk_c{wid};
[ha1, h1, h2]=plotyy(tvm, vm, t_whisk{wid}, whisk_amp{wid});

set(h1, 'color', 'k');
set(h2, 'color', widcolor);

set(ha1(1), 'xlim', [min(tvm) max(tvm)],'YLim', [min(vm)-2 max(vm)+2], 'ytick', [-100:10:100], 'position', [0.1 0.4 0.8 0.58], 'xgrid', 'on', 'color', 'none', 'ycolor', 'b');
axes(ha1(1)); box off; ylabel('Vm')
set(ha1(2), 'xlim', [min(tvm) max(tvm)], 'position', [0.1 0.4 0.8 0.44], 'xgrid', 'on', 'ycolor', widcolor);
axes(ha1(2)); box off

set(gcf, 'children', [ha1(1) ha1(2)])

ha2=axes;
set(ha2, 'nextplot', 'add', 'xlim', [min(tvm), max(tvm)],  'position', [0.1 0.1 0.8 0.25], 'xgrid', 'on');

for i=1:length(whisk_angle)
    plot(t_whisk{i}, whisk_amp{i}, 'color', whisk_c{i});
end;

    
xlabel('ms')
ylabel('Amplitude')

linkaxes([ha1, ha2], 'x')


function replotdata3(hobj, eventdata)

u=get(gcbf, 'userdata');
ha=u.ha;

whisk_kappa=[];
hawhisk=get(ha(5), 'children');

for i=1:length(hawhisk)
    whisk_kappa{i}=get(hawhisk(i), 'ydata');

    t_whisk{i}=get(hawhisk(i), 'xdata');
end;


vm=get(get(ha(6), 'children'), 'ydata');
tvm=get(get(ha(6), 'children'), 'xdata');

figure(200); clf(200)
set(gcf, 'position', [786 381 801 584], 'color', [1  1 1]);

if isempty(get(gcf, 'userdata'))
    wid=0;
    set(gcf, 'userdata', wid);
else
    wid=get(gcf, 'userdata')
    wid=rem(wid+1, 3);
    set(gcf, 'userdata', wid);
end;

wid=wid+1;

whisk_c={'b', 'g', 'r'};
 widcolor=whisk_c{wid};
[ha1, h1, h2]=plotyy(tvm, vm, t_whisk{wid}, whisk_kappa{wid});

set(h1, 'color', 'k');
set(h2, 'color', widcolor);

set(ha1(1), 'xlim', [min(tvm) max(tvm)],'YLim', [min(vm)-2 max(vm)+2], 'ytick', [-100:10:100], 'position', [0.1 0.4 0.8 0.58], 'xgrid', 'on', 'color', 'none', 'ycolor', 'b');
axes(ha1(1)); box off; ylabel('Vm')
set(ha1(2), 'xlim', [min(tvm) max(tvm)], 'position', [0.1 0.4 0.8 0.44], 'xgrid', 'on', 'ycolor', widcolor);
axes(ha1(2)); box off

set(gcf, 'children', [ha1(1) ha1(2)])

ha2=axes;
set(ha2, 'nextplot', 'add', 'xlim', [min(tvm), max(tvm)],  'position', [0.1 0.1 0.8 0.25], 'xgrid', 'on');

for i=1:length(whisk_kappa)
    plot(t_whisk{i}, whisk_kappa{i}, 'color', whisk_c{i});
end;
    
xlabel('ms')
ylabel('kappa')

linkaxes([ha1, ha2], 'x')
    
xlabel('ms')
ylabel('kappa')

linkaxes([ha1, ha2], 'x')

