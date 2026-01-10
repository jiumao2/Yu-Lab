% get all wrot
dir_this = 'E:\RHK\West\Ephys';
folder_kilosort = 'C:\Users\jiumao\Desktop\Kilosort_2_5';
addpath(genpath(folder_kilosort));

dir_out = dir('./');
folders = {dir_out.name};

for k = 1:length(folders)
    if length(folders{k}) ~= 8 
        continue
    end

    folder_data = fullfile(dir_this, folders{k}, 'kilosort2_5_output', 'sorter_output');
    if ~isfolder(folder_data)
        folder_data = fullfile(dir_this, folders{k}, 'kilosort2_5_output');
        if ~isfolder(folder_data)
            continue
        end
    end

    cd(folder_data);
    
    % Load channel map file
    load('chanMap.mat');
    
    % Load the configuration file, it builds the structure of options (ops)
    load('ops.mat');
    
    % preprocess data to create temp_wh.dat
    
    ops.nt0 	  = getOr(ops, {'nt0'}, 61); % number of time samples for the templates (has to be <=81 due to GPU shared memory)
    ops.nt0min  = getOr(ops, 'nt0min', ceil(20 * ops.nt0/61)); % time sample where the negative peak should be aligned
    
    NT       = ops.NT ; % number of timepoints per batch
    NchanTOT = ops.NchanTOT; % total number of channels in the raw binary file, including dead, auxiliary etc
    
    ops.fbinary = './recording.dat';
    o = dir(ops.fbinary);
    bytes = o.bytes;
    nTimepoints = floor(bytes/NchanTOT/2); % number of total timepoints
    ops.tstart  = ceil(ops.trange(1) * ops.fs); % starting timepoint for processing data segment
    ops.tend    = min(nTimepoints, ceil(ops.trange(2) * ops.fs)); % ending timepoint
    ops.sampsToRead = ops.tend-ops.tstart; % total number of samples to read
    ops.twind = ops.tstart * NchanTOT*2; % skip this many bytes at the start
    
    Nbatch      = ceil(ops.sampsToRead /NT); % number of data batches
    ops.Nbatch = Nbatch;
    
    ops.chanMap = './chanMap.mat';
    [chanMap, xc, yc, kcoords, NchanTOTdefault] = loadChanMap(ops.chanMap); % function to load channel map file
    ops.NchanTOT = getOr(ops, 'NchanTOT', NchanTOTdefault); % if NchanTOT was left empty, then overwrite with the default
    
    ops.igood = true(size(chanMap));
    
    ops.Nchan = numel(chanMap); % total number of good channels that we will spike sort
    ops.Nfilt = getOr(ops, 'nfilt_factor', 4) * ops.Nchan; % upper bound on the number of templates we can have
    
    rez.ops         = ops; % memorize ops
    
    rez.xc = xc; % for historical reasons, make all these copies of the channel coordinates
    rez.yc = yc;
    rez.xcoords = xc;
    rez.ycoords = yc;
    % rez.connected   = connected;
    rez.ops.chanMap = chanMap;
    rez.ops.kcoords = kcoords;
    
    
    NTbuff      = NT + 3*ops.ntbuff; % we need buffers on both sides for filtering
    
    rez.ops.Nbatch = Nbatch;
    rez.ops.NTbuff = NTbuff;
    rez.ops.chanMap = chanMap;
    
    % this requires removing bad channels first
    Wrot = get_whitening_matrix(rez);

    save(fullfile(folder_data, 'Wrot.mat'), 'Wrot');
    
    clear rez ops 
    cd(dir_this);

    disp([folders{k}, ' done!']);
end





