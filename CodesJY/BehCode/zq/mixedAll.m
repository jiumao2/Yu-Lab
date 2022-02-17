function mixedAll(bAll)

%gcolor=[0 .5 0];

figure(21); clf(21)
set(gcf, 'unit', 'centimeters', 'position',get(0,'ScreenSize'), 'paperpositionmode', 'auto' )

%% integrated data
% 0.5
mixed_reactiontime_min=nan(100*length(bAll),1);
for i=1:length(bAll)    
    for j =1:length(bAll(i).ReactionTime.min)
    mixed_reactiontime_min(100*(i-1)+j,1)=[bAll(i).ReactionTime.min(j)];
    end 
end
mixed_reactiontime_min(isnan(mixed_reactiontime_min))=[];
% 1.0
mixed_reactiontime_mid=nan(100*length(bAll),1);
for i=1:length(bAll)    
    for j =1:length(bAll(i).ReactionTime.mid)
    mixed_reactiontime_mid(100*(i-1)+j,1)=[bAll(i).ReactionTime.mid(j)];
    end 
end
mixed_reactiontime_mid(isnan(mixed_reactiontime_mid))=[];
% 1.5
mixed_reactiontime_max=nan(100*length(bAll),1);
for i=1:length(bAll)    
    for j =1:length(bAll(i).ReactionTime.max)
    mixed_reactiontime_max(100*(i-1)+j,1)=[bAll(i).ReactionTime.max(j)];
    end 
end
mixed_reactiontime_max(isnan(mixed_reactiontime_max))=[];
% mean and sem
mean_min=mean(mixed_reactiontime_min);
mean_mid=mean(mixed_reactiontime_mid);
mean_max=mean(mixed_reactiontime_max);
% SEM_min=std(mixed_reactiontime_min)./sqrt(length(mixed_reactiontime_min));
% SEM_mid=std(mixed_reactiontime_mid)./sqrt(length(mixed_reactiontime_mid));
% SEM_max=std(mixed_reactiontime_max)./sqrt(length(mixed_reactiontime_max));
mixed_mean=[mean_min,mean_mid,mean_max];
% mixed_SEM=[SEM_min;SEM_mid;SEM_max];
% ci
ci_min=bootci(1000, @(x)mean(x),mixed_reactiontime_min);
ci_mid=bootci(1000, @(x)mean(x),mixed_reactiontime_mid);
ci_max=bootci(1000, @(x)mean(x),mixed_reactiontime_max);
ci=[ci_min,ci_mid,ci_max];
% n-1
% 0.5 n-1
FP_min_pre_min=[];
for i=1:length(bAll) 
FP_min_pre_min=[FP_min_pre_min;bAll(i).FP.min.min]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_min_pre_min(find(FP_min_pre_min==0))=[];
FP_min_pre_mid=[];
for i=1:length(bAll) 
FP_min_pre_mid=[FP_min_pre_mid;bAll(i).FP.min.mid]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_min_pre_mid(find(FP_min_pre_mid==0))=[];
FP_min_pre_max=[];
for i=1:length(bAll) 
FP_min_pre_max=[FP_min_pre_max;bAll(i).FP.min.max]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_min_pre_max(find(FP_min_pre_max==0))=[];
ci_min_min=bootci(1000, @(x)mean(x),FP_min_pre_min);
ci_min_mid=bootci(1000, @(x)mean(x),FP_min_pre_mid);
ci_min_max=bootci(1000, @(x)mean(x),FP_min_pre_max);
ci_min_pre=[ci_min_min,ci_min_mid,ci_min_max];
mean_pre_min=[mean(FP_min_pre_min),mean(FP_min_pre_mid),mean(FP_min_pre_max)];
% 1.0 n-1
FP_mid_pre_min=[];
for i=1:length(bAll) 
FP_mid_pre_min=[FP_mid_pre_min;bAll(i).FP.mid.min]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_mid_pre_min(find(FP_mid_pre_min==0))=[];
FP_mid_pre_mid=[];
for i=1:length(bAll) 
FP_mid_pre_mid=[FP_mid_pre_mid;bAll(i).FP.mid.mid]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_mid_pre_mid(find(FP_mid_pre_mid==0))=[];
FP_mid_pre_max=[];
for i=1:length(bAll) 
FP_mid_pre_max=[FP_mid_pre_max;bAll(i).FP.mid.max];% this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_mid_pre_max(find(FP_mid_pre_max==0))=[];
ci_mid_min=bootci(1000, @(x)mean(x),FP_mid_pre_min);
ci_mid_mid=bootci(1000, @(x)mean(x),FP_mid_pre_mid);
ci_mid_max=bootci(1000, @(x)mean(x),FP_mid_pre_max);
ci_mid_pre=[ci_mid_min,ci_mid_mid,ci_mid_max];
mean_pre_mid=[mean(FP_mid_pre_min),mean(FP_mid_pre_mid),mean(FP_mid_pre_max)];
% 1.5 n-1
FP_max_pre_min=[];
for i=1:length(bAll) 
FP_max_pre_min=[FP_max_pre_min;bAll(i).FP.max.min]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_max_pre_min(find(FP_max_pre_min==0))=[];
FP_max_pre_mid=[];
for i=1:length(bAll) 
FP_max_pre_mid=[FP_max_pre_mid;bAll(i).FP.max.mid]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_max_pre_mid(find(FP_max_pre_mid==0))=[];
FP_max_pre_max=[];
for i=1:length(bAll) 
FP_max_pre_max=[FP_max_pre_max;bAll(i).FP.max.max]; % this is a efficient way to integrate data than one in 0.5!!!!!!!!
end
FP_max_pre_max(find(FP_max_pre_max==0))=[];
mean_pre_max=[mean(FP_max_pre_min),mean(FP_max_pre_mid),mean(FP_max_pre_max)];
ci_max_min=bootci(1000, @(x)mean(x),FP_max_pre_min);
ci_max_mid=bootci(1000, @(x)mean(x),FP_max_pre_mid);
ci_max_max=bootci(1000, @(x)mean(x),FP_max_pre_max);
ci_max_pre=[ci_max_min,ci_max_mid,ci_max_max];

% find numbers of correct, premature and late trials
% 0.5 min
premature_min_pre=[];
late_min_pre=[];
for i=1:length(bAll)
premature_min_pre=[premature_min_pre,bAll(i).Premature(1)];
late_min_pre=[late_min_pre,bAll(i).Late(1)];
end
correct_min=length(mixed_reactiontime_min);
premature_min=sum(premature_min_pre);
late_min=sum(late_min_pre);
sum_min=correct_min+premature_min+late_min;
correct_min=correct_min/sum_min;
premature_min=premature_min/sum_min;
late_min=late_min/sum_min;
% 1.0 mid
premature_mid_pre=[];
late_mid_pre=[];
for i=1:length(bAll)
premature_mid_pre=[premature_mid_pre,bAll(i).Premature(2)];
late_mid_pre=[late_mid_pre,bAll(i).Late(2)];
end
correct_mid=length(mixed_reactiontime_mid);
premature_mid=sum(premature_mid_pre);
late_mid=sum(late_mid_pre);
sum_mid=correct_mid+premature_mid+late_mid;
correct_mid=correct_mid/sum_mid;
premature_mid=premature_mid/sum_mid;
late_mid=late_mid/sum_mid;
% 1.5 max
premature_max_pre=[];
late_max_pre=[];
for i=1:length(bAll)
premature_max_pre=[premature_max_pre,bAll(i).Premature(3)];
late_max_pre=[late_max_pre,bAll(i).Late(3)];
end
correct_max=length(mixed_reactiontime_max);
premature_max=sum(premature_max_pre);
late_max=sum(late_max_pre);
sum_max=correct_max+premature_max+late_max;
correct_max=correct_max/sum_max;
premature_max=premature_max/sum_max;
late_max=late_max/sum_max;
%% find press_durs
% integrate data
press_durs=[];
for i=1:length(bAll)
press_durs=[press_durs;bAll(i).pressdurs];
end
% find 0.5
ind_pressdurs_min=find(press_durs(:,1)==0.5);
press_durs_min=press_durs(ind_pressdurs_min,2);
% find 1.0
ind_pressdurs_mid=find(press_durs(:,1)==1);
press_durs_mid=press_durs(ind_pressdurs_mid,2);
% find 1.5
ind_pressdurs_max=find(press_durs(:,1)==1.5);
press_durs_max=press_durs(ind_pressdurs_max,2);
%% plot 
subplot(5, 5, [1 2])
plot([500 1000 1500],mixed_mean,'k-o')
set(gca, 'nextplot', 'add', 'xlim', [0 2000],'xtick',[])
plot([500,500],ci_min,'b-','linewidth',1.1)
plot([1000,1000],ci_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_max,'b-','linewidth',1.1)
box off
subplot(5, 5, [6 7 11 12])
plotSpread({mixed_reactiontime_min,mixed_reactiontime_mid,mixed_reactiontime_max},'distributionColors',[0.8 0.8 0.8],'yLabel','Reaction times(ms)','xValues',[500 1000 1500])

plot([350 650],[mean_min,mean_min],'k-','linewidth',2)
plot([850 1150],[mean_mid,mean_mid],'k-','linewidth',2)
plot([1350 1650],[mean_max,mean_max],'k-','linewidth',2)
xlabel('FP(ms)')
box off
subplot(5, 5, [3 4])
plot([500 1000 1500],mean_pre_min,'k-o')
set(gca, 'nextplot', 'add', 'xlim', [0 2000])
plot([500,500],ci_min_min,'b-','linewidth',1.1)
plot([1000,1000],ci_min_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_min_max,'b-','linewidth',1.1)
set(gca,'xtick',[0 500 1000 1500])
box off
y1=ylim;
text(1250,y1(2),'FPlast:500ms','FontSize',6)
subplot(5, 5, [8 9])
plot([500 1000 1500],mean_pre_mid,'k-o')
set(gca, 'nextplot', 'add', 'xlim', [0 2000])
plot([500,500],ci_mid_min,'b-','linewidth',1.1)
plot([1000,1000],ci_mid_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_mid_max,'b-','linewidth',1.1)
set(gca,'xtick',[0 500 1000 1500])
box off
ylabel('Reaction time(ms)','Fontsize',10)
y2=ylim;
text(1250,y2(2),'FPlast:1000ms','FontSize',6)
subplot(5, 5, [13 14])
plot([500 1000 1500],mean_pre_max,'k-o')
set(gca, 'nextplot', 'add', 'xlim', [0 2000])
plot([500,500],ci_max_min,'b-','linewidth',1.1)
plot([1000,1000],ci_max_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_max_max,'b-','linewidth',1.1)
set(gca,'xtick',[0 500 1000 1500])
box off
xlabel('FP(ms)','Fontsize',10)
y3=ylim;
text(1250,y3(2),'FPlast:1500ms','FontSize',6)
subplot(5,5,[16 17 21 22])
y = [correct_min premature_min late_min; correct_mid premature_mid late_mid;correct_max premature_max late_max;];
b = bar(y,'FaceColor','flat');
b(1).CData = [0 1 0];
b(2).CData = [0.6350 0.0780 0.1840];
b(3).CData = [0.6 0.6 0.6];
ylabel('Fraction','Fontsize',10)
set(gca, 'nextplot', 'add', 'ylim', [0 1],'xtick',[])
box off
text(0.6,0.9,'FP 500ms');
text(1.8,0.9,'1000ms')
text(2.8,0.9,'1500ms')
subplot(5,5,[18  23])
h=histogram(press_durs_min,'FaceAlpha',0,'EdgeAlpha',0);
ylabel('Counts','Fontsize',10)
xlabel('Press duration(ms)','Fontsize',10)
set(gca, 'nextplot', 'add','ylim',[0 500],'xlim',[0 3000])
h.BinEdges=[0:100:5000];
h_x=h.BinEdges+h.BinWidth/2;
h_x(end)=[];

plot([0 h_x],[0 h.Values],'k-','LineSmoothing', 'on')
plot([500 500],[0 600],'Color','g','LineStyle','--')
plot([1100 1100],[0 600],'Color','b','LineStyle','--')
% values = spcrv([[h_x(1) h_x h_x(end)];[h.Values(1) h.Values h.Values(end)]],3);
% plot(values(1,:),values(2,:), 'g');
%set(h(1),'visible','on')
%set(h(2),'color','k','linewidth',0.5)
box off 
subplot(5,5,[19  24])
h=histogram(press_durs_mid,'FaceAlpha',0,'EdgeAlpha',0);
set(gca, 'nextplot', 'add','ylim',[0 500],'xlim',[0 3000])
h.BinEdges=[0:100:5000];
h_x=h.BinEdges+h.BinWidth/2;

h_x(end)=[];
plot([0 h_x],[0 h.Values],'k-','LineSmoothing', 'on')
plot([1000 1000],[0 600],'Color','g','LineStyle','--')
plot([1600 1600],[0 600],'Color','b','LineStyle','--')
box off 
subplot(5,5,[20  25])
h=histogram(press_durs_max,'FaceAlpha',0,'EdgeAlpha',0);
set(gca, 'nextplot', 'add','ylim',[0 500],'xlim',[0 3000])
h.BinEdges=[0:100:5000];
h_x=h.BinEdges+h.BinWidth/2;
h_x(end)=[];
plot([0 h_x],[0 h.Values],'k-','LineSmoothing', 'on')
plot([1500 1500],[0 600],'Color','g','LineStyle','--')
plot([2100 2100],[0 600],'Color','b','LineStyle','--')
box off 
subplot(5,5,[10  15])
plot([500 1000 1500],mean_pre_min,'k-o','linewidth',0.5)
set(gca, 'nextplot', 'add', 'xlim', [0 2000])
plot([500,500],ci_min_min,'b-','linewidth',1.1)
plot([1000,1000],ci_min_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_min_max,'b-','linewidth',1.1)
hold on
plot([500 1000 1500],mean_pre_mid,'k-o','linewidth',1)
set(gca, 'nextplot', 'add', 'xlim', [0 2000])
plot([500,500],ci_mid_min,'b-','linewidth',1.1)
plot([1000,1000],ci_mid_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_mid_max,'b-','linewidth',1.1)
hold on
plot([500 1000 1500],mean_pre_max,'k-o','linewidth',1.5)
set(gca, 'nextplot', 'add', 'xlim', [0 2000])
plot([500,500],ci_max_min,'b-','linewidth',1.1)
plot([1000,1000],ci_max_mid,'b-','linewidth',1.1)
plot([1500,1500],ci_max_max,'b-','linewidth',1.1)
xlabel ('FP (ms)')
ylabel ('RT(ms)')
box off 

subplot(5, 5, [5])
text(0, 0.8,strrep(bAll(1).Metadata.ProtocolName, '_', '-'))
text(0,0.6,upper(bAll(1).Metadata.SubjectName))
axis off



savename = ['bmixedAll_'  upper(bAll(1).Metadata.SubjectName)];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename],'-bestfit')