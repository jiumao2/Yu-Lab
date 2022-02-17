function plotvmraw2(T, dataout, varargin)

% for flexible AOM onsets


dvm=50;
dwh=80;

if nargin==2
    
    nsignal=7;
    whiskrange=[-50 425];
    vrange=[-80 225];
    type='CR';
elseif nargin==3
    vrange=varargin{1};
    whiskrange=[-50 425];
    nsignal=7;
    type='CR';
elseif nargin==4
    
    vrange=varargin{1};
    whiskrange=varargin{2};
    nsignal=7;
    type='CR';
    
elseif nargin==5
    vrange=varargin{1};
    whiskrange=varargin{2};
    nsignal=varargin{3};
    type='CR';
    
elseif nargin==6
    vrange=varargin{1};
    whiskrange=varargin{2};
    nsignal=varargin{3};
    type=varargin{4};
    
elseif nargin==7
    vrange=varargin{1};
    whiskrange=varargin{2};
    nsignal=varargin{3};
    type=varargin{4};
    dvm=varargin{5};
    
end;

close all;

poledelay=0.3;
pole=dataout.poleonset;
poleout=pole+2;
% pole=pole+poledelay;
tvm=dataout.tneural;

switch type
    
    case 'CR'
        vmnostim=cell2mat(dataout.neural_cr_nostim);
        vmstim=cell2mat(dataout.neural_cr_stim);
        nnostim=size(vmnostim, 2);
        nstim=size(vmstim, 2);
        K=randperm(min(nnostim, nstim));
        numK_nostim=dataout.cr_nostim_nums(K);
        numK_stim=dataout.cr_stim_nums(K);
        
    case 'Hit'
        vmnostim=cell2mat(dataout.neural_hit_nostim);
        vmstim=cell2mat(dataout.neural_hit_stim);
        nnostim=size(vmnostim, 2);
        nstim=size(vmstim, 2);
        K=randperm(min(nnostim, nstim));
        numK_nostim=dataout.hit_nostim_nums(K);
        numK_stim=dataout.hit_stim_nums(K);
        
    case 'Miss'
        vmnostim=cell2mat(dataout.neural_miss_nostim);
        vmstim=cell2mat(dataout.neural_miss_stim);
         nnostim=size(vmnostim, 2);
        nstim=size(vmstim, 2);
        K=randperm(min(nnostim, nstim));
        numK_nostim=dataout.miss_nostim_nums(K);
        numK_stim=dataout.miss_stim_nums(K);
        
            case 'FA'
        vmnostim=cell2mat(dataout.neural_fa_nostim);
        vmstim=cell2mat(dataout.neural_fa_stim);
         nnostim=size(vmnostim, 2);
        nstim=size(vmstim, 2);
        K=randperm(min(nnostim, nstim));
        numK_nostim=dataout.fa_nostim_nums(K);
        numK_stim=dataout.fa_stim_nums(K);
end;

% 
% vmcrnostim=sgolayfilt(removeAP(vmcrnostim, 10000, 5, 4),3, 21);
% vmcrstim=sgolayfilt(removeAP(vmcrstim, 10000, 5, 4), 3, 21);

taom=dataout.taom;
% aom=dataout.aom;

hf=figure;
set(hf, 'paperpositionmode', 'auto', 'units', 'centimeters', 'position', [2 2 20 12])
subplot(1, 2, 1)
set(gca, 'nextplot', 'add', 'xlim', [tvm(1) tvm(end)], 'ylim', vrange)
[b, a]=butter(2, [1 100]*2/10000, 'bandpass');
for i=1:nsignal
    
    plot(tvm, vmnostim(:, K(i))+dvm*(i-1), 'k');   
    plot(tvm, vmstim(:, K(i))+dvm*(i-1));   
    
    [dummy, aom, fp]=findvmtrials(T, numK_stim(i));
  
    fp=filtfilt(b, a, sgolayfilt(fp, 3, 51));
    
    plot(tvm, aom/2-2+min(vmstim(:, K(i))+dvm*(i-1)));
   % plot(tvm, 2*fp+5+min(vmstim(:, K(i))+dvm*(i-1)), 'm')
end;

plot(pole, vrange(2)-5, 'r*', 'markersize', 12)
line([pole+0.25 poleout], [vrange(2)-5 vrange(2)-5], 'color', [.5 .5 .5], 'linewidth', 4)

xlabel('sec')
ylabel('mV')
title(type)
%% 

subplot(1, 2, 2)
set(gca, 'nextplot', 'add', 'xlim', [tvm(1) tvm(end)], 'ylim',whiskrange)
for i=1:nsignal
    [whisk, t]=T.get_whisker_position(1, numK_nostim(i));
    plot(t{1}, whisk{1}+dwh*(i-1), 'k');
    
    [whisk, t]=T.get_whisker_position(1, numK_stim(i));
    plot(t{1}, whisk{1}+dwh*(i-1), 'b');
    
    [dummy, aom]=findvmtrials(T, numK_stim(i));
    plot(tvm, aom-5+min(whisk{1}+dwh*(i-1)));
    
end;

plot(pole, whiskrange(2)-10, 'r*', 'markersize', 12)

line([pole+0.25 poleout], [ whiskrange(2)-10  whiskrange(2)-10], 'color', [.5 .5 .5], 'linewidth', 4)

xlabel('sec')
ylabel ('whisker position')

saveas(hf, ['example_traces_' type], 'fig')
saveas(hf, ['example_traces_' type], 'tif')
