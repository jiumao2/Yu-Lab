function PSTHOut = PopulationActivity(r,  varargin)

% 5/13/2023 Jianing Yu
% Build upon SRTSpikesPopulation
% Since we add PSTH to r, we will just use previously computed results to
% build Population activity. 
% we avoid re-compute the same stuff. 

if nargin<1
    load(Spikes.r_name)
end;
% Extract these event-related activity
Units = r.Units.SpikeNotes;
nFP = length(r.BehaviorClass.MixedFP);
PSTH_Press                  =             cell(1, nFP); % one for short FP, one for long FP
PSTH_PressZ                  =             cell(1, nFP); % one for short FP, one for long FP 

PSTH_PressAll                  =             []; % merge short and long FPs
PSTH_PressAllZ                  =          []; % one for short FP, one for long FP 
PSTH_PressAllStat           =           [];

PSTH_PressStat          =             cell(1, nFP); % this gives the statistics of press
PSTH_Release              =            cell(1, nFP);
PSTH_ReleaseZ              =          cell(1, nFP);
PSTH_ReleaseStat       =              cell(1, nFP);% this gives the statistics of release

PSTH_ReleaseAll                  =             []; % merge short and long FPs
PSTH_ReleaseAllZ                =             []; % one for short FP, one for long FP 
PSTH_ReleaseAllStat           =           [];

PSTH_Reward             =              cell(1, nFP);
PSTH_RewardZ             =             cell(1, nFP);
PSTH_RewardStat       =              cell(1, nFP); % this gives the statistics of release

PSTH_Trigger             =              cell(1, nFP);
PSTH_TriggerZ             =             cell(1, nFP);
PSTH_TriggerStat       =              cell(1, nFP); % this gives the statistics of trigger

if ~isfield(r, 'PSTH')
    error('Compute PSTH first. Run " >>Spikes.SRT.SRTSpikes(r, []);" ')
end;

n_unit = length(r.PSTH.PSTHs);
t_baseline = [-5000 -1000]; % from -5000 to -500 ms is considered to be the baseline. 
% spikes during this period will be used to normalize the neural activity(z score). 
% if the activity is extremely sparse during this period (e..g, avg rate <
% 1 Hz), we will then use the whole press_all activity to compute z score. 

for i = 1:n_unit
    PSTH_baseline = [];
    % PSTH.PressesAll =  {psth_presses_all, ts_press_all, trialspxmat_press_all, tspkmat_press_all,  t_correct_presses_all};
    if i==1
        PSTH_PressAll(1, :)          =           r.PSTH.PSTHs(i).PressesAll{2};
        PSTH_PressAllZ(1, :)        =           r.PSTH.PSTHs(i).PressesAll{2};
    end;

    PSTH_PressAll = [PSTH_PressAll; r.PSTH.PSTHs(i).PressesAll{1}];
    tspkmatpressall =  r.PSTH.PSTHs(i).PressesAll{4};
    trialspxmatpressall = r.PSTH.PSTHs(i).PressesAll{3};
    StatOut = ExamineTaskResponsive(tspkmatpressall, trialspxmatpressall);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_PressAllStat.StatOut(i)  = StatOut;
    PSTH_Trials = [];

    for kfp = 1%:length( r.PSTH.PSTHs(i).Presses)
        if i==1
            PSTH_Press{kfp}(1, :)            =          r.PSTH.PSTHs(1).PressesAll{2};
            PSTH_PressZ{kfp}(1, :)          =          r.PSTH.PSTHs(1).PressesAll{2};
            PSTH_Release{kfp}(1, :)        =          r.PSTH.PSTHs(1).ReleasesAll{2};
            PSTH_ReleaseZ{kfp}(1, :)      =          r.PSTH.PSTHs(1).ReleasesAll{2};
            PSTH_Trigger{kfp}(1, :)          =          r.PSTH.PSTHs(1).Triggers{2};
            PSTH_TriggerZ{kfp}(1, :)        =           r.PSTH.PSTHs(1).Triggers{2};
            PSTH_Reward{kfp}(1, :)         =           r.PSTH.PSTHs(1).RewardPokes{2};
            PSTH_RewardZ{kfp}(1, :)       =           r.PSTH.PSTHs(1).RewardPokes{2};
        end;
        PSTH_Press{kfp} = [PSTH_Press{kfp};  r.PSTH.PSTHs(i).PressesAll{1}];
        tspkmat  =  r.PSTH.PSTHs(i).PressesAll{4};
        trialspxmat = r.PSTH.PSTHs(i).PressesAll{3};
        
        % restricting activity to a relatively narrow window. 
        tPressWin = [-2500 1500];
        indWin = find(tspkmat>=tPressWin(1) & tspkmat<= tPressWin(2));
        tspkmat = tspkmat(indWin);
        trialspxmat = trialspxmat(indWin, :);

        StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
        StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
        PSTH_PressStat{kfp}.StatOut(i) =  StatOut;
        PSTH_Trials(kfp) = size(trialspxmat, 2);
        PSTH_baseline = [PSTH_baseline r.PSTH.PSTHs(i).PressesAll{1}];

        PSTH_Release{kfp} = [PSTH_Release{kfp};  r.PSTH.PSTHs(i).ReleasesAll{1}];
        tspkmat  =  r.PSTH.PSTHs(i).ReleasesAll{4};
        trialspxmat = r.PSTH.PSTHs(i).ReleasesAll{3};

        % restricting activity to a relatively narrow window.
        tReleaseWin = [-500 1000];
        indWin = find(tspkmat>=tReleaseWin(1) & tspkmat<= tReleaseWin(2));
        tspkmat = tspkmat(indWin);
        trialspxmat = trialspxmat(indWin, :);

        StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
        StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
        PSTH_ReleaseStat{kfp}.StatOut(i) =  StatOut;
        PSTH_baseline = [PSTH_baseline  r.PSTH.PSTHs(i).ReleasesAll{1}];

        PSTH_Trigger{kfp} = [PSTH_Trigger{kfp}; r.PSTH.PSTHs(i).Triggers{1}];
        tspkmat  =  r.PSTH.PSTHs(i).Triggers{4};
        trialspxmat = r.PSTH.PSTHs(i).Triggers{3};
        StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
        StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
        PSTH_TriggerStat{kfp}.StatOut(i) =  StatOut;

        PSTH_Reward{kfp}     =        [PSTH_Reward{kfp};  r.PSTH.PSTHs(i).RewardPokes{1}];
        tspkmat                 =        r.PSTH.PSTHs(i).RewardPokes{4};
        trialspxmat            =        r.PSTH.PSTHs(i).RewardPokes{3};

        % restricting activity to a relatively narrow window.
        tRewardWin = [-1000 1000];
        indWin = find(tspkmat>=tRewardWin(1) & tspkmat<= tRewardWin(2));
        tspkmat = tspkmat(indWin);
        trialspxmat = trialspxmat(indWin, :);

        StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);

        StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
        PSTH_RewardStat{kfp}.StatOut(i) =  StatOut;
        PSTH_baseline = [PSTH_baseline  r.PSTH.PSTHs(i).RewardPokes{1}];

        % compute z
        mean_baseline        =        mean(PSTH_baseline);
        sd_baseline              =        std(PSTH_baseline);
        PSTH_PressZ{kfp} = [PSTH_PressZ{kfp};  (r.PSTH.PSTHs(i).PressesAll{1}-mean_baseline)/sd_baseline];
        PSTH_ReleaseZ{kfp} = [PSTH_ReleaseZ{kfp};  (r.PSTH.PSTHs(i).ReleasesAll{1}-mean_baseline)/sd_baseline];
        PSTH_TriggerZ{kfp} = [PSTH_TriggerZ{kfp};  (r.PSTH.PSTHs(i).Triggers{1}-mean_baseline)/sd_baseline];
        PSTH_RewardZ{kfp}     =        [PSTH_RewardZ{kfp};  (r.PSTH.PSTHs(i).RewardPokes{1}-mean_baseline)/sd_baseline];
    end
end;

PopOut.Name                 =        r.Meta(1).Subject;
PopOut.FPs                =    r.BehaviorClass.MixedFP;
PopOut.Protocol          =  r.BehaviorClass.Protocol;
PopOut.Trials              =    PSTH_Trials;
PopOut.Session          =    r.BehaviorClass.Date;
PopOut.Date              =        strrep(r.Meta(1).DateTime(1:11), '-','_');
PopOut.Units                  =        Units;

if isfield(r.Units, 'SpikeNotesColumn5')
    PopOut.UnitsColumn5           =   r.Units.SpikeNotesColumn5;
end

PopOut.Press                  =        PSTH_Press;
PopOut.PressZ                  =        PSTH_PressZ;
PopOut.PressStat           =        PSTH_PressStat;

PopOut.PressAll                  =        PSTH_PressAll;
PopOut.PressAllZ                  =        PSTH_PressAllZ;
PopOut.PressAllStat           =        PSTH_PressAllStat;

PopOut.Release             =        PSTH_Release;
PopOut.ReleaseZ             =        PSTH_ReleaseZ;
PopOut.ReleaseStat      =        PSTH_ReleaseStat;

PopOut.ReleaseAll             =        PSTH_ReleaseAll;
PopOut.ReleaseAllZ             =        PSTH_ReleaseAllZ;
PopOut.ReleaseAllStat      =        PSTH_ReleaseAllStat;

PopOut.Reward                =        PSTH_Reward;
PopOut.RewardZ                =        PSTH_RewardZ;
PopOut.RewardStat           =        PSTH_RewardStat;
PopOut.Trigger                  =        PSTH_Trigger;
PopOut.TriggerZ                =        PSTH_TriggerZ;
PopOut.TriggerStat           =        PSTH_TriggerStat;

[PopOut.IndSort, PopOut.IndUnmodulated] = Spikes.LeverPress.RankActivityFlatS(PopOut);
% [PopOut.IndSort{3}, PopOut.IndUnmodulated{3}] = Spikes.LeverPress.RankActivityFlat(PopOut);

PopOut.IndSort = Spikes.LeverPress.VisualizePopPSTH(PopOut);
r.PopPSTH = PopOut;
r_name = ['RTarray_' r.PSTH.PSTHs(1).ANM_Session{1} '_' strrep(r.PSTH.PSTHs(1).ANM_Session{2}, '_', '') '.mat'];
save(r_name, 'r', '-v7.3');
% Save a copy of PSTHOut to a collector folder
tosavename = ['PopOut_' r.PSTH.PSTHs(1).ANM_Session{1} '_' strrep(r.PSTH.PSTHs(1).ANM_Session{2}, '_', '')  '.mat'];
save(tosavename, 'PopOut');
% thisFolder = fullfile(findonedrive, '00_Work' , '03_Projects', '05_Physiology', 'Data', 'PopulationPSTH', r.PSTH.PSTHs(1).ANM_Session{1});
% if ~exist(thisFolder, 'dir')
%     mkdir(thisFolder)
% end
% disp('##########  copying PopOut ########## ')
% tic
% copyfile(tosavename, thisFolder)
% toc
