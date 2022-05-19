%% ����ɫ
data = load('samp11.txt'); % ��������
% �������ͼ
figure;
scatter3(data(:,1),data(:,2),data(:,3),10,data(:,3),'s','filled')
view(0,90)
axis equal
axis off
colorbar
colormap(magma) % ʹ��magma��ɫ����

%% �Ա�ɫ
N = 30; % ������������/ʹ�öԱ�ɫ����
figure
axes('ColorOrder',tab10(N),'NextPlot','replacechildren') % ʹ��tab10��ɫ����
X = linspace(0,pi*3,1000);
Y = bsxfun(@(x,n)n*sin(x+2*n*pi/N), X(:), 1:N);
plot(X,Y, 'linewidth',4)