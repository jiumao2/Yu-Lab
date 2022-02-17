function APonset=findAPonset(t, psth)

index=find(t>=-0.025& t<=0.1);

t=t(index);
psth=psth(index);

t_prime=t(2:end);
psth_prime=diff(psth);
base=std(psth_prime(t<0));
psth_prime(t_prime<0.003)=0;
APonset=t_prime(find(psth_prime>base*3, 1, 'first'));

if isempty(APonset) || APonset>0.05 || max(psth(t<0.1& t>0))<10
    APonset=NaN;
end;

figure(15); clf
plot(t, psth);
hold on

line([APonset APonset], get(gca, 'ylim'), 'color', 'r')
axis tight
% line([t(1) t(end)], [base*3 base*3], 'color', 'k')
set(gca, 'xlim', [-0.01 0.05])
