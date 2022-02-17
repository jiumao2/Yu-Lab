function [width, allwidth, allheight]=findspkwidth(Vth, minh, toplot)
% 1.22.2015
% minh is the min height applied. 

spks=Vth.spks;
nspks=size(spks, 2);
tspk=Vth.tspks;

% resample
spks=spks-repmat(spks(1, :), size(spks, 1), 1);
spks_resample=resample(spks, 10, 1);
tspk_resample=[tspk(1):0.01:tspk(1)+0.01*(size(spks_resample, 1)-1)];

allwidth=[];
allheight=[];

figure; 
ha=axes;
set(ha, 'nextplot', 'add');
for i=1:nspks
    ispks_full=spks_resample(:, i);
    ispks=spks_resample(tspk_resample>=-0.5 & tspk_resample<=1.5, i);
    t_small=tspk_resample(tspk_resample>=-0.5 & tspk_resample<=1.5);
    %
    peak=max(ispks);
    if peak>minh
        
        % find out the spike onset, which is just before the max of d2v/d2t
        
        ddv=diff(diff(ispks));
        [~, indmax]=max(ddv);
        
        base=ispks(indmax);
        
%         base=mean(ispks(t_small>=0 & t_small<=0.1));
        hh=0.5*(peak-base)+base;

        above=find(ispks>=hh);
        %
        allwidth=[allwidth t_small(above(end))-t_small(above(1))];
        allheight=[allheight peak];
        
        if toplot
            plot(tspk_resample, ispks_full, 'k');
           % line([tspk_resample(1) tspk_resample(end)], [hh hh], 'color', 'r');
            plot(t_small(above), ispks(above), 'r.')
            plot(t_small(indmax), base, 'go', 'markersize', 5, 'linewidth', 1)
        end;
    end;
    
    %     pause(.25)
    %     cla
end;

allheight(allwidth>=prctile(allwidth, 95))=[];
allwidth(allwidth>=prctile(allwidth, 95))=[];

allheight(allwidth<=prctile(allwidth, 5))=[];
allwidth(allwidth<=prctile(allwidth, 5))=[];


figure; plot(allheight, allwidth, 'ko')

width=median(allwidth)

xlabel('height');
ylabel('width')



