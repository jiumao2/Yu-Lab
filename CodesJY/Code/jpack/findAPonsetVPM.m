function APonset=findAPonsetVPM(t, psth)
% for dealing with DG's data
index=find(t>=-0.025& t<=0.1);

t=t(index);
psth=psth(index);

t_prime=t(2:end);
psth_prime=diff(psth);
base=std(psth_prime(t<0));
psth_prime2=psth_prime;
psth_prime2(t_prime<0.001)=0;
APonset=t_prime(find(psth_prime2>base*3, 1, 'first'));

if isempty(APonset) || APonset>0.05 || max(psth(t<0.1& t>0))<10
    APonset=NaN;
end;

figure(15); clf
subplot(2, 1, 1)
hbar=bar(t, psth,1, 'FaceColor',[0 0 0],'EdgeColor',[0 0 0],'LineWidth',.25);
hold on

line([APonset APonset], get(gca, 'ylim'), 'color', 'r')
axis tight
% line([t(1) t(end)], [base*3 base*3], 'color', 'k')
set(gca, 'xlim', [-0.01 0.05])

subplot(2, 1, 2)

bar(t_prime, psth_prime, 1)
hold on
line([-0.01 0.05], [base*3 base*3], 'color', 'r')
set(gca, 'xlim', [-0.01 0.05])


