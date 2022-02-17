function [vonset, voffset]=extract_direct(T, trialnums);

[v, aom]=findvmtrials(T, trialnums);

v=medfilt1(v, 40);

vmstim_onarray=[];
vmstim_offarray=[];
t_onset=[-500:5000]/10;
t_offset=[-1000:10000]/10;

for i=1:length(trialnums)
    
    aom_onset(i)=find(aom(:, i)>=1, 1, 'first');
    aom_offset(i)=find(aom(:, i)>=1, 1, 'last');
    
    ind_onset=[aom_onset(i)-500:aom_onset(i)+5000];
    ind_offset=[aom_offset(i)-1000:aom_offset(i)+10000];
    
    vmstim_i=v(:, i);
    
    vmstim_onarray(:, i)=vmstim_i(ind_onset);
    vmstim_offarray(:, i)=vmstim_i(ind_offset);
    
    aom_onarray(:,i)=aom(ind_onset,i);
    aom_offarray(:,i)=aom(ind_offset, i);
    
end;

vonset=[t_onset', mean(vmstim_onarray, 2)];
voffset=[t_offset', mean(vmstim_offarray, 2)];