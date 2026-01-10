folder_animal = 'J:\Punch';
rat_name = 'Punch';
Experimenter = 'ZQ';

dir_out = dir(folder_animal);
folder_names = {dir_out.name};

while true
    for k = 1:length(folder_names)
        folder_this = folder_names{k};
        if ~exist(fullfile(folder_animal, folder_this), 'dir')
            continue
        end
    
        if length(folder_this) ~= 8
            continue
        end
    
        % has been sorted
        if ~exist(fullfile(folder_animal, folder_this, 'catgt_Exp_g0', 'params.py'), 'file')
            continue
        end

        % has been curated
        if ~exist(fullfile(folder_animal, folder_this, 'catgt_Exp_g0', 'QualityMetrics.mat'), 'file')
            continue
        end
    
        % has built R
        if exist(fullfile(folder_animal, folder_this, ['RTarray_', rat_name, '_', folder_this, '.mat']), 'file')
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
    
        dir_output = fullfile(folder_animal, folder_this, 'catgt_Exp_g0');
        BuildR;
        
        cd(fullfile(folder_animal, folder_this));
    
        chanMap = load(fullfile(dir_output, 'chanMap.mat'));
        KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
        KilosortOutput.save();
        KilosortOutput.buildRNeuropixels(...
            'KornblumStyle', KornblumStyle,...
            'ProbeStyle', ProbeStyle,...
            'Subject', rat_name,...
            'BpodProtocol', BpodProtocol,... % 'OptoRecordingSelfTimed' for KB sessions
            'Experimenter', Experimenter);
    
        cd(folder_animal);
        clear r KilosortOutput spikeTable;
        close all;
    end
    
    disp('All sessions available are curated!');
    pause(60);    
end