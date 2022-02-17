function PSTHout = ExtractPopulationEvents(r, units)

% 9.9.2020
% 
if nargin<2
    units = 1:length(r.Units.SpikeTimes);
end;

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

% time of all reward approaches
ind_approach = find(strcmp(rb.Labels, 'ApproachOnset'));
t_approaches = rb.EventTimings(rb.EventMarkers == ind_approach);

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

movetime = zeros(1, length(t_rewards));
for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correctreleases;
    dt = dt(dt>0);
    if ~isempty(dt)
        movetime(i) = dt(end);
    end;
end;

movetime0 = zeros(1, length(t_rewards));
for i =1:length(t_rewards)
    dt = t_rewards(i)-t_approaches;
    dt = dt(dt>0);
    if ~isempty(dt)
        movetime0(i) = dt(end);
    end;
end;

t_rewards = t_rewards(movetime>0);
movetime = movetime(movetime>0);
movetime0 = movetime0(movetime>0);
[movetime, indsort] = sort(movetime);
t_rewards = t_rewards(indsort);
movetime0 = movetime0(indsort);

% time of premature presses
t_prematurepresses = t_presses(rb.PrematureIndex);
t_prematurereleases = t_releases(rb.PrematureIndex);

FPs_prematurepresses = rb.Foreperiods(rb.PrematureIndex);

% time of late presses
t_latepresses = t_presses(rb.LateIndex);
FPs_latepresses = rb.Foreperiods(rb.LateIndex);

figure; plot(t_presses, 1, 'ko'); hold on
plot(t_triggers, 1.2, 'g*')

for i =1:length(t_prematurepresses)
    plot(t_prematurepresses(i), 1.5, 'ko', 'markerfacecolor', 'r')
    ifp = FPs_prematurepresses(i); % current foreperiods
    itpress = t_prematurepresses(i);
    
    line([itpress itpress+ifp], [1.5 1.5], 'color', 'r', 'linewidth', 2)
end;

for i =1:length(t_latepresses)
    plot(t_latepresses(i), 1.8, 'ko', 'markerfacecolor', 'm')
    ifp = FPs_latepresses(i); % current foreperiods
    itpress = t_latepresses(i);
    line([itpress itpress+ifp], [1.8 1.8], 'color', 'm', 'linewidth', 2)
end;

if ~isempty(t_approaches)
    plot(t_approaches, 1.9, 'c^', 'linewidth', 1)
end;

if ~isempty(t_rewards)
    plot(t_rewards, 2.0, 'co', 'linewidth', 1)
end;
set(gca, 'ylim', [-5 5])


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

% collect PSTH from all neurons
Ncell = length(r.Units.SpikeTimes);
Ncell = length(units);

tspk = 1:4000000;
spkmat = sparse(Ncell, max(tspk));
tedges = [0:20:4000000];
tcenter = mean(tedges(1:end-1), tedges(2:end)); 
pop=zeros(Ncell, length(tcenter));

for k = 1:Ncell; 
    ku = units(k);
    spkmat_ku=spkmat;
    spktime =  r.Units.SpikeTimes(ku);
    spkmat(k, spktime.timings)=1;
    [nspk, edges] = histcounts(spktime.timings, tedges);
    nspk = smoothdata(nspk, 'gaussian', 5);
    pop(k, :)=(nspk-mean(nspk)); 
end;

%% apply PCA to pop
% pop                          44x200000              70400000  double      
% 5 min of data: 
% 
% tmax= [5*1000]
% 
% 0.5*60*1000/20;
 
tindex2 = find(tcenter>=210000 & tcenter<=220000) 
tindex = find(tcenter>=150000 & tcenter<=180000)

pop_small = pop(:, tindex);
pop_small = pop_small';
[coeff, score, latent] =  pca(pop_small);
% pop_small                   3001x44                   1056352  double          
%   score                       3001x44                   1056352  double              
%   coeff                         44x44                     15488  double              
 
n_interest = 9; 

figure;
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 18], 'paperpositionmode', 'auto' )

for i=1:4
    subplot(7, 1, i)
    plot(tcenter(tindex)/1000,score(:, i))
    title(['PC' num2str(i)]) 
    set(gca, 'ylim', [-1 2.5])
end;
xlabel('Time (s)')
% plot spike times:
colorcodes = varycolor(size(pop_small, 2));
subplot(7, 1, [5 6 7]) 
set(gca, 'nextplot', 'add'); 
 
for i=1:size(pop_small, 2)
    plot(tcenter(tindex)/1000, pop_small(:, i)*5+2*i, 'color', colorcodes(i, :));
        
end;
axis tight 
axis off 

pop_small2 = pop(:, tindex2);  
pop_small2 = pop_small2';

[coeff2, score2, latent2] =  pca(pop_small2);

score2_predicted = pop_small2*coeff;
figure;
set(gcf, 'unit', 'centimeters', 'position',[17 2 7 18], 'paperpositionmode', 'auto' )


for i=1:4
    subplot(7, 1, i)
    plot(tcenter(tindex2)/1000,score2_predicted(:, i), 'k');
    title(['PC' num2str(i)]) 
    
    set(gca, 'ylim', [-1 2.5])
end;
xlabel('Time (s)')

% plot spike times:
colorcodes = varycolor(size(pop_small2, 2));
subplot(7, 1, [ 5 6 7]) 
set(gca, 'nextplot', 'add'); 
 
for i=1:size(pop_small2, 2)
     
    plot(tcenter(tindex2)/1000, pop_small2(:, i)*5+2*i, 'color', colorcodes(i, :));
        
end;
axis tight

axis off

 
  

%% plot spike timing 
tplot = [50000 50000+30*1000];
indplot = find(tspk>=tplot(1)& tspk<=tplot(2));
hf2=figure;
ha2=axes
set(ha2, 'nextplot', 'add');
colorcodes = varycolor(Ncell);

for i=1:Ncell
    
    ispktime = find(spkmat(i, indplot));  
    
    if ~isempty(ispktime)
        xx = [ispktime; ispktime]/1000;
        yy =[i; i+0.8]-0.5;
        plot(xx, yy, 'color', colorcodes(i, :))
    end;
    
end;

set(gca, 'xlim', [0 30])
xlabel('Time (s)')
ylabel('Neuron #')
% 
% ha3=subplot(1, 2, 2);
% set(ha3, 'nextplot', 'add');
% indplot2 = find(tcenter>=tplot(1)& tcenter<=tplot(2));
% 
% for i=1:Ncell
%     
%     ispkcount =pop(i, indplot2);
%     ispkcount = ispkcount - mean(ispkcount);
%     
%     plot(tcenter(indplot2), ispkcount+2*i, 'color', colorcodes(i, :));
%         
% end;
% 
% axis off
% 
% 
% figure
% 
% plot(abs(score(9, :)), 'ko', 'linestyle', ':', 'color', 'k', 'linewidth', 1); hold on
% plot(abs(score(5, :)), 'go', 'linestyle', ':', 'color', 'g', 'linewidth', 1)

ylabel('score')
xlabel('PC#')


