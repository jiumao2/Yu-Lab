function VmvsWhisking(c, c2)
% c is corr_whiskampVm

iamp={};
ivm={};


for i=1:length(c.Vm);
    
    iamp{1}=[iamp{1} mean(c.amp{i})];
    ivm{1}=[ivm{2} mean(medfilt1(c.Vm{i}, 51))];
    
end;

for i=1:length(c.Vm_nw);
    
    iamp{1}=[iamp{1} mean(c.amp_nw{i})];
    ivm=[ivm mean(medfilt1(c.Vm_nw{i}, 51))];
    
end;

figure;
ha1=subplot(2, 1, 1)
set(ha1, 'nextplot', 'add')
plot(iamp, ivm, 'ko')

if nargin>1
    
    iamp2=[];
    ivm2=[];
    
    
    for i=1:length(c2.Vm);
        
        iamp2=[iamp2 mean(c2.amp{i})];
        ivm2=[ivm2 mean(medfilt1(c2.Vm{i}, 51))];
        
    end;
    
    for i=1:length(c2.Vm_nw);
        
        iamp2=[iamp2 mean(c2.amp_nw{i})];
        ivm2=[ivm2 mean(medfilt1(c2.Vm_nw{i}, 51))];
        
    end;
    
    plot(iamp2, ivm2, 'bo')
    
end;
  