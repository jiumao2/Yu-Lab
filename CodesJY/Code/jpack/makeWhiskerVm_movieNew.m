% function makeWhiskerVm_movieNew(Vm, whiskervid, w, twhisk, whisk, licks, touch, Vth, poleonoff, yrange, name)
function makeWhiskerVm_movieNew(iwdata2, whiskervid, trialnum, w, Vth, poleonoff, yrange, name, poleposition, wid, plotlick, ex)
% makeWhiskerVm_movieNew(iwdata2, tvidFrames.t177, 178, w, -47.9, [0.8325 2.8340], [-85 20; -40 40], 'JY0861touch')
plotex=1;

if nargin<12
    ex=0;
    if nargin<11
        plotlick=1;
    end;
end;

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
lparams.reverse=0;

Vm=removelicknoisenew(Vm, (1/(tvm(2)-tvm(1))), lparams);


if ex
    [b, a]=butter(2, 5*2/(1/(tvm(2)-tvm(1))), 'high')
    
    Vm=filtfilt(b, a, detrend(Vm));
end;

set(0,'DefaultAxesFontSize',10)
% Vm=sgolayfilt(Vm, 3, 11);
hf=figure(100); clf(hf)

jump=5;
nplot=801;

nframe=nplot*jump;   


spktimes=find(spk==1);
xx=[tvm(spktimes);tvm(spktimes)];
yy=[ones(1, numel(spktimes))+6; ones(1, numel(spktimes))+9];

% standard video aspect: 720x480
% current window size 1920 1080
set(hf, 'units', 'pixel', 'position', [100 200 1920 1080]/2, 'color', 'w', 'paperpositionmode', 'auto');
mov(1:nplot)=struct('cdata', [], 'colormap', []);

ha1=axes('units', 'pixel', 'position', [50 350 510 600]/2,'xlim', [0 340], 'ylim',[0 400],...
    'ydir','reverse', 'nextplot', 'add');
axis off

ha2=axes('units', 'pixel', 'position', [750 450 1100 500]/2,'nextplot', 'add',...
    'xlim', [-50 2000], 'ylim', yrange(1, :), 'xcolor', 'w', 'ytick', [-100:20:80]);

if ~ex
    ylabel('Membrane potential (mV)')
else
    if ~plotex
        uicontrol('style', 'text', 'string', 'Spikes', 'unit', 'pixel', ...
            'position', [290 275+100 50 20],  'backgroundcolor', [1 1 1], 'fontsize', 10);
    end;

    set(ha2, 'ytick', [], 'position', [750 550 1100 300]/2, 'ycolor', [1 1 1])
end;

tvm=tvm*1000; xx=xx*1000;

% tvm=[0:length(Vm)-1]/10; tvm=tvm-10;
if isempty(twhisk)
    twhisk=1:5000;
end;

% line([100 100], [-30 -10], 'color', 'k', 'linewidth', 3);
% text(180, -20, '20mV')
%htext = uitext(100, yrange(1, 2)-10, '0 ms');

htext=uicontrol('style', 'text', 'string', '0 ms', 'unit', 'pixel', ...
    'position', [800 980 200 50]/2,  'backgroundcolor', [1 1 1], 'fontsize', 12);

line([0 nframe], [Vth Vth], 'color', 'k', 'linewidth', 1, 'linestyle', ':');
licks=licks*1000-10;
hlick=[];
htouch=[];
if ~isempty(licks)
    hlick=text(licks(1)-150, min(get(ha2, 'ylim')), 'Lick', 'color', 'm', 'visible', 'off', 'fontsize', 10)
    lickpos=get(hlick, 'position'); lickpos=lickpos(1);
end;
if ~isempty(touchon)
    htouch=text(touchon(1)-200, yrange(3, 1)-2.5, 'Touch', 'fontsize', 10, 'color', [0 128 255]/255, 'visible', 'off')
    touchpos=get(htouch, 'position'); touchpos=touchpos(1);
end;


% text(nframe-1000, Vth+5, 'AP threshold')
% line([-200 0], [-80 -80], 'color', 'k', 'linewidth', 2, 'linestyle', '-');
% text(-600, -85, '-80mV')

ha3=axes('units', 'pixel', 'position', [750 50 1100 350]/2,'nextplot', 'add',...
    'xlim', [-50 2000], 'ylim', yrange(2, :), 'xcolor', 'w', 'ytick', [-100:20:100]);
ylabel('Whisker position (deg)')

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
        tstart=twhisk(1);
    else
        tstart=tstart+jump;
    end;
    tend=   tstart+jump;
    
    
    if tend>2000
        set(ha2, 'xlim', [tend-2050 tend])
        set(ha3, 'xlim', [tend-2050 tend])
    end;
    
    set(htext, 'string', [num2str(tstart) ' ms'], 'fontsize',12)
    axes(ha1);
    
    set(ha1, 'nextplot', 'replacechildren')
    image(whiskervid(:, :, :, 1+(k-1)*jump));
    set(ha1, 'nextplot', 'add')
    % add whisker tracker
    if any(find(framenums+1==1+(k-1)*jump))
        plot(x{framenums+1==1+(k-1)*jump}, y{framenums+1==1+(k-1)*jump}, '-', 'color', [0 208 0]/255, 'linewidth', 1);
    end;
    
    if tstart>poleonoff(1)*1000-jump && tend<poleonoff(2)*1000-jump
        hold on
        plot(poleposition(1), poleposition(2), 's', 'markersize', 8, 'markerfacecolor', 'r', 'markeredgecolor', 'r')
        axis off
        hold off
    end;
    
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
        end;
    end;
    
    
    
    
    %     ind=find(tvm>0 & tvm<tend);
    %     plot(ha2, tvm(ind), Vm(ind), 'k', 'linewidth', 1);
    
    
    %     if k==1
    %         hvm = animatedline(tvm(ind), Vm(ind), 'color', 'k', 'linewidth', 1);
    %     end;
    %     addpoints(hvm, tvm(ind), Vm(ind));
    
    % plot licks
    if plotlick
        if ~isempty(licks)|| ~isempty(hlick)
            if min(get(gca, 'xlim'))>lickpos
                set(hlick, 'visible', 'off');
            end;
        end;
        
        if ~isempty(licks)
            if 1+(k-1)*jump>licks(1)
                plot(ha2, licks(1), min(get(ha2, 'ylim')), 'm.', 'markersize', 6);
                if min(get(gca, 'xlim'))<lickpos
                    set(hlick, 'visible', 'on')
                end;
                licks(1)=[];
            end;
        end;
    end;
    % plot touch
    
    if ~isempty(touch) || ~isempty(htouch)
        if min(get(gca, 'xlim'))>touchpos
            set(htouch, 'visible', 'off');
        end;
    end;
    
    if ~isempty(touchon)
        
        if any(find(tstart>touchon(1)))
            
            % plot the duration of last touch
            axes(ha2);
            if touchpos>min(get(ha2, 'xlim'))
                set(htouch, 'visible', 'on')
            end;
            
            line([touchon(1) touchon(1)], yrange(3, :),'color', [0 128 255]/255, 'linewidth', 1);
           
            lasttouch=touchon(1);
            touchon(1)=[];
        end;
        
        if ~isempty(touchoff)
            if any(find(tstart>touchoff(1))) && length(touchoff)>length(touchon) % last touch is over but the touch duration is not plotted yet
                line([lasttouch touchoff(1)], [yrange(3, 1) yrange(3, 1)]-2.5,'color', [0 128 255]/255, 'linewidth', 1);
                touchoff(1)=[];
            end;
        end;
    end;
    
    ind2=find(twhisk>=tstart & twhisk<=tend);
   
    if last_end_whisk>0
        plot(ha3, twhisk([last_end_whisk:ind2(1)]), whisk([last_end_whisk:ind2(1)]),  'color', [0 0.6 0], 'linewidth', 1);
    end;
    
    last_end_whisk=ind2(end);
    
    axes(ha3)
    plot(ha3, twhisk(ind2), whisk(ind2), 'color', [0 0.6 0], 'linewidth', 1);
    mov(k)=getframe(hf);
end;

set(ha2, 'xlim', [0 nframe])
set(ha3, 'xlim', [0 nframe])


%cd ('C:\Users\yuj10\Dropbox (Personal)\Work\Presentations\movie')
movie2avi(mov, [name '.avi'],'compression', 'ffds','quality', 75, 'fps', 0.2*1000/jump);

close(hf)
% writerObj=VideoWriter([name '2' '.avi']);
% writerObj.Quality=100;
% writerObj.FrameRate=10;
% open(writerObj)
% writeVideo(writerObj, mov)
% close(writerObj)
