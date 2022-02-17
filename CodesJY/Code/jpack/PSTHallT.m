function PSTHallT(T, bad_trials, contacts)

if nargin<3
    contacts=[];
end;

Fs=10000;
allcolors{1}=[253 158 0]/255;
allcolors{2}=[10 172 189]/255;
allcolors{3}=[170 85 0]/255;
 
hit_col=[85 200 0]/255;
cr_col=[0 85 255]/255;
fa_col=[255 0 0]/255;
miss_col=[150 150 150]/255;



allcolors{1}=[255 85 128]/255;
allcolors{2}=[10 172 189]/255;



selected_trials=setdiff(T.trialNums, [T.stimtrialNums bad_trials]);

hittrials=      intersect(setdiff(selected_trials, T.stimtrialNums), [T.hitTrialNums T.missTrialNums]);
crtrials=       intersect(setdiff(selected_trials, T.stimtrialNums), [T.correctRejectionTrialNums T.falseAlarmTrialNums]);

[~, hit_index]= intersect(T.trialNums, hittrials);
[~, cr_index]=  intersect(T.trialNums, crtrials);

hit_spkmat=constructspkmat(T, hit_index);
cr_spkmat=constructspkmat(T, cr_index);

t=T.trials{5}.spikesTrial.time;

hit_spkmat=hit_spkmat(t<=5, :);
cr_spkmat=cr_spkmat(t<=5, :);

[psth_hit, thist]=  spikehisto(hit_spkmat, Fs, 5/0.05);
[psth_cr, thist]=   spikehisto(cr_spkmat, Fs, 5/0.05);

pole_on=median(cellfun(@(x)x.behavTrial.pinDescentOnsetTime, T.trials([hit_index; cr_index])));
pole_off=mean(cellfun(@(x)x.behavTrial.pinAscentOnsetTime, T.trials([hit_index; cr_index])));
pole_offstd=std(pole_off);


if ~isempty(contacts)
    mainwid=T.trials{hit_index(1)}.whiskerTrial.trajectoryIDs;
else
    mainwid=[];
end;
hf=figure;

set(hf, 'units', 'centimeters',...
    'position', [2 2 10 15], ...
    'paperpositionmode', 'auto', 'color', 'w');

ha0=subplot(3, 1, [1 2]);
set(ha0, 'nextplot', 'add', 'xlim', [0 5], 'ylim', [0 length([hit_index; cr_index])+1], 'ytick', [0:50:500])
title([strrep(T.cellNum, '_', '-')])

ylabel('Trials')

trialgap=1;
ntrial=0;

touchmat=[];
twhisker0=[0:0.001:5];

touchmat_hit=zeros(length(twhisker0), length(hit_index));
touchmat_cr=zeros(length(twhisker0), length(cr_index));

for i=1:length(hit_index)
    ntrial=ntrial+1;
    i_spike_times=T.trials{hit_index(i)}.spikesTrial.spikeTimes;
    
    if ~isempty(mainwid)
        for j=1:length(mainwid)
            indwid=find(T.trials{hit_index(i)}.whiskerTrial.trajectoryIDs==mainwid(j));
            twhisker=T.trials{hit_index(i)}.whiskerTrial.time{indwid};
            
            icontact=contacts{hit_index(i)};
            
            if ~isempty(icontact.segmentInds{indwid})
                touchons=twhisker(icontact.segmentInds{indwid}(:, 1)); % touch on
                touchoffs=twhisker(icontact.segmentInds{indwid}(:, 2)); % touch on
                %                 s=plot(touchons, (ntrial-1)*trialgap+1+.75/2, 'square', 'markersize', 3, 'color', 'none', 'markerfacecolor', allcolors{j});
                s=scatter(touchons,((ntrial-1)*trialgap+1+.75/2)*ones(1, length(touchons)), 5, 'markerfacecolor', allcolors{j}, 'markeredgecolor','none');
                alpha(s, .5)
                
                for k=1:length(touchons)
                    hfill=fill([touchons(k), touchoffs(k) touchoffs(k) touchons(k)],...
                        [(ntrial-1)*trialgap+.8 (ntrial-1)*trialgap+.8 (ntrial-1)*trialgap+1.95 (ntrial-1)*trialgap+1.95], allcolors{j});
                    set(hfill, 'edgecolor', 'none', 'facealpha', .5);
                    touchmat_hit(twhisker0>=touchons(k)&twhisker0<=touchoffs(k), i)=1;
                end;
                
            end;
        end;
    end;
    
    if ~isempty(i_spike_times)
        nspks=length(i_spike_times);
        
        xx=ones(3*nspks, 1)*nan;
        yy=ones(3*nspks, 1)*nan;
        
        xx(1:3:3*nspks)=i_spike_times;
        
        xx(2:3:3*nspks)=xx(1:3:3*nspks);
        
        yy(1:3:3*nspks)=(ntrial-1)*trialgap+1;
        yy(2:3:3*nspks)= yy(1:3:3*nspks)+0.75;
        
        plot(xx, yy, 'color', 'k', 'linewidth', 2);
        
    end;
end;

for i=1:length(cr_index)
    ntrial=ntrial+1;
       i_spike_times=T.trials{cr_index(i)}.spikesTrial.spikeTimes;

    
    if ~isempty(mainwid)
        for j=1:length(mainwid)
            indwid=find(T.trials{cr_index(i)}.whiskerTrial.trajectoryIDs==mainwid(j));
            twhisker=T.trials{cr_index(i)}.whiskerTrial.time{indwid};
             icontact=contacts{cr_index(i)};
            
            if ~isempty(icontact.segmentInds{indwid})
                touchons=twhisker(icontact.segmentInds{indwid}(:, 1)); % touch on
                touchoffs=twhisker(icontact.segmentInds{indwid}(:, 2)); % touch on
                s=scatter(touchons,((ntrial-1)*trialgap+1+.75/2)*ones(1, length(touchons)), 5, 'markerfacecolor', allcolors{j}, 'markeredgecolor','none');
                alpha(s, .5)
                for k=1:length(touchons)
                    hfill=fill([touchons(k), touchoffs(k) touchoffs(k) touchons(k)],...
                        [(ntrial-1)*trialgap+.8 (ntrial-1)*trialgap+.8 (ntrial-1)*trialgap+1.95 (ntrial-1)*trialgap+1.95], allcolors{j});
                    set(hfill, 'edgecolor', 'none', 'facealpha', .5);
                    touchmat_cr(twhisker0>=touchons(k)&twhisker0<=touchoffs(k), i)=1;
                end;
                
            end;
        end;
    end;
    if ~isempty(i_spike_times)
        nspks=length(i_spike_times);
        
        xx=ones(3*nspks, 1)*nan;
        yy=ones(3*nspks, 1)*nan;
        
        xx(1:3:3*nspks)=i_spike_times;
        
        xx(2:3:3*nspks)=xx(1:3:3*nspks);
        
        yy(1:3:3*nspks)=(ntrial-1)*trialgap+1;
        yy(2:3:3*nspks)= yy(1:3:3*nspks)+0.75;
        
        plot(xx, yy, 'color', 'b', 'linewidth', 2);
        
    end;
end;



ha=subplot(3, 1, 3);
set(ha, 'nextplot', 'add', 'xlim', [0 5])
title([T.cellNum T.cellCode])
plot(thist, psth_hit, 'k', 'linewidth', 2)
plot(thist, psth_cr, 'b', 'linewidth',2 )

legend('Hit', 'CR')

line([pole_on pole_on], [0 max(get(gca, 'ylim'))], 'linewidth', 1, 'color', [.7 .7 .7])
line([pole_on pole_on]+0.4, [0 max(get(gca, 'ylim'))], 'linewidth', 1, 'color', 'k')
line([pole_off pole_off], [0 max(get(gca, 'ylim'))], 'linewidth', 1, 'color', [.7 .7 .7])

xlabel ('Time (s)')
ylabel ('Spk / s')

if ~isempty(mainwid)
    for i=1:length(mainwid)
    hu=uicontrol('Parent', hf, 'Style', 'text','String',['whisker#' num2str(mainwid(i))],'BackgroundColor', [1 1 1],  'units', 'normalized',...
        'position', [0.75, 0.93+(i-1)*0.025, 0.2, 0.025], 'ForegroundColor', allcolors{i});
    end;
end;


saveas(hf, ['PSTH_all'], 'fig')
print (hf,'-dpng', ['PSTH_all'])


function spkmat=constructspkmat(T, trial_index)
spkmat=sparse([], [], [], length(T.trials{1}.spikesTrial.rawSignal), length(trial_index));
for i=1:length(trial_index)
    [~, spk_index]=intersect(T.trials{trial_index(i)}.spikesTrial.time, T.trials{trial_index(i)}.spikesTrial.spikeTimes);
    spkmat(spk_index, i)=1;
end;

