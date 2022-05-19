%% 渐变色
data = load('samp11.txt'); % 载入数据
% 输出点云图
figure;
scatter3(data(:,1),data(:,2),data(:,3),10,data(:,3),'s','filled')
view(0,90)
axis equal
axis off
colorbar
colormap(magma) % 使用magma配色方案

%% 对比色
N = 30; % 生成曲线数量/使用对比色数量
figure
axes('ColorOrder',tab10(N),'NextPlot','replacechildren') % 使用tab10配色方案
X = linspace(0,pi*3,1000);
Y = bsxfun(@(x,n)n*sin(x+2*n*pi/N), X(:), 1:N);
plot(X,Y, 'linewidth',4)