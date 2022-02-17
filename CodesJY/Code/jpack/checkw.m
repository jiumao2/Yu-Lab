function checkw(w, i)

if nargin<2
    i=randperm(w.k, 1);
end;
figure(66); clf

plot(w.Vmorg(:, i));
hold on
if ~isempty(find(w.Spkorg(:, i)))
    plot(find(w.Spkorg(:, i)), prctile(w.Vmorg(:, i), 99.5), 'mo', 'linewidth', 1)
end;
axis tight
sprintf('trial# %2.2d', w.trialnums(i))

