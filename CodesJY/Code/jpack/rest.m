function [vbase, vmean, vth]=rest(T, badtrials, inds)

[Vm, aom, tvm]=findvmtrials(T, setdiff(T.trialNums, [T.stimtrialNums, badtrials]));
trialnums=setdiff(T.trialNums, [T.stimtrialNums, badtrials]);
Vstep=Vm(50001:end, :);
Vm=Vm(1:50000, :);Vmorg=Vm;
Vm=removeAP(Vm, 10000, 5, 4);
trialbase=prctile(Vm, 5);

figure; set(gcf, 'units', 'centimeters', 'position', [2 2 8 20])
subplot(4, 1, 1)
allcolors=varycolor(size(Vm, 2));

for i=1:size(Vm, 2)
plot([size(Vm, 1)*(i-1)+1:size(Vm, 1)*(i-1)+size(Vm, 1)], Vmorg(:, i), 'color', allcolors(i, :));
hold on
end;

vbase=prctile(Vm(:), 5);
vmean=mean(Vm(:));
hold on
line([1 length(Vm(:))], [vbase vbase], 'color', 'm', 'linestyle', ':')
line([1 length(Vm(:))], [vmean vmean], 'color', 'k', 'linestyle', '--')
axis tight
set(gca, 'xtick', []);
subplot(4, 1, 2)
for i=1:size(Vm, 2)
plot(i, trialbase(i), 'o', 'color', allcolors(i, :), 'linewidth', 1)
hold on
end
title('Baseline')
axis tight

subplot(4, 1, 3)
for i=1:size(Vm, 2)
plot(i, mean(Vstep(500:1000, i))-mean(Vstep(1:100, i)), 'o', 'color', allcolors(i, :))
hold on
end
title('Vstep')
axis tight

if isempty(inds)
    inds=1:size(Vstep, 2);
end;

file=dir('VthJY*.mat');
if ~isempty(file)
    load(file.name);
else
    Vth=[];
end;
trialnums=trialnums(inds);

if ~isempty(Vth)
    subplot(4, 1, 4)
    [~, indtrial]=intersect(Vth.trials, trialnums);
    spkth=cell2mat(Vth.threshold(indtrial));
    plot(spkth, 'ko')
    vth=prctile(spkth, 10);
    line([1 length(spkth)], [vth vth], 'color', 'r')
    ylabel('threshold')
end;
axis tight

saveas(gcf, 'rest', 'fig')
print(gcf, '-dtiff', '-r500', 'rest')


Vstep=Vstep(:, inds);
[re, te, rin, tin]=fitvstep(Vstep, -.1, 100, 101);
