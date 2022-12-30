clear;
clc;

%% Load Frames
load testData.mat
lift_time = y;

y_all = [];
x_estimation_all = [];
y_estimation_all = [];
for k = randperm(size(X,3),50)
%% Professing definitions
t       = 1;        % loop processing interval
frame   = lift_time(k)-10;       % starting frame
u       = .000;     % control input
ksi     = [X(frame,2,1); X(frame,1,1); 0; 0]; % ICs
ksi_eta = ksi;      % state estimate
noise   = 1;       % process noise intensity
noise_x = 1;
noise_y = 1;
r = 10;

%% Kalman Filter params
R = [noise_x 0; 0 noise_y]; %coviarance of the noise
Q = [t^4/4 0 t^3/2 0; 0 t^4/4 0 t^3/2; t^3/2 0 t^2 0; 0 t^3/2 0 t^2].*noise^2; % covariance of the observation noise
P = Q; % estimate of initial state
F = [1 0 t 0; 0 1 0 t; 0 0 1 0; 0 0 0 1];  %state transition model
B = [1 0 0 0; 0 1 0 0];  %observation model
C = [(t^2/2); (t^2/2); t; t];  %control-input model
ksi_sta = []; % green node state
v = []; % green node velocity
y = []; % the measurements of the node state
ksi_sta_eta = []; %  initial state estimate
v_eta = []; % initial velocity estimate
P_eta = P;
pre_state = [];
pre_var = [];

%% do the kalman filter and plot the origianl node and estimation node
img = ReadJpegSEQ2('D:\Ephys\ANMs\Urey\Videos\20211124_video\20211124-17-37-42.000.seq',10);
    for s = frame:210
        y(:,s) = [X(s,2,k); X(s,1,k)]; % load the given moving node

        ksi_eta = F * ksi_eta + C * u;
        pre_state = [pre_state; ksi_eta(1)] ;
        P = F * P * F' + Q; %Time Update
        pre_var = [pre_var; P] ;
        K = P*B'*inv(B*P*B'+R); %the Kalman Gain
        % Measurement Update
        if ~isnan(y(:,s))
            ksi_eta = ksi_eta + K * (y(:,s) - B * ksi_eta); %using the innovations signal
        end

        P =  (eye(4)-K*B)*P; % updated estimate covariance

        ksi_sta_eta = [ksi_sta_eta; ksi_eta(1:2)];
        v_eta = [v_eta; ksi_eta(3:4)];

        x_estimation(s)=ksi_eta(2); %estimation in horizontal position
        y_estimation(s)=ksi_eta(1); %estimation in vertical position

%         r = 10;
%         j=0:.01:2*pi; %parameters of nodes
%         imshow(img);
%         axis off
%         hold on;
%         plot(r*sin(j)+y(2,s),r*cos(j)+y(1,s),'.b'); % the actual moving mode
%         plot(r*sin(j)+ksi_eta(2),r*cos(j)+ksi_eta(1),'.r'); % the kalman filtered tracking node
%         hold off
%         drawnow;
%         pause(0.01) %speed of loading frame
    end
    y_all = [y_all,y(:,frame:end)];
    x_estimation_all = [x_estimation_all, x_estimation(frame:end)];
    y_estimation_all = [y_estimation_all, y_estimation(frame:end)];
end
%%
l1=length(y_all(2,:)); n=1:l1;
figure;
plot(n,y_all(2,:),'b',n,x_estimation_all,'r');
xlabel('time'); ylabel('horizontal position');
title('position difference in horizontal direction: estimation(red) and exact(blue)');

%show the position difference in vertical direction between actual and estimation positions
figure;
plot(n,y_all(1,:),'b',n,y_estimation_all,'r');
xlabel('time'); ylabel('vertical position');
title('position difference in vertical direction: estimation(red) and exact(blue)');

%show the distance between actual and estimation positions or error
x_d=y_all(2,:)-x_estimation_all;
y_d=y_all(1,:)-y_estimation_all;
xy_d=x_d.^(2)+y_d.^(2);
xy_d=xy_d.^(1/2);
figure;
plot(n,xy_d);
xlabel('time'); ylabel('position distance');
title('distance between actual and estimation positions');

% %% show the position difference in horizontal direction between actual and estimation positions
% l1=length(y(2,frame:end)); n=1:l1;
% figure;
% plot(n,y(2,frame:end),'b',n,x_estimation(frame:end),'r');
% xlabel('time'); ylabel('horizontal position');
% title('position difference in horizontal direction: estimation(red) and exact(blue)');
% 
% %show the position difference in vertical direction between actual and estimation positions
% figure;
% plot(n,y(1,frame:end),'b',n,y_estimation(frame:end),'r');
% xlabel('time'); ylabel('vertical position');
% title('position difference in vertical direction: estimation(red) and exact(blue)');
% 
% %show the distance between actual and estimation positions or error
% x_d=y(2,frame:end)-x_estimation(frame:end);
% y_d=y(1,frame:end)-y_estimation(frame:end);
% xy_d=x_d.^(2)+y_d.^(2);
% xy_d=xy_d.^(1/2);
% figure;
% plot(n,xy_d);
% xlabel('time'); ylabel('position distance');
% title('distance between actual and estimation positions');

%show tracking with low noise
% n_very_noisy=150;
% figure;
% imagesc(img);
% axis off
% hold on;
% plot(r*sin(j)+y(2,n_very_noisy),r*cos(j)+y(1,n_very_noisy),'.b'); % the actual moving mode
% plot(r*sin(j)+x_estimation(n_very_noisy),r*cos(j)+y_estimation(n_very_noisy),'.r'); % the kalman filtered tracking node
% title('tracking with low noise: estimation(red) and actual(blue)');
% hold off

%show the mild noise tracking
%n_very_noisy=84;
%img_tmp = double(imread(img_file(n_very_noisy).name));
%img = img_tmp(:,:,1);  % load the image
%figure;
%imagesc(img);
%axis off
%hold on;
%plot(r*sin(j)+y(2,n_very_noisy),r*cos(j)+y(1,n_very_noisy),'.b'); % the actual moving mode
%plot(r*sin(j)+x_estimation(n_very_noisy),r*cos(j)+y_estimation(n_very_noisy),'.r'); % the kalman filtered tracking node
%title('tracking with mild noise: estimation(red) and actual(blue)');
%hold off

%show the very noise tracking
% n_very_noisy=123;
% figure;
% imagesc(img);
% axis off
% hold on;
% plot(r*sin(j)+y(2,n_very_noisy),r*cos(j)+y(1,n_very_noisy),'.b'); % the actual moving mode
% plot(r*sin(j)+x_estimation(n_very_noisy),r*cos(j)+y_estimation(n_very_noisy),'.r'); % the kalman filtered tracking node
% title('tracking with large noise: estimation(red) and actual(blue)');
% hold off


