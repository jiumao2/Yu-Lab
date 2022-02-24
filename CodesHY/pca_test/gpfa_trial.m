set(groot,'defaultfigurerenderer','opengl')
data_path = 'c:/Users/jiumao/Desktop/Eli20210923';
t_pre = -1000;
t_post = 5000;
if ~exist('r','var')
    load([data_path, '/RTarrayAll.mat'])
end
spike_times = cell(length(r.Units.SpikeTimes),1);

max_spike_time = 0;
for k = 1:length(spike_times)
    spike_times{k} = r.Units.SpikeTimes(k).timings;
    if r.Units.SpikeTimes(k).timings(end)>max_spike_time
        max_spike_time = r.Units.SpikeTimes(k).timings(end);
    end
end

% unit_of_interest = [2     4     7     8    12    14    16  19];
% unit_of_interest = [1,5,7,8,9,11,12,14,19];
unit_of_interest = 1:length(r.Units.SpikeTimes);

% binned
spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

% gaussian kernel
spikes = smoothdata(spikes','gaussian',500)';
% spikes = zscore(spikes,0,2);

% pick correct trials and separate long-FP/short-FP trials
press_times = round(r.Behavior.EventTimings(r.Behavior.EventMarkers==3));
FP_long_index = r.Behavior.Foreperiods==1500;
FP_short_index = r.Behavior.Foreperiods==750;
correct_index = r.Behavior.CorrectIndex;

fp_long = [];
fp_short = [];
for k = 1:length(correct_index)
    if FP_long_index(correct_index(k))
        fp_long = [fp_long,k];
    elseif FP_short_index(correct_index(k))
        fp_short = [fp_short,k];
    end
end
FP_long_index = fp_long;
FP_short_index = fp_short;


% t_pre = -2000;
% t_post = 5000;
t_len = t_post-t_pre+1;

spikes_trial_flattened = zeros(length(unit_of_interest),t_len*length(correct_index));

for k = 1:length(correct_index)
    spikes_trial_flattened(:,t_len*(k-1)+1:t_len*k) = spikes(:,press_times(correct_index(k))+t_pre:press_times(correct_index(k))+t_post);
end

% zscore
spikes_trial_flattened = zscore(spikes_trial_flattened,0,2);
spikes_trial = reshape(spikes_trial_flattened',t_len,length(correct_index),length(unit_of_interest));

for k = 1:length(FP_long_index)
    temp = reshape(spikes_trial(:,FP_long_index(k),:),t_len,[])';
    dat(k).spikes = temp(:,1:10:end); 
    dat(k).trialId = k;
end

%%
% chunk = 2000;
% k = 1;
% while k*chunk < length(spike_series(1,:))/100
%     dat(k).trialId = k;
%     dat(k).spikes = spike_series(:,(k-1)*chunk+1:k*chunk);
%     k = k+1;
% end
% dat(1).trialId = 1;
% dat(1).spikes = spike_series(:,1:100000);
    
binWidth = 1;
% clear nwb temp tmp max_tmp k tbl 

% Results will be saved in mat_results/runXXX/, where XXX is runIdx.
% Use a new runIdx for each dataset.
runIdx = 1;

% Select method to extract neural trajectories:
% 'gpfa' -- Gaussian-process factor analysis
% 'fa'   -- Smooth and factor analysis
% 'ppca' -- Smooth and probabilistic principal components analysis
% 'pca'  -- Smooth and principal components analysis
method = 'gpfa';

% Select number of latent dimensions
xDim = 5;
% NOTE: The optimal dimensionality should be found using 
%       cross-validation (Section 2) below.

% If using a two-stage method ('fa', 'ppca', or 'pca'), select
% standard deviation (in msec) of Gaussian smoothing kernel.
kernSD = 30;
% NOTE: The optimal kernel width should be found using 
%       cross-validation (Section 2) below.

% Extract neural trajectories
result = neuralTraj(runIdx, dat, 'method', method, 'xDim', xDim,... 
                    'kernSDList', kernSD, 'binWidth', binWidth);
% NOTE: This function does most of the heavy lifting.

% Orthonormalize neural trajectories
[estParams, seqTrain] = postprocess(result, 'kernSD', kernSD);
% NOTE: The importance of orthnormalization is described on 
%       pp.621-622 of Yu et al., J Neurophysiol, 2009.

% Plot neural trajectories in 3D space
% temp = (fp1|fp2)&index1;
% plot3D(seqTrain((fp1|fp2)&index1), 'xorth', 'dimsToPlot', 1:3, 'redTrials', find(temp&fp1&index1), 'nPlotMax', sum(temp));
% plot3D(seqTrain, 'xorth', 'dimsToPlot', 1:3, 'redTrials', find(fp1&index1), 'nPlotMax',  length(seqTrain));
plot3D(seqTrain, 'xorth');

% NOTES:
% - This figure shows the time-evolution of neural population
%   activity on a single-trial basis.  Each trajectory is extracted from
%   the activity of all units on a single trial.
% - This particular example is based on multi-electrode recordings
%   in premotor and motor cortices within a 400 ms period starting 300 ms 
%   before movement onset.  The extracted trajectories appear to
%   follow the same general path, but there are clear trial-to-trial
%   differences that can be related to the physical arm movement. 
% - Analogous to Figure 8 in Yu et al., J Neurophysiol, 2009.
% WARNING:
% - If the optimal dimensionality (as assessed by cross-validation in 
%   Section 2) is greater than 3, then this plot may mask important 
%   features of the neural trajectories in the dimensions not plotted.  
%   This motivates looking at the next plot, which shows all latent 
%   dimensions.

% Plot each dimension of neural trajectories versus time
plotEachDimVsTime(seqTrain, 'xorth', result.binWidth);
% plotEachDimVsTime(seqTrain(fp1&index1), 'xorth', result.binWidth);
% plotEachDimVsTime(seqTrain(fp2&index1), 'xorth', result.binWidth);
% plotEachDimVsTime(seqTrain(fp1&index4), 'xorth', result.binWidth);
% plotEachDimVsTime(seqTrain(fp2&index4), 'xorth', result.binWidth);
% NOTES:
% - These are the same neural trajectories as in the previous figure.
%   The advantage of this figure is that we can see all latent
%   dimensions (one per panel), not just three selected dimensions.  
%   As with the previous figure, each trajectory is extracted from the 
%   population activity on a single trial.  The activity of each unit 
%   is some linear combination of each of the panels.  The panels are
%   ordered, starting with the dimension of greatest covariance
%   (in the case of 'gpfa' and 'fa') or variance (in the case of
%   'ppca' and 'pca').
% - From this figure, we can roughly estimate the optimal
%   dimensionality by counting the number of top dimensions that have
%   'meaningful' temporal structure.   In this example, the optimal 
%   dimensionality appears to be about 5.  This can be assessed
%   quantitatively using cross-validation in Section 2.
% - Analogous to Figure 7 in Yu et al., J Neurophysiol, 2009.

fprintf('\n');
fprintf('Basic extraction and plotting of neural trajectories is complete.\n');
fprintf('Press any key to start cross-validation...\n');
fprintf('[Depending on the dataset, this can take many minutes to hours.]\n');

% rmdir('mat_results','s') 
% pause;
return
%%
% ========================================================
% 2) Full cross-validation to find:
%  - optimal state dimensionality for all methods
%  - optimal smoothing kernel width for two-stage methods
% ========================================================

% Select number of cross-validation folds
numFolds = 4;

% Perform cross-validation for different state dimensionalities.
% Results are saved in mat_results/runXXX/, where XXX is runIdx.
kernSD = 5:5:20;
parfor xDim = 1:3
  neuralTraj(runIdx, dat, 'method',  'pca', 'xDim', xDim, 'numFolds', numFolds, 'binWidth', binWidth, 'kernSDList', kernSD);
  neuralTraj(runIdx, dat, 'method', 'ppca', 'xDim', xDim, 'numFolds', numFolds, 'binWidth', binWidth, 'kernSDList', kernSD);
  neuralTraj(runIdx, dat, 'method',   'fa', 'xDim', xDim, 'numFolds', numFolds, 'binWidth', binWidth, 'kernSDList', kernSD);
  neuralTraj(runIdx, dat, 'method', 'gpfa', 'xDim', xDim, 'numFolds', numFolds, 'binWidth', binWidth, 'kernSDList', kernSD);
end
fprintf('\n');
% NOTES:
% - These function calls are computationally demanding.  Cross-validation 
%   takes a long time because a separate model has to be fit for each 
%   state dimensionality and each cross-validation fold.

% Plot prediction error versus state dimensionality.
% Results files are loaded from mat_results/runXXX/, where XXX is runIdx.
kernSD = 30; % select kernSD for two-stage methods
plotPredErrorVsDim(runIdx, kernSD);
% NOTES:
% - Using this figure, we i) compare the performance (i.e,,
%   predictive ability) of different methods for extracting neural
%   trajectories, and ii) find the optimal latent dimensionality for
%   each method.  The optimal dimensionality is that which gives the
%   lowest prediction error.  For the two-stage methods, the latent
%   dimensionality and smoothing kernel width must be jointly
%   optimized, which requires looking at the next figure.
% - In this particular example, the optimal dimensionality is 5. This
%   implies that, even though the raw data are evolving in a
%   53-dimensional space (i.e., there are 53 units), the system
%   appears to be using only 5 degrees of freedom due to firing rate
%   correlations across the neural population.
% - Analogous to Figure 5A in Yu et al., J Neurophysiol, 2009.

% Plot prediction error versus kernelSD.
% Results files are loaded from mat_results/runXXX/, where XXX is runIdx.
xDim = 8; % select state dimensionality
plotPredErrorVsKernSD(runIdx, xDim);
% NOTES:
% - This figure is used to find the optimal smoothing kernel for the
%   two-stage methods.  The same smoothing kernel is used for all units.
% - In this particular example, the optimal standard deviation of a
%   Gaussian smoothing kernel with FA is 30 ms.
% - Analogous to Figures 5B and 5C in Yu et al., J Neurophysiol, 2009.
