t = [0:0.05:2]; % time

U1 = 7*sin(t*pi)+10;
a1 = 5

U2 = 5*sin(5*t-4)+10;
a2 = -4

a0 = 20;

phi = a0 + a1*U1+a2*U2+4*rand(1, length(t));

figure; 
subplot(3, 1, 1)
plot(t, U1)
set(gca, 'ylim', [0 20])
subplot(3, 1, 2)
plot(t, U2);
set(gca, 'ylim', [0 20])
subplot(3, 1, 3)
plot(t, phi)

figure; plot3(U1, U2, phi, 'ko')