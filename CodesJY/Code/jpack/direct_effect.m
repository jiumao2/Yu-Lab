function direct_effect

vmcompare_onset=cell(1);
vmcompare_offset=cell(1);

i=1;
load('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0212\trial_array_ANM169799_121003_JY0212.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0229')
load('trial_array_ANM168814_121011_JY0229.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0242');
load('trial_array_ANM168814_121015_JY0242.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0271')
load('trial_array_ANM170852_121026_JY0271.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0274')
load('trial_array_ANM170852_121027_JY0274.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0302')
load('trial_array_ANM171184_121117_JY0302AAAA.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0298')
load('trial_array_ANM173440_121116_JY0298AAAA.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0309')
load('trial_array_ANM177545_121120_JY0309AAAA.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0318')
load('trial_array_ANM177545_121121_JY0318.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)
i=i+1;

cd('C:\Work\Projects\BehavingVm\Data\Vmdata\JY0331')
load('trial_array_ANM179408_121205_JY0331AAAA.mat')
[vmcompare_onset{i}, vmcompare_offset{i}]=extract_direct(T)

%%

vmcompare.onset=vmcompare_onset;
vmcompare.offset=vmcompare_offset;

cd('C:\Work\Projects\BehavingVm\Data\Groupdata')

save vmdirectstim_onoff vmcompare

von=[];
voff=[];


for i=1:length(vmcompare_onset)
    ton=vmcompare_onset{i}(:, 1);
    von(:, i)=vmcompare_onset{i}(:, 2);
    
    toff=vmcompare_offset{i}(:, 1);
    voff(:, i)=vmcompare_offset{i}(:, 2);
    
end;

subplot(2, 1, 1)
plot(ton, mean(von, 2)-mean(mean(von(1:400, :), 2)));
set(gca, 'xlim', [ton(1) ton(end)])
xlabel ('ms')
ylabel('mV')

subplot(2, 1, 2)
plot(toff, mean(voff, 2))
set(gca, 'xlim', [toff(1) toff(end)])
xlabel('ms')
ylabel('mV')



function [vonset, voffset]=extract_direct(T);

x=findM1trials(T, 'shift');
[v, aom]=findvmtrials(T, x);

v=medfilt1(v, 40);

vmstim_onarray=[];
vmstim_offarray=[];
t_onset=[-500:5000]/10;
t_offset=[-1000:10000]/10;

for i=1:length(x)
    
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
