function plotnostim_vs_stim(c, cstim)

figure;
subplot(2, 2, 1)
var_Vmnw=[];
for i=1:length(c.Vm_nw)
    
    plot(rand*10, var(c.Vm_nw{i}), 'ko', 'linewidth', 1.5, 'markersize', 6);
    hold on
    var_Vmnw(i)=var(c.Vm_nw{i});
end;


title ('Vm var, nonwhisking')
var_Vmnwstim=[];
for i=1:length(cstim.Vm_nw)
    
    plot(rand*10, var(cstim.Vm_nw{i}), 'bo', 'linewidth', 1.5, 'markersize', 6);
    hold on
    var_Vmnwstim(i)=var(cstim.Vm_nw{i});
    
end;


subplot(2, 2, 2)
for i=1:length(c.Vm)
    
    plot(rand*10, var(c.Vm{i}), 'ko', 'linewidth', 1.5, 'markersize', 6);
    hold on
    
end;
for i=1:length(cstim.Vm)
    
    plot(rand*10, var(cstim.Vm{i}), 'bo', 'linewidth', 1.5, 'markersize', 6);
    hold on
    
end;
title ('Vm var, whisking')


subplot(2, 2, 3)
for i=1:length(c.Vm_nw)
    
    plot(rand*10, mean(c.Vm_nw{i}), 'ko', 'linewidth', 1.5, 'markersize', 6);
    hold on
    
end;


for i=1:length(cstim.Vm_nw)
    
    plot(rand*10, mean(cstim.Vm_nw{i}), 'bo', 'linewidth', 1.5, 'markersize', 6);
    hold on
    
end;



title ('Vm avg, nonwhisking')


subplot(2, 2, 4)
for i=1:length(c.Vm)
    
    plot(rand*10, mean(c.Vm{i}), 'ko', 'linewidth', 1.5, 'markersize', 6);
    hold on
    
end;
for i=1:length(cstim.Vm)
    
    plot(rand*10, mean(cstim.Vm{i}), 'bo', 'linewidth', 1.5, 'markersize', 6);
    hold on
    
end;

title ('Vm avg,whisking')

