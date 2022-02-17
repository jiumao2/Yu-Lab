function spkout=spikewaveform(T, spikes, varargin)
% use endpulse.m to determine the electrode resistance. 
cfolder=pwd;

% this program is to analyze the spike waveform from data structure T
[b, a]=butter(2, 300*2/10000, 'high');
tspk=[-50:100]/100; % in ms

peak2trough=[]; % peak to trough ratio
width=[];

if nargin==1
    
    % basic infos
    spikes.cellNum=T.cellNum;
    spikes.cellCode=T.cellCode;
    spikes.mouseName=T.mouseName;
    spikes.sessionName=T.sessionName;
    spikes.depth=T.depth;
    
    spikes.trialnums=[]; % this is more trial index.
    spikes.time=[];
    spikes.waves=[];
    spikes.projs=[];
    spikes.choose=[];
    spikes.pcdraw=[];
    
    ntrials=length(T.trials);
    for i=1:ntrials
        vm=T.trials{i}.spikesTrial.rawSignal;
        vm=filtfilt(b, a, detrend(vm));
        vm_rs=resample(vm, 10, 1);
        
        tvm=[0:length(vm)-1]/10;
        tvm_rs=[0:length(vm_rs)-1]/100; % still in ms
        
        tspikes=T.trials{i}.spikesTrial.spikeTimes;
        
        if tspikes~=0
            for k=1:length(tspikes)
                if tspikes(k)>5 && tspikes(k)+15<50000
                    
                    ispike=vm(tspikes(k)-5:tspikes(k)+15);
                    itspike=tvm(tspikes(k)-5:tspikes(k)+15);
                    
                    ispike_rs=vm_rs(tvm_rs>=min(itspike) & tvm_rs<=max(itspike)); % resample spikes, now 100k
                    itspike_rs=tvm_rs(tvm_rs>=min(itspike) & tvm_rs<=max(itspike));
                    ispike_rs=ispike_rs-mean(ispike_rs(1:5));
                    
                    [~, imax]=max(ispike_rs);
                    tmax=itspike_rs(imax);
                    
                    ind_max=find(tvm_rs==tmax); % link the peak to the whole trace.
                    
                    %                     [~, imin]=min(ispike_rs);
                    
                    %                     peak2trough=[peak2trough abs(imax)/abs(imin)];
                    %                     width=[width abs(imax-imin)/100]; % in ms
                    
                    if ind_max>50 && ind_max+100<length(vm_rs)
                        
                        ispike_new=vm_rs(ind_max-50:ind_max+100)-mean(vm_rs(ind_max-50:ind_max-40));
                        
                    end;
                    
                    spikes.trialnums=[spikes.trialnums i];
                    spikes.tspk=tspk;
                    spikes.time=[spikes.time tvm(tspikes(k))];
                    spikes.waves=[spikes.waves; ispike_new'];
                end;
            end;
        end;
    end;
    
    
end;


for j = 1:length(varargin);
    argString = varargin{j};
    switch argString
        
        case 'delete'
            
            datacursormode on
            
            [pc1, pc2]=ginput;
            
            % draw this polygon
            pc1draw=[pc1; pc1(1)];
            pc2draw=[pc2; pc2(1)];
            
            plot(pc1draw, pc2draw, 'color', 'r');
            
            todel=[];
            
            for ik=1:size(spikes.waves, 1)
                insidepoly=inpolygon(spikes.tspk, spikes.waves(ik, :), pc1draw, pc2draw);
                if ~isempty(find(insidepoly))
                    todel=[todel ik];
                end;
            end;
            
            if ~isempty(todel)
                todel=unique(todel);
                spikes.trialnums(todel)=[];
                spikes.time(todel)=[];
                spikes.waves(todel, :)=[];
            end;
            
        case 'choose'
            
            datacursormode on
            [pc1, pc2]=ginput
            
            % draw this polygon
            pc1draw=[pc1; pc1(1)];
            pc2draw=[pc2; pc2(1)];
            
            indpoly=inpolygon(spikes.projs(:, 1), spikes.projs(:, 2), pc1draw, pc2draw);
            spikes.choose=indpoly;
            spikes.pcdraw=[pc1draw pc2draw];
            plot(pc1draw, pc2draw, 'color', 'c')
            
        case 'save'
            
            assignin('base','spikes',spikes);
            display('Saving spikes......')
            save('spikes', 'spikes')
            print(gcf, '-dtiff', '-r500', 'spike_waveform');
            print(gcf, '-dpdf', '-r500', 'spike_waveform');
            saveas(gcf, 'spike_waveform', 'fig')
            display('Saving completed')
            
        case 'output'
            
            cfolder=pwd;
            
            cd ('C:\Users\yuj10\Dropbox (Personal)\Work\Experiment_results')
            load('allspikes.mat')
            
            if ismember(spikes.cellNum, allspikes(:, 1)) % there is a registry for this cell already
                
                icell=find(ismember(allspikes(:, 1), spikes.cellNum));
                allspikes{icell, 2}=spikes.depth;
                allspikes{icell, 3}=spikes.avgwidth;
                allspikes{icell, 4}=spikes.avgPeaktoTrough;
            else
                icell=size(allspikes, 1)+1;
                allspikes{icell, 1}=spikes.cellNum;
                allspikes{icell, 2}=spikes.depth;
                allspikes{icell, 3}=spikes.avgwidth;
                allspikes{icell, 4}=spikes.avgPeaktoTrough;
            end;
            
            allspikes
            size(allspikes, 1)
            
            save allspikes allspikes
            
            load('allspikes2.mat')
            
            if ismember(spikes.cellNum, allspikes2(:, 1)) % there is a registry for this cell already
                
                icell=find(ismember(allspikes2(:, 1), spikes.cellNum));
                allspikes2{icell, 2}=spikes.depth;
                allspikes2{icell, 3}=spikes.avgwidth;
                allspikes2{icell, 4}=spikes.avgPeaktoTrough;
                
                re = input('Give the increase of resistance: ');
                
                if ~isempty(re)
                    allspikes2{icell, 5}=re;
                end;
            else
                icell=size(allspikes2, 1)+1;
                allspikes2{icell, 1}=spikes.cellNum;
                allspikes2{icell, 2}=spikes.depth;
                allspikes2{icell, 3}=spikes.avgwidth;
                allspikes2{icell, 4}=spikes.avgPeaktoTrough;
                re = input('Give the increase of resistance: ');
                allspikes2{icell, 5}=re;
            end;
            
            allspikes2
            size(allspikes2, 1)
            
            save allspikes2 allspikes2
            
            hf=figure;
            set(hf, 'units', 'centimeters', 'position', [5 2 9 16])
            
            ha1=subplot(2, 1, 1);
            plot(cell2mat(allspikes(:, 3)), log(cell2mat(allspikes(:, 4))), 'ko');
            xlabel('Duration (ms)')
            ylabel('Peak to trough ratio, log')
                      
            ha2=subplot(2, 1, 2);
            xlim=get(ha1, 'xlim'); ylim=get(ha1, 'ylim');
            [pcounts, pcenters]=hist3([cell2mat(allspikes(:, 3)), log(cell2mat(allspikes(:, 4)))], 'edges', {linspace(xlim(1),xlim(2), 50) linspace(ylim(1),ylim(2), 50)});
            imagesc(pcenters{1}, pcenters{2}, pcounts');
            set(gca, 'xlim', xlim, 'ylim',ylim, 'ydir','normal')
                       % directly write a m-file to save spike informations.
            %                 function x=allspikes
            %                 x={'cellname' 'depth' 'duration' 'peak to trough ratio'};
            
            desdir= 'C:\Users\yuj10\Dropbox (Personal)\Work\Experiment_results';
            
            filename='allspikeout';
            
            file2save=[desdir '/' filename, '.m'];
            fileid=fopen(file2save, 'a'); % 'w' here ensure the old content is discarded.
            
            
            % now start to write something into this program
            % allspikes(size(allspikes, 1)+1, :)={'JYxxx' depth duration peal};
            % x(size(x, 1)+1, :)=
            
            fprintf(fileid, '\n%s', ['x(size(x, 1)+1, :)=' '{''' ]);
            fprintf(fileid, '%s', spikes.cellNum);
            fprintf(fileid, '%s ', '''');
            fprintf(fileid, '%f  ', [spikes.depth]);
            fprintf(fileid, '%f  ', [spikes.avgwidth]);
            fprintf(fileid, '%f  ', [spikes.avgPeaktoTrough]);
            
            fprintf(fileid, '%s\n', '};');
            %
            % fprintf(fileid, '%s\n', 'x.f=[');
            % fprintf(fileid, '%f\n', f);
            % fprintf(fileid, '%s\n', '];'); % now f is successfully writen to the output x;
            %
            % fprintf(fileid, '%s\n', 'x.S_blank1=[');
            % fprintf(fileid, '%f\n', Sb1);
            % fprintf(fileid, '%s\n', '];');
            
            fclose(fileid);
            
            
            cd (cfolder)
            
            
    end;
    
end;


% all spikes contain spikes waveform (3:143); trial number is 1, spike time is 2
waveformsall=spikes.waves;
% plot spikes for sorting and supervision.

projs=pcasvd(waveformsall);

spikes.projs=projs;

handles.projs=projs;
handles.spikes=spikes;

handles.hf2=figure(10); clf;

set(10, 'units', 'centimeters',...
    'position', [4 4 20 15 ], ...
    'name', 'Spike waveform analysis',  'toolbar', 'figure', 'paperpositionmode', 'auto', 'color', 'w');

handles.ha1=axes;
set(handles.ha1, 'units','normalized', 'position', [.075 .55 .25 .35], 'nextplot','add','tickdir','out');

plot(projs(:, 1), projs(:, 2), 'ko', 'markersize', 2, 'markerfacecolor','none', 'markeredgecolor', 'k'); axis tight

if ~isempty(spikes.choose)
    
    plot(projs(spikes.choose, 1), projs(spikes.choose, 2), 'co', 'markersize', 2);
    
end;

grid on
xlabel('PC 1');
ylabel('PC2');
xlim1=get(handles.ha1,'xlim');
ylim1=get(handles.ha1, 'ylim');

handles.ha2=axes;
set(handles.ha2, 'units','normalized', 'position', [.075 .075, .25 .35],'nextplot', 'add', 'ydir', 'normal','tickdir','out');
[pcounts, pcenters]=hist3(projs(:, [1 2]), 'edges', {linspace(xlim1(1),xlim1(2), 50) linspace(ylim1(1),ylim1(2), 50)});
imagesc(pcenters{1}, pcenters{2}, pcounts');

if ~isempty(spikes.choose)
    plot(spikes.pcdraw(:, 1), spikes.pcdraw(:, 2),'c', 'linewidth', 2);
end;

set(gca, 'xlim', xlim1, 'ylim',ylim1)


handles.ha3=axes;
set(handles.ha3, 'units','normalized', 'position', [.4 .55 .25 .35], 'nextplot', 'add', 'tickdir','out', 'xgrid','on', 'ygrid', 'on');
xlabel('Time(ms)');
ylabel('Voltage')

axes(handles.ha3)

spikes.waveplots=plot(tspk, waveformsall, 'color', [.75 .75 .75], 'linewidth', .5); % this handle determine the spike index too.
plot(tspk, mean(waveformsall, 1), 'color', 'k', 'linewidth', 2);

if ~isempty(spikes.choose)
    
    plot(tspk, waveformsall(spikes.choose, :), 'c', 'linewidth', .5);
    plot(tspk, mean(waveformsall(spikes.choose, :), 1), 'color', [0 159 255]/255, 'linewidth', 2);
    
end;

line([-0.5 1], [0 0], 'linewidth', 1, 'linestyle', ':', 'color', 'k');

axis tight

% the fourth axis, plot all the spike raster data
handles.ha4=axes;
set(handles.ha4, 'units', 'normalized', 'position', [.4 .075 .25 .35], 'nextplot', 'add', 'tickdir', 'out',...
    'ylim', [0 max(spikes.trialnums)+1], 'xlim', [0 5000]); % x is ms

axes(handles.ha4);
trialgap=1;

ISI=[];

spiketrials=spikes.trialnums; % trials that have spikes.
spiketrialnums=unique(spiketrials);

for i=1:length(spiketrialnums)
    
    ind_spikes=find(spiketrials==spiketrialnums(i));
    spike_times_i=spikes.time(ind_spikes);
    
    nspks=length(spike_times_i);
    if nspks>2
        ISI=[ISI; diff(spike_times_i')];
    end;
    
    xx=ones(3*nspks, 1)*nan;
    yy=ones(3*nspks, 1)*nan;
    
    xx(1:3:3*nspks)=spike_times_i;
    
    xx(2:3:3*nspks)=xx(1:3:3*nspks);
    
    yy(1:3:3*nspks)=(spiketrialnums(i)-1)*trialgap+1;
    yy(2:3:3*nspks)= yy(1:3:3*nspks)+0.75;
    
    plot(xx, yy, 'color', 'k', 'linewidth', 2);
    
    
    if ~isempty(spikes.choose)
        
        ind_spikes=find(spiketrials==spiketrialnums(i) & spikes.choose'==1);
        
        spike_times_i=spikes.time(ind_spikes);
        
        nspks=length(spike_times_i);
        
        xx=ones(3*nspks, 1)*nan;
        yy=ones(3*nspks, 1)*nan;
        
        xx(1:3:3*nspks)=spike_times_i;
        
        xx(2:3:3*nspks)=xx(1:3:3*nspks);
        
        yy(1:3:3*nspks)=(spiketrialnums(i)-1)*trialgap+1;
        yy(2:3:3*nspks)= yy(1:3:3*nspks)+0.75;
        
        plot(xx, yy, 'color', 'c', 'linewidth', 2);
        
    end;
    
    
end;
xlabel('Time(ms)');
ylabel('Trials');

handles.ha5=axes;
set(handles.ha5, 'units', 'normalized', 'position', [.72 .55 .25 .35],'xlim', [0 50], 'nextplot', 'add', 'tickdir', 'out', 'xgrid', 'on', 'ygrid', 'on');
xlabel('ISI(ms)')
ylabel('Count')

if ~isempty(ISI)
    [NISI, bins]=hist(ISI, [0:1:100]);
    axes(handles.ha5);
    hb=bar(bins, NISI);
    set(hb, 'edgecolor', 'k', 'facecolor', 'none');
end;

handles.ha6=axes; % this is to plot peak-to-trough duration and ratio

set(handles.ha6, 'units', 'normalized', 'position', [.72 .075 .25 .35], 'nextplot', 'add', 'tickdir', 'out', 'xgrid', 'on', 'ygrid', 'on');
xlabel('Duration(ms)')
ylabel('Peak-to-trough')

[peaks, indmax]=max(spikes.waves');
indmin=zeros(size(indmax));
troughs=zeros(size(peaks));
for i=1:length(indmax)
    [troughs(i), ~]=min(spikes.waves(i, indmax(i):end));
    indmin(i)=find(spikes.waves(i, :)==troughs(i));
end;

spikes.peak2trough=abs(peaks)./abs(troughs); % peak to trough ratio
spikes.width=spikes.tspk(indmin)-spikes.tspk(indmax);

plot(spikes.width, spikes.peak2trough, 'ko', 'markersize', 2)
plot(median(spikes.width), median(spikes.peak2trough), 'ro', 'linewidth', 2)

spikes.avgwidth=median(spikes.width);
spikes.avgPeaktoTrough=median(spikes.peak2trough);

if ~isempty(spikes.choose)
    
    plot(spikes.width(spikes.choose), spikes.peak2trough(spikes.choose), 'co', 'markersize', 2)
    plot(median(spikes.width(spikes.choose)), median(spikes.peak2trough(spikes.choose)), 'ro', 'linewidth', 2, 'markerfacecolor', 'c')
    
    spikes.avgwidth=median(spikes.width(spikes.choose));
    spikes.avgPeaktoTrough=median(spikes.peak2trough(spikes.choose));
end;

set(handles.ha6, 'xlim', prctile(spikes.width,[.5 99.5]), 'ylim',prctile(spikes.peak2trough,[.5 99.5]))

% write down sth for information


uicontrol(handles.hf2, 'style', 'text', 'units', 'normalized', 'position', [.4, .95, .2, .03], ...
    'string',[spikes.cellNum spikes.cellCode], 'fontsize', 10, 'backgroundcolor', 'w');

uicontrol(handles.hf2, 'style', 'text', 'units', 'normalized', 'position', [.4, .92, .2, .03], ...
    'string',[spikes.mouseName '-' spikes.sessionName], 'fontsize', 10,  'backgroundcolor', 'w');

uicontrol(handles.hf2, 'style', 'text', 'units', 'normalized', 'position', [.63, .92, .1, .03], ...
    'string',[num2str(spikes.depth) 'um'], 'fontsize', 10,  'backgroundcolor','w');

uicontrol(handles.hf2, 'style', 'text', 'units', 'normalized', 'position', [.72, .92, .2, .03], ...
    'string',['width: ' sprintf('%1.2f', spikes.avgwidth)], 'fontsize', 10,  'backgroundcolor','w');

uicontrol(handles.hf2, 'style', 'text', 'units', 'normalized', 'position', [.72, .95, .2, .03], ...
    'string',['PtoT: ' sprintf('%1.2f', spikes.avgPeaktoTrough)], 'fontsize', 10,  'backgroundcolor','w');



ht = uitoolbar(handles.hf2);
h_b=brush(handles.hf2);
set(h_b,'Color',[1 0 1]);

folder='C:\Users\yuj10\Dropbox (Personal)\Work\code\icons';
cd (folder)
icon_del   = imread('delete.tif');

dbutton = uipushtool(ht,'CData',icon_del,'TooltipString','Delete Spikes');
set(dbutton,'ClickedCallback', ['spikewaveform(' 'T' ',' 'spikes, ''delete'')' ])

icon_choose   = load('choosespikes.mat');

chbutton = uipushtool(ht,'CData',icon_choose.choosespikes,'TooltipString','Choose Spikes');

set(chbutton,'ClickedCallback', ['spikewaveform(' 'T' ',' 'spikes, ''choose'')' ])


icon_save  = imread('save.png');
svbutton = uipushtool(ht,'CData',icon_save,'TooltipString','Save Spikes');
set(svbutton,'ClickedCallback', ['spikewaveform(' 'T' ',' 'spikes, ''save'')' ])

icon_out   = load('output.mat');

opbutton = uipushtool(ht,'CData',icon_out.output,'TooltipString','output');

set(opbutton,'ClickedCallback', ['spikewaveform(' 'T' ',' 'spikes, ''output'')' ])

cd (cfolder)
assignin('base','spikes',spikes);

function waveout=realign(wavein)
Fs=10000;
lwave=length(wavein);
lresample=linspace(1, lwave, 10*lwave);
waveout=spline([1:lwave], wavein, lresample);
% com=sum(lreample.*waveout)/sum(waveout);
% find peak
[peak, ipeak]=max(waveout);

abovehalf=find(waveout>=0.5*peak);

diffabove=diff(abovehalf);
abovestart=abovehalf([1 find(diffabove>1)+1]);
aboveend=abovehalf([find(diffabove>1) end]);
abovedur=aboveend-abovestart+1;

ix=find(abovestart<ipeak);

istart=abovestart(ix(end));
iend=aboveend(ix(end));

waveabovehalf=waveout(istart:iend);
halfdur=abovedur(ix(end));
maxspkdur=0.8*20000*10/1000;

if halfdur>maxspkdur
    waveout=[];
else
    % determine the center of mass
    tabovehalf=[0:length(waveabovehalf)-1];
    sabovehalf=waveabovehalf-0.5*peak;
    tcom=round(sum(tabovehalf.*sabovehalf)/sum(sabovehalf));
    tcom=tcom+istart;
    
    if tcom<=110 || tcom >200
        waveout=[];
    else
        waveout=waveout([tcom-110:10:tcom+200]);
    end;
end;