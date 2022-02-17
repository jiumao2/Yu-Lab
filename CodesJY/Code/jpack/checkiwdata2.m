function checkiwdata2(iwdata2, i)

figure(66); clf

plot(iwdata2.Vmorg(:, i));
hold on
plot(find(iwdata2.Spkorg(:, i)), iwdata2.Vmorg(find(iwdata2.Spkorg(:, i)), i), '^r')




