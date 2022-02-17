function [vmavg, vmall]=analyze_vmepoch(vmep, th)

h=@calvm;
nep=length(vmep);
vmall=cell2mat(vmep');

for i=1:length(vmep)
    
    vmep2{i}=sgolayfilt(removeAP(vmep{i}, 10000, th, 4), 3, 21);
        
%     if rem(i, 5)==0
%         figure(22); clf
%         plot(vmep{i}); hold on
%         plot(vmep2{i}, 'r'); hold off
%         pause
%     end;
end;

vmavg(1)=h(vmep2);
Nboot=1000;
ci=bootci(Nboot, h, vmep2);
vmavg ([2 3])=ci';

    
function dataout=calvm(datain)
vmarray=[];
for i=1:length(datain)
    vmarray=[vmarray; datain{i}];
end;
dataout=mean(vmarray);