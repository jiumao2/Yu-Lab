function plotanexample(T, contacts, trialnum, tosave, timerange, vrange, whiskrange, wid, plotaom)
% function plotanexample(T, b, trialnum, tosave, timerange, vrange, whiskrange, wid, plotaom)
% to plot single trial
% include whisking angle at base, 
% function [vout, vaom, tvm, vFP, twhisk, whisk]=findvmtrials(T, trialnums, stim_freq);
if nargin<8
    plotaom=0;
    if nargin<7
        wid=1;
        if nargin<6
            whiskrange=[-40 40];
            if nargin<5
                vrange=[-70 -20];
                if nargin<4
                    timerange=[];
                    if nargin<3
                        tosave=0;
                    end;
                end;
            end;
        end;
    end;
end;


[vm, aom, tvm, fp]=findvmtrials(T, trialnum);
b=T.trials{T.trialNums==trialnum}.behavTrial;
% [whiskpos, twhisk]=T.trials{T.trialNums==trialnum}.whiskerTrial.get_thetaAtContact(1);
 [whiskpos,twhisk] = T.get_whisker_position(wid, trialnum);
 whiskpos=cell2mat(whiskpos);
 twhisk=cell2mat(twhisk);
 
twhisk=twhisk+0.01;
% vm=sgolayfilt(vm, 3, 31);
fp=medfilt1(fp, 40);
whiskpos=medfilt1(whiskpos, 2);

if isempty(timerange)
    tlim=[min(tvm) max(tvm)];
else
    tlim=timerange;
end;

contacts_trial=contacts{T.trialNums==trialnum};

pin_des=T.pinDescentOnsetTimes(trialnum);
pin_as=T.pinAscentOnsetTimes(trialnum);
lick_times=b.beamBreakTimes;

% if ~isempty(lick_times)
%     lick_times=lick_times(:, 3);
% else 
%     lick_times=[];
% end;

twater=b.rewardTime;

hf=figure;
set (hf, 'unit', 'centimeters', 'position', [4 4 12 12], 'paperpositionmode', 'auto')

ha0=axes;
set(ha0, 'nextplot', 'add', 'unit', 'normalized', 'xlim', tlim,...
    'xticklabel', [], 'unit', 'normalized', 'position', [.18 .82 .8 .1], 'ylim', [-10 10]);
title([T.cellNum 'trial' num2str(trialnum)], 'fontsize', 10)

line([pin_des pin_des+0.25], [5 0], 'color', [0.75 0.75 0.75], 'linewidth', 3)
line([pin_des+0.25 pin_as], [0 0], 'color', [0 0 0], 'linewidth', 3)
line([pin_as pin_as+0.25], [0 5], 'color', [0.75 0.75 0.75], 'linewidth', 3)
if ~isempty(lick_times)
    plot(lick_times, -4, 'm.', 'markersize', 4)
end;

if ~isempty(twater)
line([twater(1) twater(1)+1], [-8 -8], 'color', 'c', 'linewidth', 2)
end;

axis off

ha1=axes;
set(ha1, 'nextplot', 'add', 'unit', 'normalized', 'xlim', tlim, 'unit', 'normalized', 'position', [.18 .64 .8 .15], 'ylim', whiskrange);
plot(twhisk, whiskpos, 'k')
ylabel ('Whisk pos')
if ~isempty(r{1})
    plot(twhisk(round(cp{1})), whiskpos(round(cp{1})), 'r.');
    plot(r{1}, 0, 'go');
end;
text(4, whiskrange(2)-10, ['whisker:' num2str(wid)])

ha2=axes;
set(ha2, 'nextplot', 'add', 'xticklabel', [], 'unit', 'normalized', 'xlim', tlim, 'unit', 'normalized', 'position', [.18 .475 .8 .1], 'ylim', [-1 1]);
plot(tvm, fp/10, 'k')
axis tight
axis off

ha3=axes;
set(ha3, 'nextplot', 'add', 'unit', 'normalized', 'xlim', tlim, 'unit', 'normalized', 'position', [.18 .1 .8 .35], 'ylim', vrange);

plot(tvm, vm, 'k')
line([max(tlim)-.2 max(tlim)-.2], [vrange(2)-12 vrange(2)-2], 'color', 'k')
xlabel('Time (s)')
ylabel('Vm (mV)')

if plotaom
    ha3b=axes;
    set(ha3b, 'nextplot', 'add', 'xticklabel', [], 'unit', 'normalized', 'xlim', tlim, 'color', 'none', 'position', [.18 .1 .8 .1], 'ylim', [-2 20]);
    axis off
    plot(tvm, aom, 'b')
    linkaxes([ha3, ha3b], 'x')
end;


if tosave
    print (hf, '-depsc2', ['example_trial_' num2str(trialnum)])
     print (hf, '-dpdf', ['example_trial_' num2str(trialnum)])
       print (hf, '-dtiff', ['example_trial_' num2str(trialnum)])
end;



