folder_data = 'G:\Ephys\Pierce\Sessions';
folder_raw_data = 'E:\Ephys\Pierce\SessionsRaw';
folder_names = {'20241125'};
binName = 'Exp_g0_t0.nidq.bin';

for k = 1:length(folder_names)
    folder_this = fullfile(folder_data, folder_names{k});
    path = fullfile(folder_raw_data, folder_names{k}, 'Exp_g0');

    if ~exist(fullfile(path, binName), 'file')
        warning('Data not found!');
        continue
    end

    % Parse the corresponding metafile
    meta = SGLX_readMeta.ReadMeta(binName, path);
    
    nChan = str2double(meta.nSavedChans);
    nFileSamp = str2double(meta.fileSizeBytes) / (2 * nChan);
    
    dataArray = SGLX_readMeta.ReadBin(0, nFileSamp, meta, binName, path);
    dataArray = SGLX_readMeta.GainCorrectNI(dataArray, 1, meta);
    
    LeverSignal = dataArray(2,:);

    sample_rate = str2double(meta.niSampRate);
    sample_times_sec = (1:length(LeverSignal))./sample_rate;

    % get real time
    dir_out = dir(fullfile(folder_this, 'catgt_Exp_g0/Exp_*_tcat.imec0.ap.xd_384_*_500.txt'));
    if isempty(dir_out)
        warning('Sync file in Imec not found!');
        continue
    end
    filename_imec = dir_out.name;
    
    dir_out = dir(fullfile(folder_this, 'catgt_Exp_g0/Exp_*_tcat.nidq.xa_*_500.txt'));
    if isempty(dir_out)
        warning('Sync file in NI not found!');
        continue
    end
    filename_NI = dir_out.name;
    
    cmd = ['TPrime -syncperiod=1.0 -tostream='...
        fullfile(folder_this, '\catgt_Exp_g0', filename_imec), ...
        ' -fromstream=1,',...
        fullfile(folder_this, '\catgt_Exp_g0', filename_NI),...
        ' '];
    
    writeNPY(sample_times_sec, fullfile(folder_this, '\catgt_Exp_g0\sample_times.npy'));
    cmd = [cmd, '-events=1,', folder_this, '\catgt_Exp_g0\sample_times.npy,',...
        folder_this, '\catgt_Exp_g0\sample_times_Tprime.npy '];
    
    system(cmd);

    sample_times_ms_Tprime = readNPY(fullfile(folder_this, 'catgt_Exp_g0/sample_times_Tprime.npy'))*1000;
    
    data_out = [LeverSignal; sample_times_ms_Tprime'];
    save(fullfile(folder_this, ['LeverSignal_', folder_names{k}]), 'data_out');
end

% %% send to D:\OneDrive\Work\HY_Work\SRTtoTiming\Data
% destination = 'D:\OneDrive\Work\HY_Work\SRTtoTiming\Data'; 
% 
% dir_out = dir('./20240*');
% folder_names = {dir_out.name};
% 
% for k = 1:length(folder_names)
%     folder_this = folder_names{k};
%     path = fullfile(folder_this, 'Exp_g0');
% 
%     if strcmpi(folder_this, '20240612')
%         continue
%     end
%     
%     if ~exist(fullfile(folder_this, ['LeverSignal_', folder_this, '.mat']), 'file')
%         continue
%     end
% 
%     copyfile(fullfile(folder_this, ['LeverSignal_', folder_this, '.mat']), destination);
% 
% end

