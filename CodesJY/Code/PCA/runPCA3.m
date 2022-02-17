% from steve brunton's lecture

clear all; close all; clc


x1 = rand(1, 100)*10;
x1 = x1-mean(x1);

x2 = x1*tan(pi*40/180)+2*rand(1, length(x1));

x3 = x1*tan(pi*60/180-pi/2)*1.25+4*rand(1, length(x1));

X =[x2' x3']; % 100 x 2


% SVD: X = U*S*V*

[u, s, v] = svd(X)
[c, sc]=pca(X);

% u: 100* 100
% s: 100*2
% v: 2*2

% U*S = X*V
figure; 

subplot(2, 1, 1)
plot(X(:, 1), 'b');
hold on
plot(X(:, 2), 'r')


subplot(2, 1, 2)
plot(sc(:, 1), 'm');
hold on
plot(sc(:, 2), 'c')

figure; plot(X(:, 1), X(:, 2), 'ko')


xproject = X*v;


subplot(4, 1, 1)
plot(x1, x2, 'ko'); hold on
plot(x1(20), x2(20), 'mo', 'markerfacecolor', 'm')
plot(x1(60), x2(60), 'mo', 'markerfacecolor', 'g')

subplot(4, 1, 2)
plot(xproject(:, 1), xproject(:, 2), 'ro'); hold on

x12project_single=[x1(20) x2(20)]*v;
x12project_single2=[x1(60) x2(60)]*v;

plot(x12project_single(1), x12project_single(2), 'mo', 'markerfacecolor', 'm')
plot(x12project_single2(1), x12project_single2(2), 'go', 'markerfacecolor', 'g')

axis equal
