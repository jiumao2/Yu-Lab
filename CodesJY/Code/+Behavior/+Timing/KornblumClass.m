classdef KornblumClass  
    % Takes the original bdata from MED, build a class for computing and plotting 
    %  Jianing Yu 8/28/2022

    % Adapted to Kornblum style
    %  Jianing Yu 9/5/2022 

    properties

        Subject
        Strain
        Date
        Experimenter
        Session
        Protocol
        Treatment
        Dose
        ResponseWindow
        Cue
        TrialNum
        PressIndex
        PressTime
        ReleaseTime
        HoldTime
        FP
        MixedFP
        ToneTime
        ReactionTime
        Outcome        
        Fig1
        RTbinEdges
        HoldTbinEdges
        RTbinCenters
        HoldTbinCenters
        WinSize
        StepSize
    end;

    properties (SetAccess = private)

    end

    properties (Constant)
        PerformanceType = {'Correct', 'Premature', 'Late'};
        ToneTimeNotation = {'Any positive number, tone time for correct or late release';
            '0, FP ending for uncued correct or late release';
            'NaN, premature or dark trials'}
        BinSize        = 0.02;
    end
    properties (Dependent)
        Performance
        AvgRT
        AvgRTLoose
        AvgHoldTime
        AvgHoldTimeLoose
        RTDistribution % check
        RTDistributionLoose % check
        HoldTimeDistribution % check
        PerformanceSlidingWindow % cal performance within a sliding window
        Stage % 0: warm up, 1: advanced
 
    end

    methods
        function obj = KornblumClass(medfile)
            if ~isstruct(medfile)
                if nargin==0
                    medfile = dir('*_Subject*.txt');
                    if length(medfile)>1
                        clc
                        error('More than one MED file is found')
                    end;
                    medfile = medfile.name;
                    disp(medfile)
                end;
                %UNTITLED2 Construct an instance of this class
                %   Detailed explanation goes here
                bdata = Behavior.MED.track_training_progress_advanced_KornblumStyle(medfile);
                % b2 = BehaviorClass(b);
            else
                bdata = medfile;
            end
          
            obj.TrialNum        =       length(bdata.PressTime);
            obj.PressIndex     =       [1:obj.TrialNum];

            % Session information
            obj.Subject         =       extractAfter(bdata.SessionName, 'Subject ');
            obj.Session        =        extractBefore(bdata.SessionName, '-Subject ');
            obj.Date             =        bdata.Metadata.Date;
            obj.Protocol       =       extractAfter(bdata.Metadata.ProtocolName, 'FR1_');
            obj.Cue               =       bdata.Cue;

            % Window size
            obj.WinSize = round(length(bdata.FPs)/10);
            obj.StepSize = round(length(bdata.FPs)/40);

            % Press
            obj.PressTime           = bdata.PressTime;
            obj.ReleaseTime      = bdata.ReleaseTime;
            obj.HoldTime            = bdata.ReleaseTime - bdata.PressTime;
            obj.ToneTime           = [];
            obj.FP                        = bdata.FPs;
            protocol                    = bdata.Metadata.ProtocolName;            
            obj.MixedFP             = str2double(cell2mat(extractBetween(protocol, 'Bpod', 'ms'))); % extract FP from protocol name
            obj.Fig1                     = randperm(1000, 1);
            obj.RTbinEdges                              =          [0:obj.BinSize:2];
            obj.RTbinCenters                            =         (obj.RTbinEdges(1:end-1)+ obj.RTbinEdges(2:end))/2;
            obj.HoldTbinEdges                         =          [0:obj.BinSize:4];
            obj.HoldTbinCenters                       =          (obj.HoldTbinEdges(1:end-1)+ obj.HoldTbinEdges(2:end))/2;

            % Read exeperiment
            switch bdata.Metadata.Experiment
                case {'Saline'}
                        obj.Treatment = 'Saline';
                        obj.Dose = 0;
                case {'0.25DCZ', '0.5DCZ', '1DCZ', '0.125DCZ'}
                        obj.Treatment = 'DCZ';
                        obj.Dose = str2num(extractBefore(bdata.Metadata.Experiment, 'DCZ'));
            end;

            obj.Outcome = [];
            for i =1:length(bdata.PressTime)
                if ~isempty(find(bdata.Correct == i, 1))
                    obj.Outcome{i} = 'Correct';
                    % find tone time
                    indTone = find(bdata.TimeTone - bdata.PressTime(i)>0, 1, 'first');
                    if ~isempty(indTone) && bdata.TimeTone(indTone) < obj.ReleaseTime(i)
                        obj.ToneTime(i) = bdata.TimeTone(indTone);
                        obj.ReactionTime(i) = obj.ReleaseTime(i) - obj.ToneTime(i);
                        obj.Cue(i) = 1;
                    else  % cannot find tone time but the performance is correct (must be a correct release in uncued trials)
                        obj.ToneTime(i) = 0;
                        obj.ReactionTime(i) = obj.ReleaseTime(i) - (obj.PressTime(i)+obj.FP(i)/1000);
                    end;

                elseif  ~isempty(find(bdata.Premature == i, 1))
                    obj.Outcome{i} = 'Premature';                    
                    obj.ToneTime(i)= NaN;
                    obj.ReactionTime(i) = NaN;

                elseif ~isempty(find(bdata.Late == i, 1))
                    obj.Outcome{i} = 'Late';
                    % find tone time
                    indTone = find(bdata.TimeTone - bdata.PressTime(i)>0, 1, 'first');
                    if ~isempty(indTone) && bdata.TimeTone(indTone) < obj.ReleaseTime(i)
                        obj.ToneTime(i) = bdata.TimeTone(indTone);
                        obj.ReactionTime(i) = obj.ReleaseTime(i) - obj.ToneTime(i);
                        obj.Cue(i) = 1;
                    else  % cannot find tone time
                        obj.ToneTime(i) = 0;
                        obj.ReactionTime(i) = obj.ReleaseTime(i) - (obj.PressTime(i)+obj.FP(i)/1000);
                    end;

                elseif ~isempty(find(bdata.Dark == i, 1)) 
                    obj.Outcome{i}              =       'Dark';
                    obj.ToneTime(i)             =       NaN;
                    obj.ReactionTime(i)      =      NaN;
                else
                    obj.Outcome{i}              =      'Dark';
                    obj.ToneTime(i)             =       NaN;
                    obj.ReactionTime(i)      =      NaN;
                end;
            end; 
        end

        function obj = set.Experimenter(obj,person_name)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Experimenter = string(person_name);
        end
 

        function obj = set.Treatment(obj,treatment)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~isempty(treatment)
                if ismember(treatment, {'NaN', 'Saline', 'DCZ'})
                    obj.Treatment = string(treatment);
                else
                    error(['Treatment can only be: NaN, Saline, DCZ'])
                end;
            end;
        end

        function obj = set.Dose(obj,dose)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isnumeric(dose)
                obj.Dose = dose;
            else
                error('"dose" must be a scalar')
            end;
        end

        function value=get.PerformanceSlidingWindow(obj)

            WinSize = obj.WinSize;
            StepSize = obj.StepSize;

            CountStart = 1;
            WinPos = [];
            CorrectRatio=[];
            PrematureRatio=[];
            LateRatio=[];
            CueTypes = [0 1];
            TrialIndex = [];

            while CountStart+WinSize < obj.TrialNum
                thisWin                    =          [CountStart:CountStart + WinSize];
                thisOutcome           =           obj.Outcome(thisWin);
                thisCueTypes          =           obj.Cue(thisWin);
                CorrectRatio            =           [CorrectRatio; 100*sum(strcmp(thisOutcome, 'Correct') & thisCueTypes == 0)/sum(thisCueTypes == 0) 100*sum(strcmp(thisOutcome, 'Correct') & thisCueTypes == 1)/sum(thisCueTypes == 1)];
                PrematureRatio      =           [PrematureRatio; 100*sum(strcmp(thisOutcome, 'Premature') & thisCueTypes == 0)/sum(thisCueTypes == 0) 100*sum(strcmp(thisOutcome, 'Premature') & thisCueTypes == 1)/sum(thisCueTypes == 1)];
                LateRatio                  =            [LateRatio; 100*sum(strcmp(thisOutcome, 'Late') & thisCueTypes == 0)/sum(thisCueTypes == 0) 100*sum(strcmp(thisOutcome, 'Late') & thisCueTypes == 1)/sum(thisCueTypes == 1)];
                WinPos                      =           [WinPos obj.PressTime(thisWin(end))];
                TrialIndex                  =           [TrialIndex thisWin(end)];
                CountStart                =           CountStart + StepSize;
            end;

            value = table(TrialIndex', WinPos', CorrectRatio(:, 2), CorrectRatio(:, 1), PrematureRatio(:, 2), PrematureRatio(:, 1), ...
                LateRatio(:, 2), LateRatio(:, 1), 'VariableNames',{'Trial_Index', 'Time', 'Correct_Cued', 'Correct_Uncued', 'Premature_Cued', ...
                'Premature_Uncued', 'Late_Cued', 'Late_Uncued'});
        end;

        function obj = set.MixedFP(obj,fp)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isnumeric(fp)
                obj.MixedFP = fp;
            else
                error('FP should be numeric')
            end;
        end

        function obj = set.Strain(obj,strain)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~isempty(strain) && ismember(strain, {'BN', 'Wistar', 'LE', 'SD', 'Hybrid'})
                obj.Strain = string(strain);
            end

        end

        function value = get.RTDistribution(obj)
            % Cued
            CuedRT = obj.ReactionTime(obj.Cue == 1 & strcmp(obj.Outcome, 'Correct'));
            binEdges = obj.RTbinEdges;
            binCenters = obj.RTbinCenters;
            PDF_Cued =  ksdensity(CuedRT, obj.RTbinEdges, 'function', 'pdf');
            CDF_Cued =  ksdensity(CuedRT, obj.RTbinEdges, 'function', 'cdf');
            % Uncued
            UncuedRT = obj.ReactionTime(obj.Cue == 0 & strcmp(obj.Outcome, 'Correct'));
            PDF_Uncued =  ksdensity(UncuedRT, obj.RTbinEdges, 'function', 'pdf');
            CDF_Uncued =  ksdensity(UncuedRT, obj.RTbinEdges, 'function', 'cdf');
            value = table(obj.RTbinEdges',PDF_Cued', CDF_Cued', PDF_Uncued', CDF_Uncued', ...
                'VariableNames',{'BinEdges', 'PDF_Cued', 'CDF_Cued', 'PDF_Uncued', 'CDF_Uncued'});

%             [data2575] = prctile(CuedRT, [25, 75]);
%             interq = data2575(2) - data2575(1);
%             c=5;
%             CuedRT(CuedRT>data2575(2)+interq*c | CuedRT<data2575(1)-interq*c) = [];
%             binEdges = [0:0.05:2];
%             binCenters = (binEdges(1:end-1)+binEdges(2:end))/2;
%             [data2575] = prctile(UncuedRT, [25, 75]);
%             interq = data2575(2) - data2575(1);
%             c=5;
%             UncuedRT(UncuedRT>data2575(2)+interq*c | UncuedRT<data2575(1)-interq*c) = [];
%             PDF_Uncued = histcounts(UncuedRT, binEdges, 'Normalization','pdf');
%             CDF_Uncued = histcounts(UncuedRT, binEdges, 'Normalization','cdf');
        end

        function value = get.Stage(obj)
            stage_index = zeros(1, obj.TrialNum);
            ind_first = find(obj.FP>=obj.MixedFP, 1, "first");
            stage_index(ind_first:end) = 1;
            value = stage_index;
        end

         function value = get.RTDistributionLoose(obj)
            % 2/18/2023
                       % Cued
            CuedRT = obj.ReactionTime(obj.Cue == 1 & (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
            PDF_Cued =  ksdensity(CuedRT, obj.RTbinEdges, 'function', 'pdf');
            CDF_Cued =  ksdensity(CuedRT, obj.RTbinEdges, 'function', 'cdf');
            % Uncued
            UncuedRT = obj.ReactionTime(obj.Cue == 0 & (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
            PDF_Uncued =  ksdensity(UncuedRT, obj.RTbinEdges, 'function', 'pdf');
            CDF_Uncued =  ksdensity(UncuedRT, obj.RTbinEdges, 'function', 'cdf');
            value = table(obj.RTbinEdges',PDF_Cued', CDF_Cued', PDF_Uncued', CDF_Uncued', ...
                'VariableNames',{'BinEdges', 'PDF_Cued', 'CDF_Cued', 'PDF_Uncued', 'CDF_Uncued'});

%             % Cued
%             CuedRT = obj.ReactionTime(obj.Cue == 1 & (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
%             binEdges = [0:0.05:3];
%             binCenters = (binEdges(1:end-1)+binEdges(2:end))/2;
%             [data2575] = prctile(CuedRT, [25, 75]);
%             interq = data2575(2) - data2575(1);
%             c=5;
%             CuedRT(CuedRT>data2575(2)+interq*c | CuedRT<data2575(1)-interq*c) = [];
%             PDF_Cued = histcounts(CuedRT, binEdges, 'Normalization','pdf');
%             CDF_Cued = histcounts(CuedRT, binEdges, 'Normalization','cdf');
% 
%             % Uncued
%             UncuedRT = obj.ReactionTime(obj.Cue == 0 & (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
%             binEdges = [0:0.05:3];
%             binCenters = (binEdges(1:end-1)+binEdges(2:end))/2;
%             [data2575] = prctile(UncuedRT, [25, 75]);
%             interq = data2575(2) - data2575(1);
%             c=5;
%             UncuedRT(UncuedRT>data2575(2)+interq*c | UncuedRT<data2575(1)-interq*c) = [];
%             PDF_Uncued = histcounts(UncuedRT, binEdges, 'Normalization','pdf');
%             CDF_Uncued = histcounts(UncuedRT, binEdges, 'Normalization','cdf');
% 
%             value = table(binCenters',PDF_Cued', CDF_Cued', PDF_Uncued', CDF_Uncued', ...
%                 'VariableNames',{'BinCenters', 'PDF_Cued', 'CDF_Cued', 'PDF_Uncued', 'CDF_Uncued'});
         end

         function value = get.HoldTimeDistribution(obj)

             % Cued
             CuedHT = obj.HoldTime(obj.Cue == 1 & (strcmp(obj.Outcome, 'Correct')|strcmp(obj.Outcome, 'Premature')|strcmp(obj.Outcome, 'Late')));
             PDF_Cued =  ksdensity(CuedHT, obj.HoldTbinEdges, 'function', 'pdf');
             CDF_Cued =  ksdensity(CuedHT, obj.HoldTbinEdges, 'function', 'cdf');

             % Uncued
             UncuedHT =  obj.HoldTime(obj.Cue == 0 & (strcmp(obj.Outcome, 'Correct')|strcmp(obj.Outcome, 'Premature')|strcmp(obj.Outcome, 'Late')) );
             PDF_Uncued = ksdensity(UncuedHT, obj.HoldTbinEdges, 'function', 'pdf');
             CDF_Uncued = ksdensity(UncuedHT, obj.HoldTbinEdges, 'function', 'cdf');

             value = table(obj.HoldTbinEdges', PDF_Cued', CDF_Cued', PDF_Uncued', CDF_Uncued', ...
                 'VariableNames',{'BinEdges','PDF_Cued', 'CDF_Cued', 'PDF_Uncued', 'CDF_Uncued'});

         end

        function value = get.Performance(obj)
            % Cue or Uncue
            if numel(obj.MixedFP)>1
                Foreperiod          =       [num2cell(obj.MixedFP) 'all']';
            else
                Foreperiod          =       [obj.MixedFP]';
            end;

            N_press                =       zeros(length(Foreperiod), 2);
            CorrectRatio        =       zeros(length(Foreperiod), 2);
            PrematureRatio  =       zeros(length(Foreperiod), 2);
            LateRatio              =       zeros(length(Foreperiod), 2);
            Foreperiod           =       repmat(Foreperiod, 2, 1);

            CueTypes             =       [0, 1];
            for k = 1:length(CueTypes)
                for i = 1:length(obj.MixedFP)
                    n_correct                =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Correct')        & obj.Cue == CueTypes(k));
                    n_premature          =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Premature')  & obj.Cue == CueTypes(k));
                    n_late                      =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Late')              & obj.Cue == CueTypes(k));
                    n_legit                     =       n_correct+n_premature+n_late;
                    N_press(i, k)               =       n_legit;
                    CorrectRatio(i, k)  =  100*n_correct/n_legit;
                    PrematureRatio(i, k)  =  100*n_premature/n_legit;
                    LateRatio(i, k)  =  100*n_late/n_legit;
                end;
                if i >1
                    % takes everything
                    n_correct            =    sum(strcmp(obj.Outcome, 'Correct')        &      obj.Cue    ==      CueTypes(k));
                    n_premature     =    sum(strcmp(obj.Outcome, 'Premature')   &      obj.Cue    ==      CueTypes(k));
                    n_late                 =    sum(strcmp(obj.Outcome, 'Late')               &      obj.Cue    ==      CueTypes(k));
                    n_legit               =    n_correct+n_premature+n_late;
                    i = i+1;
                    N_press(i, k)               =       n_legit;
                    CorrectRatio(i, k)  =  100*n_correct/n_legit;
                    PrematureRatio(i, k)  =  100*n_premature/n_legit;
                    LateRatio(i, k)  =  100*n_late/n_legit;
                end;
            end;
            rt_table = table(Foreperiod, CueTypes', N_press', CorrectRatio', PrematureRatio', LateRatio', ...
                'VariableNames',{'Foreperiod', 'CueTypes', 'N_Press', 'Correct', 'Premature', 'Late'});
            value = rt_table;

        end

        function value = get.AvgRT(obj)
            % Use calRT to compute RT
            CueTypes             =       [0, 1];
            RT.median                        =          zeros(length(CueTypes), 1:length(obj.MixedFP));
            RT.median_ksdensity     =          zeros(length(CueTypes), 1:length(obj.MixedFP));
            N_press                            =          zeros(length(CueTypes), 1:length(obj.MixedFP));
            Foreperiod                       =          repmat(obj.MixedFP, length(CueTypes), 1);
            for k = 1:length(CueTypes)
                for i = 1:length(obj.MixedFP)
                    iFP = obj.MixedFP(i);
                    ind_press = find(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Correct') & obj.Cue == CueTypes(k));
                    HoldDurs = 1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms
                    iRTOut = calRT(HoldDurs, iFP, 'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                    N_press(k, i) = length(HoldDurs);
                    RT.median(k, i) = iRTOut.median;
                    RT.median_ksdensity(k, i) = iRTOut.median_ksdensity;
                end;
            end;
            RT_median = RT.median';
            RT_median_ksdensity = RT.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, CueTypes', N_press', RT_median', RT_median_ksdensity', ...
                'VariableNames',{'Foreperiod', 'CueTypes', 'N_Press', 'RT_median', 'RT_median_ksdensity'});
            value = rt_table;
        end

        function value = get.AvgRTLoose(obj)
            % Use calRT to compute RT
            CueTypes             =       [0, 1];
            RT.median                        =          zeros(length(CueTypes), 1:length(obj.MixedFP));
            RT.median_ksdensity     =          zeros(length(CueTypes), 1:length(obj.MixedFP));
            N_press                            =          zeros(length(CueTypes), 1:length(obj.MixedFP));
            Foreperiod                       =          repmat(obj.MixedFP, length(CueTypes), 1);
            for k = 1:length(CueTypes)
                for i = 1:length(obj.MixedFP)
                    iFP = obj.MixedFP(i);
                    ind_press = find(obj.FP == obj.MixedFP(i) & (strcmp(obj.Outcome, 'Correct')|strcmp(obj.Outcome, 'Late')) & obj.Cue == CueTypes(k));
                    HoldDurs = 1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms
                    iRTOut = calRT(HoldDurs, iFP, 'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                    N_press(k, i) = length(HoldDurs);
                    RT.median(k, i) = iRTOut.median;
                    RT.median_ksdensity(k, i) = iRTOut.median_ksdensity;
                end;
            end;
            RT_median = RT.median';
            RT_median_ksdensity = RT.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, CueTypes', N_press', RT_median', RT_median_ksdensity', ...
                'VariableNames',{'Foreperiod', 'CueTypes', 'N_Press', 'RT_median', 'RT_median_ksdensity'});
            value = rt_table;
        end

        function Save(obj, savepath)
            if nargin<2
                savepath = pwd;
                save(fullfile(savepath, ['KbClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]]),  'obj');
            end
        end

        function Print(obj, targetDir)
            savename = ['KbClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]];
            if nargin==2
                % check if targetDir exists
                if ~contains(targetDir, '/') && ~contains(targetDir, '\')
                    % so it is a relative path
                    if ~exist(targetDir, 'dir')
                        mkdir(targetDir)
                    end;
                end;
                savename = fullfile(targetDir, savename)
            end;
 
            print (obj.Fig1,'-dpdf', [savename], '-bestfit')
            print (obj.Fig1,'-dpng', [savename])
            saveas(obj.Fig1, savename, 'fig')
        end;

        function PlotDistribution(obj)
        % Plot PDF, violinplot and stuff



        end;

        function Plot(obj)
            try
                set_matlab_default
            catch
                disp('You do not have "set_matlab_default"' )
            end

            % plot the entire session
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            figure(obj.Fig1); clf(obj.Fig1)
            set(gcf, 'unit', 'centimeters', 'position',[2 2 18 18], 'paperpositionmode', 'auto', 'color', 'w')

            plotsize1 = [6, 2.8];
            plotsize2 = [2, 2.8];
            plotsize4 = [2.5 2.8];
            plotsize5 = [2, 0.5];

            hui_1 = uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized', 'position', [0.1 0.945 0.2 0.05],...
                'string', [obj.Subject], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' );

            hui_2 = uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized', 'position', [0.2 0.945 0.3 0.05],...
                'string', [obj.Session], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' );

            hui_3 = uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized', 'position', [0.4 0.945 0.2 0.05],...
                'string', [obj.Treatment], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' );

            ha1 = axes;            
            title('Cue trials', 'fontsize', 7, 'FontWeight', 'bold');
            xlevel = 2;
            ylevel = 18-plotsize1(2)-1.3;

            set(ha1, 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 3500], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear');
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')
            line([0 obj.ReleaseTime(end)], [obj.MixedFP obj.MixedFP], 'color', [0.5 0.5 0.5], 'linestyle', ':', 'linewidth', 1)
            text(obj.ReleaseTime(end)+100, obj.MixedFP, ['FP: ' num2str(obj.MixedFP)], ...
                'fontsize', 7, 'fontname', 'dejavu sans', 'FontWeight','bold')

            % plot press times
            line([obj.PressTime(obj.Cue==1); obj.PressTime(obj.Cue==1)], [0 250], 'color', 'b')
            ind_premature_presses = (strcmp(obj.Outcome, 'Premature') & obj.Cue == 1);
            scatter(obj.ReleaseTime(ind_premature_presses), ...
                1000*(obj.ReleaseTime(ind_premature_presses) - obj.PressTime(ind_premature_presses)), ...
                28, col_perf(2, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

            ind_late_presses = strcmp(obj.Outcome, 'Late') & obj.Cue == 1;
            LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
            LateDur(LateDur>3500) = 3499;
            scatter(obj.ReleaseTime(ind_late_presses), LateDur, ...
                28, col_perf(3, :),  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

            ind_dark_presses = strcmp(obj.Outcome, 'Dark') & obj.Cue == 1;
            scatter(obj.ReleaseTime(ind_dark_presses), ...
                1000*(obj.ReleaseTime(ind_dark_presses) - obj.PressTime(ind_dark_presses)), ...
                18, 'k',  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');
 
            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Cue == 1;
            scatter(obj.ReleaseTime(ind_good_presses), ...
                1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses)), ...
                28, col_perf(1, :),   'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

            ind_premature_presses_cued      =           ind_premature_presses;
            ind_late_presses_cued                   =           ind_late_presses;
            ind_good_presses_cued                 =           ind_good_presses;

            % Write information
            hainfo=axes;
            xlevel2 = xlevel + plotsize1(1)+0.5;
            set(hainfo, 'units', 'centimeters', 'position', [xlevel2, ylevel, plotsize2], ...
                'xlim', [1.95 10], 'ylim', [0 9], 'nextplot', 'add');

            plot(2, 8, 'o', 'linewidth', 1, 'color', col_perf(1, :),'markerfacecolor', col_perf(1, :));
            text(3, 8, 'Correct', 'fontsize', 8);
            plot(2, 7, 'o', 'linewidth', 1, 'color', col_perf(2, :),'markerfacecolor', col_perf(2, :));
            text(3, 7, 'Premature', 'fontsize', 8);
            plot(2, 6 , 'o', 'linewidth', 1,'color', col_perf(3, :),'markerfacecolor', col_perf(3, :));
            text(3, 6, 'Late', 'fontsize', 8);
            plot(2, 5, 'ko', 'linewidth', 1,'markerfacecolor', 'k');
            text(3, 5, 'Dark', 'fontsize', 8);
            axis off

            ha2 = axes;
            title('Uncue trials', 'fontsize', 7, 'FontWeight', 'bold')
            ylevel2 = ylevel -plotsize1(2)-1.5;
            set(ha2, 'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], ...
                'nextplot', 'add', 'ylim', [0 3500], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            line([0 obj.ReleaseTime(end)], [obj.MixedFP obj.MixedFP], 'color', [0.5 0.5 0.5], 'linestyle', ':', 'linewidth', 1)
            text(obj.ReleaseTime(end)+100, obj.MixedFP, ['FP: ' num2str(obj.MixedFP)], ...
                'fontsize', 7, 'fontname', 'dejavu sans', 'FontWeight','bold')
            % plot press times
            line([obj.PressTime(obj.Cue==0); obj.PressTime(obj.Cue==0)], [0 250], 'color', 'b')
            ind_premature_presses = (strcmp(obj.Outcome, 'Premature') & obj.Cue == 0);
            hs = scatter(obj.ReleaseTime(ind_premature_presses), ...
                1000*(obj.ReleaseTime(ind_premature_presses) - obj.PressTime(ind_premature_presses)), ...
                25, col_perf(2, :), 'o',  'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_late_presses = strcmp(obj.Outcome, 'Late') & obj.Cue == 0;
            LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
            LateDur(LateDur>3500) = 3499;
            scatter(obj.ReleaseTime(ind_late_presses), LateDur, ...
                25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_dark_presses = strcmp(obj.Outcome, 'Dark') & obj.Cue == 0;
            scatter(obj.ReleaseTime(ind_dark_presses), ...
                1000*(obj.ReleaseTime(ind_dark_presses) - obj.PressTime(ind_dark_presses)), ...
                15, 'k', 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Cue == 0;
            scatter(obj.ReleaseTime(ind_good_presses), ...
                1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses)), ...
                25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_premature_presses_uncued      =           ind_premature_presses;
            ind_late_presses_uncued                   =           ind_late_presses;
            ind_good_presses_uncued                 =           ind_good_presses;

            ylevel3=ylevel2-plotsize1(2)-1.5;

            % performance at sliding window
            ha3 = axes;
            set(ha3,  'units', 'centimeters', 'position', [xlevel, ylevel3, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')

            plot(obj.PerformanceSlidingWindow.Time, obj.PerformanceSlidingWindow.Correct_Uncued, 'o', 'linestyle', '-', 'color', col_perf(1, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', 'w', 'markeredgecolor', col_perf(1, :));
            plot(obj.PerformanceSlidingWindow.Time, obj.PerformanceSlidingWindow.Premature_Uncued, 'o', 'linestyle', '-', 'color', col_perf(2, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', 'w', 'markeredgecolor', col_perf(2, :));
            plot(obj.PerformanceSlidingWindow.Time, obj.PerformanceSlidingWindow.Late_Uncued, 'o', 'linestyle', '-', 'color', col_perf(3, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', 'w', 'markeredgecolor', col_perf(3, :));

            plot(obj.PerformanceSlidingWindow.Time, obj.PerformanceSlidingWindow.Correct_Cued,  'o', 'linestyle', '-', 'color', col_perf(1, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w');
            plot(obj.PerformanceSlidingWindow.Time, obj.PerformanceSlidingWindow.Premature_Cued, 'o', 'linestyle', '-', 'color', col_perf(2, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w');
            plot(obj.PerformanceSlidingWindow.Time, obj.PerformanceSlidingWindow.Late_Cued, 'o', 'linestyle', '-', 'color', col_perf(3, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w');
            xlabel('Time in session (sec)')
            ylabel('Performance (%)')

            % Plot reaction time (for uncued trials, it is release time
            % minus the foreperiod)
            ha11 = axes;
            xlevel = 2;
            ylevel4=ylevel3-plotsize1(2)-1.5;

            set(ha11, 'units', 'centimeters', 'position', [xlevel, ylevel4, plotsize1], 'nextplot', 'add', ...
                'ylim', [-100 1000], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')

            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Cue == 1;
            scatter(obj.ReleaseTime(ind_good_presses), ...
                1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses))-obj.FP(ind_good_presses), ...
                28, col_perf(1, :),   'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

            ind_late_presses = strcmp(obj.Outcome, 'Late') & obj.Cue == 1;
            LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
            LateDur(LateDur>3500) = 3499;
            scatter(obj.ReleaseTime(ind_late_presses), LateDur-obj.FP(ind_late_presses), ...
                28, col_perf(3, :),  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');
            xlabel('Time in session (sec)')
            ylabel('Release time (msec)')

            % Plot reaction time (for uncued trials, it is release time
            % minus the foreperiod) uncued trials
            ha111 = axes;
            xlevel3 = xlevel2 +2.5;
            set(ha111, 'units', 'centimeters', 'position', [xlevel3, ylevel4, plotsize1], 'nextplot', 'add', ...
                'ylim', [-100 1000], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')

            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Cue == 0;
            scatter(obj.ReleaseTime(ind_good_presses), ...
                1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses))-obj.FP(ind_good_presses), ...
                25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_late_presses = strcmp(obj.Outcome, 'Late') & obj.Cue == 0;
            LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
            LateDur(LateDur>3500) = 3499;
            scatter(obj.ReleaseTime(ind_late_presses), LateDur-obj.FP(ind_late_presses), ...
                25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            xlabel('Time in session (sec)')
            ylabel('Release time (msec)')


            % Write information
            hainfo2=axes;
            xlevel2 = xlevel + plotsize1(1)+0.5;
            set(hainfo2, 'units', 'centimeters', 'position', [xlevel2, ylevel3, plotsize2], ...
                'xlim', [2 10], 'ylim', [0 9], 'nextplot', 'add');

            plot(2, 8, 'o', 'linewidth', 0.5, 'color', col_perf(1, :),'markerfacecolor', col_perf(1, :));
            text(3, 8, 'Cue', 'fontsize', 8);
            plot(2, 7, 'o', 'linewidth', 1, 'markerfacecolor', 'w','markeredgecolor', col_perf(1, :));
            text(3, 7, 'Uncue', 'fontsize', 8);

            plot(2, 6, 'o', 'linewidth', 0.5, 'color', col_perf(2, :),'markerfacecolor', col_perf(2, :));
            text(3, 6, 'Cue', 'fontsize', 8);
            plot(2, 5, 'o', 'linewidth', 1, 'markerfacecolor', 'w','markeredgecolor', col_perf(2, :));
            text(3, 5, 'Uncue', 'fontsize', 8);

            plot(2, 4 , 'o', 'linewidth', 0.5,'color', col_perf(3, :),'markerfacecolor', col_perf(3, :));
            text(3, 4, 'Cue', 'fontsize', 8);
            plot(2, 3 , 'o', 'linewidth', 1, 'markerfacecolor', 'w','markeredgecolor', col_perf(3, :));
            text(3, 3, 'Uncue', 'fontsize', 8);
            axis off

            xlevel3 = xlevel2 +2.5;
            ha3 = axes; %
            set(ha3,'units', 'centimeters', 'position', [xlevel3, ylevel3, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1000], 'xlim', [0 8], 'xtick', [])
            hb1=bar([1], (sum(ind_good_presses_cued)));
            set(hb1, 'EdgeColor', 'none', 'facecolor',col_perf(1, :), 'linewidth', 1);
            hb2=bar([2], (sum(ind_premature_presses_cued)));
            set(hb2, 'EdgeColor',  'none', 'facecolor', col_perf(2, :), 'linewidth', 1);
            hb3=bar([3], (sum(ind_late_presses_cued)));
            set(hb3, 'EdgeColor',  'none', 'facecolor',col_perf(3, :), 'linewidth', 1);
            hb1uc=bar([5], (sum(ind_good_presses_uncued)));
            set(hb1uc, 'EdgeColor', col_perf(1, :), 'facecolor','w', 'linewidth', 2);
            hb2uc=bar([6], (sum(ind_premature_presses_uncued)));
            set(hb2uc, 'EdgeColor', col_perf(2, :), 'facecolor', 'w', 'linewidth', 2);
            hb3uc=bar([7], (sum(ind_late_presses_uncued)));
            set(hb3uc, 'EdgeColor', col_perf(3, :), 'facecolor','w', 'linewidth', 2);
            axis 'auto y'
            ylabel('Number')

            % Plot performance for different FPs
            xlevel4 = xlevel3+plotsize4(1)+1.25;

            ha4 = axes;
            set(ha4,'units', 'centimeters', 'position', [xlevel4, ylevel3, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 8], 'xtick', [],...
                'xticklabelrotation', 30);
            bar(1, obj.Performance.Correct(obj.Performance.CueTypes==1), ...
                'Edgecolor', 'none','Facecolor', col_perf(1, :), 'linewidth', 2);
            bar(2, obj.Performance.Premature(obj.Performance.CueTypes==1), ...
                'Edgecolor', 'none', 'Facecolor', col_perf(2, :), 'linewidth', 2);
            bar(3, obj.Performance.Late(obj.Performance.CueTypes==1), ...
                'Edgecolor', 'none','Facecolor', col_perf(3, :), 'linewidth', 2);
            text(1, 95, 'Cued', 'fontsize', 7, 'fontname', 'dejavu sans', 'fontweight', 'bold')

            bar(5, obj.Performance.Correct(obj.Performance.CueTypes==0), ...
                'Edgecolor', col_perf(1, :),'Facecolor', 'w', 'linewidth',2);
            bar(6, obj.Performance.Premature(obj.Performance.CueTypes==0), ...
                'Edgecolor', col_perf(2, :), 'Facecolor', 'w', 'linewidth', 2);
            bar(7, obj.Performance.Late(obj.Performance.CueTypes==0), ...
                'Edgecolor', col_perf(3, :),'Facecolor', 'w', 'linewidth', 2);
            text(5, 95, 'Uncued', 'fontsize', 7, 'fontname', 'dejavu sans', 'fontweight', 'bold')

            title('Performance', 'fontweight', 'normal', 'fontweight', 'bold')
            ylabel('Performance (%)')

            % Plot reaction time distribution
            ha5 = axes;
            set(ha5,'units', 'centimeters', 'position', [xlevel3, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 2], ...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            CueColor         =          [39 39 39]/255;
            UncueColor    =          [173, 123, 233]/255;
            plot(obj.RTDistributionLoose.BinEdges, smoothdata(obj.RTDistributionLoose.PDF_Cued, 'gaussian', 7), 'color', CueColor, 'linewidth', 1)
            plot(obj.RTDistributionLoose.BinEdges, smoothdata(obj.RTDistributionLoose.PDF_Uncued, 'gaussian', 7), 'color', UncueColor, 'linewidth', 1)
            axis 'auto y'
            xlabel('Release time (s)')
            ylabel('PDF(1/s)')
            hl = legend('Cued', 'Uncued', 'Units', 'centimeters', ...
                'position', [xlevel3+0.2, ylevel+plotsize4(2)+0.25, plotsize5], ...
                'EdgeColor', 'none');

            % Plot reaction time cumulative distribution
            ha5b = axes;
            set(ha5b,'units', 'centimeters', 'position', [xlevel3, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 2], ...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            plot(obj.RTDistributionLoose.BinEdges, smoothdata(obj.RTDistributionLoose.CDF_Cued, 'gaussian', 7), ...
                'color', CueColor, 'linewidth', 1)
            plot(obj.RTDistributionLoose.BinEdges, smoothdata(obj.RTDistributionLoose.CDF_Uncued, 'gaussian', 7), ...
                'color', UncueColor, 'linewidth', 1)
            axis 'auto y'
            xlabel('Reaction time (s)')
            ylabel('CDF')

            ha6 = axes;
            set(ha6,'units', 'centimeters', 'position', [xlevel4, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 3], ...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            plot(obj.HoldTimeDistribution.BinEdges, smoothdata(obj.HoldTimeDistribution.PDF_Cued, 'gaussian', 7), 'color', CueColor, 'linewidth', 1)
            plot(obj.HoldTimeDistribution.BinEdges, smoothdata(obj.HoldTimeDistribution.PDF_Uncued, 'gaussian', 7), 'color', UncueColor, 'linewidth', 1)
          
            axis 'auto y'
            line([obj.MixedFP obj.MixedFP]/1000, get(ha6, 'YLim'), ...
                'color', [0.5 0.5 0.5], 'linestyle', ':', 'linewidth', 1)
            xlabel('Hold duration (s)')

            % Plot reaction time cumulative distribution
            ha6b = axes;
            set(ha6b,'units', 'centimeters', 'position', [xlevel4, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 3], ...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            plot(obj.HoldTimeDistribution.BinEdges, smoothdata(obj.HoldTimeDistribution.CDF_Cued, 'gaussian', 7), ...
                'color', CueColor, 'linewidth', 1)
            plot(obj.HoldTimeDistribution.BinEdges, smoothdata(obj.HoldTimeDistribution.CDF_Uncued, 'gaussian', 7), ...
                'color', UncueColor, 'linewidth', 1)
            axis 'auto y'
            line([obj.MixedFP obj.MixedFP]/1000, [0 1], ...
                'color', [0.5 0.5 0.5], 'linestyle', ':', 'linewidth', 1)
            xlabel('Hold duration (s)')
            ylabel('CDF')
        end;
    end
end
