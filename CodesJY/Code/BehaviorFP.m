function BehaviorFP(r, ch)

% read r array

figure(23); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 15], 'paperpositionmode', 'auto' )

chindex = find(r.FP.channels==ch);

release_time = r.Behavior.Onset{2};
press_time = r.Behavior.Onset{end};

tpre = 1000;
tpost = 1000;
MaxDur = max(r.FP.data{chindex}(:, 1));

fp_release = [];
fp_press = [];

for i =1:length(release_time)
    
    
    if round(release_time(i))-tpre>0 && round(release_time(i))+tpost<MaxDur
        index_release = [round(release_time(i))-tpre:round(release_time(i))+tpost];
        fp_release = [fp_release r.FP.data{chindex}(index_release,2)];
    end;
    
    if round(press_time(i))-tpre>0 && round(press_time(i))+tpost<MaxDur
        index_press = [round(press_time(i))-tpre:round(press_time(i))+tpost];
        fp_press = [fp_press r.FP.data{chindex}(index_press,2)];
    end;
end;

%% perform spectrum analysis
%   [S,t,f,Serr]=mtspecgramc(data,movingwin,params)
% movingwin       =   [0.25 0.02];
% params.tapers   =   [0.25*4 1];
% params.pad      =   2;
% params.Fs       =   1000;  % FP sampling rate is 1000
% params.fpass    =   [0  100];
% params.err      =   [2 0.05];
% params.trialave =   1;

movingwin       =   [0.5 0.025];
params.tapers   =   [0.5*2.5 1];
params.pad      =   2;
params.Fs       =   1000;  % FP sampling rate is 1000
params.fpass    =   [0  100];
params.err      =   [2 0.05];
params.trialave =   1;


[ibad, jbad] = find(abs(fp_press)>2000);
fp_press2=fp_press;
fp_press2(:,  unique(jbad))=[];
[spec_press.S, spec_press.t, spec_press.f, spec_press.Serr]         = mtspecgramc(fp_press2, movingwin, params);
[ibad, jbad] = find(abs(fp_release)>2000);
fp_release2=fp_release;
fp_release2(:,  unique(jbad))=[];
[spec_release.S, spec_release.t, spec_release.f, spec_release.Serr] = mtspecgramc(fp_release2, movingwin, params);

fp_badpress = [];
fp_badrelease = [];

[badpress_time, ibad] = setdiff(r.Behavior.Onset{5}, r.Behavior.Onset{6});
badrelease_time = r.Behavior.Offset{5}(ibad);

for i =1:length(badpress_time)
    
    if round(badpress_time(i))-tpre>0 && round(badpress_time(i))+tpost<MaxDur
        index_press = [round(badpress_time(i))-tpre:round(badpress_time(i))+tpost];
        if isempty(find(abs(r.FP.data{chindex}(index_press,2))>2000));
            fp_badpress = [fp_badpress r.FP.data{chindex}(index_press,2)];
        end;
    end;
    
    if round(badrelease_time(i))-tpre>0 && round(badrelease_time(i))+tpost<MaxDur
        index_release = [round(badrelease_time(i))-tpre:round(badrelease_time(i))+tpost];
        if isempty(find(abs(r.FP.data{chindex}(index_release,2))>2000))
            fp_badrelease = [fp_badrelease r.FP.data{chindex}(index_release,2)];
        end;
    end;
end;


figure(23)
[b, a]=butter(2, [1 40]*2/1000, 'bandpass');

ha=subplot(2, 2, 1);
set(ha, 'xlim', [-tpre tpost], 'ylim', [0 5000], 'nextplot', 'add')
for i =1:size(fp_press2, 2)
    plot([-tpre : tpost]/1000, filtfilt(b, a, fp_press2(:, i))/3+i*100)
end;
axis tight;

ha2=subplot(2, 2, 2);
set(ha2, 'xlim', [-tpre tpost], 'ylim', [0 5000], 'nextplot', 'add')
for i =1:size(fp_release2, 2)
    plot([-tpre : tpost]/1000, filtfilt(b, a, fp_release2(:, i))/3+i*100)
end;
axis tight


figure(25); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )

ha=subplot(1, 2, 2);
set(ha, 'xlim', [-tpre tpost], 'ylim', [0 5000], 'nextplot', 'add')
for i =1:size(fp_badrelease, 2)
    plot([-tpre : tpost], fp_badrelease(:, i)/4+i*100)
end;
axis tight

ha2=subplot(1, 2, 1);
set(ha2, 'xlim', [-tpre tpost], 'ylim', [0 5000], 'nextplot', 'add')
for i =1:size(fp_badrelease, 2)
    plot([-tpre : tpost], fp_badpress(:, i)/4+i*100)
end;
axis tight


figure(24); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 12 12], 'paperpositionmode', 'auto' )

ha=subplot(2, 1, 2);
set(ha, 'xlim', [-tpre tpost], 'ylim', [-1000 1000], 'nextplot', 'add');

plot([-tpre : tpost], mean(fp_release2, 2))
hold on
plot([-tpre : tpost], mean(fp_badrelease, 2), 'r')
xlabel ('Time (ms)')
 
title('Release')

ha2=subplot(2, 1, 1);
set(ha2, 'xlim', [-tpre tpost], 'ylim', [-1000 1000], 'nextplot', 'add');
plot([-tpre : tpost], mean(fp_press2, 2))
hold on
plot([-tpre : tpost], mean(fp_badpress, 2), 'r')
title('Press')
xlabel ('Time (ms)')

%% plot spectrum with a moving window
figure(23);

ha1=subplot(2,2,3);
set(ha1, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 80]);
imagesc(spec_press.t-1, spec_press.f, log(spec_press.S'), log([5 30000]))

xlabel ('Time-Press(s)')
ylabel ('Freq(Hz)')

ha2=subplot(2, 2, 4);
set(ha2, 'nextplot', 'add', 'ydir', 'normal', 'xlim', [-.8 .8], 'ylim', [0 80]);
imagesc(spec_release.t-1, spec_release.f, log(spec_release.S'), log([5 30000]))

xlabel ('Time-Press(s)')
ylabel ('Freq(Hz)')

