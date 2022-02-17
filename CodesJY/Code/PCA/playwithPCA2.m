t=[0:0.01:10]; % 10 second of data


x1= 5*sin(2*pi*t-pi)+3*randn(1, length(t));
x2 = x1*2.5-10+2*randn(1, length(x1));

figure; subplot(2, 1, 1);plot(t, x1, t, x2)

subplot(2, 1, 2); plot(x1, x2, 'ko')

x=[x1;x2]';

[u, s, v]=svd(x);

scores = x*v;

figure; plot(scores);

