function stout=silence_testing(cellnum, code, tracenumall, th, ss, binsize, note, savefig)
% th is the threshold
% th(1) threshold; th(2) max amplitude; th(3) duration max; th(4) high-pass
% filter or not
% 7.29.2014: test the effect of silencing, yellow or blue. 
% ss: sensory stimulation

if nargin<8
    savefig=0;
    if nargin<7
        note='';
        if nargin<6
            binsize=0.1;
        end;
    end;
end;

if numel(th)<3
    th(2)=4;
    th(3)=100;
end;

if numel(th)<4
    th(4)=1;
end;

Vm=[];
Air=[];
Air_ind=[]; % if Air_ind=1, means there is air puff
Opto=[];
Opto_ind=[]; % if Opto_ind=1, means it is optogenetic trial. 

for i=1:length(tracenumall)
    tracenum=tracenumall(i);
    
if tracenum < 10
    filler = '000';
elseif tracenum <100
    filler = '00';
elseif tracenum <1000
    filler = '0';
end

d = load(['C:\Work\Projects\BehavingVm\Data\physiology\' cellnum filesep cellnum code filler int2str(tracenum) '.xsg'],'-mat');

Vm=[Vm d.data.ephys.trace_1];

Air=[Air d.data.acquirer.trace_2];
if length(find(d.data.acquirer.trace_2>5))>100
    Air_ind=[Air_ind 1];
else
    Air_ind=[Air_ind 0];
end;

Opto=[Opto d.data.acquirer.trace_1];
if length(find(d.data.acquirer.trace_1>4))>100
    Opto_ind=[Opto_ind 1];
else
    Opto_ind=[Opto_ind 0];
end;


end;

t=[0:size(Vm, 1)-1]/10000;

figure; 
ha1=subplot(3, 1, 1);
plot(t, Vm)

ha2=subplot(3, 1, 2);
plot(t, Air)
title('Puff')

ha3=subplot(3, 1, 3);
plot(t, Opto)
title('Shutter')

linkaxes([ha1, ha2, ha3], 'x')

figure;
subplot(2, 1, 1)
plot(Vm(:))
subplot(2, 1, 2)
plot(prctile(Vm(1:50000, :), 5, 1), 'bo-')

hf=figure; 
set(hf, 'units', 'centimeters', 'position', [2 1 12 18],'paperpositionmode', 'auto', 'color', 'w')

% spikes

if ~isempty(intersect(ss, [0 1]))
    ind1=find(Air_ind==ss & Opto_ind==0);
    ind2=find(Air_ind==ss & Opto_ind==1);
else
    ind1=find(Opto_ind==0);
    ind2=find(Opto_ind==1);
end;

% spikes
% function spikes=spikespy(Vm, Fs, threshold, width, Vmax, hp)
spks=spikespy(Vm, 10000, th(1), th(3), th(2), th(4));

[histos_1, ts ] = spikehisto(spks(:, ind1),10000, round(max(t)/binsize));
[histos_2, ts ] = spikehisto(spks(:, ind2),10000, round(max(t)/binsize));

ha1=subplot(6, 1, [3]); set(gca, 'nextplot', 'add')
bar(ts, histos_1, 'linewidth', 1, 'edgecolor', 'k', 'facecolor', 'none'); hold on
bar(ts, histos_2,'linewidth', 1, 'edgecolor', [255 150 0]/255, 'facecolor', 'none');
box off
set(gca, 'xlim', [min(t) 4.5])

ylabel('Hz')

ha2=subplot(6, 1, [4 5 6]);set(gca, 'nextplot', 'add')
plot(t, mean(removeAP(Vm(:, ind1), 10000, 5, 4), 2), 'k'); hold on
plot(t, mean(removeAP(Vm(:, ind2), 10000, 5, 4), 2), 'color', [255 150 0]/255);
ylabel('mV')
xlabel ('s')
set(gca, 'xlim', [min(t) 4.5])
box off

% plot(mean(Vm(:, Air_ind==0&Opto_ind==0), 2), 'k--');
% plot(mean(Vm(:, Air_ind==0&Opto_ind==1), 2), 'g--');

ha3=subplot(6, 1, 1);set(gca, 'nextplot', 'add')
plot(t, mean(removeAP(Air(:, ind1), 10000, 5, 4), 2), 'color', [0.75 0.75 0.75], 'linewidth', 1); hold on
plot(t, mean(removeAP(Air(:, ind2), 10000, 5, 4), 2), 'color', [0.75 0.75 0.75], 'linewidth', 1);

set(gca, 'xlim', [min(t) 4.5])
axis off
text(3, -1, 'Air puff')
title([cellnum, code '--' note])

ha4=subplot(6, 1, 2); set(gca, 'nextplot', 'add')
plot(t, mean(Opto(:, Opto_ind==0), 2), 'k'); hold on
plot(t, mean(Opto(:, Opto_ind==1), 2), 'color', [255 150 0]/255);
% plot(mean(Opto(:, Air_ind==0&Opto_ind==0), 2), 'k--');
% plot(mean(Opto(:, Air_ind==0&Opto_ind==1), 2), 'g--');
set(gca, 'xlim', [min(t) 4.5])
axis off
text(3, -1, 'Laser shutter')


if ss==1
    
hf2=figure; 
set(hf2, 'units', 'centimeters', 'position', [2 1 10 15],'paperpositionmode', 'auto', 'color', 'w')

PSPind1=[];
puffstim=[];
% control condition
for i=1:length(ind1)
    iair=Air(:, ind1(1));
    onsets=find(iair>1);
    puffon=[onsets(1); onsets(1+find(diff(onsets)>1))];
    for j=1:length(puffon)
    PSPind1=[PSPind1 Vm(puffon(j)-50*10 :puffon(j)+450*10, ind1(i))];
    puffstim=[puffstim Air(puffon(j)-50*10:puffon(j)+450*10, ind1(i))];
    end;
end;

PSPind2=[];
% stim condition
for i=1:length(ind2)
    iair=Air(:, ind2(1));
    onsets=find(iair>1);
    puffon=[onsets(1); onsets(1+find(diff(onsets)>1))];
    for j=1:length(puffon)
        PSPind2=[PSPind2 Vm(puffon(j)-50*10 :puffon(j)+450*10, ind2(i))];
        puffstim=[puffstim Air(puffon(j)-50*10:puffon(j)+450*10, ind2(i))];
    end;
end;


subplot(7, 1, [4:6])
tpsp=[0:size(PSPind1, 1)-1]/10000;

plot(tpsp, mean(removeAP(PSPind1, 10000, th(1), th(3)), 2), 'k', 'linewidth', 1); hold on
plot(tpsp, mean(removeAP(PSPind2, 10000, th(1), th(3)), 2), 'color', [255 150 0]/255, 'linewidth', 1);
set(gca, 'xlim', [tpsp(1)-0.05 tpsp(end)+0.05])
box off

ylabel ('Vm (mV)')

subplot(7, 1, [1:3])
[histos_PSP1, tse] = spikehisto(spikespy(PSPind1, 10000, th(1), th(3), th(2), th(4)),10000, round(max(tpsp)/0.01));
[histos_PSP2, tse] = spikehisto(spikespy(PSPind2, 10000, th(1), th(3), th(2), th(4)),10000, round(max(tpsp)/0.01));
tse=tse-0.05;
hbar1=bar(tse, histos_PSP1);
set(hbar1, 'edgecolor', 'k', 'facecolor', 'none')
hold on
hbar2=bar(tse, histos_PSP2);
set(hbar2, 'edgecolor', [255 150 0]/255, 'facecolor', 'none')
set(gca, 'xlim', [tse(1)-0.05 tse(end)+0.05])
box off
xlabel('Time (s)')
ylabel ('Spk/s')
title([cellnum, code '--' note])

subplot(7, 1, 7)
plot(tpsp, mean(puffstim, 2), 'color', [.75 .75 .75], 'linewidth', 2)
set(gca, 'xlim', [tpsp(1)-0.05 tpsp(end)+0.05]);
box off
axis off

end;

hf3=figure;
set(hf3, 'units', 'centimeters', 'position', [2 1 10 12],'paperpositionmode', 'auto', 'color', 'w')

ind1=find(Opto_ind==0);
ind2=find(Opto_ind==1);

[histos_1b, ts_b ] = spikehisto(spks(:, ind1),10000, round(max(t)/binsize));
[histos_2b, ts_b ] = spikehisto(spks(:, ind2),10000, round(max(t)/binsize));

vmswitch=[]; % 0.5 s before and 0.5 s after laser onset
vmswitchnone=[];
spkswitch=[];
spkswithnone=[];
shutterswitch=[];
shutterswitchnone=[];

for i=1:length(ind2)
    shutter_onset(i)=find(Opto(:, ind2(i))>2, 1, 'first');
    ivm=removeAP(Vm(:, ind2(i)), 10000, 5, 4);
    iopto=Opto(:, ind2(i));
    vmswitch(:, i)=ivm(shutter_onset(i)-0.5*10000:shutter_onset(i)+0.5*10000);
    shutterswitch(:, i)=iopto(shutter_onset(i)-0.5*10000:shutter_onset(i)+0.5*10000);
end;

for i=1:length(ind1)
    shutter_onset_fake=shutter_onset(randperm(length(shutter_onset), 1));
    ivm=removeAP(Vm(:, ind1(i)), 10000, 5, 4);
    iopto=Opto(:, ind1(i));
    vmswitchnone(:, i)=ivm(shutter_onset_fake-0.5*10000:shutter_onset_fake+0.5*10000);
    shutterswitchnone(:, i)=iopto(shutter_onset_fake-0.5*10000:shutter_onset_fake+0.5*10000);
end;


tvmswitch=[-0.5*10000:0.5*10000]/10000;
spkswitch=histos_2b(ts_b>=t(shutter_onset(1))-0.5&ts_b<=t(shutter_onset(1))+0.5);
spkswitchnone=histos_1b(ts_b>=t(shutter_onset(1))-0.5&ts_b<=t(shutter_onset(1))+0.5);

tspkswitch=ts_b(ts_b>=t(shutter_onset(1))-0.5&ts_b<=t(shutter_onset(1))+0.5)-t(shutter_onset(1));

subplot(5, 1, [1 2])
plot(tvmswitch, mean(vmswitchnone, 2), 'color', 'k', 'linewidth', 1);hold on
plot(tvmswitch, mean(vmswitch, 2), 'color', [255 150 0]/255, 'linewidth', 1); 

set(gca, 'xlim', [-0.5 0.5]);
box off
ylabel('mV')

subplot(5, 1, [3 4])
bar(tspkswitch, spkswitchnone, 'facecolor', 'none', 'edgecolor', 'k', 'linewidth', 2); hold on
bar(tspkswitch, spkswitch, 'facecolor', 'none', 'edgecolor', [255 150 0]/255, 'linewidth', 2); 

box off
set(gca, 'xlim', [-0.5 0.5]);
xlabel('s'); 
ylabel('Spk/s')

subplot(5, 1, 5)
plot(tvmswitch, mean(shutterswitchnone, 2), 'color', 'k', 'linewidth', 1);hold on
plot(tvmswitch, mean(shutterswitch, 2), 'color', [255 150 0]/255, 'linewidth', 2); 

set(gca, 'xlim', [-0.5 0.5], 'ylim', [-2 10]);
box off
axis off


%% plot some examples
% 5 from control, 5 from stim. 

ind1example=ind1(randperm(length(ind1), 5));
ind2example=ind2(randperm(length(ind2), 5));

vmexample1=Vm(:, ind1example);

vmexample2=Vm(:, ind2example);

hf4=figure;
set(hf4, 'units', 'centimeters', 'position', [2 1 12 12],'paperpositionmode', 'auto', 'color', 'w')
ha1=axes('units', 'centimeters', 'position', [2, 2, 8 8], 'nextplot', 'add', 'xlim', [0 4.5]);

for i=1:length(ind2example)
    plot(t, 0.5*(vmexample2(:, i)-mean(vmexample2(:, i)))/std(vmexample2(:, i))+i*15+10, 'color', [255 150 0]/255);
end;

for i=1:length(ind1example)
    plot(t, 0.5*(vmexample1(:, i)-mean(vmexample1(:, i)))/std(vmexample1(:, i))+80+i*15+10, 'color', 'k');
end;

plot(t, mean(Opto(:, ind2example), 2), 'color', [255 150 0]/255, 'linewidth', 1);
text(5, 2, 'shutter')
plot(t, mean(Air(:, ind2example), 2)+10, 'color',  [.75 .75 .75], 'linewidth', 1);
text(5, mean(mean(Air(:, ind2example), 2)+10),'air')

line([0 5], [-5 -5], 'linewidth', 1, 'color', 'k')
line([0 0], [-5 -6], 'linewidth', 1, 'color', 'k')
line([1 1], [-5 -6], 'linewidth', 1, 'color', 'k')
line([2 2], [-5 -6], 'linewidth', 1, 'color', 'k')
line([3 3], [-5 -6], 'linewidth', 1, 'color', 'k')
line([4 4], [-5 -6], 'linewidth', 1, 'color', 'k')
line([5 5], [-5 -6], 'linewidth', 1, 'color', 'k')
axis tight
axis off


stout.id=[cellnum, code];
stout.range=tracenumall;
stout.Vm=Vm;
stout.Spk=spks;
stout.ind1=ind1;
stout.ind2=ind2;
stout.spkhist1=histos_1;
stout.spkhist2=histos_2;
stout.thist=ts;
stout.Air=Air;
stout.Opto=Opto;
stout.indAir=Air_ind;
stout.indOpto=Opto_ind;
stout.tvmswitch=tvmswitch;
stout.vmswitch={vmswitch, vmswitchnone};
stout.tspkswitch=tspkswitch;
stout.spkswitch={spkswitch, spkswitchnone};
stout.shutterswitch={shutterswitch, shutterswitchnone};

if savefig

print(hf, '-dtiff', '-r500', 'avgresponse')
    
if ss==1
    print(hf2, '-dtiff', '-r500', 'PSTH')
end;

print(hf3, '-dtiff', '-r500', 'transition')

print(hf4, '-dtiff', '-r500', 'examples')

save silence_out stout

end;

    
    


