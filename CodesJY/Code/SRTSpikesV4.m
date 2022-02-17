function SRTSpikesV4(r, ind, varargin)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port. 

% SRTSpikes(r, 13, 'FRrange', [0 35])

% 8.9.2020
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

%  r.Behavior.Labels
%     {'TBD1'}    {'TBD2'}    {'LeverPress'}    {'Trigger'}
%     {'LeverRelease'}    {'GoodPress'}    {'GoodRelease'}
%     {'ValveOnset'}    {'ValveOffset'}    {'PokeOnset'}
%     {'PokeOffset'}
 
    
FRrange = [];
printname = [];
printsize = [2 2 20 16];
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'FRrange'
                FRrange = varargin{i+1};
            case 'Name'
                printname = varargin{i+1};
            case 'size'
                printsize = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
else
end

rb = r.Behavior;
% all FPs 
FPs = rb.Foreperiods;

% time of all presses
ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);
length(t_presses)
% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);
 
% index of non-premature releases
ind_np = setdiff([1:length(rb.Foreperiods)],[rb.DarkIndex; rb.PrematureIndex]);

% time of all triggers
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);

% index and time of correct presses
t_correctpresses = t_presses(rb.CorrectIndex);
FPs_correctpresses = rb.Foreperiods(rb.CorrectIndex);
% index and time of correct releases
t_correctreleases = t_releases(rb.CorrectIndex); 
% reaction time of correct responses
rt_correct = t_correctreleases - t_correctpresses - FPs_correctpresses;

% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = rb.EventTimings(rb.EventMarkers == ind_portin);

ind_portout = find(strcmp(rb.Labels, 'PokeOffset'));
t_portout = rb.EventTimings(rb.EventMarkers == ind_portout);

movetime = zeros(1, length(t_rewards));
for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correctreleases;
    dt = dt(dt>0);
    if ~isempty(dt)
        movetime(i) = dt(end);
    end;
end;
 
t_rewards = t_rewards(movetime>0);
movetime = movetime(movetime>0);
[movetime, indsort] = sort(movetime);
t_rewards = t_rewards(indsort); 

% time of premature presses
t_prematurepresses = t_presses(rb.PrematureIndex);
t_prematurereleases = t_releases(rb.PrematureIndex);
FPs_prematurepresses = rb.Foreperiods(rb.PrematureIndex);

% time of late presses
t_latepresses = t_presses(rb.LateIndex);
FPs_latepresses = rb.Foreperiods(rb.LateIndex);

figure; 

for i =1:length(t_presses)
    press_dur = [t_releases(i) t_presses(i)];
    line(press_dur, [1 1], 'color', 'k', 'linewidth', 2); hold on
    plot(press_dur, 1, 'color', 'k', 'marker','o', 'markersize', 4, 'linewidth',1)
end;
text(-1000, 1.1, 'Press', 'color', 'k')

hold on
plot(t_triggers, 1.2, 'g*')
text(-1000, 1.3, 'Trigger', 'color', 'g')

for i =1:length(t_prematurepresses)
    plot(t_prematurepresses(i), 1.5, 'ko', 'markerfacecolor', 'r')
    ifp = FPs_prematurepresses(i); % current foreperiods
    itpress = t_prematurepresses(i);
    line([itpress itpress+ifp], [1.5 1.5], 'color', 'r', 'linewidth', 2)
end;
text(-1000, 1.6, 'Premature', 'color', 'r')

for i =1:length(t_latepresses)
    plot(t_latepresses(i), 1.8, 'ko', 'markerfacecolor', 'm')
    ifp = FPs_latepresses(i); % current foreperiods
    itpress = t_latepresses(i);
    line([itpress itpress+ifp], [1.8 1.8], 'color', 'm', 'linewidth', 2)
end;
text(-1000, 1.9, 'Late', 'color', 'r')

for i =1:length(t_portin)
    port_access = [t_portin(i) t_portout(i)];
    line(port_access, [2.4 2.4], 'color', 'b', 'linewidth', 2)
    plot(port_access, 2.4, 'color', 'b', 'marker','o', 'markersize', 4, 'linewidth',1)
end;
text(-1000, 2.5, 'Poke', 'color', 'b')

plot(t_rewards, 2.0, 'co', 'linewidth', 1)
text(-1000,  2.1, 'Reward', 'color', 'c')

set(gca, 'ylim', [0.5 3.5], 'xlim', [-5000 max(get(gca, 'xlim'))])

% get correct response 0.75 sec, and 1.5 sec
t_correctsorted{1}      =   t_correctpresses(FPs_correctpresses == 750);
t_correctsorted{2}      =   t_correctpresses(FPs_correctpresses == 1500);

trelease_correctsorted{1}      =   t_correctreleases(FPs_correctpresses == 750);
trelease_correctsorted{2}      =   t_correctreleases(FPs_correctpresses == 1500);

rt_correctsorted{1}     =   rt_correct(FPs_correctpresses == 750);
[rt_correctsorted{1}, indsort] =  sort(rt_correctsorted{1});
t_correctsorted{1} = t_correctsorted{1}(indsort); 
trelease_correctsorted{1} = trelease_correctsorted{1}(indsort);

rt_correctsorted{2}     =   rt_correct(FPs_correctpresses == 1500);
[rt_correctsorted{2}, indsort] =  sort(rt_correctsorted{2});
t_correctsorted{2} = t_correctsorted{2}(indsort); 
trelease_correctsorted{2} = trelease_correctsorted{2}(indsort);

% derive PSTH from these
ku = ind;
params.pre = 2000;
params.post = 750+1000;
params.binwidth = 20;

if ku>length(r.Units.SpikeTimes)
    display('##########################################')
    display('########### That is all you have ##############')
    display('##########################################')
    return
end;

[psth_correct{1}, ts{1}, trialspxmat{1}, tspkmat{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{1}, params);
psth_correct{1} = smoothdata (psth_correct{1}, 'gaussian', 5);
        
params.post = 1500+1000;
[psth_correct{2}, ts{2}, trialspxmat{2}, tspkmat{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{2}, params);
psth_correct{2} = smoothdata (psth_correct{2}, 'gaussian', 5);

params.pre = 1500;
params.post = 2000;
params.binwidth = 20;
[psth_release_correct{1}, ts_release{1}, trialspxmat_release{1}, tspkmat_release{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{1}, params);
psth_release_correct{1} = smoothdata (psth_release_correct{1}, 'gaussian', 5);
     
[psth_release_correct{2}, ts_release{2}, trialspxmat_release{2}, tspkmat_release{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{2}, params);
psth_release_correct{2} = smoothdata (psth_release_correct{2}, 'gaussian', 5);

% premature release PSTH
[psth_premature_release, ts_premature_release, trialspxmat_premature_release, tspkmat_premature_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurereleases, params);
psth_premature_release = smoothdata (psth_premature_release, 'gaussian', 5);
     
% reward PSTH
params.pre = 5000;
params.post = 10000;
[psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards, params);
psth_rew = smoothdata (psth_rew, 'gaussian', 5);
    

%% release
figure;
plot(ts{2}, psth_correct{2}, 'k', 'linewidth', 1); hold on
plot(ts{1}, psth_correct{1}, 'b', 'linewidth', 1);
 
line([750 750], [0 10], 'color', 'r', 'linestyle', '-.', 'linewidth', 1)
line([1500 1500], [0 10], 'color', 'r', 'linestyle', '-.', 'linewidth', 1)

text(750+10, 5, '750 ms', 'color', 'k')
text(1500+10, 5, '1500 ms', 'color', 'b')

xlabel('Time from press onset (ms)')
ylabel('Firing rate (spk per s)')
title('Press-related activity')

%% plot raster and spks
hf=27;
figure(27); clf(27)
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')

ha1 =  axes('unit', 'centimeters', 'position', [1 1 4 3], 'nextplot', 'add', 'xlim', [-2000 2000]);
plot(ts{1}, psth_correct{1}, 'b', 'linewidth', 1); hold on
plot(ts{2}, psth_correct{2}, 'k', 'linewidth', 1)

xlabel('Time from press (ms)')
ylabel ('Spks per s')

if ~isempty(FRrange)
    set(ha1, 'ylim', FRrange)
    else
    axis 'auto y'
end

% make raster plot  750 ms FP
rasterheight = 0.07;
ntrial1 = size(trialspxmat{1}, 2);
ha2 =  axes('unit', 'centimeters', 'position', [1 4.5+0.5 4*size(trialspxmat{1}, 1)/4000 ntrial1*rasterheight],...
    'nextplot', 'add',...
    'xlim', [min(tspkmat{1}) max(tspkmat{1})], 'ylim', [-ntrial1 1], 'box', 'on');

apmat = trialspxmat{1};
k =0;

for i =1:size(trialspxmat{1}, 2)
    
    irt = rt_correctsorted{1}(i);
    xx =  tspkmat{1}(find(apmat(:, i)));
    yy = [0 0.8]-k;
    xxrt = [irt+750; irt+750];
    if  isempty(find(isnan(apmat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    
    % press time
    itpress = t_correctsorted{1}(i);
    i_portin = t_portin-itpress;
    i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);
    
    xxipin=[i_portin; i_portin];
    if ~isempty(xxipin)
        line([xxipin xxipin], yy, 'color', 'r', 'linewidth', 1.5)
    end;
end;

line([750 750], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('750 ms')


% make raster plot 1500 ms FP
ntrial2 = size(trialspxmat{2}, 2);
ha3 =  axes('unit', 'centimeters', 'position', [1 4.5+0.5+ntrial1*rasterheight+0.5 4*size(trialspxmat{2}, 1)/4000 ntrial2*rasterheight],...
    'nextplot', 'add',  'xticklabel', [],...
    'xlim', [min(tspkmat{2}) max(tspkmat{2})], 'ylim', [-ntrial2 1], 'box', 'on');

apmat = trialspxmat{2};
k =0;
for i =1:size(trialspxmat{2}, 2)
    irt = rt_correctsorted{2}(i);
    xx =  tspkmat{2}(find(apmat(:, i)));
    yy = [0 0.8]-k;
    xxrt = [irt+1500; irt+1500];
    if  isempty(find(isnan(apmat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    
    % plot port poke time
    itpress = t_correctsorted{2}(i);
    i_portin = t_portin-itpress;
    i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);
    
    xxipin=[i_portin; i_portin];
    if ~isempty(xxipin)
        line([xxipin xxipin], yy, 'color', 'r', 'linewidth', 1.5)
    end;
    
end;
line([1500 1500], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('1500 ms')
%% release PSTHs
ha4 =  axes('unit', 'centimeters', 'position', [7 1 4 3], 'nextplot', 'add', 'xlim', [-1500 2000]);
plot(ts_release{1}, psth_release_correct{1}, 'b', 'linewidth', 1); hold on
plot(ts_release{2}, psth_release_correct{2}, 'k', 'linewidth', 1)
if  size(trialspxmat_premature_release, 2)>5
    plot(ts_premature_release, psth_premature_release, 'color', [0.6 0.6 0.6], 'linewidth', 1)
end;
xlabel('Time from release (ms)')
ylabel ('Spks per s')
if ~isempty(FRrange)
    set(ha4, 'ylim', FRrange)
    else
    axis 'auto y'
end
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

% make raster plot  750 ms FP
ntrial1 = size(trialspxmat_release{1}, 2)
ha5 =  axes('unit', 'centimeters', 'position', [7 4.5+0.5 4*size(trialspxmat_release{1}, 1)/3000 ntrial1*rasterheight],...
    'nextplot', 'add',...
    'xlim', [min(tspkmat_release{1}) max(tspkmat_release{1})], 'ylim', [-ntrial1 1], 'box', 'on');

apmat = trialspxmat_release{1};
k =0;
for i =1:size(trialspxmat_release{1}, 2)
    irt = rt_correctsorted{1}(i);
    xx =  tspkmat_release{1}(find(apmat(:, i)));
    yy = [0 0.8]-k;
    xxrt = [-irt; -irt];
    if  isempty(find(isnan(apmat(:, i))))
          if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    
    % plot port poke time
    itpress =trelease_correctsorted{1}(i);
    i_portin = t_portin-itpress;
    i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);
    
    xxipin=[i_portin; i_portin];
    if ~isempty(xxipin)
        line([xxipin xxipin], yy, 'color', 'r', 'linewidth', 1.5)
    end;
    
end;
title('750 ms')
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

% make raster plot  1500 ms FP
ntrial2 = size(trialspxmat_release{2}, 2)
ha3 =  axes('unit', 'centimeters', 'position', [7 4.5+0.5+ntrial1*rasterheight+0.5 4*size(trialspxmat_release{2}, 1)/3000 ntrial2*rasterheight],...
    'nextplot', 'add', 'xticklabel', [],...
    'xlim', [min(tspkmat_release{2}) max(tspkmat_release{2})], 'ylim', [-ntrial2 1], 'box', 'on');

apmat = trialspxmat_release{2};
k =0;
for i =1:size(trialspxmat_release{2}, 2)
    irt = rt_correctsorted{2}(i);
    xx =  tspkmat_release{2}(find(apmat(:, i)));
    yy = [0 0.8]-k;
    xxrt = [-irt; -irt];
    if  isempty(find(isnan(apmat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    
     % plot port poke time
    itpress =trelease_correctsorted{2}(i);
    i_portin = t_portin-itpress;
    i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);
    
    xxipin=[i_portin; i_portin];
    if ~isempty(xxipin)
        line([xxipin xxipin], yy, 'color', 'r', 'linewidth', 1.5)
    end;
    
end;
title('1500 ms')
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

% make raster plot premature  
% tspkmat_premature_release
ntrial3 = size(trialspxmat_premature_release, 2);

ha6 =  axes('unit', 'centimeters', 'position',  [7 4.5+0.5+ntrial1*rasterheight+0.5+ntrial2*rasterheight+0.5 4*size(trialspxmat_premature_release, 1)/3000 ntrial3*rasterheight],...
    'nextplot', 'add', 'xticklabel', [], 'xlim', [min(tspkmat_premature_release) max(tspkmat_premature_release)], 'ylim', [-ntrial3 1], 'box', 'on');

apmat = trialspxmat_premature_release;
k =0;
for i =1:size(trialspxmat_premature_release, 2)
    xx =  tspkmat_premature_release(find(apmat(:, i)));
    yy = [0 0.8]-k;
    if  isempty(find(isnan(apmat(:, i))))
            if ~isempty(xx)
            line([xx; xx], yy, 'color', [0.5 0.5 0.5], 'linewidth', 1)
        end;
        k = k+1;
    end;
end;
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

title('Premature')

%% reward
ha7 =  axes('unit', 'centimeters', 'position', [13 1 6 3], 'nextplot', 'add', 'xlim', [-5000 10000]);
plot(ts_rew, psth_rew, 'k', 'linewidth', 1); 
xlabel('Time from reward delivery (ms)')
ylabel ('Spks per s')
if ~isempty(FRrange)
    set(ha7, 'ylim', FRrange)
else
    axis 'auto y'
end
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

% make raster plot reward
ntrial4 = size(trialspxmat_rew, 2);
ha8 =  axes('unit', 'centimeters', 'position', [13 4.5+0.5 6 ntrial4*rasterheight],...
    'nextplot', 'add', 'xlim', [min(tspkmat_rew) max(tspkmat_rew)], 'ylim', [-ntrial4 1], 'box', 'on');

apmat = trialspxmat_rew;
k =0;
for i =1:size(trialspxmat_rew, 2)
    xx =  tspkmat_rew(find(apmat(:, i)));
    yy = [0 1]-k;
    imov = -movetime(i);
    if  isempty(find(isnan(apmat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        line([imov; imov], yy, 'color', 'g', 'linewidth', 1)
        k = k+1;
    end;
     
     % plot port poke time
    itreward =t_rewards(i);
    i_portin = t_portin-itreward;
    i_portin = i_portin(i_portin>=-2000 & i_portin<=10000);
    
    xxipin=[i_portin; i_portin];
    if ~isempty(xxipin)
        line([xxipin xxipin], yy, 'color', 'r', 'linewidth', 1.5)
    end;
    
end;
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

%% make sure ha1, 4, 7 have the same y axis range

ylimmax = 1.1*max([(get(ha1, 'ylim')), (get(ha4, 'ylim')), (get(ha7, 'ylim'))]);
set(ha1, 'ylim', [0 ylimmax]);
axes(ha1)
line([750 750], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
line([1500 1500], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

set(ha4, 'ylim', [0 ylimmax]);
axes(ha4)
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

set(ha7, 'ylim', [0 ylimmax]);
axes(ha7)

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1) 

%% plot spks

% plot spike waveform
thiscolor = [0 0 0];
ha0=axes('unit', 'centimeters', 'position', [13 4.5+1+0.5+ntrial4*rasterheight 2 1.5], 'nextplot', 'add', 'xlim', [0 64])
set(ha0, 'nextplot', 'add')

allwaves = r.Units.SpikeTimes(ku).wave;
allwaves= allwaves(:, [1:64]);

if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot=[1:size(allwaves, 1)];
end;

wave2plot = allwaves(nplot, :);

plot([1:64], wave2plot, 'color', [0.8 .8 0.8]);
plot([1:64], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)

axis([0 65 min(wave2plot(:)) max(wave2plot(:))])
set (gca, 'ylim', [-800 400])
axis tight

line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
axis off

switch r.Units.SpikeNotes(ku, 3)
    case 1
        title(['#' num2str(ku) '(Ch' num2str(r.Units.SpikeNotes(ku, 1)) ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/SU']);
    case 2
        title(['#' num2str(ku) '(Ch' num2str(r.Units.SpikeNotes(ku, 1)) '#' num2str(ku) ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/MU']);
    otherwise
end

% plot autocorrelation
kutime = r.Units.SpikeTimes(ku).timings;

kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;

[c, lags] = xcorr(kutime2, 25); % max lag 100 ms
c(lags==0)=0;


ha00= axes('unit', 'centimeters', 'position', [16 4.5+0.5+1+ntrial4*rasterheight 2 1.5], 'nextplot', 'add', 'xlim', [-25 25])
if median(c)>1
    set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 median(c)])
else
    set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 1], 'ylim', [0 1])
end;

hbar = bar(lags, c);
set(hbar, 'facecolor', 'k')
 
    xlabel('Lag(ms)')

ch = r.Units.SpikeNotes(ind, 1);

uicontrol('style', 'text', 'units', 'centimeters', 'position', [1 4.5+0.5+ntrial1*rasterheight+0.5+0.5+ntrial2*rasterheight 4 0.5],...
    'string', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w', 'fontsize', 10)

uicontrol('style', 'text', 'units', 'centimeters', 'position', [1 4.5+0.5+ntrial1*rasterheight+0.5+ntrial2*rasterheight+1 4 0.5],...
    'string', (['Unit#' num2str(ind) '(Ch' num2str(ch) ')']), 'BackgroundColor','w', 'fontsize', 10)
% 
% tic
% print (gcf,'-dpng', ['PSTH_unit' num2str(ind)])
% toc
% 
% tic
% print (gcf,'-dpdf', ['PSTH_unit' num2str(ind)])
% toc
% 
% saveas(gcf,['PSTH_unit' num2str(ind)], 'fig')

% save to a folder
anm_name = r.Meta(1).Subject;
session =strrep(r.Meta(1).DateTime(1:11), '-','_');

mkdir(fullfile('C:\Users\jiani\OneDrive\Work\Physiology\UnitsCollection', anm_name, session))
tosavename= fullfile('C:\Users\jiani\OneDrive\Work\Physiology\UnitsCollection', anm_name, session, [anm_name '_', session '_' printname 'Unit' num2str(ind) '_Ch' num2str(ch)]);

print (gcf,'-dpdf', tosavename) 
print (gcf,'-dpng', tosavename)

mkdir(fullfile(pwd, 'Fig'))
tosavename= fullfile(pwd, 'Fig', ['Unit' num2str(ind) '_Ch' num2str(ch)]);
print (gcf,'-dpdf', tosavename) 
print (gcf,'-dpng', tosavename)
