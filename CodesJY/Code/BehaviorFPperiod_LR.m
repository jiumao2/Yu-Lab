function BehaviorFPperiod_LR(r, cutoff)
% compare left versus right hemispheres
% read r array

if nargin<2
    cutoff = 16;  % default mode: 16 array on one side. 
end;

Fs=1000;

release_time = r.Behavior.Onset{2};
press_time = r.Behavior.Onset{end};

tpre = 1000;
tpost = 1000;

MaxDur = max(r.FP.data{1}(:, 1));

fp_release = [];
fp_press = [];

left_array_chs      = r.FP.channels(r.FP.channels<=cutoff);
right_array_chs     = r.FP.channels(r.FP.channels>=cutoff);

left_release        = cell(1, length(left_array_chs));
right_release       = cell(1, length(right_array_chs));

left_press        = cell(1, length(left_array_chs));
right_press       = cell(1, length(right_array_chs));

for j = 1:length(left_array_chs)
    k = find(r.FP.channels==left_array_chs(j));
    for i =1:length(release_time)
        if round(release_time(i))-tpre>0 && round(release_time(i))+tpost<MaxDur
            index_release = [round(release_time(i))-tpre:round(release_time(i))+tpost];
            if max(abs(r.FP.data{k}(index_release,2)))<1500
                left_release{j} = [left_release{j} r.FP.data{k}(index_release,2)];
            end;
        end;
        
        if round(press_time(i))-tpre>0 && round(press_time(i))+tpost<MaxDur
            index_press = [round(press_time(i))-tpre:round(press_time(i))+tpost];
            if max(abs(r.FP.data{k}(index_press,2)))<1500
                left_press{j} = [left_press{j} r.FP.data{k}(index_press,2)];
            end;
        end;
    end;
end;


for j = 1:length(right_array_chs)
    k = find(r.FP.channels==right_array_chs(j));
    for i =1:length(release_time)
        if round(release_time(i))-tpre>0 && round(release_time(i))+tpost<MaxDur
            index_release = [round(release_time(i))-tpre:round(release_time(i))+tpost];
            if max(abs(r.FP.data{k}(index_release,2)))<1500
                right_release{j} = [right_release{j} r.FP.data{k}(index_release,2)];
            end;
        end;
        
        if round(press_time(i))-tpre>0 && round(press_time(i))+tpost<MaxDur
            index_press = [round(press_time(i))-tpre:round(press_time(i))+tpost];
            if max(abs(r.FP.data{k}(index_press,2)))<1500
                right_press{j} = [right_press{j} r.FP.data{k}(index_press,2)];
            end;
        end;
    end;
end;


%% perform spectrum analysis
%   [S,t,f,Serr]=mtspecgramc(data,movingwin,params)
movingwin       =   [0.5 0.025];
params.tapers   =   [0.5*2 1];
params.pad      =   2;
params.Fs       =   1000;  % FP sampling rate is 1000
params.fpass    =   [0  100];
params.err      =   [2 0.05];
params.trialave =   1;

spec_press_left         = struct('S', [], 't', [], 'f', [], 'Serr', []);
spec_release_left       = struct('S', [], 't', [], 'f', [], 'Serr', []);

spec_press_right        = struct('S', [], 't', [], 'f', [], 'Serr', []);
spec_release_right      = struct('S', [], 't', [], 'f', [], 'Serr', []);

for i = 1:length(left_array_chs)
    
    spec_press_left(i)         = struct('S', [], 't', [], 'f', [], 'Serr', []);
spec_release_left(i)       = struct('S', [], 't', [], 'f', [], 'Serr', []);

    
    fp_press    = left_press{i};
    fp_release  = left_release{i};
    
    [ibad, jbad] = find(abs(fp_press)>2000);
    fp_press2=fp_press;
    fp_press2(:,  unique(jbad))=[];
    
    % calculate power spectrum
    
    tall = [1:size(fp_press2, 1)]/Fs;
    
    tbeg = 0;
    
    while tbeg+movingwin(1)<tall(end)
        
        data_signal = fp_press2(tall>tbeg & tall<=tbeg+movingwin(1), :);
        
        [p, f]=pspectrum(data_signal, Fs);
        
        spec_press_left(i).S=[spec_press_left(i).S mean(p, 2)];
        spec_press_left(i).f = f;
        spec_press_left(i).t = [spec_press_left(i).t mean([tbeg, tbeg+movingwin(1)])];
        
        tbeg = tbeg + movingwin(2);
        
    end;
    
    [ibad, jbad] = find(abs(fp_release)>2000);
    fp_release2=fp_release;
    fp_release2(:,  unique(jbad))=[];

    tbeg = 0;
    while tbeg+movingwin(1)<tall(end);
        
        data_signal = fp_release2(tall>tbeg & tall<=tbeg+movingwin(1), :);
        
        [p, f]=pspectrum(data_signal, Fs);
        
        spec_release_left(i).S=[spec_release_left(i).S mean(p, 2)];
        spec_release_left(i).f = f;
        spec_release_left(i).t = [spec_release_left(i).t mean([tbeg, tbeg+movingwin(1)])];
        
        tbeg = tbeg+movingwin(2);
        
    end;

end;


for i = 1:length(right_array_chs)
    
    spec_press_right(i)        = struct('S', [], 't', [], 'f', [], 'Serr', []);
spec_release_right(i)      = struct('S', [], 't', [], 'f', [], 'Serr', []);

    
    fp_press    = right_press{i};
    fp_release  = right_release{i};
    
    [ibad, jbad] = find(abs(fp_press)>2000);
    fp_press2=fp_press;
    fp_press2(:,  unique(jbad))=[];
    
    % calculate power spectrum
    
    tall = [1:size(fp_press2, 1)]/Fs;
    
    tbeg = 0;
    while tbeg+movingwin(1)<tall(end);
        
        data_signal = fp_press2(tall>tbeg & tall<=tbeg+movingwin(1), :);
        
        [p, f]=pspectrum(data_signal, Fs);
        
        spec_press_right(i).S=[spec_press_right(i).S mean(p, 2)];
        spec_press_right(i).f = f;
        spec_press_right(i).t = [spec_press_right(i).t mean([tbeg, tbeg+movingwin(1)])];
        
        tbeg = tbeg+movingwin(2);
        
    end;
    
    [ibad, jbad] = find(abs(fp_release)>2000);
    fp_release2=fp_release;
    fp_release2(:,  unique(jbad))=[];

    tbeg = 0;
    
    while tbeg+movingwin(1)<tall(end);
        
        data_signal = fp_release2(tall>tbeg & tall<=tbeg+movingwin(1), :);
        
        [p, f]=pspectrum(data_signal, Fs);
        
        spec_release_right(i).S=[spec_release_right(i).S mean(p, 2)];
        spec_release_right(i).f = f;
        spec_release_right(i).t = [spec_release_right(i).t mean([tbeg, tbeg+movingwin(1)])];
        
        tbeg = tbeg+movingwin(2);
        
    end;

end;


S_left_press=[];
S_left_release=[];
S_right_press=[];
S_right_release=[];


for i =1:length(spec_press_left)
    S_left_press(:,:,i) = spec_press_left(i).S;
end;

S_left_press=mean(S_left_press, 3);


for i =1:length(spec_release_left)
    S_left_release(:,:,i) = spec_release_left(i).S;
end;

S_left_release = mean(S_left_release, 3);

for i =1:length(spec_press_right)
    S_right_press(:,:,i) = spec_press_right(i).S;
end;
S_right_press=mean(S_right_press, 3);

for i =1:length(spec_release_right)
    S_right_release(:,:,i) = spec_release_right(i).S;
end;
S_right_release=mean(S_right_release, 3);


%% plot spectrum with a moving window
figure(23); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 25], 'paperpositionmode', 'auto' )

ha1=subplot(3, 2,1);
set(ha1, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
indexf =  find(spec_press_left(1).f>0 & spec_press_left(1).f<40);
imagesc(spec_press_left(1).t-1, spec_press_left(1).f(indexf), log(S_left_press(indexf, :)))

xlabel ('Time-Left Press(s)')
ylabel ('Freq(Hz)')

ha2=subplot(3, 2, 2);
set(ha2, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_release_left(1).t-1, spec_release_left(1).f(indexf), log(S_left_release(indexf, :)))

xlabel ('Time-Left Release(s)')
ylabel ('Freq(Hz)')

ha3=subplot(3, 2,3);
set(ha3, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_press_right(1).t-1, spec_press_right(1).f(indexf), log(S_right_press(indexf, :)))

xlabel ('Time-Right Press(s)')
ylabel ('Freq(Hz)')

ha4=subplot(3, 2, 4);
set(ha4, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_release_right(1).t-1, spec_release_right(1).f(indexf), log(S_right_release(indexf, :)))

xlabel ('Time-Right Release(s)')
ylabel ('Freq(Hz)')

trange_prepress = [-0.8 -0.3];
trange_postpress = [0 0.5];

index_prepress      = find(spec_press_left(1).t-1>=trange_prepress(1) & spec_press_left(1).t-1<=trange_prepress(2));
index_postpress     = find(spec_press_left(1).t-1>=trange_postpress(1) & spec_press_left(1).t-1<=trange_postpress(2));;
index_prerelease    = index_prepress;
index_postrelease   = index_postpress;

ha5=subplot(3, 2,5);
set(ha5, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [1 40], 'ylim', [5 50000],'yscale', 'log');

plot(spec_release_right(1).f, mean(S_left_press(:, index_prepress), 2), 'r-', 'linewidth', 1)
plot(spec_release_right(1).f, mean(S_right_press(:, index_prepress), 2), 'b-', 'linewidth', 1)

plot(spec_release_right(1).f, mean(S_left_press(:, index_postpress), 2), 'r-', 'linewidth', 2)
plot(spec_release_right(1).f, mean(S_right_press(:, index_postpress), 2), 'b-', 'linewidth', 2)

title('Pre - and post : press')

ha6=subplot(3, 2,6);
set(ha6, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [1 40], 'ylim', [5 50000],'yscale', 'log');

plot(spec_release_right(1).f, mean(S_left_release(:, index_prerelease), 2), 'r-', 'linewidth', 1)
plot(spec_release_right(1).f, mean(S_right_release(:, index_prerelease),2), 'b-', 'linewidth', 1)

plot(spec_release_right(1).f, mean(S_left_release(:, index_postrelease), 2), 'r-', 'linewidth', 2)
plot(spec_release_right(1).f, mean(S_right_release(:, index_postrelease), 2), 'b-', 'linewidth', 2)

title('Pre - and post : release')

%% plot spectrum with a moving window
S_press = [S_left_press; S_right_press];

S_release = [S_left_release; S_right_release];

S=[S_press; S_release];

maxS =1.1*max(log(max(S(:))));
%
% %% plot spectrum with a moving window
figure(26); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 20 20], 'paperpositionmode', 'auto' )

ha1=subplot(3,2,1);
set(ha1, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_press_left(1).t-1, spec_press_left(1).f(indexf), (log(S_left_press(indexf, :))), log([100 500000]))
%
xlabel ('Time-Left Press(s)')
ylabel ('Freq(Hz)')

ha2=subplot(3, 2, 2);
set(ha2, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_release_left(1).t-1, spec_release_left(1).f(indexf), (log(S_left_release(indexf, :))), log([100 500000]))

xlabel ('Time-Left Release(s)')
ylabel ('Freq(Hz)')

ha3=subplot(3,2,3);
set(ha3, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_press_right(1).t-1, spec_press_right(1).f(indexf), (log(S_right_press(indexf, :))), log([100 500000]))

xlabel ('Time-Right Press(s)')
ylabel ('Freq(Hz)')

ha4=subplot(3, 2, 4);
set(ha4, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 40]);
imagesc(spec_release_right(1).t-1, spec_release_right(1).f(indexf), (log(S_right_release(indexf, :))), log([100 500000]))

xlabel ('Time-Right Release(s)')
ylabel ('Freq(Hz)')

% 
ha5=subplot(3, 2,5);
set(ha5, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [1 40], 'ylim', [100 500000],'yscale', 'log');

plot(spec_release_right(1).f, mean(S_left_press(:, index_prepress), 2), 'r-', 'linewidth', 1)
plot(spec_release_right(1).f, mean(S_right_press(:, index_prepress), 2), 'b-', 'linewidth', 1)

plot(spec_release_right(1).f, mean(S_left_press(:, index_postpress), 2), 'r-', 'linewidth', 2)
plot(spec_release_right(1).f, mean(S_right_press(:, index_postpress), 2), 'b-', 'linewidth', 2)

legend('preL','preR','postL','postR');
title('Press')
xlabel('Freq (Hz)')
ylabel ('Power')

ha6=subplot(3, 2,6);
set(ha6, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [1 40], 'ylim', [100 500000],'yscale', 'log');

plot(spec_release_right(1).f, mean(S_left_release(:, index_prerelease), 2), 'r-', 'linewidth', 1)
plot(spec_release_right(1).f, mean(S_right_release(:, index_prerelease),2), 'b-', 'linewidth', 1)

plot(spec_release_right(1).f, mean(S_left_release(:, index_postrelease), 2), 'r-', 'linewidth', 2)
plot(spec_release_right(1).f, mean(S_right_release(:, index_postrelease), 2), 'b-', 'linewidth', 2)


legend('preL','preR','postL','postR');
title('Release')
xlabel('Freq (Hz)')
ylabel ('Power')
print (26,'-dpng', ['PowerSpec_LvsR2'])


