t=[0:100];

x1 = 55*(5*sin(.2*t))+2*(3*cos(.2*t+pi/3))+10*rand(1, length(t));
x2 = 33*(5*sin(.2*t))+25*(3*cos(.2*t+pi/3))+2*rand(1, length(t));
x3 = 15*(5*sin(.2*t+rand(1, length(t))))+37*(3*cos(.2*t+pi/3))+13*rand(1, length(t));

x=[x1;x2;x3]

figure; 
subplot(5, 1, 1)
plot(t, x([1 2 3], :),'linewidth', 2)
title('Data')

[u, s, v]=svd(x);

pcas = v';

for i = 1:4
subplot(5, 1, 1+i)
plot(t, v(i, :), 'k')
title(['PCA' num2str(i)])
end;

figure;

plot(v(1, [1:30]), v(2, [1:30]), 'r', 'linewidth', 1)
hold on
plot(v(1, 1), v(2, 1), 'ko', 'linewidth', 1)

xlabel('PCA1')
ylabel('PCA2')