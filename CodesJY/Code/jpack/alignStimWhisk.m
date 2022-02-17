function alignStimWhisk(dout, range, lasertype);

if nargin<3
    lasertype=[0 0 1];
    if nargin<2
        range=[-0.5 1
            -.5 1];
    end;
end;

% dout is from the program that collect whisking and laser profiles


laser_on=[];
whisking_on=[];
whiskingamp_on=[];
whiskingsetpt_on=[];

whisking_onsham=[];
whiskingamp_onsham=[];
whiskingsetpt_onsham=[];

tlaser_on=[range(1, 1):1/10000:range(1, 2)]; % from 0.5s pre laser onset to 1s post laser onset
twhisker_on=[range(1, 1)*1000:range(1, 2)*1000]/1000; 

laser_off=[];
whisking_off=[];
whiskingamp_off=[];
whiskingsetpt_off=[];

whisking_offsham=[];
whiskingamp_offsham=[];
whiskingsetpt_offsham=[];

tlaser_off=[range(2, 1):1/10000:range(2, 2)]; % from 0.5s pre laser onset to 1s post laser onset
twhisker_off=[range(2, 1)*1000:range(2, 2)*1000]/1000;


for i=1:size(dout.whisk_stim, 2);
    
laser_on(i)=find(dout.aom(:, i)>1, 1, 'first');
laser_off(i)=find(dout.aom(:, i)>1, 1, 'last');

[~, ind_on]=min(abs(dout.twhisk-laser_on(i)/10000));
whisking_on(:, i)=dout.whisk_stim(ind_on+range(1, 1)*1000:ind_on+range(1, 2)*1000, i);
whiskingamp_on(:, i)=dout.amp_stim(ind_on+range(1, 1)*1000:ind_on+range(1, 2)*1000, i);
whiskingsetpt_on(:, i)=dout.setpt_stim(ind_on+range(1, 1)*1000:ind_on+range(1, 2)*1000, i);

[~, ind_off]=min(abs(dout.twhisk-laser_off(i)/10000));
whisking_off(:, i)=dout.whisk_stim(ind_off+range(2, 1)*1000:ind_off+range(2, 2)*1000, i);
whiskingamp_off(:, i)=dout.amp_stim(ind_off+range(2, 1)*1000:ind_off+range(2, 2)*1000, i);
whiskingsetpt_off(:, i)=dout.setpt_stim(ind_off+range(2, 1)*1000:ind_off+range(2, 2)*1000, i);

aom_on(:, i)=dout.aom(laser_on(i)+range(1, 1)*10000:laser_on(i)+range(1, 2)*10000, i);
aom_off(:, i)=dout.aom(laser_off(i)+range(2, 1)*10000:laser_off(i)+range(2, 2)*10000, i);
end;

for i=1:size(dout.whisk_nostim, 2);
    
    isham=randperm(length(laser_on), 1);
    laser_onsham=laser_on(isham);
    laser_offsham=laser_off(isham);
    
    [~, ind_on]=min(abs(dout.twhisk-laser_onsham/10000));
    whisking_onsham(:, i)=dout.whisk_nostim(ind_on+range(1, 1)*1000:ind_on+range(1, 2)*1000, i);
    whiskingamp_onsham(:, i)=dout.amp_nostim(ind_on+range(1, 1)*1000:ind_on+range(1, 2)*1000, i);
    whiskingsetpt_onsham(:, i)=dout.setpt_nostim(ind_on+range(1, 1)*1000:ind_on+range(1, 2)*1000, i);
    
    [~, ind_off]=min(abs(dout.twhisk-laser_offsham/10000));
    whisking_offsham(:, i)=dout.whisk_nostim(ind_off+range(2, 1)*1000:ind_off+range(2, 2)*1000, i);
    whiskingamp_offsham(:, i)=dout.amp_nostim(ind_off+range(2, 1)*1000:ind_off+range(2, 2)*1000, i);
    whiskingsetpt_offsham(:, i)=dout.setpt_nostim(ind_off+range(2, 1)*1000:ind_off+range(2, 2)*1000, i);
    
end;

figure;

figure;
set(gcf, 'units', 'centimeter', 'position', [1 1 15 15], 'paperpositionmode', 'auto', 'color', 'w')

subplot(2, 2, 1)% whisking set point, on
ci=bootci(1000, @mean, whiskingsetpt_onsham');ci=ci';
cistim=bootci(1000, @mean, whiskingsetpt_on');cistim=cistim';

plot(twhisker_on, mean(whiskingsetpt_onsham, 2), 'k', 'linewidth', 2)
hold on
plot(twhisker_on, ci, 'k:');

plot(twhisker_on, mean(whiskingsetpt_on, 2), 'color', lasertype, 'linewidth', 2)
hold on
plot(twhisker_on, cistim, ':', 'color', lasertype);

plot(tlaser_on, -2+min(mean(whiskingsetpt_on, 2))+0.25*mean(aom_on, 2),  'color', lasertype)
xlabel('time')
ylabel('set point')
set(gca, 'xlim', [min(twhisker_on) max(twhisker_on)])
title([dout.name ' VGAT-ChR2'])

subplot(2, 2, 2)% whisking set point, off
ci=bootci(1000, @mean, whiskingsetpt_offsham');ci=ci';
cistim=bootci(1000, @mean, whiskingsetpt_off');cistim=cistim';

plot(twhisker_off, mean(whiskingsetpt_offsham, 2), 'k', 'linewidth', 2)
hold on
plot(twhisker_off, ci, 'k:');

plot(twhisker_off, mean(whiskingsetpt_off, 2), 'color', lasertype, 'linewidth', 2)
hold on
plot(twhisker_off, cistim, ':', 'color', lasertype);

plot(tlaser_off, -2+min(mean(whiskingsetpt_off, 2))+0.25*mean(aom_off, 2), 'color', lasertype)
xlabel('time')
ylabel('set point')
set(gca, 'xlim', [min(twhisker_off) max(twhisker_off)])

subplot(2, 2, 3)% whisking amp, on
ci=bootci(1000, @mean, whiskingamp_onsham');ci=ci';
cistim=bootci(1000, @mean, whiskingamp_on');cistim=cistim';

plot(twhisker_on, mean(whiskingamp_onsham, 2), 'k', 'linewidth', 2)
hold on
plot(twhisker_on, ci, 'k:');

plot(twhisker_on, mean(whiskingamp_on, 2), 'color', lasertype, 'linewidth', 2)
hold on
plot(twhisker_on, cistim, ':', 'color', lasertype);

plot(tlaser_on, -2+min(mean(whiskingamp_on, 2))+0.25*mean(aom_on, 2), 'color', lasertype)
xlabel('time')
ylabel('whisk amp')
set(gca, 'xlim', [min(twhisker_on) max(twhisker_on)])

subplot(2, 2, 4)% whisking amp, off
ci=bootci(1000, @mean, whiskingamp_offsham');ci=ci';
cistim=bootci(1000, @mean, whiskingamp_off');cistim=cistim';

plot(twhisker_off, mean(whiskingamp_offsham, 2), 'k', 'linewidth', 2)
hold on
plot(twhisker_off, ci, 'k:');

plot(twhisker_off, mean(whiskingamp_off, 2), 'color', lasertype, 'linewidth', 2)
hold on
plot(twhisker_off, cistim, ':', 'color', lasertype);

plot(tlaser_off, -2+min(mean(whiskingamp_off, 2))+0.25*mean(aom_off, 2), 'color', lasertype)
xlabel('time')
ylabel('whisk amp')
set(gca, 'xlim', [min(twhisker_off) max(twhisker_off)])
