% makePhototagging_movieNew       (iwdata2,  58,  92,  [-10 10; -20 60; -5 5], 'JY1591Phototagging',  0, 1, 1)
function makePhototagging_movieNew(iwdata2, trialnum, Vth, yrange, name, wid,  ex)
% makeWhiskerVm_movieNew(iwdata2, tvidFrames.t177, 178, w, -47.9, [0.8325 2.8340], [-85 20; -40 40], 'JY0861touch')

if nargin<7
    ex=0;
 end;

Vm=             iwdata2.Vmorg(:, iwdata2.trialnums==trialnum);
spk=            iwdata2.Spkorg(:, iwdata2.trialnums==trialnum);
opto=           iwdata2.opto(:, iwdata2.trialnums==trialnum );
tvm=            iwdata2.tvm;
twhisk=         1000*iwdata2.t;

if  nargin<10 || isempty(wid)
whisk=          (squeeze(iwdata2.S_ctk(1, :, iwdata2.trialnums==trialnum)));
licks=          iwdata2.t(find(squeeze(iwdata2.S_ctk(11, :, find(iwdata2.trialnums==trialnum))))); 
% licks=licks(1);
touchon=        1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(9, :,  find(iwdata2.trialnums==trialnum)))));
touchoff=       1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(10, :, find(iwdata2.trialnums==trialnum)))));
touch=          [touchon' touchoff'];

else
    whisk=          (squeeze(iwdata2.S_ctk(1, :, iwdata2.trialnums==trialnum, wid+1)));
licks=          iwdata2.t(find(squeeze(iwdata2.S_ctk(11, :, find(iwdata2.trialnums==trialnum, wid+1))))); 
% licks=licks(1);
touchon=        1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(9, :,  find(iwdata2.trialnums==trialnum, wid+1)))));
touchoff=       1000*iwdata2.t(find(squeeze(iwdata2.S_ctk(10, :, find(iwdata2.trialnums==trialnum, wid+1)))));
touch=          [touchon' touchoff'];
    
end;

lparams.peak=2;
lparams.negpeak=-2;
lparams.max=10;
lparams.dur=[-2 15]; % before and after peak
lparams.removedur=[-.5 2.5];
lparams.removelicks=1;
lparams.reverse=1;

Vm=removelicknoisenew(Vm, (1/(tvm(2)-tvm(1))), lparams);

if ex
    [b, a]=butter(2, 1*2/(1/(tvm(2)-tvm(1))), 'high')
    Vm=filtfilt(b, a, detrend(Vm));
end;

set(0,'DefaultAxesFontSize',12)
% Vm=sgolayfilt(Vm, 3, 11);
hf=figure(100); clf(hf)

jump=5;
nplot=510;

nframe=nplot*jump;   

spktimes=find(spk==1);
xx=[tvm(spktimes);tvm(spktimes)];
yy=[ones(1, numel(spktimes))+5; ones(1, numel(spktimes))+7];

% standard video aspect: 720x480
% current window size 1920 1080
set(hf, 'units', 'pixel', 'position', [100 200 1920 1080]/2, 'color', 'w', 'paperpositionmode', 'auto');
mov(1:nplot)=struct('cdata', [], 'colormap', []);

hu=uicontrol('Style','text','String','Optogenetic tagging of FS interneuron with ChR2+ activation',...
    'units', 'pixels', 'position', [0 500 960 30], 'fontsize', 12, 'backgroundcolor', 'w'); 

ha1=axes('units', 'pixel', 'position', [50 250 510 600]/2,'xlim', [0 340], 'ylim',[0 400],...
    'ydir','reverse', 'nextplot', 'add');
% this will be spike plotting window.
axis off

ha2=axes('units', 'pixel', 'position', [250 550 1500 450]/2,'nextplot', 'add',...
    'xlim', [-50 2500], 'ylim', yrange(1, :), 'xcolor', 'w', 'ytick', [-100:20:80]);
set(ha2, 'ytick', [-10:5:10], 'position', [250 550 1500 400]/2)
axis off
% add scale bars
line([0 0]-50,[0 5], 'color', 'k', 'linewidth', 2)
line([0 500]-50, [yrange(1, 1) yrange(1, 1)]+2 , 'color', 'k', 'linewidth', 2)

text(-130-50, 2.5, '5mV', 'fontsize', 12)
text(200-50, yrange(1, 1)-1+2,  '500ms', 'fontsize', 12)

tvm=tvm*1000; xx=xx*1000;

% tvm=[0:length(Vm)-1]/10; tvm=tvm-10;
if isempty(twhisk)
    twhisk=1:5000;
end;

% line([100 100], [-30 -10], 'color', 'k', 'linewidth', 3);
% text(180, -20, '20mV')
%htext = uitext(100, yrange(1, 2)-10, '0 ms');
% htext=uicontrol('style', 'text', 'string', '0 ms', 'unit', 'pixel', ...
%     'position', [1700 980 200 50]/2,  'backgroundcolor', [1 1 1], 'fontsize', 12);

% htext2=uicontrol('style', 'text', 'string', 'Photostimulation', 'unit', 'pixel', ...
%     'position', [1200 980 400 50]/2,  'backgroundcolor', [1 1 1], 'fontsize', 12);

line([0 nframe], [Vth Vth], 'color', 'k', 'linewidth', 1, 'linestyle', ':');
licks=licks*1000-10;


% text(nframe-1000, Vth+5, 'AP threshold')
% line([-200 0], [-80 -80], 'color', 'k', 'linewidth', 2, 'linestyle', '-');
% text(-600, -85, '-80mV')
% 
ha3=axes('units', 'pixel', 'position', [250 150 500 350]/2,'nextplot', 'add',...
    'xlim', [-2 7], 'ylim', yrange(2, :), 'xtick', [-2:7], 'ytick', [-5:5:5], 'ycolor', 'w');

line([0 5], [yrange(2, 1)+0.5 yrange(2, 1)+0.5], 'color', 'b', 'linewidth', 3)
line([-2 -2],[0 2]+yrange(2, 1)+1, 'color', 'k', 'linewidth', 2)

text(-3.4, 1+yrange(2, 1)+1, '5mV', 'fontsize', 12)

xlabel('Time from laser onset (ms)')

% Here are the whisker tracker data

last_end=0;
last_end_whisk=0;
withintouch=0;

opto2=sparse([], [], [], size(opto, 1), size(opto, 2));
opto2(find(opto>1))=1;

hlaser=[];

firstlaser=tvm(find(opto>1, 1, 'first'));
axes(ha2)
hlaser=text(firstlaser-200, -3, 'Laser', 'color', 'b', 'visible', 'off', 'fontsize', 12)
laserpos=get(hlaser, 'position'); 
laserpos=laserpos(1);

hspike=text(firstlaser-200, 6.5, 'Spike', 'color', 'k', 'visible', 'off', 'fontsize', 12)
spikepos=get(hspike, 'position'); 
spikepos=spikepos(1);

laseronlast=0;
laseron=[];

start=50;

for k=1:nplot
    
    if k==1
        tstart=twhisk(1)+start;
    else
        tstart=tstart+jump;
    end;
    tend=   tstart+jump;
    

%     set(htext, 'string', [num2str(tstart) ' ms'], 'fontsize',12)
%     axes(ha1);
%     
%     set(ha1, 'nextplot', 'replacechildren')
%     image(whiskervid(:, :, :, 1+(k-1)*jump));
%     set(ha1, 'nextplot', 'add')
%     % add whisker tracker
%     if any(find(framenums+1==1+(k-1)*jump))
%         plot(x{framenums+1==1+(k-1)*jump}, y{framenums+1==1+(k-1)*jump}, '-', 'color', [0 208 0]/255, 'linewidth', 1);
%     end;

%     if tstart>poleonoff(1)*1000-jump && tend<poleonoff(2)*1000-jump
%         hold on
%         plot(poleposition(1), poleposition(2), 's', 'markersize', 8, 'markerfacecolor', 'r', 'markeredgecolor', 'r')
%         axis off
%         hold off
%     end;
%
axes(ha2);
%   set(ha2, 'nextplot', 'replacechildren')
ind=find(tvm>=tstart & tvm<=tend);
ind_laser=find(opto2(ind));


if ~isempty(ind_laser)
    laseron= tvm(ind(ind_laser));laseron=laseron(1);
    
    diff=laseron-laseronlast;
    
    if diff>100 % new pulase
        
        vm_seg=Vm(tvm>=laseron-2 & tvm<= laseron+7);
        plot(ha3, tvm(tvm>=laseron-2 & tvm<= laseron+7)-laseron, vm_seg, 'k', 'linewidth', 1)
        
    end;
    
    plot(ha2, tvm(ind(ind_laser)), -3, 'b.', 'linewidth', 1);
    set(hlaser, 'visible', 'on'); set(hspike, 'visible', 'on');
    laseronlast=laseron;
    
end;

if laserpos<min(get(gca, 'xlim'))
    set(hlaser, 'visible', 'off');
    set(hspike, 'visible', 'off');
end;
% if last_end>2
%     plot(ha2, tvm([last_end:ind(1)]), opto2([last_end:ind(1)]), 'b.', 'linewidth', 1);
% end;

ind=find(tvm>=tstart & tvm<=tend);

plot(ha2, tvm(ind), Vm(ind), 'k', 'linewidth', 1);
if last_end>0
    plot(ha2, tvm([last_end:ind(1)]), Vm([last_end:ind(1)]), 'k', 'linewidth', 1);
end;

last_end=ind(end);

if find(xx(1, :)>=tstart & xx(1, :)<=tend)
    
    ind=find(xx(1, :)>=tstart & xx(1, :)<=tend);
    % plot(xx, yy, 'k', 'linewidth', 1)
    plot(ha2,xx(:, ind), yy(:, ind), 'k', 'linewidth', 1);
end;


% plot opto profile.
    
    %     ind=find(tvm>0 & tvm<tend);
    %     plot(ha2, tvm(ind), Vm(ind), 'k', 'linewidth', 1);
    
    
    %     if k==1
    %         hvm = animatedline(tvm(ind), Vm(ind), 'color', 'k', 'linewidth', 1);
    %     end;
    %     addpoints(hvm, tvm(ind), Vm(ind));
    
  
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
close(hf)