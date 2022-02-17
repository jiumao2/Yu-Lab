function makeWhiskerVm_movie(Vm, whiskervid, twhisk, whisk, licks, Vth, poleonoff, yrange, name)
% makeWhiskerVm_movie(exp1.vout(:, 1)), vidFrames.t180);

% Vm=sgolayfilt(Vm, 3, 11);
hf=figure(100); clf(hf)
nplot=400;
nframe=nplot*10;        
set(hf, 'units', 'centimeters', 'position', [2 2 16*1.25 11.25], 'color', 'w', 'paperpositionmode', 'auto');
mov(1:nplot)=struct('cdata', [], 'colormap', []);

ha1=axes('units', 'centimeters', 'position', [1 2 5 7],'xlim', [0 340], 'ylim',[0 400],...
    'ydir','reverse', 'nextplot', 'replacechildren');
axis off

ha2=axes('units', 'centimeters', 'position', [9 5.5 10 5],'nextplot', 'add',...
    'xlim', [-200 nframe], 'ylim', yrange(1, :), 'xcolor', 'w', 'ytick', [-100:20:80]);

ylabel('Vm (mV)')
tvm=[0:length(Vm)-1]/10; tvm=tvm-10;
if isempty(twhisk)
    twhisk=1:5000;
end;

% line([100 100], [-30 -10], 'color', 'k', 'linewidth', 3);
% text(180, -20, '20mV')
htext = text(100, yrange(1, 2)-10, '0 ms');
line([0 nframe], [Vth Vth], 'color', 'k', 'linewidth', 1, 'linestyle', ':');
licks=licks*1000-10;
if ~isempty(licks)
    hlick=text(licks(1)-400, min(get(ha2, 'ylim')), 'lick', 'color', 'm', 'visible', 'off')
end;
% text(nframe-1000, Vth+5, 'AP threshold')
% line([-200 0], [-80 -80], 'color', 'k', 'linewidth', 2, 'linestyle', '-');
% text(-600, -85, '-80mV')

ha3=axes('units', 'centimeters', 'position', [9 1 10 4],'nextplot', 'add',...
    'xlim', [-200 nframe], 'ylim', yrange(2, :), 'xcolor', 'w', 'ytick', [-90:30:90]);
ylabel('Theta (deg)')


for k=1:nplot
    axes(ha1)
    image(whiskervid(:, :, :, 1+k*10)); axis off
    
    if 1+(k-1)*10>poleonoff(1)*1000-10 && 1+(k-1)*10<poleonoff(2)*1000-10
        hold on
        plot(197, 359, 's', 'markersize', 10, 'markerfacecolor', 'r', 'markeredgecolor', 'r')
        axis off
        hold off
    end;
    
    ind=find(tvm>=1+(k-1)*10 & tvm<k*10+1);
    
    axes(ha2)
    set(htext, 'string', [num2str(1+(k-1)*10) 'ms'])
    plot(ha2, tvm(ind), Vm(ind), 'k', 'linewidth', 1);
    
    % plot licks
    if ~isempty(licks)
        if 1+(k-1)*10>licks(1)
            plot(ha2, licks(1), min(get(ha2, 'ylim')), 'm.', 'markersize', 6);
            set(hlick, 'visible', 'on')
            licks(1)=[];
        end;
    end;
    
    ind2=find(twhisk>=1+(k-1)*10 & twhisk<k*10+1);
    
    axes(ha3)
    plot(ha3, twhisk(ind2), whisk(ind2), 'color', [0 0.6 0], 'linewidth', 1);
    mov(k)=getframe(hf);
end;

cd ('C:\Users\yuj10\Dropbox (Personal)\Work\Presentations\movie')
movie2avi(mov, [name '.avi'],'compression', 'none', 'fps', 10);
% writerObj=VideoWriter([name '2' '.avi']);
% writerObj.Quality=100;
% writerObj.FrameRate=10;
% open(writerObj)
% writeVideo(writerObj, mov)
% close(writerObj)
