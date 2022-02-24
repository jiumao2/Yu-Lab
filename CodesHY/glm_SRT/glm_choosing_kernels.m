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

t_pre = -3000;
t_post = 2500;
press_kernel_pre = round(-1000/bin_width); % bin numbers
press_kernel_post = round(1000/bin_width);
release_kernel_pre = round(-1000/bin_width);
release_kernel_post = round(1000/bin_width);
trigger_kernel_pre = round(0/bin_width);
trigger_kernel_post = round(1000/bin_width);
holding_kernel_pre = round(-40/bin_width);
holding_kernel_post = round(40/bin_width);

lift_highest_kernel_pre = round(-1000/bin_width);
lift_highest_kernel_post = round(1000/bin_width);

is_all_unit_included = false;
% spike_kernel_pre = round(-600/bin_width);
% spike_kernel_post = -1;

Kernels.kernel_pre = {press_kernel_pre,release_kernel_pre,trigger_kernel_pre,holding_kernel_pre,lift_highest_kernel_pre};
Kernels.kernel_post = {press_kernel_post,release_kernel_post,trigger_kernel_post,holding_kernel_post,lift_highest_kernel_post};

Kernels.max_kernel_post = max(cell2mat(Kernels.kernel_post));
Kernels.min_kernel_pre = min(cell2mat(Kernels.kernel_pre));

Kernels.n_folds = 5;
Kernels.t_pre = t_pre;
Kernels.t_post = t_post;
Kernels.bin_width = bin_width;

%%
% for number_unit = 1:length(r.Units.SpikeTimes)
% for number_unit = 24:24
number_unit = 24;
    
Kernels.names = {'press','release','trigger','holding','lift_highest'};
% Kernels.ridge_lambda = {1,1,1,1,1};
% Kernels.l2_lambda = {0,0,0,0,0};
Kernels.n_par = {press_kernel_post-press_kernel_pre+1,...
    release_kernel_post-release_kernel_pre+1, ...
    trigger_kernel_post-trigger_kernel_pre+1, ...
    holding_kernel_post-holding_kernel_pre+1, ...
    lift_highest_kernel_post-lift_highest_kernel_pre+1};
pos = cell(length(Kernels.n_par),1);
pos_start = 1;
for k = 1:length(Kernels.n_par)
    pos{k} = pos_start:pos_start+Kernels.n_par{k}-1;
    pos_start = pos_start+Kernels.n_par{k};
end
Kernels.pos = pos;

if is_all_unit_included
    len_unit = length(r.Units.SpikeTimes);
else
    len_unit = 1;
end
bin_training_length = round((t_post-t_pre)/bin_width+Kernels.min_kernel_pre-Kernels.max_kernel_post);
Kernels.total_par = sum(cell2mat(Kernels.n_par));

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

lift_highest_time = [r.VideoInfos.LiftHighestTime];
lift_highest_time_correct = lift_highest_time(good_index);

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
lift_highest_stim = bins;
spikes = repmat(bins,[1,1,length(r.Units.SpikeTimes)]);
%% Bin each stimulus
for k = 1:size(bins,2)
    for j = 1:size(bins,1)
        press_stim(j,k) = sum(t_bins(j+1,k)>=press_time & press_time>t_bins(j,k));
        release_stim(j,k) = sum(t_bins(j+1,k)>=release_time & release_time>t_bins(j,k));
        trigger_stim(j,k) = sum(t_bins(j+1,k)>=trigger_time & trigger_time>t_bins(j,k));
        holding_stim(j,k) = any(t_bins(j+1,k)>=press_time & release_time>t_bins(j,k));
        lift_highest_stim(j,k) = sum(t_bins(j+1,k)>=lift_highest_time & lift_highest_time>t_bins(j,k));
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
training_set_x = zeros(Kernels.total_par,bin_training_length*size(bins,2));
training_set_y = zeros(1,bin_training_length*size(bins,2));
count = 1;
for j = 1:size(bins,2)
%     k = -Kernels.min_kernel_pre+1;
    k = round(-Kernels.t_pre/Kernels.bin_width+Kernels.min_kernel_pre);
    while k+Kernels.max_kernel_post<=size(bins,1)
        if is_all_unit_included
            training_set_y(count) = spikes(k,j,number_unit);
        else
            training_set_y(count) = spikes(k,j,1);
        end
        temp_training_set_x = [];
        temp_training_set_x = [temp_training_set_x; press_stim(k+press_kernel_pre:k+press_kernel_post,j)];
        temp_training_set_x = [temp_training_set_x; release_stim(k+release_kernel_pre:k+release_kernel_post,j)];
        temp_training_set_x = [temp_training_set_x; trigger_stim(k+trigger_kernel_pre:k+trigger_kernel_post,j)];
        temp_training_set_x = [temp_training_set_x; holding_stim(k+holding_kernel_pre:k+holding_kernel_post,j)];
        temp_training_set_x = [temp_training_set_x; lift_highest_stim(k+lift_highest_kernel_pre:k+lift_highest_kernel_post,j)];
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

Kernels.training_set_x = training_set_x;
Kernels.training_set_y = training_set_y;
%%
rnd_idx = randperm(size(training_set_x,1));
break_idx = round(linspace(1,size(training_set_x,1)+1,Kernels.n_folds+1));
group_idx = cell(Kernels.n_folds,1);
for k = 1:length(break_idx)-1
    group_idx{k} = rnd_idx(break_idx(k):(break_idx(k+1)-1));
end
Kernels.group_idx = group_idx;

% %%
% names = {};
% glm_output = [];
% for k = 1:length(Kernels.names)
%     to_choose = 1:length(Kernels.names);
%     this_ind = nchoosek(to_choose,k);
%     for j = 1:size(this_ind,1)
%         all_ind = [];
%         for i = 1:size(this_ind,2)
%             all_ind = [all_ind,Kernels.pos{this_ind(j,i)}];
%             if i == 1
%                 temp_name = Kernels.names{this_ind(j,i)}(1);
%             else
%                 temp_name = [temp_name,'+',Kernels.names{this_ind(j,i)}(1)];
%             end
%         end
%         temp_training_set_x = [ones(size(training_set_x,1),1),training_set_x(:,all_ind)];
%         w = glmfit(temp_training_set_x,training_set_y,'poisson','constant','off');
%         neglogli = neglogli_poissGLM(w,temp_training_set_x,training_set_y,1);
%         glm_output = [glm_output,neglogli];
%         names{length(names)+1} = temp_name;
%     end
% end
% %%
% figure;
% bar(glm_output-min(glm_output));
% xticks(1:31)
% set(gca,'XTickLabel',names);
% set(gca,'XTickLabelRotation',-90);
% % end
