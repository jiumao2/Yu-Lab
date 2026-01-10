folder_animal = 'E:\RHK\West\Ephys';
rat_name = 'West';
Experimenter = 'RHK';

dir_out = dir(folder_animal);
folder_names = {dir_out.name};

for k = 1:length(folder_names)
    folder_this = folder_names{k};
    if ~isfolder(fullfile(folder_animal, folder_this))
        continue
    end

    if length(folder_this) ~= 8
        continue
    end

    % has been sorted
    if ~isfolder(fullfile(folder_animal, folder_this, 'kilosort2_5_output'))
        continue
    end

    fprintf('Building r in %s!\n', folder_this);

    dir_out = dir(fullfile(folder_animal, folder_this, '*_Subject*.txt'));
    if isempty(dir_out) || length(dir_out) > 1
        fprintf('Wrong med files in %s!', folder_this);
        continue
    end

    med_file = dir_out.name;
    s = readcell(fullfile(folder_animal, folder_this, med_file));
    protocol = s{10,2};
    disp(protocol);

    if contains(protocol, 'Probe')
        KornblumStyle = false;
        ProbeStyle = true;
        BpodProtocol = 'OptoRecording';
    elseif contains(protocol, 'KornblumStyle')
        KornblumStyle = true;
        ProbeStyle = false;
        BpodProtocol = 'OptoRecordingSelfTimed';
    else
        KornblumStyle = false;
        ProbeStyle = false;
        BpodProtocol = 'OptoRecording';
    end

    dir_output = fullfile(folder_animal, folder_this, 'kilosort2_5_output', 'sorter_output');
    if ~isfolder(dir_output)
        dir_output = fullfile(folder_animal, folder_this, 'kilosort2_5_output');
    end

    BuildR;

    cd(fullfile(folder_animal, folder_this));

    chanMap = load(fullfile(dir_output, 'chanMap.mat'));
    KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
    KilosortOutput.save();

    i_block = 1;
    block_names = {};
    while isfile(folder_animal, folder_this, ['datafile00', num2str(i_block),'.ns6'])
        block_names{end+1} = ['datafile00', num2str(i_block),'.nev'];

        i_block = i_block + 1;
    end

    KilosortOutput.buildR(...
        'KornblumStyle', KornblumStyle,...
        'ProbeStyle', ProbeStyle,...
        'Subject', rat_name,...
        'blocks', block_names,...
        'Version', 'Version5',...
        'BpodProtocol', BpodProtocol,...
        'Experimenter', Experimenter,...
        'NS6all', NS6all,...
        'saveWaveMean', true);

    load(fullfile(folder_animal, folder_this, ['RTarray_', rat_name, '_', folder_this, '.mat']));

    if ~KornblumStyle
        Spikes.SRT.SRTSpikes(r,[]);
    else
        Spikes.Timing.KornblumSpikes(r, [], 'CombineCueUncue', false);
    end

    cd(folder_animal);
    clear r KilosortOutput spikeTable;
    close all;
end

disp('All sessions available are curated!');
