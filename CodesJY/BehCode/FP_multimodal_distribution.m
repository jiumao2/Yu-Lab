function dataout = FP_multimodal_distribution

% d1 = 0.5;
% alpha1 = 12;
% 
% d2 = 1.5;
% alpha2 = 8;

d1 = 0.5;
alpha1 = 12;

d3 = 1.15;
alpha3 = 96;

d2 = 1.5;
alpha2 = 12;


t = [0:0.01:3];
B=zeros(1, length(t));

for i =1:length(t)
    ti = t(i);
    
    if ti<=d1
        B(i)=0;
        
    elseif ti>d1 & ti<=d3
        
        R1 = 9*alpha1*(ti-d1)*exp(-alpha1*((ti-d1)^2));
        R2 = 0;
        R3 =0;
        B(i)= mean([R1, R2, R3]);
        
    elseif ti>d3 & ti<=d2
        
        R1 = 9*alpha1*(ti-d1)*exp(-alpha1*((ti-d1)^2));
        R3 = 2*alpha3*(ti-d3)*exp(-alpha3*((ti-d3)^2));
        R2 = 0;
        B(i)= mean([R1, R2, R3]);
        
        
    else
        
        R1 = 9*alpha1*(ti-d1)*exp(-alpha1*((ti-d1)^2));
        R3 = 2*alpha3*(ti-d3)*exp(-alpha3*((ti-d3)^2));
        R2 = 9*alpha2*(ti-d2)*exp(-alpha2*((ti-d2)^2));
        B(i)= mean([R1, R2, R3]);
        
        
    end;
    
end;


figure; 
subplot(2, 1, 1)
hold on

% cumulative sum

BY = cumsum(B);
BY=BY/max(BY);

hold on

FPall =[];

for n =1:20  % make 10 sets of FPs
    
    fps_all = zeros(1, 600);
    
    for i=1:length(fps_all)
        
        y = sum(rand>[0 BY(1:end-1)]);
        display(num2str(t(y)))
        ty = t(y);
        fps_all(i)=ty;
    end;
    
    hold on
    FPall=[FPall fps_all];
    plot(fps_all, 2*rand(1, length(fps_all)), 'r.')
    dataout = round(fps_all*1000);
    
    sprintf('%5.0d, ', dataout);
    
    fid=fopen(['FP_multimodal' num2str(n) '.txt'],'w');
    fprintf(fid, '%d,', dataout);
    fclose(fid);true
    
end;

plot(t, BY, 'm:', 'linewidth', 2)
plot(t, B, 'k-', 'linewidth', 2)


subplot(2, 1, 2)

tbins =[0:50:3000]/1000;
tcenters = (tbins(1:end-1)+tbins(2:end))/2;
npress = histcounts(FPall, tbins);

hbar = bar(tcenters, npress);

set(gca, 'xlim', [0 3])
