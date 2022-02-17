% function makeWhiskerVm_movieNew(Vm, whiskervid, w, twhisk, whisk, licks, touch, Vth, poleonoff, yrange, name)
function makeWhiskerMovieSpikeVPM(r, whiskervid, start, yrange, title, name)
% makeWhiskerVm_movieNew(iwdata2, tvidFrames.t177, 178, w, -47.9, [0.8325 2.8340], [-85 20; -40 40], 'JY0861touch')

t=[0:size(r.angle, 1)-1]; % t in ms

% Vm=             iwdata2.Vmorg(:, iwdata2.trialnums==trialnum);
spk=            sparse([], [], [], length(t), 1);
spk(r.spikes)=  1;
 
% else
whisk=          r.angle(:, r.PW);
twhisk=         t;
touch_periods=  t(find(r.contacts(:, r.PW)));
touchon=[];
touchoff=[];
if ~isempty(touch_periods)
touchon=        touch_periods([1 find(diff(touch_periods)>1)+1]);
touchoff=       touch_periods([find(diff(touch_periods)>1) end]);
end;

set(0,'DefaultAxesFontSize',10)
% Vm=sgolayfilt(Vm, 3, 11);
hf=figure(100); clf(hf)

% start=.3; % start from .33 sec
jump=4;
nplot=2000/jump;
% nplot=1000/jump;
nframe=nplot*jump;   

spktimes=find(spk==1);
xx=[t(spktimes); t(spktimes)];
yy=[zeros(1, numel(spktimes))-2; zeros(1, numel(spktimes))+2];

% standard video aspect: 720x480
% current window size 1920 1080
set(hf, 'units', 'pixel', 'position', [100 200 1920 950]/2, 'color', 'w', 'paperpositionmode', 'auto');

hu=uicontrol('Style','text','String',title, 'units', 'pixels', 'position', [0 425 960 30], 'fontsize', 12, 'backgroundcolor', 'w'); 

mov(1:nplot)=struct('cdata', [], 'colormap', []);

ha1=axes('units', 'pixel', 'position', [100 200 600 904]/2.5,'xlim', [0 300], 'ylim',[0 552],...
    'ydir','reverse', 'nextplot', 'add');
axis off


ha2=axes('units', 'pixel', 'position', [750 300 1100 700]/2,'nextplot', 'add',...
    'xlim', [-50+start*1000 nframe+start*1000], 'ylim', yrange(1, :), 'xcolor', 'w', 'ytick', [-100:20:80]);
axis off
% uicontrol('style', 'text', 'string', 'Spikes', 'unit', 'pixel', ...
%     'position', [290 275+100 50 20],  'backgroundcolor', [1 1 1], 'fontsize', 10);

htouch=[];
 
if ~isempty(touchon)
    htouch=text(touchon(1)-200, yrange(3, 1)-2.5, 'Touch', 'fontsize', 10, 'color', [0 128 255]/255, 'visible', 'off')
    touchpos=get(htouch, 'position'); touchpos=touchpos(1);
end;

ha3=axes('units', 'pixel', 'position', [750 100 1100 400]/2,'nextplot', 'add',...
    'xlim', [-50+start*1000 nframe+start*1000], 'ylim', yrange(2, :), 'xcolor', 'w', 'ytick', [-100:20:100]);
axis off
text(start*1000, 70, 'Whisker position', 'fontsize', 10, 'color',[0 208 0]/255)
line([10 510]+start*1000,[yrange(2, 1) yrange(2, 1)], 'color', 'k', 'linewidth', 2);
text(200+start*1000, yrange(2, 1)+8, '500 ms', 'fontsize', 10)
line([-50+start*1000 -50+start*1000],[-40 0], 'color', 'k', 'linewidth', 2)
text(-250+start*1000, -20, '20 deg', 'fontsize', 10)

y= (squeeze(r.whiskerPos.x(:, :, r.PW)));
x=squeeze(r.whiskerPos.y(:, :, r.PW));

framenums=1:size(whiskervid, 4);

last_end=0;
last_end_whisk=0;
withintouch=0;

whisk_collection=[];
tracking_collection={};

last_end=0;
last_end_whisk=0;
withintouch=0;

lasttouch=0;
lasttouchoff=0;
firstspike=0;

for k=1:nplot
    if k==1
        tstart=t(1)+start*1000;
    else
        tstart=tstart+jump;
    end;
    tend=   tstart+jump;
    
    
%     if tend>2000
%         set(ha2, 'xlim', [tend-2050 tend])
%         set(ha3, 'xlim', [tend-2050 tend])
%     end;
%     
    
%     set(htext, 'string', [num2str(tstart) ' ms'], 'fontsize',12)
    axes(ha1);
    set(ha1, 'nextplot', 'replacechildren')
    
    % add whisker tracker
    if any(find(framenums==1+(k-1)*jump+start*1000))
        imagefile=whiskervid(:, :, :, 1+(k-1)*jump+start*1000);
        
        imagefilenew=[];
        for j=1:size(imagefile, 3)
            imagefilenew(:, :, j)=flipud(imagefile(:, :, j)');
        end;
        imagesc(imagefilenew(:, :, 1)); colormap(gray)
        whisk_collection(:, :, k)= imagefilenew(:, :, 1);
        set(ha1, 'nextplot', 'add')
        plot(x(framenums==1+(k-1)*jump+start*1000, :), 551-(y(framenums==1+(k-1)*jump+start*1000, :)), '-', 'color', [0 208 0]/255, 'linewidth', 1);
         tracking_collection{k}=[x(framenums==1+(k-1)*jump+start*1000, :); 551-(y(framenums==1+(k-1)*jump+start*1000, :))];
    else
        [~, index]=min(abs(framenums+1-1-(k-1)*jump-start*1000)); % find the nearest frame that has tracker data
        cframe=framenwhos
        ums(index);
        
        image(whiskervid(:, :, :, cframe+1));
        xxx=whiskervid(:, :, :, cframe+1);
        whisk_collection(:, :, k)= xxx(:, :, 1);
        set(ha1, 'nextplot', 'add')
        plot(x{index}, 1+y{index}, '-', 'color', [0 208 0]/255, 'linewidth', 1);
        tracking_collection{k}=[x{index}; 1+y{index}];
    end;
    
    %     if tstart>poleonoff(1)*1000-jump && tend<poleonoff(2)*1000-jump
    %       axes(ha2)
    %         plot(poleonoff(1)*1000, yrange(1, 2)-2, 's', 'markersize', 6, 'markerfacecolor', 'k', 'markeredgecolor', 'k')
    %     end;
    
    axes(ha2);
    
    if ~isempty(xx)
            ind=find(xx(1, :)>=tstart & xx(1, :)<=tend);
            % plot(xx, yy, 'k', 'linewidth', 1)
            plot(ha2,xx(:, ind), yy(:, ind), 'k', 'linewidth', 1);
            if ind==1
                text(xx(1, ind)-250,0, 'spike', 'fontsize', 10)
            end;
        end;
  
    % plot licks
%     if plotlick
%         if ~isempty(licks)|| ~isempty(hlick)
%             if min(get(gca, 'xlim'))>lickpos
%                 set(hlick, 'visible', 'off');
%             end;
%         end;
%         
%         if ~isempty(licks)
%             if 1+(k-1)*jump+start*1000>licks(1)
%                 plot(ha2, licks(1), min(get(ha2, 'ylim')), 'm.', 'markersize', 6);
%                 if min(get(gca, 'xlim'))<lickpos
%                     set(hlick, 'visible', 'on')
%                 end;
%                 licks(1)=[];
%             end;
%         end;
%     end;
    % plot touch
%     
%     if  ~isempty(htouch)
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
%             line([touchon(1) touchon(1)], yrange(3, :),'color', [0 128 255]/255, 'linewidth', 1);
%            
%             lasttouch=touchon(1);
%             touchon(1)=[];
%         end;
%         
%         if ~isempty(touchoff)
%             if any(find(tstart>touchoff(1))) && length(touchoff)>length(touchon) % last touch is over but the touch duration is not plotted yet
%                 line([lasttouch touchoff(1)], [yrange(3, 1) yrange(3, 1)]-2.5,'color', [0 128 255]/255, 'linewidth', 1);
%                 touchoff(1)=[];
%             end;
%         end;
%     end;




    axes(ha2);
    
    if ~isempty(touchon)
        
        % plot touch:
        if any(find(tstart>=touchon(1)))
            
            % plot the duration of last touch
            axes(ha2);
            if touchpos>min(get(ha2, 'xlim'))
                set(htouch, 'visible', 'on')
            end;
            
            %             line([touchon(1) touchon(1)], yrange(3, :),'color', [0 128 255]/255, 'linewidth', 1);
            %
            
            lasttouch=touchon(1);
            lasttouchoff=touchoff(1);
            touchon(1)=[];
            touchoff(1)=[];
            
            % plot touch duration as shade:
            
            
            if tend<lasttouchoff
                plotshaded([lasttouch, tend], [yrange(3, 1), yrange(3, 1); yrange(3, 2), yrange(3, 2)], [0 128 255]/255);
            else
                plotshaded([lasttouch, lasttouchoff], [yrange(3, 1), yrange(3, 1); yrange(3, 2), yrange(3, 2)], [0 128 255]/255);
            end;
            
        elseif isempty(find(tstart>=touchon(1))) && any(find(tstart<lasttouchoff))  % means this frame still within the recent touch, need to plot the touch duration here
            if tend<lasttouchoff
                plotshaded([tstart, tend], [yrange(3, 1), yrange(3, 1); yrange(3, 2), yrange(3, 2)], [0 128 255]/255);
            else
                plotshaded([tstart, lasttouchoff], [yrange(3, 1), yrange(3, 1); yrange(3, 2), yrange(3, 2)], [0 128 255]/255);
            end;
            
        end;
    end;
    
    
    ind2=find(twhisk>=tstart & twhisk<=tend);
   
    if last_end_whisk>0
        plot(ha3, twhisk([last_end_whisk:ind2(1)]), whisk([last_end_whisk:ind2(1)]),  'color', [0 208 0]/255, 'linewidth', 1);
    end;
    
    last_end_whisk=ind2(end);
    
    axes(ha3)
    plot(ha3, twhisk(ind2), whisk(ind2), 'color', [0 208 0]/255, 'linewidth', 1);
    mov(k)=getframe(hf);
end;

for kk=1:50
    mov(end+1)=getframe(hf);
end;

axes(ha1);
for ik=1:length(tracking_collection)
    xik=tracking_collection{ik};
    plot(xik(1, :), xik(2, :), '-', 'color', [0 208 0]/255, 'linewidth', 0.25);
end;

v=VideoWriter([name], 'MPEG-4');
v.FrameRate=0.1*(1000/jump);
v.Quality=100;
open(v)
writeVideo(v, mov)
close(v)
%cd ('C:\Users\yuj10\Dropbox (Personal)\Work\Presentations\movie')
%movie2avi(mov, [name '.avi'],'compression', 'ffds','quality', 75, 'fps', 0.2*1000/jump);
print(hf, ['last_frame'],'-dtiff')

close(hf)
% writerObj=VideoWriter([name '2' '.avi']);
% writerObj.Quality=100;
% writerObj.FrameRate=10;
% open(writerObj)
% writeVideo(writerObj, mov)
% close(writerObj)
