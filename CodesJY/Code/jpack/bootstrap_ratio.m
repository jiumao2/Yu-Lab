function [bootciout samplestat]=bootstrap_ratio(x1, x2, x3)

% calculate the confidence interval of this: (x3-x1)/(x2-x1)

nreps=1000;

bootstrapstat=zeros(1, nreps);

for i=1:nreps
    
    resamplex1=x1(ceil(rand(size(x1))*length(x1)));
    resamplex2=x2(ceil(rand(size(x2))*length(x2)));
    resamplex3=x3(ceil(rand(size(x3))*length(x3)));
   %  bootstrapstat(i)=(median(resamplex3)-median(resamplex1))/(median(resamplex2)-median(resamplex1));
    bootstrapstat(i)=(mean(resamplex3)-mean(resamplex1))/(mean(resamplex2)-mean(resamplex1));

    
end;

% samplestat=(median(x3)-median(x1))/(median(x2)-median(x1));
samplestat=(mean(x3)-mean(x1))/(mean(x2)-mean(x1));
bootciout=prctile(bootstrapstat, [50-95/2 50+95/2]);

figure(111)
clf
xx = min(bootstrapstat):.01:max(bootstrapstat);
hist(bootstrapstat,xx);
hold on
ylim = get(gca,'YLim');
plot(samplestat*[1,1],ylim,'y-','LineWidth',2);
plot(mean(bootstrapstat)*[1,1],ylim,'g-','LineWidth',2);
plot(bootciout(1)*[1,1],ylim,'r-','LineWidth',2);
plot(bootciout(2)*[1,1],ylim,'r-','LineWidth',2);
plot([1,1],ylim,'b-','LineWidth',2)
%set(gca,'XTick',[-10:.5:10]);
title('bootstrapping on a ratio of variances');
