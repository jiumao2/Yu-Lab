% Use GLM to fit the ephys data
% Output will be saved to './GLM/Unit#'
clear;
load RTarrayAll.mat

glm_dir = 'Fig/GLM';
if ~exist(glm_dir,'dir')
    mkdir(glm_dir);
end
    
%% parameters
% number_unit = 1;
mode = 'Video'; % Behavior/Video; Video Mode includes data from videos

bin_width = 20; % ms

t_pre = -2000;
t_post = 3500;

Kernels.names = {'Press','Release','Trigger','Holding'}; % Lift_start, Lift_highest, Hand, Trajectory
% press
Kernels.Press.kernel_pre = round(-1000/bin_width); % bin numbers
Kernels.Press.kernel_post = round(1000/bin_width);
% release
Kernels.Release.kernel_pre = round(-1000/bin_width);
Kernels.Release.kernel_post = round(1000/bin_width);
% trigger
Kernels.Trigger.kernel_pre = round(0/bin_width);
Kernels.Trigger.kernel_post = round(1000/bin_width);
% holding
Kernels.Holding.kernel_pre = round(-40/bin_width);
Kernels.Holding.kernel_post = round(40/bin_width);
% lift_start
Kernels.Lift_start.kernel_pre = round(-1000/bin_width);
Kernels.Lift_start.kernel_post = round(1000/bin_width);
% lift_Highest
Kernels.Lift_Highest.kernel_pre = round(-1000/bin_width);
Kernels.Lift_Highest.kernel_post = round(1000/bin_width);
% % Hand
% Kernels.Hand.kernel_pre = round(-1000/bin_width);
% Kernels.Hand.kernel_post = round(1000/bin_width);
% % Trajectory
% Kernels.Trajectory.kernel_pre = round(-2000/bin_width);
% Kernels.Trajectory.kernel_post = round(2000/bin_width);

max_kernel_post = round(1000/bin_width);
min_kernel_pre = round(-1000/bin_width);

n_folds = 2; % does not support cross validation now

% Plot
% max_figure_num_per_row = 5;

%%
Kernels.n_par = cell(1,length(Kernels.names));
for k = 1:length(Kernels.names)
    Kernels.n_par{k} = Kernels.(Kernels.names{k}).kernel_post-Kernels.(Kernels.names{k}).kernel_pre+1;
end
total_par = sum(cell2mat(Kernels.n_par));
bin_training_length = round((t_post-t_pre)/bin_width+min_kernel_pre-max_kernel_post);

%% Get event time from r
if strcmp(mode,'Behavior')
    correct_index = r.Behavior.CorrectIndex;
elseif strcmp(mode,'Video')
    if isfield(r,'VideoInfos_side')
        video_index = [r.VideoInfos_side.Index];
        correct_index = video_index(strcmp({r.VideoInfos_side.Performance},'Correct'));
    else
        video_index = [r.VideoInfos_top.Index];
        correct_index = video_index(strcmp({r.VideoInfos_top.Performance},'Correct'));
    end
end


press_time = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverPress')));
press_time_correct = press_time(correct_index);

release_time = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverRelease')));
release_time_correct = release_time(correct_index);

trigger_time = press_time + r.Behavior.Foreperiods;
trigger_time_correct = trigger_time(correct_index);

FPs_correct = r.Behavior.Foreperiods(correct_index);
long_index = find(FPs_correct==1500);
short_index = find(FPs_correct==750);

spike_time = {r.Units.SpikeTimes.timings};
%% Set the bins
bins = zeros(round((t_post-t_pre)/bin_width),length(press_time_correct));
t_bins = zeros(round(((t_post-t_pre)/bin_width+1)),length(press_time_correct));
for k = 1:size(t_bins,2)
    for j = 1:size(t_bins,1)
        t_bins(j,k) = press_time_correct(k)+bin_width*(j-1)+t_pre;
    end
end

Kernels.Press.stim = bins;
Kernels.Release.stim = bins;
Kernels.Trigger.stim = bins;
Kernels.Holding.stim = bins;

%% Bin each stimulus
for k = 1:size(bins,2)
    for j = 1:size(bins,1)
        Kernels.Press.stim(j,k) = sum(t_bins(j+1,k)>=press_time & press_time>t_bins(j,k));
        Kernels.Release.stim(j,k) = sum(t_bins(j+1,k)>=release_time & release_time>t_bins(j,k));
        Kernels.Trigger.stim(j,k) = sum(t_bins(j+1,k)>=trigger_time & trigger_time>t_bins(j,k));
        Kernels.Holding.stim(j,k) = any(t_bins(j+1,k)>=press_time & release_time>t_bins(j,k));
    end
end
%% Form training set
training_set_x = zeros(total_par,bin_training_length*size(bins,2));
count = 1;
for j = 1:size(bins,2)
    k = -min_kernel_pre+1;
    while k+max_kernel_post<=size(bins,1)      
        temp_training_set_x = [];
        for name_idx = 1:length(Kernels.names)
            temp_training_set_x = [temp_training_set_x; Kernels.(Kernels.names{name_idx}).stim(k-Kernels.(Kernels.names{name_idx}).kernel_post:k-Kernels.(Kernels.names{name_idx}).kernel_pre,j)];
        end        
        training_set_x(:,count) = temp_training_set_x;
        count = count + 1;
        k = k+1;
    end
end
training_set_x = training_set_x';
training_set_x = [ones(size(training_set_x,1),1),training_set_x];

r.GLM.training_set_x = training_set_x;

%%
for number_unit = 1:length(r.Units.SpikeTimes)
    
Kernels.ridge_lambda = num2cell(ones(1,length(Kernels.names)));
Kernels.l2_lambda = num2cell(zeros(1,length(Kernels.names)));

%% training_set_y
spikes = bins;
for k = 1:size(bins,2)
    for j = 1:size(bins,1)
        spikes(j,k) = sum(t_bins(j+1,k)>=spike_time{number_unit} & spike_time{number_unit}>t_bins(j,k));
    end
end
training_set_y = zeros(1,bin_training_length*size(bins,2));
count = 1;
for j = 1:size(bins,2)
    k = -min_kernel_pre+1;
    while k+max_kernel_post<=size(bins,1)
        training_set_y(count) = spikes(k,j);
        count = count + 1;
        k = k+1;
    end
end
training_set_y = training_set_y';
r.GLM.training_set_y{number_unit} = training_set_y;

%% Fitting
max_iter = 100;
best_smoothing_test_LL = -1e8;
wmap = rand(total_par+1,1); % initialize parameter estimate

for iter = 1:max_iter
%% === 5. Ridge regression prior ======================
opts = optimoptions('fminunc','algorithm','trust-region','SpecifyObjectiveGradient',true,'HessianFcn','objective','display','none');

% Set up grid of lambda values (ridge parameters)
lamvals = 2.^(0:20); % it's common to use a log-spaced set of values
nlam = length(lamvals);

% Precompute some quantities (X'X and X'*y) for training and test data
Imat = eye(total_par+1); % identity matrix of size of filter + const
Imat(1,1) = 0; % remove penalty on constant dc offset

% Allocate space for train and test errors
negLtrain = zeros(nlam,1);  % training error
negLtest = zeros(nlam,1);   % test error
w_ridge = zeros(total_par+1,nlam); % filters for each lambda

% Define train and test log-likelihood funcs
idx = randperm(size(training_set_x,1));
groups_idx = {};
for k = 1:n_folds
    groups_idx{k} = idx(round(size(training_set_x,1)/n_folds*(k-1)+1):round(size(training_set_x,1)/n_folds*k));
end

negLtrainfun = @(prs)neglogli_poissGLM(prs,training_set_x(groups_idx{1},:),training_set_y(groups_idx{1}),bin_width/1000); 
negLtestfun = @(prs)neglogli_poissGLM(prs,training_set_x(groups_idx{2},:),training_set_y(groups_idx{2}),bin_width/1000); 

for n_kernel = 1:length(Kernels.names)
    % Now compute MAP estimate for each ridge parameter
    for jj = 1:nlam

        % Compute ridge-penalized MAP estimate
        D = [];
        for k = 1:length(Kernels.names)
            Dx1 = spdiags(ones(Kernels.n_par{k},1)*[-1 1],0:1,Kernels.n_par{k}-1,Kernels.n_par{k}); 
            if k ~= n_kernel
                D = blkdiag(D,Kernels.ridge_lambda{k}*eye(Kernels.n_par{k})+Kernels.l2_lambda{k}*(Dx1')*Dx1);
            else
                D = blkdiag(D,lamvals(jj)*eye(Kernels.n_par{k})+Kernels.l2_lambda{k}*(Dx1')*Dx1);
            end
        end
        Cinv = blkdiag(1,D); % set inverse prior covariance
        lossfun = @(prs)neglogposterior(prs,negLtrainfun,Cinv);
        wmap = fminunc(lossfun,wmap,opts);

        % Compute negative logli
        negLtrain(jj) = negLtrainfun(wmap); % training loss
        negLtest(jj) = negLtestfun(wmap); % test loss

        % store the filter
        w_ridge(:,jj) = wmap;

    end
    [~,imin] = min(negLtest);
    Kernels.ridge_lambda{n_kernel} = lamvals(imin);
    wmap = w_ridge(:,imin);
end


%% === 6. L2 smoothing prior ===========================
% Use penalty on the squared differences between filter coefficients,
% penalizing large jumps between successive filter elements. This is
% equivalent to placing an iid zero-mean Gaussian prior on the increments
% between filter coeffs.  (See tutorial 3 for visualization of the prior
% covariance).

% This matrix computes differences between adjacent coeffs

% Select smoothing penalty by cross-validation 
lamvals = 2.^(1:16); % grid of lambda values (ridge parameters)
nlam = length(lamvals);
for n_kernel = 1:length(Kernels.names)

    % Allocate space for train and test errors
    negLtrain_sm = zeros(nlam,1);  % training error
    negLtest_sm = zeros(nlam,1);   % test error
    w_smooth = zeros(total_par+1,nlam); % filters for each lambda

    % Now compute MAP estimate for each ridge parameter
    for jj = 1:nlam

        % Compute MAP estimate
        D = [];
        for k = 1:length(Kernels.names)
            Dx1 = spdiags(ones(Kernels.n_par{k},1)*[-1 1],0:1,Kernels.n_par{k}-1,Kernels.n_par{k}); 
            if k == n_kernel
                Dx = lamvals(jj)*(Dx1')*Dx1 + Kernels.ridge_lambda{k}*eye(Kernels.n_par{k}); % computes squared diffs
            else
                Dx = Kernels.l2_lambda{k}*(Dx1')*Dx1 + Kernels.ridge_lambda{k}*eye(Kernels.n_par{k}); % computes squared diffs
            end
            D = blkdiag(D,Dx);
        end

        % Embed Dx matrix in matrix with one extra row/column for constant coeff
        D = blkdiag(0,D); 
        
        Cinv = D; % set inverse prior covariance
        lossfun = @(prs)neglogposterior(prs,negLtrainfun,Cinv);
        wmap = fminunc(lossfun,wmap,opts);

        % Compute negative logli
        negLtrain_sm(jj) = negLtrainfun(wmap); % training loss
        negLtest_sm(jj) = negLtestfun(wmap); % test loss

        % store the filter
        w_smooth(:,jj) = wmap;

    end
    [~,imin] = min(negLtest_sm);
    Kernels.l2_lambda{n_kernel} = lamvals(imin);
    wmap = w_smooth(:,imin);
end

% Last, lets see which one actually achieved lower test error
fprintf('\nIteration:      %03d\n', iter);
fprintf('\nBest ridge test LL:      %.5f\n', -min(negLtest));
fprintf('Best smoothing test LL:  %.5f\n', -min(negLtest_sm));
if -min(negLtest_sm)-best_smoothing_test_LL>0
    best_smoothing_test_LL = -min(negLtest_sm);
    wmap_best = wmap;
    close all
else
    wmap = wmap_best;
    Kernels.wmap = wmap;
    Kernels.smoothing_test_LL = -min(negLtest_sm);
    break
end
end
%% Get model output and each filter
close all;

% Prediction
prediction_length = 1000;
y = exp(training_set_x*wmap)*bin_width/1000;
h_prediction = figure;
plot(y(1:prediction_length),'r')
hold on
plot(training_set_y(1:prediction_length),'b');
k = bin_training_length;
while k < prediction_length
    xline(k,'--')
    k = k + bin_training_length;
end
xlabel('#Bin')
ylabel('Spike Count')
legend({'Model','Raw Data'})

% Show each kernel
p = 1;
w_const = wmap(p)./bin_width*1000;
p = p+1;

for name_idx = 1:length(Kernels.names)
    Kernels.(Kernels.names{name_idx}).w = flip(wmap(p:p+Kernels.n_par{name_idx}-1)./bin_width*1000);
    p = p+Kernels.n_par{name_idx};
end

h_kernel = figure;

ylim_max = max(wmap(2:end))./bin_width*1000+5;
ylim_min = min(wmap(2:end))./bin_width*1000-5;
subplot_row = 1;
subplot_col = length(Kernels.names);

for k = 1:length(Kernels.names)
subplot(subplot_row,subplot_col,k)
plot((Kernels.(Kernels.names{k}).kernel_pre:Kernels.(Kernels.names{k}).kernel_post)*bin_width,Kernels.(Kernels.names{k}).w);
xlabel('time(ms)')
xline(0,'--');
end
for k = 1:length(Kernels.names)
subplot(subplot_row,subplot_col,k);title([Kernels.names{k},' Weights']);ylim([ylim_min,ylim_max]);
end
h_kernel.Position(1) = 1;
h_kernel.Position(2) = 400;
h_kernel.Position(3) = 4*h_kernel.Position(4);

%% PSTH, aligned to press/trigger/release
y_trial = reshape(y,[],length(correct_index));
y_trial_long = y_trial(:,long_index);
y_trial_short = y_trial(:,short_index);
y_psth_long = mean(y_trial_long,2)./bin_width*1000;
y_psth_short = mean(y_trial_short,2)./bin_width*1000;

data_psth_long = mean(spikes(:,long_index,1),2)./bin_width*1000;
data_psth_short = mean(spikes(:,short_index,1),2)./bin_width*1000;


t_y = linspace(t_pre-min_kernel_pre*bin_width,t_post-max_kernel_post*bin_width,length(y_psth_long));
t_data = linspace(t_pre,t_post,size(spikes,1));
h_psth = figure;
subplot(2,1,1);
plot(t_y,y_psth_long,'r-')
hold on
plot(t_data,data_psth_long,'b-')
legend({'Model','Raw Data'})
xlabel('time(ms) related to Press')
ylabel('Firing Rate (Hz)')

subplot(2,1,2);
plot(t_y,y_psth_short,'r-')
hold on
plot(t_data,data_psth_short,'b-')
legend({'Model','Raw Data'})
xlabel('time(ms) related to Press')
ylabel('Firing Rate (Hz)')

subplot(2,1,1); title('FP = 1500ms')
subplot(2,1,2); title('FP = 750ms')

%% Save the output
Kernels.wmap = wmap;
saveas(h_psth,[glm_dir,'/PSTH_Unit',num2str(number_unit),'.png'])
saveas(h_kernel,[glm_dir,'/kernel_Unit',num2str(number_unit),'.png'])
saveas(h_prediction,[glm_dir,'/prediction_Unit',num2str(number_unit),'.png'])
save([glm_dir,'/Kernels_Unit',num2str(number_unit),'.mat'],'Kernels')
r.GLM.Kernels(number_unit) = Kernels;
end

save RTarrayAll.mat r