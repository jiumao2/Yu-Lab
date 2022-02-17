function [aout_bt, ypred1, delta1]=fitpulseon(t1, v1, vb, Iinj, a0, fixedRs)
bt=2000;

if isempty(fixedRs)
mdf1=@(a, x)Iinj*a(1)*(1-exp(-x/a(2)))+Iinj*a(3)*(1-exp(-x/a(4)));

[aout,r,J,Sigma] = ...
    nlinfit(t1, mean(v1-vb, 2), mdf1, a0);

% setting up bootstrap procedure
     re=zeros(1, bt);
     te=zeros(1, bt);
     rin=zeros(1, bt);
     tin=zeros(1, bt);
     mse=zeros(1, bt);
     
     h = waitbar(0,'Just chill...');
     for i=1:bt
         ind_resample=randsample(size(v1, 2), size(v1, 2), true);
         v1_resample=v1(:, ind_resample);
         vb_resample=vb(:, ind_resample);
         
         try
             [aout_resample, ~, ~, ~, mse_resample] = ...
                 nlinfit(t1, mean(v1_resample-vb_resample, 2), mdf1, a0);
         catch err
             aout_resample=[NaN NaN NaN NaN];
             mse_resample=NaN;
         end;
         re(i)=aout_resample(1);
         te(i)=aout_resample(2);
         rin(i)=aout_resample(3);
         tin(i)=aout_resample(4);
         mse(i)=mse_resample;
         
         waitbar(i/bt);
     end;
     
     
else
mdf1=@(a, x)Iinj*fixedRs*(1-exp(-x/a(1)))+Iinj*a(2)*(1-exp(-x/a(3)));
[aout,r,J,Sigma] = ...
    nlinfit(t1, mean(v1-vb, 2), mdf1, a0);


% Calculate model predictions and confidence intervals
[ypred1,delta1] = nlpredci(mdf1,t1,aout,r,'covar',Sigma);

% setting up bootstrap procedure
     re=zeros(1, bt);
     te=zeros(1, bt);
     rin=zeros(1, bt);
     tin=zeros(1, bt);
     mse=zeros(1, bt);
     
     h = waitbar(0,'Just chill...');
     for i=1:bt
         ind_resample=randsample(size(v1, 2), size(v1, 2), true);
         v1_resample=v1(:, ind_resample);
         vb_resample=vb(:, ind_resample);
         
         try
             [aout_resample, ~, ~, ~, mse_resample] = ...
                 nlinfit(t1, mean(v1_resample-vb_resample, 2), mdf1, a0);
         catch err
             aout_resample=[NaN NaN NaN NaN];
             mse_resample=NaN;
         end;
         re(i)=fixedRs;
         te(i)=aout_resample(1);
         rin(i)=aout_resample(2);
         tin(i)=aout_resample(3);
         mse(i)=mse_resample;
         
         waitbar(i/bt);
     end;
     

% Calculate parameter confidence intervals
ci = nlparci(aout,r,'Jacobian',J);    
end;
 
 close(h)
 
 re(isnan(re))=[];
 te(isnan(te))=[];
 rin(isnan(rin))=[];
 tin(isnan(tin))=[];
 mse(isnan(mse))=[];
 
 
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
 
 
%  set(gcf, 'userdata', mfitout)
%  saveas(gcf, 'vpulsefitting_bootstrap', 'fig')
%  export_fig(gcf, 'vpulsefitting_bootstrap', '-tiff');
%  

aout_bt=[median(re) median(te) median(rin) median(tin)];
aout_bt([2 3], :)=[prctile(re, [2.5, 97.5]') prctile(te, [2.5, 97.5]') prctile(rin, [2.5, 97.5]') prctile(tin, [2.5, 97.5]')];

% Calculate model predictions and confidence intervals
if isempty(fixedRs)
    [ypred1,delta1] = nlpredci(mdf1,t1, aout_bt(1, :),r,'covar',Sigma);
else
    [ypred1,delta1] = nlpredci(mdf1,t1, aout_bt(1, 2:end),r,'covar',Sigma);
end;

% % Calculate parameter confidence intervals
% ci = nlparci(aout,r,'Jacobian',J);


