% function makeWhiskerVm_movieNew(Vm, whiskervid, w, twhisk, whisk, licks, touch, Vth, poleonoff, yrange, name)
function makeWhiskerVm_movieNewT(iwdata2, whiskervid, trialnum, w, Vth,  yrange, name,wid, plotlick, ex, title)
% makeWhiskerVm_movieNew(iwdata2, tvidFrames.t177, 178, w, -47.9, [0.8325 2.8340], [-85 20; -40 40], 'JY0861touch')

wcolor=[0 208 0]/255;  % whisker color
tcolor=[0 128 255]/255;  % touch color

plotex=1;
% if nargin<13
%     title=[];
%     if nargin<12
%         ex=0;
%         if nargin<11
%             plotlick=1;
%         end;
%     end;
% end;

plotlick=0;

Vm=             iwdata2.Vmorg(:, iwdata2.trialnums==trialnum);
spk=            iwdata2.Spkorg(:, iwdata2.trialnums==trialnum);
tvm=            iwdata2.tvm;
twhisk=         1000*iwdata2.t;

% if  nargin<10 || isempty(wid)
% whisk=          (squeeze(iwdata2.S_ctk(1, :, iwdata2.trialnums==trialnum)));
% licks=          iwdata2.t(find(squeeze(iwdata2.S_ctk(11, :, find(iwdata2.trialnums==trialnum)))));
% % licks=licks(1);
% touchon=        1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(9, :,  find(iwdata2.trialnums==trialnum)))));
% touchoff=       1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(10, :, find(iwdata2.trialnums==trialnum)))));
% touch=          [touchon' touchoff'];
%
% else
whisk=          (squeeze(iwdata2.S_ctk(1, :, iwdata2.trialnums==trialnum, wid+1)));
licks=          iwdata2.t(find(squeeze(iwdata2.S_ctk(10, :, find(iwdata2.trialnums==trialnum, wid+1)))));
% licks=licks(1);
touchon=        1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(8, :,  find(iwdata2.trialnums==trialnum, wid+1)))));
touchoff=       1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(9, :, find(iwdata2.trialnums==trialnum, wid+1)))));
touch=          [touchon' touchoff'];

% end;

% if ~isempty(licks)
% Vm=removelicknoise(tvm, Vm, licks, ~ex);
% end;

lparams.peak=2;
lparams.negpeak=-2;
lparams.max=10;
lparams.dur=[-2 15]; % before and after peak
lparams.removedur=[-.5 2.5];
lparams.removelicks=0;
lparams.reverse=1;

Vm=removelicknoisenew(Vm, (1/(tvm(2)-tvm(1))), lparams);

if ex
    [b, a]=butter(2, 1*2/(1/(tvm(2)-tvm(1))), 'high')
    Vm=filtfilt(b, a, detrend(Vm));
end;

set(0,'DefaultAxesFontSize',12)
% Vm=sgolayfilt(Vm, 3, 11);
hf=figure(100); clf(hf)

start=0.05; % start from .33 sec
jump=4;
nplot=2100/jump;

nframe=nplot*jump;   

spktimes=find(spk==1);
xx=[tvm(spktimes) tvm(spktimes)]';
yy=[ones(1, numel(spktimes))+7; ones(1, numel(spktimes))+9];

% standard video aspect: 720x480
% current window size 1920 1080
set(hf, 'units', 'pixel', 'position', [100 200 1920 1080]/2, 'color', 'w', 'paperpositionmode', 'auto');

hu=uicontrol('Style','text','String',title, 'units', 'pixels', 'position', [0 500 960 30], 'fontsize', 12, 'backgroundcolor', 'w'); 

mov(1:nplot)=struct('cdata', [], 'colormap', []);

ha1=axes('units', 'pixel', 'position', [25 150 340*.75 400*.75],'xlim', [0 340], 'ylim',[0 400],...
    'ydir','reverse', 'nextplot', 'add');
axis off

ha2=axes('units', 'pixel', 'position', [700 400 1100 600]/2,'nextplot', 'add',...
    'xlim', [-50+start*1000 nframe+start*1000], 'ylim', yrange(1, :), 'xcolor', 'w', 'ytick', [-100:20:80]);
axis off

if ex
    text(start*1000, (yrange(1, 2)-yrange(1, 1))/5, 'cell-attached recording', 'fontsize', 12)
    line([-50+start*1000 -50+start*1000],[0 5], 'color', 'k', 'linewidth', 2)
    text(-155+start*1000, 2.5, '5mV', 'fontsize', 12)
    
else
   
    text(start*1000, Vth+4, 'Spike threshold', 'fontsize', 12)
    
    line([-50+start*1000 -50+start*1000],[-40 -20], 'color', 'k', 'linewidth', 2)
    text(-230+start*1000, -30, '20mV', 'fontsize', 12)
    
    startVm=floor(mean(Vm(tvm>=start & tvm<=start+0.1)));
    
    text(-200+start*1000, startVm, sprintf('%2.0dmV', startVm), 'fontsize', 12)
    
    minVm=floor(min(Vm(tvm>=start & tvm<=start+0.1)));
    text(start*1000, minVm-9, 'Membrane potential', 'fontsize', 12)
end;

if ~ex
    ylabel('Membrane potential (mV)')
else
    if ~plotex
        uicontrol('style', 'text', 'string', 'Spikes', 'unit', 'pixel', ...
            'position', [290 275+100 50 20],  'backgroundcolor', [1 1 1], 'fontsize', 12);
    end;
    set(ha2, 'ytick', [], 'position', [700 550 1100 300]/2, 'ycolor', [1 1 1])
end;

tvm=tvm*1000; xx=xx*1000;

% tvm=[0:length(Vm)-1]/10; tvm=tvm-10;
if isempty(twhisk)
    twhisk=1:5000;
end;

% line([100 100], [-30 -10], 'color', 'k', 'linewidth', 3);
% text(180, -20, '20mV')
%htext = uitext(100, yrange(1, 2)-10, '0 ms');

% htext=uicontrol('style', 'text', 'string', '0 ms', 'unit', 'pixel', ...
%     'position', [800 980 200 50]/2,  'backgroundcolor', [1 1 1], 'fontsize', 12);

 line([0 nframe]+start*1000, [Vth Vth], 'color', 'k', 'linewidth', 1, 'linestyle', ':');
licks=licks*1000-10;
hlick=[];
htouch=[];
if ~isempty(licks)
    hlick=text(licks(1)-150, min(get(ha2, 'ylim')), 'Lick', 'color', 'm', 'visible', 'off', 'fontsize', 12)
    lickpos=get(hlick, 'position'); lickpos=lickpos(1);
end;
if ~isempty(touchon)
    htouch=text(touchon(1)-200, yrange(3, 1)-2.5, 'Touch', 'fontsize', 12, 'color', tcolor, 'visible', 'off')
    touchpos=get(htouch, 'position'); touchpos=touchpos(1);
end;


ha3=axes('units', 'pixel', 'position', [700 100 1100 300]/2,'nextplot', 'add',...
    'xlim', [-50+start*1000 nframe+start*1000], 'ylim', yrange(2, :), 'xcolor', 'w', 'ytick', [-100:20:100]);
axis off

startWhisker=max(whisk(twhisk>=start*1000 & twhisk<=start*1000+100))+25;

text(start*1000, startWhisker, 'Whisker position', 'fontsize', 12, 'color',wcolor)
line([10 510]+start*1000,[yrange(2, 1) yrange(2, 1)], 'color', 'k', 'linewidth', 2);
text(205+start*1000, yrange(2, 1)+8, '500ms', 'fontsize', 12)
line([-50+start*1000 -50+start*1000],[-40 0], 'color', 'k', 'linewidth', 2)
text(-230+start*1000, -20, '20deg', 'fontsize', 12)

% Here are the whisker tracker data

if  nargin<10 || isempty(wid)
    x=cellfun(@(x)x{4}, w.trackerData{1}, 'uniformoutput', false);
    y=cellfun(@(x)x{5}, w.trackerData{1}, 'uniformoutput', false);
else
    x=cellfun(@(x)x{4}, w.trackerData{1+wid}, 'uniformoutput', false);
    y=cellfun(@(x)x{5}, w.trackerData{1+wid}, 'uniformoutput', false);
end;

framenums=w.allFrameNums;

last_end=0;
last_end_whisk=0;
withintouch=0;

for k=1:nplot
    if k==1
        tstart=twhisk(1)+start*1000;
    else
        tstart=tstart+jump;
    end;
    tend=   tstart+jump;
    
    
%     if tend>2000
%         set(ha2, 'xlim', [tend-2050 tend])
%         set(ha3, 'xlim', [tend-2050 tend])
%     end;
    
    
%     set(htext, 'string', [num2str(tstart) ' ms'], 'fontsize',12)
    axes(ha1);
    set(ha1, 'nextplot', 'replacechildren')

    % add whisker tracker
    if any(find(framenums+1==1+(k-1)*jump+start*1000))
        imagesc(whiskervid(:, :, :, 1+(k-1)*jump+start*1000));
        set(ha1, 'nextplot', 'add')
        plot(x{framenums+1==1+(k-1)*jump+start*1000}, 1+y{framenums+1==1+(k-1)*jump+start*1000}, '-', 'color', wcolor, 'linewidth', 1);
    else
        [~, index]=min(abs(framenums+1-1-(k-1)*jump-start*1000)); % find the nearest frame that has tracker data
        cframe=framenums(index);
        
        imagesc(whiskervid(:, :, :, cframe+1));
        set(ha1, 'nextplot', 'add')
        plot(x{index}, 1+y{index}, '-', 'color', wcolor, 'linewidth', 1);
    end;
    
%     if tstart>poleonoff(1)*1000-jump && tend<poleonoff(2)*1000-jump
%       axes(ha2)
%         plot(poleonoff(1)*1000, yrange(1, 2)-2, 's', 'markersize', 6, 'markerfacecolor', 'k', 'markeredgecolor', 'k')
%     end;
    
    axes(ha2);
    %   set(ha2, 'nextplot', 'replacechildren')
    if ~ex || plotex
        
        ind=find(tvm>=tstart & tvm<=tend);
        
        plot(ha2, tvm(ind), Vm(ind), 'k', 'linewidth', 1);
        if last_end>0
            plot(ha2, tvm([last_end:ind(1)]), Vm([last_end:ind(1)]), 'k', 'linewidth', 1);
        end;
        
        last_end=ind(end);
        
    end
    
    if ex
        if ~isempty(xx)
            ind=find(xx(1, :)>=tstart & xx(1, :)<=tend);
            % plot(xx, yy, 'k', 'linewidth', 1)
            plot(ha2,xx(:, ind), yy(:, ind), 'k', 'linewidth', 1);
            if ind==1
                text(xx(1, ind)-150, yy(2, ind), 'spike', 'fontsize', 12)
            end;
        end;
    end;

    % plot licks
    if plotlick
        if ~isempty(licks)|| ~isempty(hlick)
            if min(get(gca, 'xlim'))>lickpos
                set(hlick, 'visible', 'off');
            end;
        end;
        
        if ~isempty(licks)
            if 1+(k-1)*jump+start*1000>licks(1)
                plot(ha2, licks(1), min(get(ha2, 'ylim')), 'm.', 'markersize', 6);
                if min(get(gca, 'xlim'))<lickpos
                    set(hlick, 'visible', 'on')
                end;
                licks(1)=[];
            end;
        end;
    end;
%     % plot touch
%  %%   
%     if ~isempty(touch) || ~isempty(htouch)
%         if min(get(gca, 'xlim'))>touchpos
%             set(htouch, 'visible', 'off');
%         end;
%     end;
%     
%     if ~isempty(touchon)
%         
%         if any(find(tstart>touchon(1)))
%             
%             % plot the duration of last touch
%             axes(ha2);
%             if touchpos>min(get(ha2, 'xlim'))
%                 set(htouch, 'visible', 'on')
%             end;
%             
%             line([touchon(1) touchon(1)], yrange(3, :),'color', tcolor, 'linewidth', 1);
%            
%             lasttouch=touchon(1);
%             touchon(1)=[];
%         end;
%         
%         %         if ~isempty(touchoff)
%         %             if any(find(tstart>touchoff(1))) && length(touchoff)>length(touchon) % last touch is over but the touch duration is not plotted yet
%         %                 line([lasttouch touchoff(1)], [yrange(3, 1) yrange(3, 1)]-2.5,'color', tcolor, 'linewidth', 1);
%         %                 touchoff(1)=[];
%         %             end;
%         %         end;
%         %
%         
%         if ~isempty(touchoff)
%             
%             if any(find(tend<touchoff(1))) &&  any(find(tstart<touchoff(1)))  && length(touchoff)>length(touchon)
%                 line([lasttouch tend], [yrange(3, 1) yrange(3, 1)]-2.5,'color',tcolor, 'linewidth', 1);
%                 
%             elseif any(find(tstart>touchoff(1))) && length(touchoff)>length(touchon) % last touch is over but the touch duration is not plotted yet
%                 line([lasttouch touchoff(1)], [yrange(3, 1) yrange(3, 1)]-2.5,'color',tcolor, 'linewidth', 1);
%                 touchoff(1)=[];
%             end;
%         end;
%         
%         
%     end;
% %     
    %%
    ind2=find(twhisk>=tstart & twhisk<=tend);
   
    if last_end_whisk>0
        plot(ha3, twhisk([last_end_whisk:ind2(1)]), whisk([last_end_whisk:ind2(1)]),  'color', tcolor, 'linewidth', 1);
    end;
    
    last_end_whisk=ind2(end);
    
    axes(ha3)
    plot(ha3, twhisk(ind2), whisk(ind2), 'color', wcolor, 'linewidth', 1);
    mov(k)=getframe(hf);
end;

for kk=1:50
    mov(end+1)=getframe(hf);
end;

v=VideoWriter([name], 'MPEG-4');
v.FrameRate=0.1*(1000/jump);
v.Quality=100;
open(v)
writeVideo(v, mov)
close(v)
%cd ('C:\Users\yuj10\Dropbox (Personal)\Work\Presentations\movie')
%movie2avi(mov, [name '.avi'],'compression', 'ffds','quality', 75, 'fps', 0.2*1000/jump);
print(hf, ['last_frame_simplified'],'-depsc')
close(hf)
% writerObj=VideoWriter([name '2' '.avi']);
% writerObj.Quality=100;
% writerObj.FrameRate=10;
% open(writerObj)
% writeVideo(writerObj, mov)
% close(writerObj)