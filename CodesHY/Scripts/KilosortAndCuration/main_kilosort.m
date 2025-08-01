%% you need to change most of the paths in this block
addpath(genpath('C:\Users\jiumao\Desktop\Kilosort_2_5'));
% rootZ = '.\catgt_Exp_g0'; % the raw data binary file is in this folder
% rootH = '.\catgt_Exp_g0'; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = rootZ; % take from Github folder and put it somewhere else (together with the master_file)

SGLXMetaToCoords(fullfile(rootZ, 'Exp_g0_tcat.imec0.ap.meta'));
drawnow;

chanMapFile = fullfile(rootZ, 'chanMap.mat');

ops.trange    = [0 Inf]; % time range to sort
ops.NchanTOT  = 385; % total number of channels in your recording

run('configFile384.m');
ops.fproc   = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = chanMapFile;

%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = nblocks; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 
ops.Th = [8, 3];
ops.fig = 1;

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

% set CAR
ops.CAR = 0;

% set Filter
ops.Filter = 0;

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);
%
% NEW STEP TO DO DATA REGISTRATION
rez = datashift2(rez, 1); % last input is for shifting data
drawnow;
drawnow;

% ORDER OF BATCHES IS NOW RANDOM, controlled by random number generator
iseed = 1;
                 
% main tracking and template matching algorithm
rez = learnAndSolve8b(rez, iseed);

% OPTIONAL: remove double-counted spikes - solves issue in which individual spikes are assigned to multiple templates.
% See issue 29: https://github.com/MouseLand/Kilosort/issues/29
rez = remove_ks2_duplicate_spikes(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% decide on cutoff
rez = set_cutoff(rez);
% eliminate widely spread waveforms (likely noise)
rez.good = get_good_units(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, rootZ);

% save ops
ops = rez.ops;
save(fullfile(rootZ, 'ops.mat'), 'ops');

% %% if you want to save the results to a Matlab file...
% 
% % discard features in final rez file (too slow to save)
% rez.cProj = [];
% rez.cProjPC = [];
% 
% % final time sorting of spikes, for apps that use st3 directly
% [~, isort]   = sortrows(rez.st3);
% rez.st3      = rez.st3(isort, :);
% 
% % Ensure all GPU arrays are transferred to CPU side before saving to .mat
% rez_fields = fieldnames(rez);
% for i = 1:numel(rez_fields)
%     field_name = rez_fields{i};
%     if(isa(rez.(field_name), 'gpuArray'))
%         rez.(field_name) = gather(rez.(field_name));
%     end
% end
% 
% % save final results as rez2
% fprintf('Saving final results in rez2  \n')
% fname = fullfile(rootZ, 'rez2.mat');
% save(fname, 'rez', '-v7.3');