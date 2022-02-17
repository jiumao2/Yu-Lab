function [re, te, rin, tin]=pulsetrain(cellnum, code, sweepnums, bt, type, fixedRs)

cdir=pwd;

cd('C:\Work\Projects\BehavingVm\Data\physiology');

objvm=LCA.SweepArray2(cellnum, code, sweepnums);

s = LCA.SweepArray2(cellnum, code, sweepnums);
s = s.set_primary_threshold_all(12);
train=cellfun(@(x) x.rawSignal, s.sweeps, 'UniformOutput', false);
train=cell2mat(train); 


train=removeAPnew(train, 10000, 0.33, [-50 -40 50 25], 10000);

pulsedur=2500;
switch type
    
    case 'train'
        train=train(5493+9+5000:5493+pulsedur*10-1+9, :);
        figure
        train=reshape(train, pulsedur, []);
        
    case 'single'
        train=train(50100+1:50100+150*10, :);
end;
cd (cdir)

figure;
subplot(2,1,1)
plot(train(:));
subplot(2, 1, 2)
plot(mean(train(20*10:100*10, :),1)-train(1, :), 'ko-')

[re0, te0, rin0, tin0]=fitvstep(mean(train, 2), -.1, 100, 1, fixedRs);

if bt>0
     re=zeros(1, bt);
     te=zeros(1, bt);
     rin=zeros(1, bt);
     tin=zeros(1, bt);
     mse=zeros(1, bt);
     h = waitbar(0,'Just chill...');
     for i=1:bt
         itrain=mean(train(:, randsample([1:size(train, 2)], size(train, 2), true)), 2);
         itrain=itrain(1:1000);
         ttrain=[1:1000]'/10;
         [fitout, mse(i)]=quickfit(ttrain, itrain, fixedRs);
         re(i)=fitout(1); te(i)=fitout(2); rin(i)=fitout(3); tin(i)=fitout(4);
         waitbar(i/bt);
     end;
 end;
 
 close(h)
 
 re(isnan(re))=[];
 te(isnan(te))=[];
 rin(isnan(rin))=[];
 tin(isnan(tin))=[];
 mse(isnan(mse))=[];
 
 figure; hist(mse, 100)
 ind=find(mse<prctile(mse, 75)& rin<500 & rin>0 & tin<50 & re<500 & re>0 & te<5);
 
 re=re(ind);
 te=te(ind);
 rin=rin(ind);
 tin=tin(ind);
 mse=mse(ind);
 
 if bt>0
     figure;
     subplot(2, 2, 1)
     hist(re, 20);
     title ('series resistance')
     legend(num2str(round(median(re))))
     
     subplot(2, 2, 2)
     hist(te, 20);
     title('Rs time')
     legend(num2str(0.1*round(10*median(te))))
     
     subplot(2, 2, 3)
     hist(rin, 20);
     title ('input resistance')
     xlabel('Mohm')
     legend(num2str(round(median(rin))))
     
     subplot(2, 2, 4)
     hist(tin, 20);
     title('Rin time')
     xlabel('ms')
     legend(num2str(0.1*round(10*median(tin))))
     
     mfitout.re=re;
     mfitout.rin=rin;
     mfitout.te=te;
     mfitout.tin=tin;
     mfitout.mse=mse;
     
     
     set(gcf, 'userdata', mfitout)
     saveas(gcf, 'vpulsefitting_bootstrap', 'fig')
     export_fig(gcf, 'vpulsefitting_bootstrap', '-tiff');
     
 end;
 
function [aout, mse]=quickfit(t, v, fixedRs);
v=v-v(1);
Iinj=-.1;
if fixedRs==0
vx=@(a, x)Iinj*a(1)*(1-exp(-x/a(2)))+Iinj*a(3)*(1-exp(-x/a(4)));
a0=[150,1, 30, 10];
else
    vx=@(a, x)Iinj*fixedRs*(1-exp(-x/a(1)))+Iinj*a(2)*(1-exp(-x/a(3)));
a0=[1, 50, 5];
end;

try
[aout, r, j, cov, mse]=nlinfit(t, v, vx, a0);

%rsquare=1-sum(r.^2)/sum((v-mean(v)).^2);

catch err
    aout=[NaN NaN NaN NaN];
    mse=[NaN];
end;

if fixedRs~=0
    aout=[fixedRs aout];
end;
