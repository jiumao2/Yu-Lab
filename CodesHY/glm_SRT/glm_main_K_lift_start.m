% Use GLM to fit the ephys data
% Output will be saved to 'data_path/GLM/Unit#'
clear;
data_path = 'c:/Users/jiumao/Desktop/Urey20210929';
load([data_path,'/RTarrayAll.mat'])

glm_dir = [data_path,'/GLM'];
if ~exist(glm_dir,'dir')
    mkdir(glm_dir);
end

show_figure = false;
    
%% parameters
% number_unit = 1;
bin_width = 20; % ms

t_pre = -3500;
t_post = 3500;
press_kernel_pre = round(-1000/bin_width); % bin numbers
press_kernel_post = round(1000/bin_width);
release_kernel_pre = round(-1000/bin_width);
release_kernel_post = round(1000/bin_width);
trigger_kernel_pre = round(0/bin_width);
trigger_kernel_post = round(1000/bin_width);
holding_kernel_pre = round(-40/bin_width);
holding_kernel_post = round(40/bin_width);

lift_start_kernel_pre = round(-1000/bin_width);
lift_start_kernel_post = round(1500/bin_width);

is_all_unit_included = false;
% spike_kernel_pre = round(-600/bin_width);
% spike_kernel_post = -1;

max_kernel_post = round(1500/bin_width);
min_kernel_pre = round(-1000/bin_width);

n_folds = 2; % does not support cross validation now

%%
for number_unit = 1:length(r.Units.SpikeTimes)
% for number_unit = 24:24
    
Kernels.names = {'press','release','trigger','holding','lift_start'};
Kernels.ridge_lambda = {1,1,1,1,1};
Kernels.l2_lambda = {0,0,0,0,0};
Kernels.n_par = {press_kernel_post-press_kernel_pre+1,...
    release_kernel_post-release_kernel_pre+1, ...
    trigger_kernel_post-trigger_kernel_pre+1, ...
    holding_kernel_post-holding_kernel_pre+1, ...
    lift_start_kernel_post-lift_start_kernel_pre+1};

if is_all_unit_included
    len_unit = length(r.Units.SpikeTimes);
else
    len_unit = 1;
end
bin_training_length = round((t_post-t_pre)/bin_width+min_kernel_pre-max_kernel_post);
n_par = press_kernel_post-press_kernel_pre+1 ...
    +release_kernel_post-release_kernel_pre+1 ...
    +trigger_kernel_post-trigger_kernel_pre+1 ...
    +holding_kernel_post-holding_kernel_pre+1 ... 
    +lift_start_kernel_post-lift_start_kernel_pre+1;
%     +(spike_kernel_post-spike_kernel_pre+1)*len_unit;

% save_path = [data_path,'/GLM/Unit',num2str(number_unit)];
% if ~exist(save_path,'dir')
%     mkdir(save_path);
% end

%% Get event time from r
video_index = [r.VideoInfos.Index];
good_index = strcmp({r.VideoInfos.Hand},'Left') & strcmp({r.VideoInfos.Performance},'Correct');

% correct_index = r.Behavior.CorrectIndex;
correct_index = video_index(good_index);

press_time = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverPress')));
press_time_correct = press_time(correct_index);

release_time = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverRelease')));
release_time_correct = release_time(correct_index);

cue_index = find(r.Behavior.CueIndex==1);
uncue_index = find(r.Behavior.CueIndex~=1);

trigger_time = press_time(cue_index) + r.Behavior.Foreperiods(cue_index);
trigger_time_correct = press_time(intersect(correct_index,cue_index)) + r.Behavior.Foreperiods(intersect(correct_index,cue_index));

lift_start_time = [r.VideoInfos.LiftStartTime];
lift_start_time_correct = lift_start_time(good_index);

FPs_correct = r.Behavior.Foreperiods(correct_index);
cue_index_correct = find(r.Behavior.CueIndex(correct_index)==1);
uncue_index_correct = find(r.Behavior.CueIndex(correct_index)~=1);

n_neuron = length(r.Units.SpikeTimes);
spike_time = {r.Units.SpikeTimes.timings};
%% Set the bins
bins = zeros(round((t_post-t_pre)/bin_width),length(press_time_correct));
t_bins = zeros(round(((t_post-t_pre)/bin_width+1)),length(press_time_correct));
for k = 1:size(t_bins,2)
    for j = 1:size(t_bins,1)
        t_bins(j,k) = press_time_correct(k)+bin_width*(j-1)+t_pre;
    end
end

press_stim = bins;
release_stim = bins;
trigger_stim = bins;
holding_stim = bins;
lift_start_stim = bins;
spikes = repmat(bins,[1,1,length(r.Units.SpikeTimes)]);
%% Bin each stimulus
for k = 1:size(bins,2)
    for j = 1:size(bins,1)
        press_stim(j,k) = sum(t_bins(j+1,k)>=press_time & press_time>t_bins(j,k));
        release_stim(j,k) = sum(t_bins(j+1,k)>=release_time & release_time>t_bins(j,k));
        trigger_stim(j,k) = sum(t_bins(j+1,k)>=trigger_time & trigger_time>t_bins(j,k));
        holding_stim(j,k) = any(t_bins(j+1,k)>=press_time & release_time>t_bins(j,k));
        lift_start_stim(j,k) = sum(t_bins(j+1,k)>=lift_start_time & lift_start_time>t_bins(j,k));
        for i = 1:len_unit
            if is_all_unit_included
                spikes(j,k,i) = sum(t_bins(j+1,k)>=spike_time{i} & spike_time{i}>t_bins(j,k));
            else
                spikes(j,k,i) = sum(t_bins(j+1,k)>=spike_time{number_unit} & spike_time{number_unit}>t_bins(j,k));
            end
        end
    end
end
%% Form training set
training_set_x = zeros(n_par,bin_training_length*size(bins,2));
training_set_y = zeros(1,bin_training_length*size(bins,2));
count = 1;
for j = 1:size(bins,2)
    k = max_kernel_post+1;
    while k-min_kernel_pre<=size(bins,1)
        if is_all_unit_included
            training_set_y(count) = spikes(k,j,number_unit);
        else
            training_set_y(count) = spikes(k,j,1);
        end
        temp_training_set_x = [];
        temp_training_set_x = [temp_training_set_x; press_stim(k-press_kernel_post:k-press_kernel_pre,j)];
        temp_training_set_x = [temp_training_set_x; release_stim(k-release_kernel_post:k-release_kernel_pre,j)];
        temp_training_set_x = [temp_training_set_x; trigger_stim(k-trigger_kernel_post:k-trigger_kernel_pre,j)];
        temp_training_set_x = [temp_training_set_x; holding_stim(k-holding_kernel_post:k-holding_kernel_pre,j)];
        temp_training_set_x = [temp_training_set_x; lift_start_stim(k-lift_start_kernel_post:k-lift_start_kernel_pre,j)];
%         for i = 1:len_unit
%             temp_training_set_x = [temp_training_set_x; spikes(k+spike_kernel_pre:k+spike_kernel_post,j,i)];
%         end
        
        training_set_x(:,count) = temp_training_set_x;
        count = count + 1;
        k = k+1;
    end
end
training_set_x = training_set_x';
training_set_y = training_set_y';
training_set_x = [ones(size(training_set_x,1),1),training_set_x];
%% Fitting
max_iter = 100;
best_smoothing_test_LL = -1e8;

wmap = rand(n_par+1,1); % initialize parameter estimate

for iter = 1:max_iter
%% === 5. Ridge regression prior ======================
ntfilt = n_par;
ttk = 1:n_par;
opts = optimoptions('fminunc','algorithm','trust-region','SpecifyObjectiveGradient',true,'HessianFcn','objective','display','none');

% Set up grid of lambda values (ridge parameters)
lamvals = 2.^(0:20); % it's common to use a log-spaced set of values
nlam = length(lamvals);

% Precompute some quantities (X'X and X'*y) for training and test data
Imat = eye(ntfilt+1); % identity matrix of size of filter + const
Imat(1,1) = 0; % remove penalty on constant dc offset

% Allocate space for train and test errors
negLtrain = zeros(nlam,1);  % training error
negLtest = zeros(nlam,1);   % test error
w_ridge = zeros(ntfilt+1,nlam); % filters for each lambda

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
    figure;clf; plot(ttk,ttk*0,'k'); hold on; % initialize plot
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

        % plot it
        if show_figure
            plot(ttk,wmap(2:end),'linewidth', 2); 
            title(['ridge estimate: lambda = ', num2str(lamvals(jj))]);
            xlabel('time before spike (s)'); drawnow;
        end
    end
    hold off;
    [~,imin] = min(negLtest);
    Kernels.ridge_lambda{k} = lamvals(imin);
    wmap = w_ridge(:,imin);
    % note that the esimate "shrinks" down as we increase lambda
end

% Plot filter estimates and errors for ridge estimates

if show_figure
    subplot(222);
    plot(ttk,w_ridge(2:end,:)); axis tight;  
    title('all ridge estimates');
    subplot(221);
    semilogx(lamvals,-negLtrain,'o-', 'linewidth', 2);
    title('training logli');
    subplot(223); 
    semilogx(lamvals,-negLtest,'-o', 'linewidth', 2);
    xlabel('lambda');
    title('test logli');
end

% Notice that training error gets monotonically worse as we increase lambda
% However, test error has an dip at some optimal, intermediate value.

% Determine which lambda is best by selecting one with lowest test error 
[~,imin] = min(negLtest);
filt_ridge= w_ridge(2:end,imin);
if show_figure
    subplot(224);
    plot(ttk,ttk*0, 'k--', ttk,filt_ridge,'linewidth', 2);
    xlabel('time before spike (s)'); axis tight;
    title('best ridge estimate');
end
lambda_ridge = lamvals(imin);
wmap = w_ridge(:,imin);

%% === 6. L2 smoothing prior ===========================
figure;
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
    w_smooth = zeros(ntfilt+1,nlam); % filters for each lambda

    % Now compute MAP estimate for each ridge parameter
    clf; plot(ttk,ttk*0,'k'); hold on; % initialize plot
    filtML = wmap;
    wmap = filtML; % initialize with ML fit
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
        
        if show_figure
            % plot it
            plot(ttk,wmap(2:end),'linewidth',2);
            title(['smoothing estimate: lambda = ', num2str(lamvals(jj))]);
            xlabel('time before spike (s)'); drawnow;
        end

    end
    hold off;
    [~,imin] = min(negLtest_sm);
    Kernels.l2_lambda{n_kernel} = lamvals(imin);
    wmap = w_smooth(:,imin);
end

%% Plot filter estimates and errors for smoothing estimates

if show_figure
    subplot(222);
    plot(ttk,w_smooth(2:end,:)); axis tight;  
    title('all smoothing estimates');
    subplot(221);
    semilogx(lamvals,-negLtrain_sm,'o-', 'linewidth', 2);
    title('training LL');
    subplot(223); 
    semilogx(lamvals,-negLtest_sm,'-o', 'linewidth', 2);
    xlabel('lambda');
    title('test LL');
end

% Notice that training error gets monotonically worse as 5we increase lambda
% However, test error has an dip at some optimal, intermediate value.

% Determine which lambda is best by selecting one with lowest test error 
[~,imin] = min(negLtest_sm);
filt_smooth= w_smooth(2:end,imin);
if show_figure
subplot(224);
    h = plot(ttk,ttk*0, 'k--', ttk,filt_ridge,...
        ttk,filt_smooth,'linewidth', 1);
    xlabel('time before spike (s)'); axis tight;
    title('best smoothing estimate');
    legend(h(2:3), 'ridge', 'L2 smoothing', 'location', 'northwest');
end
% clearly the "L2 smoothing" filter looks better by eye!

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
    break
end
end
%% Get model output and each filter
close all;

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

p = 1;
w_const = wmap(p)./bin_width*1000;
p = p+1;
w_press = wmap(p:p+press_kernel_post-press_kernel_pre)./bin_width*1000;
p = p+press_kernel_post-press_kernel_pre+1;
w_release = wmap(p:p+release_kernel_post-release_kernel_pre)./bin_width*1000;
p = p+release_kernel_post-release_kernel_pre+1;
w_trigger = wmap(p:p+trigger_kernel_post-trigger_kernel_pre)./bin_width*1000;
p = p+trigger_kernel_post-trigger_kernel_pre+1;
w_holding = wmap(p:p+holding_kernel_post-holding_kernel_pre)./bin_width*1000;
p = p+holding_kernel_post-holding_kernel_pre+1;
w_lift_start = wmap(p:p+lift_start_kernel_post-lift_start_kernel_pre)./bin_width*1000;
p = p+lift_start_kernel_post-lift_start_kernel_pre+1;
w_spike = reshape(wmap(p:end),[],len_unit)./bin_width*1000;
h_kernel = figure;

ylim_max = max(wmap(2:end))./bin_width*1000+5;
ylim_min = min(wmap(2:end))./bin_width*1000-5;
subplot(3,2,1)
plot((press_kernel_pre:press_kernel_post)*bin_width,flip(w_press));
xlabel('time(ms)')
xline(0,'--');
subplot(3,2,2)
plot((release_kernel_pre:release_kernel_post)*bin_width,flip(w_release));
xlabel('time(ms)')
xline(0,'--');
subplot(3,2,3)
plot((trigger_kernel_pre:trigger_kernel_post)*bin_width,flip(w_trigger));
xlabel('time(ms)')
xline(0,'--');
subplot(3,2,4)
plot((holding_kernel_pre:holding_kernel_post)*bin_width,flip(w_holding));
xlabel('time(ms)')
xline(0,'--');
subplot(3,2,5)
plot((lift_start_kernel_pre:lift_start_kernel_post)*bin_width,flip(w_lift_start));
xlabel('time(ms)')
xline(0,'--');
subplot(3,2,1);title('Press Weights');ylim([ylim_min,ylim_max]);
subplot(3,2,2);title('Release Weights');ylim([ylim_min,ylim_max]);
subplot(3,2,3);title('Trigger Weights');ylim([ylim_min,ylim_max]);
subplot(3,2,4);title('Holding Weights');ylim([ylim_min,ylim_max]);
subplot(3,2,5);title('Lift (start point) Weights');ylim([ylim_min,ylim_max]);
% figure;
% ax = axes;
% if is_all_unit_included
%     for k = 1:length(r.Units.SpikeTimes)
%         subplot(5,5,k);
%         plot(spike_kernel_pre:spike_kernel_post,w_spike(:,k))
%     end
% else
%     plot(spike_kernel_pre:spike_kernel_post,w_spike)
% end
% title(ax,'Post-spike filter')
%% PSTH, aligned to press/trigger/release
y_trial = reshape(y,[],length(correct_index));
y_trial_cue = y_trial(:,cue_index_correct);
y_trial_uncue = y_trial(:,uncue_index_correct);
y_psth_cue = mean(y_trial_cue,2)./bin_width*1000;
y_psth_uncue = mean(y_trial_uncue,2)./bin_width*1000;
if is_all_unit_included
    data_psth_cue = mean(spikes(:,cue_index_correct,number_unit),2)./bin_width*1000;
    data_psth_uncue = mean(spikes(:,uncue_index_correct,number_unit),2)./bin_width*1000;
else
    data_psth_cue = mean(spikes(:,cue_index_correct,1),2)./bin_width*1000;
    data_psth_uncue = mean(spikes(:,uncue_index_correct,1),2)./bin_width*1000;
end

t_y = linspace(t_pre+max_kernel_post*bin_width,t_post+min_kernel_pre*bin_width,length(y_psth_cue));
t_data = linspace(t_pre,t_post,size(spikes,1));
h_psth = figure;
subplot(2,1,1);
plot(t_y,y_psth_cue,'r-')
hold on
plot(t_data,data_psth_cue,'b-')
legend({'Model','Raw Data'})
xlabel('time(ms) related to Press')
ylabel('Firing Rate (Hz)')

subplot(2,1,2);
plot(t_y,y_psth_uncue,'r-')
hold on
plot(t_data,data_psth_uncue,'b-')
legend({'Model','Raw Data'})
xlabel('time(ms) related to Press')
ylabel('Firing Rate (Hz)')

subplot(2,1,1); title('Cued')
subplot(2,1,2); title('Uncued')

%% Save the output
Kernels.wmap = wmap;
saveas(h_psth,[glm_dir,'/PSTH_Unit',num2str(number_unit),'.png'])
saveas(h_kernel,[glm_dir,'/kernel_Unit',num2str(number_unit),'.png'])
saveas(h_prediction,[glm_dir,'/prediction_Unit',num2str(number_unit),'.png'])
save([glm_dir,'/Kernels_Unit',num2str(number_unit),'.mat'],'Kernels')
end