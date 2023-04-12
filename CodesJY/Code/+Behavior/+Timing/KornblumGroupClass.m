classdef KornblumGroupClass
    % 11/8/2022, Jianing Yu
    % This takes kornblum class from each session, group them together,
    % mark each session with proper statement, and plot the data 


    properties

        Subject
        Sessions
        Dates
        Strain
        Experimenter
        Protocols
        NumSessions
        NumTrialsPerSession
        TreatmentSessions
        DoseSessions
        Treatments
        Doses
        Cue

        IQR_Sessions

        PressIndex
        PressTime
        ReleaseTime
        HoldTime
        FP
        MixedFP
        ToneTime
        ReactionTime
        Outcome
        Stage
        RTbinCenters
        HoldTbinCenters
        PerformanceSlidingWindow
        PerformanceOverSessions

        Control

        Fig1
        Fig2
        Fig3

        RTbinEdges_Sessions
        HoldTbinEdges_Sessions
        PDF_RT_Sessions
        CDF_RT_Sessions
        PDF_RTLoose_Sessions
        CDF_RTLoose_Sessions
        PDF_HoldT_Sessions
        CDF_HoldT_Sessions

        ProgressTrials % for plotting the first and last # Trials. Default is 200

        SessionControl              % for claiming what sessions should be considered 'Control'
        SessionChemo                % for claiming what sessions should be considered 'Chemo'

    end;

    properties (SetAccess = private)
            pHoldTMedian_Control
            pHoldTMedian_Chemo
    end

    properties (Constant)

        PerformanceType = {'Correct', 'Premature', 'Late'}
        ToneTimeNotation = {'Any positive number, tone time for correct or late release'; 
            '0, FP ending for uncued correct or late release'; 
            'NaN, premature or dark trials'}
        RTbinEdges = [0:0.05:2]; 
        HoldTbinEdges = [0:0.05:4];
        RTCeiling = 5; % RTs over 5 sec will be removed
        ResponseWindow = [0.6 1]; % for cue and uncue trials. 
        GaussEqn = 'a1*exp(-((x-b1)/c1)^2)+a2*exp(-((x-b2)/c2)^2)';
        StartPoints = [1 1 1 2 2 1];
        LowerBound = [0 0 0 0 0 0];
        UpperBound = [10 10 10 10 10 10];

    end
    properties (Dependent)
        RT_Cue
        RT_Uncue
        HoldT_Cue
        HoldT_Uncue

        PDF_RT_Cue            
        CDF_RT_Cue    
        PDF_RT_Uncue    
        CDF_RT_Uncue   

        PDF_HoldT_Cue        
        PDF_HoldT_Cue_Gauss % using a gauss model to fit the data
        FWHM_HoldT_Cue % Full width at half maximum, derived from Gauss model
        CDF_HoldT_Cue   
        PDF_HoldT_Uncue  
        PDF_HoldT_Uncue_Gauss % using a gauss model to fit the data
        FWHM_HoldT_Uncue % Full width at half maximum, derived from Gauss model
        CDF_HoldT_Uncue    

        PerformanceTable
        FastResponseRatio
        IQR

        PDF_HoldT_Cue_Progress % early and late, for tracking progress
        PDF_HoldT_Uncue_Progress

        IndexSessionsControl   % Index of control sessions
        IndexSessionsChemo    % Index of chemo sessions

        ResponseTimeChemoTable

        HoldT_Control % collect hold time for control/chemo comparison analysis
        HoldT_Chemo % collect hold time for control/chemo comparison analysis

        HoldTMedian_Control
        HoldTMedian_Chemo

        PDF_HoldT_Control
        PDF_HoldT_Chemo
        CDF_HoldT_Control
        CDF_HoldT_Chemo

    end


    methods
        function obj = KornblumGroupClass(KornblumClassAll)
            % KornblumClassAll is a collection of kornblum class from all
            % sessions for a rat
            obj.Subject                                  =                 unique(cellfun(@(x)x.Subject, KornblumClassAll, 'UniformOutput', false)');
            obj.Strain                                     =                 KornblumClassAll{1}.Strain;
            obj.Sessions                                =                 cellfun(@(x)x.Session, KornblumClassAll, 'UniformOutput', false)';
            obj.Dates                                     =                 cellfun(@(x)x.Date, KornblumClassAll, 'UniformOutput', false)';
            obj.Experimenter                         =                cellfun(@(x)x.Experimenter, KornblumClassAll, 'UniformOutput', false)';
            obj.Protocols                                =                cellfun(@(x)x.Protocol, KornblumClassAll, 'UniformOutput', false)';
            obj.NumSessions                         =                length(KornblumClassAll);
            obj.NumTrialsPerSession             =                cellfun(@(x)x.TrialNum, KornblumClassAll);
            obj.Cue                                         =                 cell2mat(cellfun(@(x)x.Cue, KornblumClassAll , 'UniformOutput', false));

            randNums                                     =            randperm(1000, 3);
            obj.Fig1                                         =            randNums(1);
            obj.Fig2                                         =            randNums(2);
            obj.Fig3                                         =            randNums(3);

            obj.ProgressTrials                         =            200;

            obj.RTbinEdges_Sessions                 =             KornblumClassAll{1}.RTbinEdges;
            obj.HoldTbinEdges_Sessions           =             KornblumClassAll{1}.HoldTbinEdges;
            obj.PDF_RT_Sessions                        =             cell(obj.NumSessions,2);
            obj.CDF_RT_Sessions                        =              cell(obj.NumSessions,2);
            obj.PDF_RTLoose_Sessions              =              cell(obj.NumSessions, 2);
            obj.CDF_RTLoose_Sessions              =              cell(obj.NumSessions, 2);
            obj.PDF_HoldT_Sessions                  =               cell(obj.NumSessions, 2);
            obj.CDF_HoldT_Sessions                  =               cell(obj.NumSessions, 2);

            obj.SessionControl                             =                [];
            obj.SessionChemo                              =                [];

            for i =1:obj.NumSessions

                obj.PDF_RT_Sessions(i, :)           = {KornblumClassAll{i}.RTDistribution.PDF_Cued,KornblumClassAll{i}.RTDistribution.PDF_Uncued };
                obj.PDF_RTLoose_Sessions(i, :) =  {KornblumClassAll{i}.RTDistributionLoose.PDF_Cued,KornblumClassAll{i}.RTDistributionLoose.PDF_Uncued };
                obj.CDF_RT_Sessions(i, :)           =  {KornblumClassAll{i}.RTDistribution.CDF_Cued,KornblumClassAll{i}.RTDistribution.CDF_Uncued };
                obj.CDF_RTLoose_Sessions(i, :) =  {KornblumClassAll{i}.RTDistributionLoose.CDF_Cued,KornblumClassAll{i}.RTDistributionLoose.CDF_Uncued };
                obj.PDF_HoldT_Sessions(i, :)      =  {KornblumClassAll{i}.HoldTimeDistribution.PDF_Cued,KornblumClassAll{i}.HoldTimeDistribution.PDF_Uncued };
                obj.CDF_HoldT_Sessions(i, :)      = {KornblumClassAll{i}.HoldTimeDistribution.CDF_Cued,KornblumClassAll{i}.HoldTimeDistribution.CDF_Uncued };

                obj.PressIndex                          =           [obj.PressIndex repmat(i, 1,   obj.NumTrialsPerSession(i))];
                obj.PressTime                           =           [obj.PressTime KornblumClassAll{i}.PressTime];
                obj.ReleaseTime                       =           [obj.ReleaseTime KornblumClassAll{i}.ReleaseTime];
                obj.HoldTime                            =           [obj.HoldTime KornblumClassAll{i}.HoldTime];
                obj.FP                                         =           [obj.FP KornblumClassAll{i}.FP];
                obj.MixedFP                              =           [obj.MixedFP KornblumClassAll{i}.MixedFP];
                obj.ToneTime                            =            [obj.ToneTime KornblumClassAll{i}.ToneTime];
                obj.ReactionTime                     =            [obj.ReactionTime KornblumClassAll{i}.ReactionTime];
                obj.Outcome                             =            [obj.Outcome;  KornblumClassAll{i}.Outcome'];
                obj.Stage                                   =            [obj.Stage KornblumClassAll{i}.Stage];
                obj.TreatmentSessions        =             [obj.TreatmentSessions KornblumClassAll{i}.Treatment];
                obj.DoseSessions                 =             [obj.DoseSessions KornblumClassAll{i}.Dose];
                obj.Treatments                        =             [obj.Treatments repmat(KornblumClassAll{i}.Treatment, 1, obj.NumTrialsPerSession(i))];
                obj.Doses                                =            [obj.Doses repmat(KornblumClassAll{i}.Dose, 1, obj.NumTrialsPerSession(i))];
                obj.PerformanceOverSessions{i} =         KornblumClassAll{i}.Performance;      
            
                HoldT_Cued = KornblumClassAll{i}.HoldTime(KornblumClassAll{i}.Stage ==1 & KornblumClassAll{i}.Cue == 1)*1000;
                HoldT_Uncued = KornblumClassAll{i}.HoldTime(KornblumClassAll{i}.Stage ==1 & KornblumClassAll{i}.Cue == 0)*1000;

                obj.IQR_Sessions(i, :) = [diff(prctile(HoldT_Cued, [25 75])) diff(prctile(HoldT_Uncued, [25 75]))];
                iSlidingWindowTable  =           KornblumClassAll{i}.PerformanceSlidingWindow;
                iSlidingWindowTable.('Session') = repmat(i, size(iSlidingWindowTable, 1), 1);
                obj.PerformanceSlidingWindow = [obj.PerformanceSlidingWindow; iSlidingWindowTable];
                obj.Control = {'Saline', 'NaN'};

            end; 

            obj.RTbinCenters = mean([obj.RTbinEdges(1:end-1); obj.RTbinEdges(2:end)], 1);
            obj.HoldTbinCenters = mean([obj.HoldTbinEdges(1:end-1); obj.HoldTbinEdges(2:end)], 1);

        end

        function value = get.PDF_HoldT_Control(obj)
            PDF = zeros(length(obj.HoldTbinEdges), 2);
            if ~isempty(obj.HoldT_Control)
                for k = 1:length(obj.HoldT_Control)
                    PDF(:, k) = ksdensity( obj.HoldT_Control{k}, obj.HoldTbinEdges,'function', 'pdf');
                end;
                value = PDF;
            end;
        end;


        function value = get.CDF_HoldT_Control(obj)
            CDF = zeros(length(obj.HoldTbinEdges), 2);
            if ~isempty(obj.HoldT_Control)
                for k = 1:length(obj.HoldT_Control)
                    CDF(:, k) = ksdensity( obj.HoldT_Control{k}, obj.HoldTbinEdges,'function', 'cdf');
                end;
                value = CDF;
            end;
        end;

        function value = get.PDF_HoldT_Chemo(obj)
            PDF = zeros(length(obj.HoldTbinEdges), 2);
            if ~isempty(obj.HoldT_Chemo)
                for k = 1:length(obj.HoldT_Chemo)
                    PDF(:, k) = ksdensity( obj.HoldT_Chemo{k}, obj.HoldTbinEdges,'function', 'pdf');
                end;
                value = PDF;
            end;
        end;


        function value = get.CDF_HoldT_Chemo(obj)
            CDF = zeros(length(obj.HoldTbinEdges), 2);
            if ~isempty(obj.HoldT_Chemo)
                for k = 1:length(obj.HoldT_Chemo)
                    CDF(:, k) = ksdensity( obj.HoldT_Chemo{k}, obj.HoldTbinEdges,'function', 'cdf');
                end;
                value = CDF;
            end;
        end;


        function value = get.HoldT_Control(obj)
            IndexControlTrials          =       ismember(obj.PressIndex, find(obj.IndexSessionsControl)) & obj.Cue == 1 & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')');
            value{1}                         =       obj.HoldTime(IndexControlTrials);
            IndexControlTrials          =       ismember(obj.PressIndex, find(obj.IndexSessionsControl)) & obj.Cue == 0 & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')');
            value{2}                         =       obj.HoldTime(IndexControlTrials);
        end;

        function value = get.HoldT_Chemo(obj)
            IndexChemoTrials          =       ismember(obj.PressIndex, find(obj.IndexSessionsChemo)) & obj.Cue == 1 & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')');
            value{1}                         =       obj.HoldTime(IndexChemoTrials);
            IndexChemoTrials          =       ismember(obj.PressIndex, find(obj.IndexSessionsChemo)) & obj.Cue == 0 & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')');
            value{2}                         =       obj.HoldTime(IndexChemoTrials);
        end;

        function obj = CalHoldTChemo(obj)
            if ~isempty(obj.HoldT_Control) && ~isempty(obj.HoldT_Chemo)
                obj.pHoldTMedian_Control = cell(1, length(obj.HoldT_Control));
                obj.pHoldTMedian_Chemo = cell(1, length(obj.HoldT_Chemo));
                for i =1:length(obj.HoldT_Control)
                    IQRfun = @(x)diff(prctile(x, [27 75]));
                    thisIQR = IQRfun(obj.HoldT_Control{i});
                    thisIQR_CI95 = bootci(1000, IQRfun, obj.HoldT_Control{i});
                    obj.pHoldTMedian_Control{i} = [median(obj.HoldT_Control{i}) transpose(bootci(1000, @median, obj.HoldT_Control{i})); thisIQR thisIQR_CI95'];
                    thisIQR = IQRfun(obj.HoldT_Chemo{i});
                    thisIQR_CI95 = bootci(1000, IQRfun, obj.HoldT_Chemo{i});
                    obj.pHoldTMedian_Chemo{i} = [median(obj.HoldT_Chemo{i}) transpose(bootci(1000, @median, obj.HoldT_Chemo{i})); thisIQR thisIQR_CI95'];
                end;
            end;
        end;

        function value = get.HoldTMedian_Control(obj)
                value = obj.pHoldTMedian_Control;
        end
               
        function value = get.HoldTMedian_Chemo(obj)
            value = obj.pHoldTMedian_Chemo;
        end

        function value = get.IndexSessionsControl(obj)
            if isempty(obj.SessionControl)
                value = strcmp(obj.TreatmentSessions, 'Saline');
            else
                value = zeros(1, length(obj.TreatmentSessions));
                for k =1:length(obj.SessionControl)
                    value(find(strcmp(obj.Dates, obj.SessionControl{k})))=1;
                end;
            end
        end;

        function value = get.IndexSessionsChemo(obj)
            if isempty(obj.SessionChemo)
                value = strcmp(obj.TreatmentSessions, 'DCZ');
            else
                value = zeros(1, length(obj.TreatmentSessions));
                for k =1:length(obj.SessionChemo)
                    value(find(strcmp(obj.Dates, obj.SessionChemo{k})))=1;
                end;
            end
        end

        function obj = PlotChemoEffect(obj)
            % Compare effect of chemo inactivation on the performance
            set_matlab_default;
            % This is to plot pre and post lesion hold time PDF, which gives
            % a quick show on the effect
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPs = obj.MixedFP;
            colors = {[0 0 0.6], [255, 201, 60]/255};
            FPColors = [45, 205, 223]/255;
            SessionsCol = [3, 0, 28]/255;

            figure(obj.Fig3); clf(obj.Fig3)
            set(obj.Fig3, 'unit', 'centimeters', 'position',[2 2 40 15], 'paperpositionmode', 'auto', 'color', 'w')

            CueSymbol = 'o';
            UncueSymbol = 's';
            CIColor = [0.75 0.75 0.75];

            ylevel = 1.25;
            xlevel = 1.5;
            MarkerAlpha = 0.5;
            HoldTimeRange = unique(obj.MixedFP)/1000+[-0.5 0.5];

            ha_HoldT1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', HoldTimeRange, ...
                'xtick',[0.2:0.2:3], 'ylim', HoldTimeRange,'ytick', [0:0.2:3], 'ticklength', [0.02 0.1]);
            line(HoldTimeRange, HoldTimeRange, 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            title('Hold time (median)')
            xlabel('Control (sec)')
            ylabel('Chemo (sec)')

            % Plot cue trials
            line(obj.HoldTMedian_Control{1}(1, [2 3]), obj.HoldTMedian_Chemo{1}(1, 1)*[1 1], 'linewidth', 1.0, 'color',CIColor)
            line(obj.HoldTMedian_Control{1}(1, 1)*[1 1], obj.HoldTMedian_Chemo{1}(1, [2 3]), 'linewidth', 1.0, 'color',CIColor)
            MarkerSize = 65;
            scatter(obj.HoldTMedian_Control{1}(1, 1), ...
                obj.HoldTMedian_Chemo{1}(1, 1), ...
                'Marker', CueSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha',MarkerAlpha);

            % Plot uncue trials
            line(obj.HoldTMedian_Control{2}(1, [2 3]), obj.HoldTMedian_Chemo{2}(1, 1)*[1 1], 'linewidth', 1.0, 'color',CIColor)
            line(obj.HoldTMedian_Control{2}(1, 1)*[1 1], obj.HoldTMedian_Chemo{2}(1, [2 3]), 'linewidth', 1.0, 'color',CIColor)
            MarkerSize = 45;
            scatter(obj.HoldTMedian_Control{2}(1, 1), ...
                obj.HoldTMedian_Chemo{2}(1, 1), ...
                'Marker', UncueSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha',MarkerAlpha);

            % Plot markers
            scatter(HoldTimeRange(2)-0.05, HoldTimeRange(1)+0.2, 'Marker', CueSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(HoldTimeRange(2), HoldTimeRange(1)+0.2, 'Cue', 'fontName', 'dejavu sans', 'fontsize', 8)

            scatter(HoldTimeRange(2)-0.05, HoldTimeRange(1)+0.1, 'Marker', UncueSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(HoldTimeRange(2), HoldTimeRange(1)+0.1, 'Uncue', 'fontName', 'dejavu sans', 'fontsize', 8)
 
            xlevel = xlevel +7;
            IQRRange = [0 0.6];
            ha_HoldT2 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', IQRRange, ...
                'xtick',[0:0.1:3], 'ylim', IQRRange,'ytick', [0:0.1:3], 'ticklength', [0.02 0.1]);
            line(IQRRange, IQRRange, 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            title('Hold time (IQR)')
            xlabel('Control (sec)')
            ylabel('Chemo (sec)')

            % Plot cue trials (IQR)
            line(obj.HoldTMedian_Control{1}(2, [2 3]), obj.HoldTMedian_Chemo{1}(2, 1)*[1 1], 'linewidth', 1.0, 'color',CIColor)
            line(obj.HoldTMedian_Control{1}(2, 1)*[1 1], obj.HoldTMedian_Chemo{1}(2, [2 3]), 'linewidth', 1.0, 'color',CIColor)
            MarkerSize = 45;

            scatter(obj.HoldTMedian_Control{1}(2, 1), ...
                obj.HoldTMedian_Chemo{1}(2, 1), ...
                'Marker', CueSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

            % Plot uncue trials (IQR)
            line(obj.HoldTMedian_Control{2}(2, [2 3]), obj.HoldTMedian_Chemo{2}(2, 1)*[1 1], 'linewidth', 1.0, 'color',CIColor)
            line(obj.HoldTMedian_Control{2}(2, 1)*[1 1], obj.HoldTMedian_Chemo{2}(2, [2 3]), 'linewidth', 1.0, 'color',CIColor)
            MarkerSize = 45;
            scatter(obj.HoldTMedian_Control{2}(2, 1), ...
                obj.HoldTMedian_Chemo{2}(2, 1), ...
                'Marker', UncueSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

            ylevel2 = ylevel+7.5;
            xlevel = 7;
            maxHoldTime = (obj.MixedFP(end)+1500)/1000;
            ha1s = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel2 4 5], 'xlim', [0 maxHoldTime], 'xtick', [0:0.5:3], 'ylim', [0 5], 'ticklength', [0.02 0.1]);
            xlabel('Hold duration (s)')
            ylabel('PDF (1/s)')

            maxPDF = max([max(obj.PDF_HoldT_Control(:)) max(obj.PDF_HoldT_Chemo(:))])*1.25;
            FPLineStyles = {'-', '-.'};
            line(ha1s, [1 1]*unique(obj.MixedFP)/1000, [0, maxPDF], 'linestyle', ':', 'color', [0.5 0.5 0.5], 'linewidth', 1)

            for i =1:size(obj.PDF_HoldT_Control, 2)
                plot(ha1s, obj.HoldTbinEdges,obj.PDF_HoldT_Control(:, i), 'color', colors{1}, 'linewidth', 2/i);
                plot(ha1s, obj.HoldTbinEdges,obj.PDF_HoldT_Chemo(:, i), 'color', colors{2}, 'linewidth', 2/i);
            end;
            set(ha1s, 'ylim', [0, maxPDF])

            % CDF
            xlevel = xlevel +5;
            ha1c = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel2 4 5], 'xlim', [0 maxHoldTime], 'xtick', [0:0.5:3], 'ylim', [0 1], 'ticklength', [0.02 0.1]);
            xlabel('Hold duration (s)')
            ylabel('CDF')

            line(ha1c, [1 1]*unique(obj.MixedFP)/1000, [0, 1], 'linestyle', ':', 'color', [0.5 0.5 0.5], 'linewidth', 1)

            for i =1:size(obj.CDF_HoldT_Control, 2)
                plot(ha1c, obj.HoldTbinEdges,obj.CDF_HoldT_Control(:, i), 'color', colors{1}, 'linewidth', 2/i);
                plot(ha1c, obj.HoldTbinEdges,obj.CDF_HoldT_Chemo(:, i), 'color', colors{2}, 'linewidth', 2/i);
            end;
            set(ha1s, 'ylim', [0, maxPDF])           
    
           % add legend
            line(ha1c, maxHoldTime+[.5 .8]-1, [0.5 0.5], 'color', colors{1}, 'linewidth', 2)
            text(ha1c, maxHoldTime +.85-1, 0.5, 'Control (Cue)', 'fontname', 'dejavu sans','fontsize',  7);
            line(ha1c, maxHoldTime+[.5 .8]-1, [0.4 0.4], 'color', colors{2}, 'linewidth', 2)
            text(ha1c, maxHoldTime +.85-1, 0.4, 'Chemo (Cue)', 'fontname', 'dejavu sans','fontsize',  7);

            line(ha1c, maxHoldTime+[.5 .8]-1, [0.3 0.3], 'color', colors{1}, 'linewidth', 1)
            text(ha1c, maxHoldTime +.85-1, 0.3, 'Control (Uncue)', 'fontname', 'dejavu sans','fontsize',  7);
            line(ha1c, maxHoldTime+[.5 .8]-1, [0.2 0.2], 'color', colors{2}, 'linewidth', 1)
            text(ha1c, maxHoldTime +.85-1, 0.2, 'Chemo (Uncue)', 'fontname', 'dejavu sans','fontsize',  7);
            
            % Plot data in a violin plot to show all data points
            HoldTimeMax = maxHoldTime;
            xlevel = 1.5;
            ha2s = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel2 4 5], 'xlim', [0 5], ...
                'xtick', [0:1:6], 'ylim', [0 HoldTimeMax], 'ticklength', [0.02 0.1], ...
                'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);
 
            % Violinplot based on sessions
            HoldTimeAll = [];
            HoldTimeFPType = [];
            acc = 0;

            for k =1:length(obj.HoldT_Control)
                acc = acc + 1;
                % Control
                HoldTk = obj.HoldT_Control{k};
                HoldTk(HoldTk > 10) = [];
                HoldTimeAll = [HoldTimeAll HoldTk];
                HoldTimeFPType = [HoldTimeFPType acc*ones(1, length(HoldTk))];

                acc = acc + 1;
                % DCZ
                if isempty(obj.PDF_HoldT_Chemo)
                    return;
                end;

                HoldTk = obj.HoldT_Chemo{k};
                HoldTk(HoldTk > 10) = [];
                if ~isempty(HoldTk)
                    HoldTimeAll = [HoldTimeAll HoldTk];
                    HoldTimeFPType = [HoldTimeFPType acc*ones(1, length(HoldTk))];
                else
                    HoldTimeAll = [HoldTimeAll rand(1, 100)/10];
                    HoldTimeFPType = [HoldTimeFPType acc*ones(1,100)];
                end;
            end;

            axes(ha2s)
            hVio1 = violinplot(HoldTimeAll,  HoldTimeFPType, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false,'Bandwidth', 0.2);

            for iv =1:length(hVio1)
                if rem(iv, 2)~=0
                    hVio1(iv).EdgeColor = 'k';
                    hVio1(iv).ScatterPlot.MarkerFaceColor =colors{1};
                else
                    hVio1(iv).EdgeColor ='k';
                    hVio1(iv).ScatterPlot.MarkerFaceColor =colors{2};
                end;

                if iv>2
                    hVio1(iv).ViolinPlot.LineWidth = 1;
                else
                    hVio1(iv).ViolinPlot.LineWidth =2;
                end;

                hVio1(iv).ScatterPlot.MarkerFaceAlpha = 0.35;
                hVio1(iv).ViolinPlot.LineWidth  = 0.5;
                hVio1(iv).ScatterPlot.SizeData = 6;
                hVio1(iv).BoxPlot.LineWidth = 1;
                hVio1(iv).BoxColor = [0.8 0 0.2];
                hVio1(iv).ViolinPlot.FaceColor = [0.8 0.8 0.8];
            end;

            line([0 5], unique(obj.MixedFP)*[1 1]/1000,  'linestyle', ':', 'color', [0.5 0.5 0.5], 'linewidth', 1)

            set(gca, 'xticklabel', num2cell(obj.MixedFP), 'box', 'off', 'xlim', [0.5 4.5], 'xtick',[1:4], ...
                'xticklabel', {'Control (Cue)', 'Chemo', 'Control (Uncue)', 'Chemo'},'xticklabelrotation', 45)   
            ylabel('Hold time (s)')

            uicontrol('Style', 'text', 'parent', obj.Fig3, 'units', 'normalized', 'position', [0.1 0.95 0.25 0.04],...
                'string', [obj.Subject{1} ' | Control vs DCZ'], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 8, 'horizontalalignment', 'left');

            % Control and DCZ trials should appear as pairs
            xlevel = 19;
            ylevel = 1.5;
            PlotSize1 = [9 5];
            PlotSize2 = [9 3];
            TimeStep = 0;
            maxHoldTime=maxHoldTime*1000;
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;

            SessionsCol = [3, 0, 28]/255;
            TrialsCol = [91, 143, 185]/255;
 
            ha_Session = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel PlotSize1], 'xlim', [0 3600], ...
                'xtick',[0:600:3600], 'ylim', [0 100],'ytick', [0:20:100], 'ticklength', [0.01 0.1]);

            xlabel('Time (sec)')
            ylabel('Performance (Cue)')

            xlevel_Uncue = xlevel +PlotSize1(1)+1.5;
            ha_Session_Uncue = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel_Uncue ylevel PlotSize1], 'xlim', [0 3600], ...
                'xtick',[0:600:3600], 'ylim', [0 100],'ytick', [0:20:100], 'ticklength', [0.01 0.1]);
            xlabel('Time (sec)')
            ylabel('Performance (Uncue)')

            ylevel = ylevel +9.5; % control sessions
            ha_Trial1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel PlotSize2], 'xlim', [0 3600], ...
                'xtick',[], 'ylim', [0 maxHoldTime],'ytick', [0:500:maxHoldTime], 'yticklabel', num2cell((0:500:maxHoldTime)/1000), 'ticklength', [0.01 0.1]);

            ylabel('Hold time (sec)')
            htl1 = title(['Control ' sprintf('%s|', obj.Dates{find(obj.IndexSessionsControl)})], ...
                'fontname', 'dejavu sans', 'fontsize', 6, 'fontangle', 'italic','color', colors{1});
            htl1.Position(2)=htl1.Position(2)+250;

            ha_Trial1_Uncue = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel_Uncue ylevel PlotSize2], 'xlim', [0 3600], ...
                'xtick',[], 'ylim', [0 maxHoldTime],'ytick', [0:500:maxHoldTime], 'yticklabel', num2cell((0:500:maxHoldTime)/1000),  'ticklength', [0.01 0.1]);

            ylevel = ylevel - 4; % DCZ sessions
            ha_Trial2 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel PlotSize2], 'xlim', [0 3600], ...
                'xtick',[], 'xticklabel', [], 'ylim', [0 maxHoldTime],'ytick', [0:500:maxHoldTime],'yticklabel', num2cell((0:500:maxHoldTime)/1000),   'ticklength', [0.01 0.1]);

            htl2=title(['Chemo ' sprintf('%s|', obj.Dates{find(obj.IndexSessionsChemo)})], ...
                'fontname', 'dejavu sans', 'fontsize', 6, 'fontangle', 'italic', 'color', colors{2});
            htl2.Position(2)=htl2.Position(2)+250;

            ha_Trial2_Uncue = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel_Uncue ylevel PlotSize2], 'xlim', [0 3600], ...
                'xtick',[], 'xticklabel', [], 'ylim', [0 maxHoldTime],'ytick', [0:500:maxHoldTime], 'yticklabel', num2cell((0:500:maxHoldTime)/1000),  'ticklength', [0.01 0.1]);

            %  Plot control sessions first
             IndControlSession = find(obj.IndexSessionsControl == 1);
             IndChemoSession = find(obj.IndexSessionsChemo == 1);

             Symbols = {CueSymbol, UncueSymbol};
              CuedUncued = [1 0];
             for k =1:length(IndControlSession)

                 IndControlSession_k = IndControlSession(k);
                 IndChemoSession_k = IndChemoSession(k);

                 IndControlTrials = find(obj.PressIndex == IndControlSession_k);
                 IndChemoTrials = find(obj.PressIndex == IndChemoSession_k);

                 ControlTimeSliding                   = obj.PerformanceSlidingWindow.Time(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlCorrectCuedSliding               = obj.PerformanceSlidingWindow.Correct_Cued(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlPrematureCuedSliding         = obj.PerformanceSlidingWindow.Premature_Cued(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlLateCuedSliding                     = obj.PerformanceSlidingWindow.Late_Cued(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlCorrectUncuedSliding               = obj.PerformanceSlidingWindow.Correct_Uncued(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlPrematureUncuedSliding         = obj.PerformanceSlidingWindow.Premature_Uncued(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlLateUncuedSliding                     = obj.PerformanceSlidingWindow.Late_Uncued(obj.PerformanceSlidingWindow.Session == IndControlSession_k);

                 hp1 = plot(ha_Session, ControlTimeSliding+TimeStep, ControlCorrectCuedSliding, 'color', col_perf(1, :), 'linewidth', 2);
                 plot(ha_Session, ControlTimeSliding+TimeStep, ControlPrematureCuedSliding, 'color', col_perf(2, :), 'linewidth', 2)
                 plot(ha_Session, ControlTimeSliding+TimeStep, ControlLateCuedSliding, 'color', col_perf(3, :), 'linewidth', 2)

                 plot(ha_Session_Uncue, ControlTimeSliding+TimeStep, ControlCorrectUncuedSliding, 'color', col_perf(1, :), 'linewidth', 1);
                 plot(ha_Session_Uncue, ControlTimeSliding+TimeStep, ControlPrematureUncuedSliding, 'color', col_perf(2, :), 'linewidth', 1)
                 plot(ha_Session_Uncue, ControlTimeSliding+TimeStep, ControlLateUncuedSliding, 'color', col_perf(3, :), 'linewidth', 1)

                 ChemoTimeSliding                   = obj.PerformanceSlidingWindow.Time(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoCorrectCuedSliding               = obj.PerformanceSlidingWindow.Correct_Cued(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoPrematureCuedSliding         = obj.PerformanceSlidingWindow.Premature_Cued(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoLateCuedSliding                     = obj.PerformanceSlidingWindow.Late_Cued(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);

                 ChemoCorrectUncuedSliding               = obj.PerformanceSlidingWindow.Correct_Uncued(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoPrematureUncuedSliding         = obj.PerformanceSlidingWindow.Premature_Uncued(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoLateUncuedSliding                     = obj.PerformanceSlidingWindow.Late_Uncued(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);

                 hp2 = plot(ha_Session, ChemoTimeSliding+TimeStep, ChemoCorrectCuedSliding, 'color', col_perf(1, :), 'linewidth', 2,  'linestyle', '-.');
                 plot(ha_Session, ChemoTimeSliding+TimeStep, ChemoPrematureCuedSliding, 'color', col_perf(2, :), 'linewidth', 2,  'linestyle', '-.')
                 plot(ha_Session, ChemoTimeSliding+TimeStep, ChemoLateCuedSliding, 'color', col_perf(3, :), 'linewidth', 2,  'linestyle', '-.')

                 plot(ha_Session_Uncue, ChemoTimeSliding+TimeStep, ChemoCorrectUncuedSliding, 'color', col_perf(1, :), 'linewidth', 1,  'linestyle', '-.');
                 plot(ha_Session_Uncue, ChemoTimeSliding+TimeStep, ChemoPrematureUncuedSliding, 'color', col_perf(2, :), 'linewidth', 1,  'linestyle', '-.')
                 plot(ha_Session_Uncue, ChemoTimeSliding+TimeStep, ChemoLateUncuedSliding, 'color', col_perf(3, :), 'linewidth', 1,  'linestyle', '-.')
                
                 axes(ha_Trial1)
                 ha_Trial1_All = [ha_Trial1 ha_Trial1_Uncue];
   
                 for i =1:2 % cued and uncued
                     axes(ha_Trial1_All(i))
                     iIndControlTrials = IndControlTrials(obj.Cue(IndControlTrials) ==CuedUncued(i));
                     symbolSize = 35;
                     % plot correct
                     IndCorrectControl= iIndControlTrials(strcmp(obj.Outcome(iIndControlTrials), 'Correct'));
                     ha_scatter_correct = scatter(obj.PressTime(IndCorrectControl)+TimeStep, obj.HoldTime(IndCorrectControl)*1000, ...
                         'Marker', Symbols{i}, 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                     IndPrematureControl= iIndControlTrials(strcmp(obj.Outcome(iIndControlTrials), 'Premature'));
                     ha_scatter_premature = scatter(obj.PressTime(IndPrematureControl)+TimeStep, obj.HoldTime(IndPrematureControl)*1000, ...
                         'Marker', Symbols{i}, 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                     IndLateControl= iIndControlTrials(strcmp(obj.Outcome(iIndControlTrials), 'Late'));
                     HoldTimeLate = obj.HoldTime(IndLateControl)*1000;
                     HoldTimeLate(HoldTimeLate>maxHoldTime) = maxHoldTime;
                     ha_scatter_late = scatter(obj.PressTime(IndLateControl)+TimeStep, HoldTimeLate, ...
                         'Marker',Symbols{i}, 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                 end;

                 line(ha_Trial1, [TimeStep TimeStep], [0 maxHoldTime], 'color', 'k', 'linestyle', '--')
                 line(ha_Trial1_Uncue, [TimeStep TimeStep], [0 maxHoldTime], 'color', 'k', 'linestyle', '--')

                 axes(ha_Trial2)
                 ha_Trial2_All = [ha_Trial2 ha_Trial2_Uncue];

                 % Chemo trials
                 for i =1:2 % cued and uncued
                    axes(ha_Trial2_All(i))
                     iIndChemoTrials = IndChemoTrials(obj.Cue(IndChemoTrials) ==CuedUncued(i));
                     symbolSize = 35;
                     % plot correct
                     IndCorrectChemo= iIndChemoTrials(strcmp(obj.Outcome(iIndChemoTrials), 'Correct'));
                     ha_scatter_correct = scatter(obj.PressTime(IndCorrectChemo)+TimeStep, obj.HoldTime(IndCorrectChemo)*1000, ...
                         'Marker', Symbols{i}, 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                     IndPrematureChemo= iIndChemoTrials(strcmp(obj.Outcome(iIndChemoTrials), 'Premature'));
                     ha_scatter_premature = scatter(obj.PressTime(IndPrematureChemo)+TimeStep, obj.HoldTime(IndPrematureChemo)*1000, ...
                         'Marker', Symbols{i}, 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                     IndLateChemo= iIndChemoTrials(strcmp(obj.Outcome(iIndChemoTrials), 'Late'));
                     HoldTimeLate = obj.HoldTime(IndLateChemo)*1000;
                     HoldTimeLate(HoldTimeLate>maxHoldTime) = maxHoldTime;
                     ha_scatter_late = scatter(obj.PressTime(IndLateChemo)+TimeStep, HoldTimeLate, ...
                         'Marker',Symbols{i}, 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                 end;

                 line(ha_Trial2, [TimeStep TimeStep], [0 maxHoldTime], 'color', 'k', 'linestyle', '--');
                 line(ha_Trial2_Uncue, [TimeStep TimeStep], [0 maxHoldTime], 'color', 'k', 'linestyle', '--');
                 TimeStep = TimeStep + max(max(ControlTimeSliding), max(ChemoTimeSliding)) +300;
             end;

             hlegend = legend([hp1, hp2], 'Control', 'Chemo','location', 'best');
             set(hlegend, 'units', 'centimeters', 'position', [26 2 2 0.5])

             set(ha_Session, 'xlim', [0 TimeStep], 'xtick', [0:1000:3000])
             set(ha_Session_Uncue, 'xlim', [0 TimeStep], 'xtick', [0:1000:3000])

             set(ha_Trial1, 'xlim', [0 TimeStep], 'xtick', []);
             set(ha_Trial2, 'xlim', [0 TimeStep], 'xtick', []);

             set(ha_Trial1_Uncue, 'xlim', [0 TimeStep], 'xtick', []);
             set(ha_Trial2_Uncue, 'xlim', [0 TimeStep], 'xtick', []);

             htl1.Position(1)=TimeStep*0.5;
             htl2.Position(1)=TimeStep*0.5;
        end

        function value = get.RT_Cue(obj)
            % Reaction time
            RTCue              =        cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
                Ind_Cue_Control          =        ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            else
                Ind_Cue_Control          =        (strcmp(obj.Treatments, 'Saline') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            end;
            Ind_Cue_DCZ                =        (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            RTCue{1}                        =          obj.ReactionTime(Ind_Cue_Control);
            RTCue{2}                        =          obj.ReactionTime(Ind_Cue_DCZ);
            value                               =          RTCue;
        end;

        function value = get.RT_Uncue(obj)
            % Reaction time
            RTUncue                             =        cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
                Ind_Uncue_Control          =        ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            else
                Ind_Uncue_Control          =        (strcmp(obj.Treatments, 'Saline') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            end;
            Ind_Uncue_DCZ                =        (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            RTUncue{1}                        =         obj.ReactionTime(Ind_Uncue_Control);
            RTUncue{2}                        =         obj.ReactionTime(Ind_Uncue_DCZ);
            value                                    =         RTUncue;
        end;

        function value = get.PDF_HoldT_Cue_Progress(obj)
            % track this number of trials at the beginnig of training
            % 'obj.ProgressTrials'
            Index_AllCuedTrials = find(obj.Stage ==1 & obj.Cue == 1 & obj.FP == unique(obj.MixedFP)  & ~strcmp(obj.Treatments, 'DCZ'));           
            % Early
            IndexEarly = Index_AllCuedTrials(1:min(obj.ProgressTrials, length(Index_AllCuedTrials)));
            % Late
            Index_AllCuedTrials_Flipped = fliplr(Index_AllCuedTrials);
            IndexLate = Index_AllCuedTrials_Flipped(1:min(obj.ProgressTrials, length(Index_AllCuedTrials_Flipped)));
 
            HoldTimeEarly = obj.HoldTime(IndexEarly);
            HoldTimeLate  = obj.HoldTime(IndexLate);

            PDFOut{1, 1}                                        =            ksdensity(HoldTimeEarly, obj.HoldTbinEdges, 'function', 'pdf');
            PDFOut{2, 1}                                        =            ksdensity(HoldTimeLate, obj.HoldTbinEdges, 'function', 'pdf');

            PDFOut{1, 2}                                        =           HoldTimeEarly;
            PDFOut{2, 2}                                        =           HoldTimeLate;

            value = PDFOut; 
        end

        function value = get.PDF_HoldT_Uncue_Progress(obj)
            % track this number of trials at the beginnig of training
            % 'obj.ProgressTrials'
             Index_AllUncuedTrials                      =           find(obj.Stage ==1 & obj.Cue == 0 & obj.FP == unique(obj.MixedFP) & ~strcmp(obj.Treatments, 'DCZ'));           
            % Early
            IndexEarly                                          =               Index_AllUncuedTrials(1:min(obj.ProgressTrials, length(Index_AllUncuedTrials)));
            % Late
            Index_AllUncuedTrials_Flipped           =               fliplr(Index_AllUncuedTrials);
            IndexLate                                               =               Index_AllUncuedTrials_Flipped(1:min(obj.ProgressTrials, length(Index_AllUncuedTrials_Flipped)));
 
            HoldTimeEarly                                      =            obj.HoldTime(IndexEarly);
            HoldTimeLate                                       =            obj.HoldTime(IndexLate);

            PDFOut{1, 1}                                        =            ksdensity(HoldTimeEarly, obj.HoldTbinEdges, 'function', 'pdf');
            PDFOut{2, 1}                                        =            ksdensity(HoldTimeLate, obj.HoldTbinEdges, 'function', 'pdf');

            PDFOut{1, 2}                                        =           HoldTimeEarly;
            PDFOut{2, 2}                                        =           HoldTimeLate;
            
            value = PDFOut; 
        end

        function value = get.HoldT_Cue(obj)
            % Reaction time
            HoldTCue                            =          cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
                Ind_Cue_Control               =          ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            else
                Ind_Cue_Control               =          (strcmp(obj.Treatments, 'Saline') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            end;
            Ind_Cue_DCZ                      =         (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            HoldTCue{1}                        =         obj.HoldTime(Ind_Cue_Control);
            HoldTCue{2}                        =         obj.HoldTime(Ind_Cue_DCZ);
            value                                     =         HoldTCue;
        end;

        function value = get.HoldT_Uncue(obj)
            % Reaction time
            HoldTUncue                             =        cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
            Ind_Uncue_Control                =        ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            else
            Ind_Uncue_Control                =        (strcmp(obj.Treatments, 'Saline') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            end;
            Ind_Uncue_DCZ                      =        (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            HoldTUncue{1}                        =        obj.HoldTime(Ind_Uncue_Control);
            HoldTUncue{2}                        =        obj.HoldTime(Ind_Uncue_DCZ);
            value                                          =        HoldTUncue;
        end;

        function value = get.PDF_RT_Cue(obj)
            PDFOut = cell(1, length(obj.RT_Cue));
            for i =1:length(PDFOut)
                RT_Cue                                          =           obj.RT_Cue{i};
                if ~isempty(RT_Cue)
         %             RT_Cue(RT_Cue> obj.RTCeiling) =            [];
                    PDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i} = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_RT_Cue(obj)
            CDFOut = cell(1, length(obj.RT_Cue));
            for i =1:length(CDFOut)
                RT_Cue                                          =           obj.RT_Cue{i};
                if ~isempty(RT_Cue)
           %           RT_Cue(RT_Cue> obj.RTCeiling) =            [];
                    CDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}  = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_RT_Uncue(obj)
            PDFOut = cell(1, length(obj.RT_Uncue));
            for i =1:length(PDFOut)
                RT_Uncue                                          =           obj.RT_Uncue{i};
                if ~isempty(RT_Uncue)
                    PDFOut{i}                                        =            ksdensity(RT_Uncue, obj.RTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i}       = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_RT_Uncue(obj)
            CDFOut = cell(1, length(obj.RT_Uncue));
            for i =1:length(CDFOut)
                RT_Uncue                                                                                          =           obj.RT_Uncue{i};
                if ~isempty(RT_Uncue)
                    RT_Uncue(RT_Uncue> obj.RTCeiling)                                           =            [];
                    CDFOut{i}                                                                                           =            ksdensity(RT_Uncue, obj.RTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}     = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_HoldT_Cue(obj)
            PDFOut = cell(1, length(obj.HoldT_Cue));
            for i =1:length(PDFOut)
                HoldT_Cue                                                                                           =           obj.HoldT_Cue{i};
                if ~isempty(HoldT_Cue)
                    PDFOut{i}                                                                                              =            ksdensity(HoldT_Cue, obj.HoldTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i}  = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_HoldT_Cue(obj)
            CDFOut = cell(1, length(obj.HoldT_Cue));
            for i =1:length(CDFOut)
                HoldT_Cue                                                                                                   =            obj.HoldT_Cue{i};
                if ~isempty(HoldT_Cue)
                    HoldT_Cue(HoldT_Cue> obj.RTCeiling+unique(obj.MixedFP))           =            [];
                    CDFOut{i}                                                                                                      =            ksdensity(HoldT_Cue, obj.HoldTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}   = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_HoldT_Uncue(obj)
            PDFOut = cell(1, length(obj.HoldT_Uncue));
            for i =1:length(PDFOut)
                HoldT_Uncue                                                                                                     =           obj.HoldT_Uncue{i};
                if ~isempty(HoldT_Uncue)
                    PDFOut{i}                                                                                                            =            ksdensity(HoldT_Uncue, obj.HoldTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i}  = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_HoldT_Uncue(obj)
            CDFOut = cell(1, length(obj.HoldT_Uncue));
            for i =1:length(CDFOut)
                HoldT_Uncue                                                                                                     =           obj.HoldT_Uncue{i};
                if ~isempty(HoldT_Uncue)
                    CDFOut{i}                                                                                                            =            ksdensity(HoldT_Uncue, obj.HoldTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}     = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.IQR(obj)
            Types = {'Cue_Saline'; 'Cue_DCZ'; 'Uncue_Saline'; 'Uncue_DCZ'};
            Cue  = zeros(1, length(obj.RT_Cue));
            for i =1:length(Cue)
                RT_Cue                                          =           obj.RT_Cue{i};
                if ~isempty(RT_Cue)
                    Cue(i)                                        =       diff(prctile(RT_Cue, [25 75]));
                end;
            end;
            Uncue  = zeros(1, length(obj.RT_Uncue));
            for i =1:length(Uncue)
                RT_Uncue                                          =           obj.RT_Uncue{i};
                if ~isempty(RT_Uncue)
                    Uncue(i)                                        =       diff(prctile(RT_Uncue, [25 75]));
                end;
            end;
            IQR = [Cue'; Uncue'];
            IQRTable = table(Types, IQR);
            value = IQRTable;
        end;

        function value = get.PDF_HoldT_Cue_Gauss(obj)
            x = obj.HoldTbinEdges;
            y =  obj.PDF_HoldT_Cue{1};
            f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
            value{1}= f;
            if length(obj.PDF_RT_Cue)>1 && ~isempty(obj.PDF_RT_Cue{2})
                y =  obj.PDF_HoldT_Cue{2};
                f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
                value{2}= f;
            end;
        end;

        function value = get.PDF_HoldT_Uncue_Gauss(obj)
            x = obj.HoldTbinEdges;
            y =  obj.PDF_HoldT_Uncue{1};
            f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
            value{1}= f;
            if length(obj.PDF_RT_Uncue)>1 && ~isempty(obj.PDF_RT_Uncue{2})
                y =  obj.PDF_HoldT_Uncue{2};
                f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
                value{2}= f;
            end;
        end;

        function value = get.FWHM_HoldT_Cue(obj)
            % compute FWHM based on the model
             xnew = [obj.HoldTbinEdges(1):0.001:obj.HoldTbinEdges(end)];
             f = obj.PDF_HoldT_Cue_Gauss{1};
             ynew = f(xnew);
             x_above = xnew(ynew>0.5*max(ynew));
             value(1) = x_above(end) - x_above(1);
             if length(obj.PDF_RT_Cue)>1 && ~isempty(obj.PDF_RT_Cue{2})
                 f = obj.PDF_HoldT_Cue_Gauss{2};
                 ynew = f(xnew);
                 x_above = xnew(ynew>0.5*max(ynew));
                 value(2) = x_above(end) - x_above(1);
             end;
        end;

        function value = get.FWHM_HoldT_Uncue(obj)
            % compute FWHM based on the model
            xnew = [obj.HoldTbinEdges(1):0.001:obj.HoldTbinEdges(end)];
            f = obj.PDF_HoldT_Uncue_Gauss{1};
            ynew = f(xnew);
            x_above = xnew(ynew>0.5*max(ynew));
            value(1) = x_above(end) - x_above(1);
            if length(obj.PDF_RT_Uncue)>1 && ~isempty(obj.PDF_RT_Uncue{2})
                f = obj.PDF_HoldT_Uncue_Gauss{2};
                ynew = f(xnew);
                x_above = xnew(ynew>0.5*max(ynew));
                value(2) = x_above(end) - x_above(1);
            end;
        end;

        function value = get.PerformanceTable(obj)
            %  Calculate performance
            OutcomeCount = {'All'; 'Correct'; 'Premature'; 'Late'}; % 'fast' means response within 1 second after tone
            CueUncueSal            =         zeros(4, 2); % 4: all, correct, premature, late; 1st col, cue trials, 2nd col, uncue,  saline
            CueUncueDCZ          =         zeros(4, 2); % 4: all, correct, premature, late; 1st col, cue trials, 2nd col, uncue,  DCZ
            CueTypes                   =         [1 0];           % cue, uncue
            P_CueUncue_Saline            =         zeros(4, 2); 
            P_CueUncue_DCZ                =         zeros(4, 2); 

            for k =1:length(CueTypes)

                n_correct                                  =       sum(strcmp(obj.Treatments, 'Saline') & strcmp(obj.Outcome', 'Correct')        & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_premature                            =       sum(strcmp(obj.Treatments, 'Saline') & strcmp(obj.Outcome', 'Premature')  & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_late                                        =       sum(strcmp(obj.Treatments, 'Saline') & strcmp(obj.Outcome', 'Late')              & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_legit                                       =       n_correct+n_premature+n_late;
                CueUncueSal(1, k)                   =           CueUncueSal(1, k) + n_legit;
                CueUncueSal(2, k)                   =           CueUncueSal(2, k) + n_correct;
                CueUncueSal(3, k)                   =           CueUncueSal(3, k) + n_premature;
                CueUncueSal(4, k)                   =           CueUncueSal(4, k) + n_late;
                P_CueUncue_Saline(:, k)        =            [1; CueUncueSal(2, k)/CueUncueSal(1, k); CueUncueSal(3, k)/CueUncueSal(1, k); CueUncueSal(4, k)/CueUncueSal(1, k)];

                n_correct                             =       sum(strcmp(obj.Treatments, 'DCZ') & strcmp(obj.Outcome', 'Correct')        & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_premature                       =       sum(strcmp(obj.Treatments, 'DCZ') & strcmp(obj.Outcome', 'Premature')  & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_late                                    =       sum(strcmp(obj.Treatments, 'DCZ') & strcmp(obj.Outcome', 'Late')              & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_legit                                   =       n_correct+n_premature+n_late;
                CueUncueDCZ(1, k)             =          CueUncueDCZ(1, k) + n_legit;
                CueUncueDCZ(2, k)             =          CueUncueDCZ(2, k) + n_correct;
                CueUncueDCZ(3, k)             =          CueUncueDCZ(3, k) + n_premature;
                CueUncueDCZ(4, k)             =          CueUncueDCZ(4, k) + n_late;
                P_CueUncue_DCZ(:, k)        =          [1; CueUncueDCZ(2, k)/CueUncueDCZ(1, k); CueUncueDCZ(3, k)/CueUncueDCZ(1, k); CueUncueDCZ(4, k)/CueUncueDCZ(1, k)];

            end;

            BehaviorTypes = {'OutcomeCount',...
                'N_Cue_Saline', 'Percent_Cue_Saline', ...
                'N_Cue_DCZ', 'Percent_Cue_DCZ',...
                'N_Uncue_Saline', 'Percent_Uncue_Saline', ...
                'N_Uncue_DCZ', 'Percent_Uncue_DCZ'};

            value = table(OutcomeCount, ...
                CueUncueSal(:, 1), P_CueUncue_Saline(:, 1),...
                CueUncueDCZ(:, 1), P_CueUncue_DCZ(:, 1), ...
                CueUncueSal(:, 2), P_CueUncue_Saline(:, 2), ...
                CueUncueDCZ(:, 2), P_CueUncue_DCZ(:, 2),...
                'VariableNames', BehaviorTypes);

        end

        function value = get.FastResponseRatio(obj)
            % ratio of responses within a time window after tone (only count post tone responses, excluding premature responses)
            vNames = {'Type', 'Ratio'};
            AllTypes = {'Cue_Saline'; 'Cue_DCZ'; 'Uncue_Saline'; 'Uncue_DCZ'};

            % Cue, Control
            iRT = obj.RT_Cue{1};
            Ratio_Cue_Control = sum(iRT>0.1 & iRT<=obj.ResponseWindow(1))/length(iRT);
            iRT = obj.RT_Cue{2};
            Ratio_Cue_DCZ = sum(iRT>0.1 & iRT<=obj.ResponseWindow(1))/length(iRT);
            iRT = obj.RT_Uncue{1};
            Ratio_Uncue_Control = sum(iRT>0.1 & iRT<=obj.ResponseWindow(2))/length(iRT);
            iRT = obj.RT_Uncue{2};
            Ratio_Uncue_DCZ = sum(iRT>0.1 & iRT<=obj.ResponseWindow(2))/length(iRT);
            Ratio = [Ratio_Cue_Control; Ratio_Cue_DCZ; Ratio_Uncue_Control; Ratio_Uncue_DCZ];

            value = table(AllTypes, Ratio, ...
                'VariableNames', vNames);

        end

        function PlotPerformanceSessions(obj)
            % Show performance over multiple sessions
            % Show response time distribution

            set_matlab_default;
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPColor = [189, 198, 184]/255;
            WhiskerColor = [132, 121, 225]/255;
            IndDCZ = find(strcmp(obj.TreatmentSessions, 'DCZ'));

            figure(obj.Fig2); clf(obj.Fig2)
            set(gcf, 'unit', 'centimeters', 'position',[2 2 31 19.25], 'paperpositionmode', 'auto', 'color', 'w')

            % Plot press duration across these sessions
            plotsize1 = [8 4]; % trials over sessions
            plotsize2 = [6 4]; % performance over sessions, sliding window
            plotsize3 = [4 4]; % performance over sessions
            plotsize4 = [0.5*obj.NumSessions 4]; % PDF, colormap

            plotsizeViolin = [6, 4];
            plotsizeIQR = [6, 4];

            plotsize5 = [3 4]; % for showing PDF
            plotsize6 = [5 3]; % for writing information
            symbolSize = 20*10/obj.NumSessions;
            jitter = 0.25;
            ShadeCol = [255, 212, 149]/255;

            StartTime = 0;
            maxPressDur = unique(obj.MixedFP)+2000; 

            % Press duration, Cued. 
            ha(1) = axes;
            title('Cued', 'fontsize', 7, 'FontWeight', 'bold')
            xlevel = 2;
            ylevel = 19-plotsize1(2)-1.25;
            set(ha(1), 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [-100 maxPressDur], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % Performance score, Cued
            xlevel2 = xlevel + plotsize1(1) + 1.5;
            %             ylevel2 = ylevel - plotsize1(2) - 1.25;
            ha(2) = axes;
            set(ha(2),  'units', 'centimeters', 'position', [xlevel2, ylevel, plotsize2], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear','xticklabel',[])
            ylabel('Performance')
            title('Cued', 'fontsize', 7, 'FontWeight', 'bold')

            % Performance over session
            xlevel3= xlevel2 + plotsize2(1) + 1.5;
            ha(3) = axes;
            set(ha(3),  'units', 'centimeters', 'position', [xlevel3, ylevel, plotsize3], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear')
            ylabel('Performance (average)')
            xlabel('Sessions')
            title('Cued', 'fontsize', 7, 'FontWeight', 'bold')

            % PDF of press duration, colormap, over sessions
            xlevel4= xlevel3 + plotsize3(1) + 1.5;
            ha(4) = axes;
            set(ha(4),  'units', 'centimeters', 'position', [xlevel4, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 maxPressDur], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear', ...
                'xtick', [1:obj.NumSessions], 'xticklabel', obj.Dates)
            ylabel('Press dur (msec)')
            title('Cued', 'fontsize', 7, 'FontWeight', 'bold')

            Pos = get(gcf, 'position');
            Pos(3) = xlevel4+plotsize4(1)+2;
            set(gcf, 'position', Pos)

            %% Uncued trials
            ha(5) = axes;
            title('Uncued trials', 'fontsize', 7, 'FontWeight', 'bold')
            xlevel = 2;
            ylevel2 = ylevel - plotsize1(2) - 1.75;
            set(ha(5), 'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
                'ylim', [-100 maxPressDur], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % Performance score, Uncued
            ha(6) = axes;
            set(ha(6),  'units', 'centimeters', 'position', [xlevel2, ylevel2, plotsize2], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear','xticklabel',[])
            ylabel('Performance')
            title('Uncued', 'fontsize', 7, 'FontWeight', 'bold')

            % Performance over session
            ha(7) = axes;
            set(ha(7),  'units', 'centimeters', 'position', [xlevel3, ylevel2, plotsize3], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear')
            ylabel('Performance (average)')
            xlabel('Sessions')
            title('Uncued', 'fontsize', 7, 'FontWeight', 'bold')

            % PDF of press duration, colormap, over sessions
            ha(8) = axes;
            set(ha(8),  'units', 'centimeters', 'position', [xlevel4, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 maxPressDur], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear', ...
                'xtick', [1:obj.NumSessions], 'xticklabel', obj.Dates)
            ylabel('Press dur (msec)')
            xlabel('Sessions')
            title('Uncued', 'fontsize', 7, 'FontWeight', 'bold')

            % for violin plot, a new level
            ylevel3 = ylevel2 - plotsize1(2) - 2.25;

            ha_violin_cued =    axes;
            set(ha_violin_cued, 'units', 'centimeters', 'position', [xlevel, ylevel3, plotsizeViolin], 'nextplot', 'add', ...
                'ylim', [-100 maxPressDur], 'yscale', 'linear')
            title('Cued', 'fontsize', 7, 'FontWeight', 'bold')
            ylabel('Press dur (msec)')

            xlevel2prime = xlevel + plotsizeViolin(1) +1.25;
            ha_violin_uncued =    axes;
            set(ha_violin_uncued, 'units', 'centimeters', 'position', [xlevel2prime, ylevel3, plotsizeViolin], 'nextplot', 'add', ...
                'ylim', [-100 maxPressDur], 'yscale', 'linear')
            title('Uncued', 'fontsize', 7, 'FontWeight', 'bold')
            ylabel('Press dur (msec)')

            % Last plot is the width of response distribution
            ha_response_width = axes;
            xlevel5 = xlevel2prime + plotsizeViolin(1) + 1.5;
            ylim = [min(obj.IQR_Sessions(:))*0.8 max(obj.IQR_Sessions(:))*1.2];
            
            set(ha_response_width, 'units', 'centimeters', 'position', [xlevel5, ylevel3, plotsizeIQR], 'nextplot', 'add', ...
                'ylim', ylim,'ytick',[0:200:5000], 'yscale', 'linear', 'xlim', [0 obj.NumSessions+1], 'xtick', [1:obj.NumSessions], ...
                'xticklabel', obj.Dates, 'XTickLabelRotation', 90)

            ylabel('IQR (ms)')
            title('IQR', 'fontsize', 7, 'FontWeight', 'bold')

            yrange = ylim;
            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    plotshaded([IndDCZ(j)-2*jitter  IndDCZ(j)+2*jitter],  [yrange(1) yrange(1); yrange(2) yrange(2)], ShadeCol, 0.5);
                end;
            end;

            hp_cued = plot([1:obj.NumSessions], obj.IQR_Sessions(:, 1), 'Marker', 'o', 'Color', 'k', 'MarkerFaceColor', 'k', ...
                'MarkerEdgeColor', 'w','linestyle', '-', 'linewidth', 1, 'markersize', 5);
            hp_uncued = plot([1:obj.NumSessions], obj.IQR_Sessions(:, 2), 'Marker', 'o', 'Color', 'k', 'MarkerFaceColor', 'w', ...
                'MarkerEdgeColor', 'k', 'linestyle', '-', 'linewidth', 1, 'markersize', 5);
            
            hlegend = legend([hp_cued, hp_uncued], 'Cued', 'Uncued', 'Box', 'off'); 

            % Plot early and late sessoins PDF
            ha_pdf_progress = axes;
            xlevel6 = xlevel5 + plotsizeIQR(1) + 1.25;             
            set(ha_pdf_progress, 'units', 'centimeters', 'position', [xlevel6, ylevel3, plotsize5], 'nextplot', 'add', ...
                'xlim', [0 max(obj.HoldTbinEdges)*1000],'xtick',[0:500:max(obj.HoldTbinEdges)*1000], 'yscale', 'linear');
            
            MaxPDF = 0;

            ylabel('PDF (1/s)')
            xlabel('Hold dur (ms)')
            title('Cued', 'fontsize', 7, 'FontWeight', 'bold')
            EarlyColor = [62, 84, 172]/255;
            LateColor = [249, 74, 41]/255;
            hp1 = plot(ha_pdf_progress, obj.HoldTbinEdges*1000, smoothdata(obj.PDF_HoldT_Cue_Progress{1, 1}, 'gaussian', 5), ...
                'color', EarlyColor, 'linewidth', 1.5);
            hp2 = plot(ha_pdf_progress, obj.HoldTbinEdges*1000, smoothdata(obj.PDF_HoldT_Cue_Progress{2, 1}, 'gaussian', 5), ...
                'color', LateColor, 'linewidth', 1.5);
       
            MaxPDF = max([MaxPDF smoothdata(obj.PDF_HoldT_Cue_Progress{1, 1}, 'gaussian', 7)]);
            MaxPDF = max([MaxPDF smoothdata(obj.PDF_HoldT_Cue_Progress{2, 1}, 'gaussian', 7)]);

            ha_pdf_progress2 = axes;
            xlevel7 = xlevel6 + plotsize5(1) + 1.25;             
            set(ha_pdf_progress2, 'units', 'centimeters', 'position', [xlevel7, ylevel3, plotsize5], 'nextplot', 'add', ...
                'xlim', [0 max(obj.HoldTbinEdges)*1000],'xtick',[0:500:max(obj.HoldTbinEdges)*1000], 'yscale', 'linear');
            
            ylabel('PDF (1/s)')
            xlabel('Hold dur (ms)')
            title('Uncued', 'fontsize', 7, 'FontWeight', 'bold')

            hp3 = plot(ha_pdf_progress2, obj.HoldTbinEdges*1000, smoothdata(obj.PDF_HoldT_Uncue_Progress{1, 1}, 'gaussian', 5), ...
                'color', EarlyColor, 'linewidth', 1.5);
            hp4 = plot(ha_pdf_progress2, obj.HoldTbinEdges*1000, smoothdata(obj.PDF_HoldT_Uncue_Progress{2, 1}, 'gaussian', 5), ...
                'color', LateColor, 'linewidth', 1.5);

            MaxPDF = max([MaxPDF smoothdata(obj.PDF_HoldT_Uncue_Progress{1, 1}, 'gaussian', 7)]);
            MaxPDF = max([MaxPDF smoothdata(obj.PDF_HoldT_Uncue_Progress{2, 1}, 'gaussian', 7)]);

            set(ha_pdf_progress, 'ylim', [0 MaxPDF*1.2]);
            set(ha_pdf_progress2, 'ylim', [0 MaxPDF*1.2]);

            line(ha_pdf_progress, [unique(obj.MixedFP) unique(obj.MixedFP)], [0  MaxPDF*1.2], 'linestyle', '-.', 'color', [0.8 0.8 0.8], 'linewidth', 1)
            line(ha_pdf_progress2, [unique(obj.MixedFP) unique(obj.MixedFP)], [0  MaxPDF*1.2], 'linestyle', '-.', 'color', [0.8 0.8 0.8], 'linewidth', 1)

            axes(ha_pdf_progress2)
            legend([hp3, hp4], 'Early', 'Late', 'Box','off', 'Location','northeast')
            % Press duration y range
            PressDurRange = [-100 maxPressDur];
            PerformanceSessions = zeros(3, obj.NumSessions, 2);
            HoldTDistributionAll = cell(1, 2); % Cued, Uncued
            maxHoldT_PDF       =  max(max(cell2mat(obj.PDF_HoldT_Sessions)));

            % check figure size again
            Pos = get(gcf, 'position');
            if Pos(3)<xlevel7+plotsize5(2)
                Pos(3)=0.5+xlevel7+plotsize5(2);
            end;
            set(gcf, 'position', Pos)

             for i =1:obj.NumSessions

                HoldTDistributionAll{1} = [HoldTDistributionAll{1} obj.PDF_HoldT_Sessions{i, 1}];
                HoldTDistributionAll{2} = [HoldTDistributionAll{2} obj.PDF_HoldT_Sessions{i, 2}];

                iPressTimes                 =           obj.PressTime(obj.PressIndex ==i);
                iReleaseTimes             =           obj.ReleaseTime(obj.PressIndex ==i);
                iCue                               =           obj.Cue(obj.PressIndex == i);
                iOutcome                     =            [obj.Outcome(obj.PressIndex == i)]'; 
                iStage                            =            obj.Stage(obj.PressIndex == i);
                indPerformanceSliding   =       find(obj.PerformanceSlidingWindow.Session == i);

                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(5), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
               
                set(ha(2), 'ylim', [0 100], 'xlim', [0 iReleaseTimes(end)+StartTime], ...
                    'yscale', 'linear', 'xtick', []);
                set(ha(6), 'ylim', [0 100], 'xlim', [0 iReleaseTimes(end)+StartTime], ...
                    'yscale', 'linear', 'xtick', []);

                line(ha(1), [iPressTimes(1) + StartTime iPressTimes(1) + StartTime], PressDurRange, ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(5), [iPressTimes(1) + StartTime iPressTimes(1) + StartTime], PressDurRange, ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1)

                if  strcmp(obj.TreatmentSessions{i}, 'DCZ')

                    axes(ha(1))
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [PressDurRange(1) PressDurRange(1); PressDurRange(2) PressDurRange(2)], ShadeCol, 0.5);
                    axes(ha(2))
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [-5 -5; 100 100], ShadeCol, 0.5);

                    axes(ha(5))
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [PressDurRange(1) PressDurRange(1); PressDurRange(2) PressDurRange(2)], ShadeCol, 0.5);
                    axes(ha(6))
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [-5 -5; 100 100], ShadeCol, 0.5);

                    %  [-100 maxPressDur]
                    axes(ha_violin_cued)
                    plotshaded([i-2*jitter  i+2*jitter], [-100 -100; maxPressDur maxPressDur], ShadeCol, 0.5);
                    axes(ha_violin_uncued)
                    plotshaded([i-2*jitter  i+2*jitter],  [-100 -100; maxPressDur maxPressDur], ShadeCol, 0.5);
                    
                end;

                % plot press times
                line(ha(1), [iPressTimes(iCue==1); iPressTimes(iCue==1)]+StartTime, [-100; 0], 'color', 'b')
                % Plot premature responses
                % Cued
                ind_premature_presses = (strcmp(iOutcome, 'Premature') & iCue == 1 & iStage ==1);
                scatter(ha(1), iReleaseTimes(ind_premature_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_premature_presses) -iPressTimes(ind_premature_presses)), ...
                    8, col_perf(2, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, ...
                    'MarkerEdgeColor','none', 'SizeData', symbolSize);

                % Uncued
                line(ha(5), [iPressTimes(iCue==0); iPressTimes(iCue==0)]+StartTime, [-100; 0], 'color', 'b')
                ind_premature_presses = (strcmp(iOutcome, 'Premature') & iCue == 0 & iStage ==1);
                scatter(ha(5), iReleaseTimes(ind_premature_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_premature_presses) -iPressTimes(ind_premature_presses)), ...
                    8, col_perf(2, :), 'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor', col_perf(2, :), ...
                     'SizeData', symbolSize);

                % Plot late responses
                % Cued
                ind_late_presses = (strcmp(iOutcome, 'Late') & iCue == 1 & iStage ==1);
                LateDur =   1000*(iReleaseTimes(ind_late_presses) - iPressTimes(ind_late_presses));
                LateDur(LateDur>maxPressDur) = maxPressDur;
                scatter(ha(1), iReleaseTimes(ind_late_presses)+StartTime, LateDur, ...
                    8, col_perf(3, :),  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none', ...
                     'SizeData', symbolSize);
                
                % Uncued
                ind_late_presses = (strcmp(iOutcome, 'Late') & iCue == 0 & iStage ==1);
                LateDur =   1000*(iReleaseTimes(ind_late_presses) - iPressTimes(ind_late_presses));
                LateDur(LateDur>maxPressDur) = maxPressDur;
                scatter(ha(5), iReleaseTimes(ind_late_presses)+StartTime, LateDur, ...
                    8, col_perf(3, :),  'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor', col_perf(3, :) ,...
                     'SizeData', symbolSize);

                %  Plot dark responses
                % Cued
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iCue == 1  & iStage ==1;
                scatter(ha(1), iReleaseTimes(ind_dark_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_dark_presses) - iPressTimes(ind_dark_presses)), ...
                    8, 'k',  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none', ...
                     'SizeData', symbolSize);

                % Uncued
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iCue == 0  & iStage ==1;
                scatter(ha(5), iReleaseTimes(ind_dark_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_dark_presses) - iPressTimes(ind_dark_presses)), ...
                    8, 'k',  'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','k', ...
                     'SizeData', symbolSize);

                % Plot correct responses
                % Cued
                ind_good_presses = strcmp(iOutcome, 'Correct') & iCue == 1  & iStage ==1;
                scatter(ha(1), iReleaseTimes(ind_good_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_good_presses) - iPressTimes(ind_good_presses)), ...
                    8, col_perf(1, :),   'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none', 'SizeData', symbolSize);

                ind_good_presses = strcmp(iOutcome, 'Correct') & iCue == 0  & iStage ==1;
                scatter(ha(5), iReleaseTimes(ind_good_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_good_presses) - iPressTimes(ind_good_presses)), ...
                    8, col_perf(1, :),   'o','filled', 'Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor',col_perf(1, :), ...
                     'SizeData', symbolSize);

                % Plot performance indPerformanceSliding
                line(ha(2), [obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime], [0 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(6), [obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime], [0 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1)

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :))
                % add mean performance
                iCorrect            =        obj.PerformanceOverSessions{i}.Correct(obj.PerformanceOverSessions{i}.CueTypes==1);
                iPremature       =        obj.PerformanceOverSessions{i}.Premature(obj.PerformanceOverSessions{i}.CueTypes==1);
                iLate                 =        obj.PerformanceOverSessions{i}.Late(obj.PerformanceOverSessions{i}.CueTypes==1);

                tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                %                 line(ha(2), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);
                PerformanceSessions(1, i, 1) = iCorrect; % cue correct response performance
                PerformanceSessions(2, i, 1) = iPremature; % cue correct response performance
                PerformanceSessions(3, i, 1) = iLate; % cue correct response performance

                % add session time
                iSession = obj.Sessions{i}(5:10);
                iSession = strrep(iSession, '-', '');

                text(ha(2), obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime, -20, iSession , "fontname",'dejavu sans','FontSize',7,'FontWeight','bold','Color', ...
                    'k', 'Rotation', 90)
                text(ha(6), obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime, -20, iSession , "fontname",'dejavu sans','FontSize',7,'FontWeight','bold','Color', ...
                    'k', 'Rotation', 90)

                % Sliding window, uncued response
                plot(ha(6),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :))

                iCorrect = obj.PerformanceOverSessions{i}.Correct(obj.PerformanceOverSessions{i}.CueTypes==0);
                iPremature       =        obj.PerformanceOverSessions{i}.Premature(obj.PerformanceOverSessions{i}.CueTypes==0);
                iLate                 =        obj.PerformanceOverSessions{i}.Late(obj.PerformanceOverSessions{i}.CueTypes==0);
                tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                %                 line(ha(4), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);
                PerformanceSessions(1, i, 2) = iCorrect; % cue correct response performance
                PerformanceSessions(2, i, 2) = iPremature; % cue correct response performance
                PerformanceSessions(3, i, 2) = iLate; % cue correct response performance

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :))
                plot(ha(6),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :))

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :))

                plot(ha(6),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :))

                StartTime = iReleaseTimes(end) + StartTime;
            end;


            line(ha(1), [0 iReleaseTimes(end)+StartTime], [unique(obj.MixedFP) unique(obj.MixedFP)], ...
                'color', 'k', 'linestyle', '--','linewidth', 1)
            line(ha(5), [0 iReleaseTimes(end)+StartTime], [unique(obj.MixedFP) unique(obj.MixedFP)], ...
                'color', 'k', 'linestyle', '--','linewidth', 1)

            % add average perfromance score: AllPreLesionSessions / AllPostLesionSessions
            % cued response
            axes(ha(3))
            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    plotshaded([IndDCZ(j)-2*jitter  IndDCZ(j)+2*jitter],  [0 0; 100 100], ShadeCol, 0.5);
                end;
            end;

            hp_correct(1)              =           plot(ha(3), [1:obj.NumSessions], PerformanceSessions(1, :, 1), ...
                'linewidth', 2.5, 'color', col_perf(1, :), 'marker', '.', 'markersize', 10);
            hp_premature(1)        =           plot(ha(3), [1:obj.NumSessions], PerformanceSessions(2, :, 1), ...
                'linewidth', 2.5, 'color', col_perf(2, :), 'marker', '.', 'markersize', 10);
            hp_late(1)                     =           plot(ha(3), [1:obj.NumSessions], PerformanceSessions(3, :, 1), ...
                'linewidth', 2.5, 'color', col_perf(3, :), 'marker', '.', 'markersize', 10);

            % add average perfromance score: AllPreLesionSessions / AllPostLesionSessions
            % uncued response
            axes(ha(7))
            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    plotshaded([IndDCZ(j)-2*jitter  IndDCZ(j)+2*jitter],  [0 0; 100 100], ShadeCol, 0.5);
                end;
            end;

            hp_correct(2)              =           plot(ha(7), [1:obj.NumSessions], PerformanceSessions(1, :, 2), ...
                'linewidth', 2.5, 'color', col_perf(1, :), 'marker', '.', 'markersize', 10);
            hp_premature(2)        =           plot(ha(7), [1:obj.NumSessions], PerformanceSessions(2, :, 2), ...
                'linewidth', 2.5, 'color', col_perf(2, :), 'marker', '.', 'markersize', 10);
            hp_late(2)                     =           plot(ha(7), [1:obj.NumSessions], PerformanceSessions(3, :, 2), ...
                'linewidth', 2.5, 'color', col_perf(3, :), 'marker', '.', 'markersize', 10);

            % Colormap:
            axes(ha(4))
            imagesc([1:obj.NumSessions], obj.HoldTbinEdges_Sessions*1000,  HoldTDistributionAll{1}, [0 maxHoldT_PDF*1.2]);
            colormap(turbo)
            hbar1 = colorbar;
            set(hbar1, 'units', 'centimeters', 'position', [xlevel4+plotsize4(1)+0.1, ylevel, [0.2 plotsize4(2)]] )
            hbar1.Label.String = 'PDF (1/sec)';

            % add chemo session marks          
            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    arrow([IndDCZ(j), 0], [IndDCZ(j) 100], ...
                        'color', ShadeCol, 'linewidth', 2, 'Length',3, 'TipAngle', 35);
                                arrow([IndDCZ(j), 0], [IndDCZ(j) 100], ...
                        'color', ShadeCol, 'linewidth', 2, 'Length',3, 'TipAngle', 35);
                    pos = [IndDCZ(j)-0.5, 0, 1, max(obj.MixedFP)+2000];
                    rectangle('Position',pos, 'EdgeColor', ShadeCol, 'linewidth', 1, 'linestyle', ':')
                end;
            end;

            axes(ha(8))
            imagesc([1:obj.NumSessions], obj.HoldTbinEdges_Sessions*1000,  HoldTDistributionAll{2}, [0 maxHoldT_PDF*1.2]);
            colormap(turbo)
            hbar2 = colorbar;
            set(hbar2, 'units', 'centimeters', 'position', [xlevel4+plotsize4(1)+0.1, ylevel2, [0.2 plotsize4(2)]] )
            hbar2.Label.String = 'PDF (1/sec)';

            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    arrow([IndDCZ(j), 0], [IndDCZ(j) 100], ...
                        'color', ShadeCol, 'linewidth', 2, 'Length',3, 'TipAngle', 35);
                    pos = [IndDCZ(j)-0.5, 0, 1, max(obj.MixedFP)+2000];
                    rectangle('Position',pos, 'EdgeColor', ShadeCol, 'linewidth', 1, 'linestyle', ':')
                end;
            end;

            % Use violinplot to show response distribution 
            % reaction time violing plot
            axes(ha_violin_cued)
            HoldT_Cued = obj.HoldTime(obj.Stage ==1 & obj.Cue == 1)*1000;
            HoldT_Cued_Indx = obj.PressIndex(obj.Stage ==1 & obj.Cue == 1);
            hVio1 = violinplot(HoldT_Cued,  HoldT_Cued_Indx, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false, 'EdgeColor', [0 0 0], 'BoxColor', [253, 138, 138]/255, 'ViolinColor', [0.6 0.6 0.6]);
          
            for iv =1:length(hVio1)
                hVio1(iv).EdgeColor = [0 0 0];
                hVio1(iv).WhiskerPlot.Color = WhiskerColor;
                hVio1(iv).WhiskerPlot.LineWidth = 1.5;
                hVio1(iv).ScatterPlot.MarkerFaceColor = 'k';
                hVio1(iv).ScatterPlot.SizeData = 10;
                hVio1(iv).ViolinPlot.FaceColor = [0.8 0.8 0.8];
                hVio1(iv).BoxColor=[253, 138, 138]/255;
                hVio1(iv).BoxWidth = 0.03;
            end;

            set( ha_violin_cued, 'xtick', unique(obj.PressIndex), 'xticklabels', obj.Dates, 'box', 'off','XTickLabelRotation', 35);
            line(ha_violin_cued, get(ha_violin_cued, 'xlim'), [unique(obj.MixedFP) unique(obj.MixedFP)], 'color', 'k', 'linewidth', 1, 'linestyle', '--')

            axes(ha_violin_uncued)
            HoldT_Uncued = obj.HoldTime(obj.Stage ==1 & obj.Cue == 0)*1000;
            HoldT_Uncued_Indx = obj.PressIndex(obj.Stage ==1 & obj.Cue == 0);
            hVio2 = violinplot(HoldT_Uncued,  HoldT_Uncued_Indx, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false, 'EdgeColor', [0 0 0], 'BoxColor', [253, 138, 138]/255, 'ViolinColor', [0.6 0.6 0.6]);

            for iv =1:length(hVio2)
                hVio2(iv).EdgeColor = [0 0 0];
                hVio2(iv).WhiskerPlot.Color = WhiskerColor;
                hVio2(iv).WhiskerPlot.LineWidth = 1.5;
                hVio2(iv).ScatterPlot.MarkerFaceColor = 'k';
                hVio2(iv).ScatterPlot.SizeData = 10;
                hVio2(iv).ViolinPlot.FaceColor = [0.8 0.8 0.8];
                hVio2(iv).BoxColor=[253, 138, 138]/255;
                hVio2(iv).BoxWidth = 0.03;
            end;

            set(ha_violin_uncued, 'xtick', unique(obj.PressIndex), 'xticklabels', obj.Dates, 'box', 'off','XTickLabelRotation', 35);
            line(ha_violin_uncued, get(ha_violin_cued, 'xlim'), [unique(obj.MixedFP) unique(obj.MixedFP)], 'color', 'k', 'linewidth', 1, 'linestyle', '--')

            hui_1 = uicontrol('Style', 'text', 'parent', obj.Fig2, 'units', 'normalized', 'position', [0.1 0.965 0.2 0.03],...
                'string',  ['Subject: ' obj.Subject{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans' );

            hui_2 = uicontrol('Style', 'text', 'parent', obj.Fig2, 'units', 'normalized', 'position', [0.2 0.965 0.4 0.03],...
                'string', ['Protocol: ' obj.Protocols{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans');
        end

        function outputArg = Plot(obj)
            % Plot group data
            set_matlab_default;
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPColor = [189, 198, 184]/255;
            WhiskerColor = [132, 121, 225]/255;

            figure(20); clf(20)
            set(gcf, 'unit', 'centimeters', 'position',[2 2 28 19], 'paperpositionmode', 'auto', 'color', 'w')

            % Plot press duration across these sessions
            plotsize1 = [8, 3];
            plotsize4 = [4 3];
            plotsize5 = [2 3]; % for writing information
            plotsize6 = [5 3]; % for writing information
            plotsize3 = [2 3];
            StartTime = 0;
 
            ha(1) = axes;
            title('Cued trials', 'fontsize', 7, 'FontWeight', 'bold')
            xlevel = 2;
            ylevel = 19-plotsize1(2)-1.25;
            set(ha(1), 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 3500], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % Performance score, Cued
            xlevel = 2;
            ylevel2 = ylevel - plotsize1(2) - 1.25;

            ha(2) = axes;
            set(ha(2),  'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')

            ylabel('Performance')

            %% Uncued trials
            ha(3) = axes;
            title('Uncued trials', 'fontsize', 7, 'FontWeight', 'bold')
            xlevel = 2;
            ylevel3 = ylevel2 - plotsize1(2) - 1.5;
            set(ha(3), 'units', 'centimeters', 'position', [xlevel, ylevel3, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 3500], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % Performance score, Uncued
            xlevel = 2;
            ylevel4 = ylevel3 - plotsize1(2) - 1.25;
            ha(4) = axes;
            set(ha(4),  'units', 'centimeters', 'position', [xlevel, ylevel4, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')
            ylabel('Performance')
            title('Uncued trials', 'fontsize', 7, 'FontWeight', 'bold')

            % Press duration y range
            PressDurRange = [0, unique(obj.MixedFP)+1000];

            ShadeCol = [255 203 66]/255;

            for i =1:obj.NumSessions
                iPressTimes                 =           obj.PressTime(obj.PressIndex ==i);
                iReleaseTimes             =           obj.ReleaseTime(obj.PressIndex ==i);
                iCue                               =           obj.Cue(obj.PressIndex == i);
                iOutcome                     =            [obj.Outcome(obj.PressIndex == i)]'; 
                iStage                            =            obj.Stage(obj.PressIndex == i);
                indPerformanceSliding   =       find(obj.PerformanceSlidingWindow.Session == i);

                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(3), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(2), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);
                set(ha(4), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);

                line(ha(1), [iPressTimes(1) + StartTime iPressTimes(1) + StartTime], [0 3500], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(3), [iPressTimes(1) + StartTime iPressTimes(1) + StartTime], [0 3500], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1)

                % Shade DCZ trials
                if strcmp(obj.TreatmentSessions{i}, 'DCZ')
                    axes(ha(1)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; PressDurRange(2) PressDurRange(2)], [255 203 66]/255)
                    axes(ha(2)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; 100 100], [255 203 66]/255)
                    axes(ha(3)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; PressDurRange(2) PressDurRange(2)], [255 203 66]/255)
                    axes(ha(4)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; 100 100], [255 203 66]/255)
                end

                % plot press times
                line(ha(1), [iPressTimes(iCue==1); iPressTimes(iCue==1)]+StartTime, [0; 250], 'color', 'b')
                % Plot premature responses
                % Cued
                ind_premature_presses = (strcmp(iOutcome, 'Premature') & iCue == 1 & iStage ==1);
                scatter(ha(1), iReleaseTimes(ind_premature_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_premature_presses) -iPressTimes(ind_premature_presses)), ...
                    8, col_perf(2, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Uncued
                line(ha(3), [iPressTimes(iCue==0); iPressTimes(iCue==0)]+StartTime, [0 250], 'color', 'b')
                ind_premature_presses = (strcmp(iOutcome, 'Premature') & iCue == 0 & iStage ==1);
                scatter(ha(3), iReleaseTimes(ind_premature_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_premature_presses) -iPressTimes(ind_premature_presses)), ...
                    8, col_perf(2, :), 'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor', col_perf(2, :));

                % Plot late responses
                % Cued
                ind_late_presses = (strcmp(iOutcome, 'Late') & iCue == 1 & iStage ==1);
                LateDur =   1000*(iReleaseTimes(ind_late_presses) - iPressTimes(ind_late_presses));
                LateDur(LateDur>3500) = 3499;
                scatter(ha(1), iReleaseTimes(ind_late_presses)+StartTime, LateDur, ...
                    8, col_perf(3, :),  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');
                % Uncued
                ind_late_presses = (strcmp(iOutcome, 'Late') & iCue == 0 & iStage ==1);
                LateDur =   1000*(iReleaseTimes(ind_late_presses) - iPressTimes(ind_late_presses));
                LateDur(LateDur>3500) = 3499;
                scatter(ha(3), iReleaseTimes(ind_late_presses)+StartTime, LateDur, ...
                    8, col_perf(3, :),  'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor', col_perf(3, :));

                %  Plot dark responses
                % Cued
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iCue == 1  & iStage ==1;
                scatter(ha(1), iReleaseTimes(ind_dark_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_dark_presses) - iPressTimes(ind_dark_presses)), ...
                    8, 'k',  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Uncued
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iCue == 0  & iStage ==1;
                scatter(ha(3), iReleaseTimes(ind_dark_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_dark_presses) - iPressTimes(ind_dark_presses)), ...
                    8, 'k',  'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','k');

                % Plot correct responses
                % Cued
                ind_good_presses = strcmp(iOutcome, 'Correct') & iCue == 1  & iStage ==1;
                scatter(ha(1), iReleaseTimes(ind_good_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_good_presses) - iPressTimes(ind_good_presses)), ...
                    8, col_perf(1, :),   'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                ind_good_presses = strcmp(iOutcome, 'Correct') & iCue == 0  & iStage ==1;
                scatter(ha(3), iReleaseTimes(ind_good_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_good_presses) - iPressTimes(ind_good_presses)), ...
                    8, col_perf(1, :),   'o','filled', 'Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor',col_perf(1, :));

                % Plot performance indPerformanceSliding
                line(ha(2), [obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime], [0 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(4), [obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime], [0 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1)

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :))

                % add mean performance
                iCorrect = obj.PerformanceOverSessions{i}.Correct(obj.PerformanceOverSessions{i}.CueTypes==1);
                tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                line(ha(2), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);


                % add session time
                iSession = obj.Sessions{i}(5:10);
                iSession = strrep(iSession, '-', '');

                text(ha(2), obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime, -25, iSession , "fontname",'dejavu sans','FontSize',7,'FontWeight','bold','Color', ...
                    'k', 'Rotation', 25)
                text(ha(4), obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime, -25, iSession , "fontname",'dejavu sans','FontSize',7,'FontWeight','bold','Color', ...
                    'k', 'Rotation', 25)

                plot(ha(4),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :))

                iCorrect = obj.PerformanceOverSessions{i}.Correct(obj.PerformanceOverSessions{i}.CueTypes==0);
                tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                line(ha(4), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :))
                plot(ha(4),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :))

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :))
                plot(ha(4),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :))
                StartTime = iReleaseTimes(end) + StartTime;
            end;

            line(ha(1), [0 iReleaseTimes(end)+StartTime], [unique(obj.MixedFP)  unique(obj.MixedFP)], 'color', [0 0 0], 'linestyle', ':', 'linewidth', 1)
            line(ha(3), [0 iReleaseTimes(end)+StartTime], [unique(obj.MixedFP)  unique(obj.MixedFP)], 'color', [0 0 0], 'linestyle', ':', 'linewidth', 1)
 
            %% Plot reaction time distribution
            SalineColor = [90 90 90]/255;
            DCZColor     =  [255, 203, 66]/255;

            if length(obj.PDF_RT_Cue)>1 && ~isempty(obj.PDF_RT_Cue{2})
                TwoConditions = 1;
            else
                TwoConditions = 0;
            end;
   
            % Plot PDF, reaction time, cued trials
            ha5 = axes;
            xlevel2 = xlevel + plotsize1(1) + 1.5;
            set(ha5,'units', 'centimeters', 'position', [xlevel2, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 2],'xtick', [0:4], ...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            maxPDF = 0;
            plot(obj.RTbinEdges, obj.PDF_RT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.RTbinEdges, obj.PDF_RT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            maxPDF = max([maxPDF, max(obj.PDF_RT_Cue{1}), max(obj.PDF_RT_Uncue{1})]);
            if TwoConditions
                plot(obj.RTbinEdges, obj.PDF_RT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.RTbinEdges, obj.PDF_RT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
                maxPDF = max([maxPDF, max(obj.PDF_RT_Cue{2}), max(obj.PDF_RT_Uncue{2})]);
            end;

            xlabel('Reaction time (s)')
            ylabel('PDF (1/s)')
            set(gca, 'ylim', [0 maxPDF*1.1])

            % Plot CDF, reaction time, cued trials
            ha7 = axes;
            xlevel3 = xlevel2 + plotsize4(1) + 1.25;
            set(ha7,'units', 'centimeters', 'position', [xlevel3, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            plot(obj.RTbinEdges, obj.CDF_RT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.RTbinEdges, obj.CDF_RT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')

            if TwoConditions
                plot(obj.RTbinEdges, obj.CDF_RT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.RTbinEdges, obj.CDF_RT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            end;

            xlabel('Reaction time (s)')
            ylabel('CDF')

            % Plot press duration distribution using violinplot
            ha8a = axes;
            xlevel4 = xlevel3 + plotsize4(1) + 1.5;
            set(ha8a,'units', 'centimeters', 'position', [xlevel4, ylevel, plotsize6], 'nextplot', 'add', ...
                'ylim', [0 2], ...
                'xlim', [0.5 4.5], 'xtick', [0:4],'xticklabel', {'Cue (Saline)', 'Cue (DCZ)', 'Uncue (Saline)', 'Uncue (DCZ)'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            ylabel('Reaction time (s)')

            if TwoConditions

                RTVec       =             [];
                RTType     =             [];
                RTVec         =           [RTVec obj.RT_Cue{1}];
                RTType       =             [RTType ones(1, length(obj.RT_Cue{1}))];
                RTVec         =           [RTVec obj.RT_Cue{2}];
                RTType       =             [RTType 2*ones(1, length(obj.RT_Cue{2}))];
                RTVec         =           [RTVec obj.RT_Uncue{1}];
                RTType       =             [RTType 3*ones(1, length(obj.RT_Uncue{1}))];
                RTVec         =           [RTVec obj.RT_Uncue{2}];
                RTType       =             [RTType 4*ones(1, length(obj.RT_Uncue{2}))];

                hVio = violinplot(RTVec,  RTType);
                for iv =1:length(hVio)
                    hVio(iv).EdgeColor = [0 0 0];
                    hVio(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio(1).ViolinColor = {SalineColor};
                % add outliers
                outliers_RT_Cue = find_outliers(obj.RT_Cue{1});
                if ~isempty(outliers_RT_Cue)
                    plot(1, outliers_RT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end

                hVio(2).ViolinColor = {DCZColor};
                outliers_RT_CueDCZ = find_outliers(obj.RT_Cue{2});
                if ~isempty(outliers_RT_CueDCZ)
                    plot(2, outliers_RT_CueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio(3).ViolinColor = {SalineColor};
                outliers_RT_Uncue = find_outliers(obj.RT_Uncue{1});
                if ~isempty(outliers_RT_Uncue)
                    plot(3, outliers_RT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio(4).ViolinColor = {DCZColor};
                outliers_RT_UncueDCZ = find_outliers(obj.RT_Uncue{2});
                if ~isempty(outliers_RT_UncueDCZ)
                    plot(4, outliers_RT_UncueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end
                line([1 2], [median(obj.RT_Cue{1}) median(obj.RT_Cue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
                line([3 4], [median(obj.RT_Uncue{1}) median(obj.RT_Uncue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
            else

                RTVec       =             [];
                RTType     =             [];
                RTVec         =           [RTVec obj.RT_Cue{1}];
                RTType       =             [RTType ones(1, length(obj.RT_Cue{1}))];
                RTVec         =           [RTVec obj.RT_Uncue{1}];
                RTType       =             [RTType 3*ones(1, length(obj.RT_Uncue{1}))];
                hVio = violinplot(RTVec,  RTType);
                for iv =1:length(hVio)
                    hVio(iv).EdgeColor = [0 0 0];
                    hVio(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio(1).ViolinColor = {SalineColor};
                % add outliers
                outliers_RT_Cue = find_outliers(obj.RT_Cue{1});
                if ~isempty(outliers_RT_Cue)
                    plot(1, outliers_RT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio(2).ViolinColor = {SalineColor};
                outliers_RT_Uncue = find_outliers(obj.RT_Uncue{1});
                if ~isempty(outliers_RT_Uncue)
                    plot(2, outliers_RT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;
                set(ha8a, 'xlim', [0.5 2.5]);
            end;

            set(ha8a, 'xticklabel', {''}, 'box','off')

            % find out the probability that lever release is within 1000 ms following the
            % end of FP
            ha5b = axes;
            set(ha5b,'units', 'centimeters', 'position', [xlevel2, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 2], ...
                'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            % add Foreperiod as a shaded area
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 5 5], FPColor)
            maxPDF = 0;
            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue{1}));
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue{2}));
            end;
            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Uncue{1}));
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Uncue{2}));
            end;
            xlabel('Hold duration (s)')
            ylabel('PDF (1/s)')
            set(gca, 'ylim', [0 maxPDF*1.1])

            % Plot CDF
            ha7b = axes;
            set(ha7b,'units', 'centimeters', 'position', [xlevel3, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 1 1], FPColor)

            plot(obj.HoldTbinEdges, obj.CDF_HoldT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.HoldTbinEdges, obj.CDF_HoldT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.CDF_HoldT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.HoldTbinEdges, obj.CDF_HoldT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            end;
            xlabel('Hold duration (s)')
            ylabel('CDF')

            % Plot press duration distribution using violinplot
            ha8 = axes;
            set(ha8,'units', 'centimeters', 'position', [xlevel4, ylevel2, plotsize6], 'nextplot', 'add', ...
                'ylim', [0 4], ...
                'xlim', [0.5 4.5], 'xtick', [0:4],'xticklabel', {'Cue (Saline)', 'Cue (DCZ)', 'Uncue (Saline)', 'Uncue (DCZ)'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            ylabel('Hold duration (s)')
            plotshaded([0 5], [0 0;  unique(obj.MixedFP)/1000 unique(obj.MixedFP)/1000], FPColor)

            if TwoConditions
                PressDurVec       =             [];
                PressType            =             [];
                PressDurVec         =           [PressDurVec obj.HoldT_Cue{1}];
                PressType             =             [PressType ones(1, length(obj.HoldT_Cue{1}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Cue{2}];
                PressType             =             [PressType 2*ones(1, length(obj.HoldT_Cue{2}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Uncue{1}];
                PressType             =             [PressType 3*ones(1, length(obj.HoldT_Uncue{1}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Uncue{2}];
                PressType             =             [PressType 4*ones(1, length(obj.HoldT_Uncue{2}))];

                hVio1 = violinplot(PressDurVec,  PressType);
                for iv =1:length(hVio1)
                    hVio1(iv).EdgeColor = [0 0 0];
                    hVio1(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio1(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio1(1).ViolinColor = {SalineColor};
                outliers_HoldT_Cue = find_outliers(obj.HoldT_Cue{1});
                if ~isempty(outliers_HoldT_Cue)
                    plot(1, outliers_HoldT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(2).ViolinColor = {DCZColor};
                outliers_HoldT_CueDCZ = find_outliers(obj.HoldT_Cue{2});
                if ~isempty(outliers_HoldT_CueDCZ)
                    plot(2, outliers_HoldT_CueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(3).ViolinColor = {SalineColor};
                outliers_HoldT_Uncue = find_outliers(obj.HoldT_Uncue{1});
                if ~isempty(outliers_HoldT_Uncue)
                    plot(3, outliers_HoldT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(4).ViolinColor = {DCZColor};
                outliers_HoldT_UncueDCZ = find_outliers(obj.HoldT_Uncue{2});
                if ~isempty(outliers_HoldT_UncueDCZ)
                    plot(4, outliers_HoldT_UncueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                line([1 2], [median(obj.HoldT_Cue{1}) median(obj.HoldT_Cue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
                line([3 4], [median(obj.HoldT_Uncue{1}) median(obj.HoldT_Uncue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
                set(ha8, 'xticklabel', {'Cue (Saline)', 'Cue (DCZ)', 'Uncue (Saline)', 'Uncue (DCZ)'}, 'box','off')
            else
                PressDurVec       =             [];
                PressType            =             [];
                PressDurVec         =           [PressDurVec obj.HoldT_Cue{1}];
                PressType             =             [PressType ones(1, length(obj.HoldT_Cue{1}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Uncue{1}];
                PressType             =             [PressType 3*ones(1, length(obj.HoldT_Uncue{1}))];
                hVio1 = violinplot(PressDurVec,  PressType);
                for iv =1:length(hVio1)
                    hVio1(iv).EdgeColor = [0 0 0];
                    hVio1(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio1(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio1(1).ViolinColor = {SalineColor};
                outliers_HoldT_Cue = find_outliers(obj.HoldT_Cue{1});
                if ~isempty(outliers_HoldT_Cue)
                    plot(1, outliers_HoldT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(2).ViolinColor = {SalineColor};
                outliers_HoldT_Uncue = find_outliers(obj.HoldT_Uncue{1});
                if ~isempty(outliers_HoldT_Uncue)
                    plot(2, outliers_HoldT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                set(ha8, 'xlim', [0.5 2.5], 'xticklabel', {'Cue','Uncue'}, 'box','off')
            end;

            % Plot performance scores
            thisTable = obj.PerformanceTable;
            ha9 = axes; % Cue trials
            ylevel3 = ylevel2 - plotsize4(2) - 1.5;
            set(ha9,'units', 'centimeters', 'position', [xlevel2, ylevel3, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 8], 'xtick', [1 3.5 6], 'xticklabel', {'Correct', 'Premature', 'Late'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            % Correct, Cue, Saline, DCZ
            bar(1,100* thisTable.Percent_Cue_Saline(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5);
            bar(2,100* thisTable.Percent_Cue_DCZ(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5);

            % Premature, Cue, Saline, DCZ
            bar(3.5,100* thisTable.Percent_Cue_Saline(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor',SalineColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5);
            bar(4.5,100* thisTable.Percent_Cue_DCZ(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5);

            % Late, Cue, Saline
            bar(6,100* thisTable.Percent_Cue_Saline(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5);
            bar(7,100* thisTable.Percent_Cue_DCZ(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor',DCZColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5);
            text(3, 100, 'Cued trials', 'fontsize', 8, 'fontname', 'dejavu sans', 'fontweight', 'bold')
            ylabel('Performance (%)')

            ha10 = axes; % Uncue trials
            set(ha10,'units', 'centimeters', 'position', [xlevel3, ylevel3, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 8], 'xtick', [1 3.5 6], 'xticklabel', {'Correct', 'Premature', 'Late'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            ylabel('Performance (%)')

             % Correct, Cue, Saline, DCZ
            bar(1,100* thisTable.Percent_Uncue_Saline(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5, 'linestyle', '-.');
            bar(2,100* thisTable.Percent_Uncue_DCZ(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5, 'linestyle', '-.');

            % Premature, Cue, Saline, DCZ
            bar(3.5,100* thisTable.Percent_Uncue_Saline(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor',SalineColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5, 'linestyle', '-.');
            bar(4.5,100* thisTable.Percent_Uncue_DCZ(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5, 'linestyle', '-.');

            % Late, Cue, Saline
            bar(6,100* thisTable.Percent_Uncue_Saline(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5, 'linestyle', '-.');
            bar(7,100* thisTable.Percent_Uncue_DCZ(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor',DCZColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5, 'linestyle', '-.');
            text(3, 100, 'Uncued trials', 'fontsize', 8, 'fontname', 'dejavu sans', 'fontweight', 'bold')
            ylabel('Performance (%)')

            ha10 = axes;
            set(ha10,'units', 'centimeters', 'position', [xlevel4, ylevel3, plotsize3], 'nextplot', 'add', ...
                'ylim', [30 100], 'xlim', [0.5 4.5], 'xtick', [1 2 3 4], 'xticklabel', {'Cue', ' ', 'Uncue', ' '},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            thisTable = obj.FastResponseRatio;
            ylabel('Fast-responding ratio')

            bar(1, 100*thisTable.Ratio(strcmp(thisTable.Type, 'Cue_Saline')),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5)
            if length(obj.FWHM_HoldT_Cue)>1
                bar(2, 100*thisTable.Ratio(strcmp(thisTable.Type, 'Cue_DCZ')),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5)
            end;

            bar(3,  100*thisTable.Ratio(strcmp(thisTable.Type, 'Uncue_Saline')),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            if length(obj.FWHM_HoldT_Uncue)>1
                bar(4, 100*thisTable.Ratio(strcmp(thisTable.Type, 'Uncue_DCZ')),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            end;

            % Plot normalized PDF (peak normalized to 1)
            ha11 = axes;
            ylevel4 = ylevel3 - plotsize4(2) - 1.5;
            set(ha11,'units', 'centimeters', 'position', [xlevel2, ylevel4, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1.1], 'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            % add Foreperiod as a shaded area
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 1.1 1.1], FPColor)

            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{1}/max(obj.PDF_HoldT_Cue{1}), 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{1}/max(obj.PDF_HoldT_Uncue{1}), 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{2}/max(obj.PDF_HoldT_Cue{2}), 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{2}/max(obj.PDF_HoldT_Uncue{2}), 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            end;

            xlabel('Hold duration (s)')
            ylabel('PDF (normalized)')

            % Plot Gauss normalized PDF (peak normalized to 1)
            ha12 = axes; 
            set(ha12,'units', 'centimeters', 'position', [xlevel3, ylevel4, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1.1], 'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            % add Foreperiod as a shaded area
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 10 10], FPColor)

            maxPDF = 0;

            tfit = [obj.HoldTbinEdges(1):0.01:obj.HoldTbinEdges(end)];

            plot(tfit, obj.PDF_HoldT_Cue_Gauss{1}(tfit), 'color', SalineColor, 'linewidth', 1.25)
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue_Gauss{1}(tfit)));
            plot(tfit, obj.PDF_HoldT_Uncue_Gauss{1}(tfit), 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Uncue_Gauss{1}(tfit)));

            if TwoConditions
                plot(tfit, obj.PDF_HoldT_Cue_Gauss{2}(tfit), 'color', DCZColor, 'linewidth', 1.25)
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue_Gauss{2}(tfit)));
                plot(tfit, obj.PDF_HoldT_Uncue_Gauss{2}(tfit), 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue_Gauss{2}(tfit)));
            end;

            set(gca, 'ylim', [0 maxPDF])
            xlabel('Hold duration (s)')
            ylabel('PDF (2-term Gauss fit)')

            ha13 = axes;
            set(ha13,'units', 'centimeters', 'position', [xlevel4, ylevel4, plotsize3], 'nextplot', 'add', ...
                'ylim', [0 1000], 'xlim', [0.5 4.5], 'xtick', [1 2 3 4], 'xticklabel', {'Cue', ' ', 'Uncue', ' '},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            bar(1, 1000*obj.FWHM_HoldT_Cue(1),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5)
            if length(obj.FWHM_HoldT_Cue)>1
                bar(2, 1000*obj.FWHM_HoldT_Cue(2),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5)
            end;

            bar(3, 1000*obj.FWHM_HoldT_Uncue(1),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            if length(obj.FWHM_HoldT_Uncue)>1
                bar(4, 1000*obj.FWHM_HoldT_Uncue(2),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            end;

            axis 'auto y'
            ylabel('FWHM (ms)')
           

            % Write information
            ha6 = axes;
            xlevel5 = xlevel4 + plotsize3(1)+0.5;

            set(ha6,'units', 'centimeters', 'position', [xlevel5, ylevel4, plotsize3], 'nextplot', 'add', ...
                'ylim', [2 10], ...
                'xlim', [0 10], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            line([0  5], [9 9],  'color', SalineColor, 'linewidth', 1.25)
            text(6, 9, 'Cue-Saline', 'fontsize', 8, 'fontname', 'dejavu sans')
            line([0 5], [7 7],  'color', DCZColor, 'linewidth', 1.25)
            text(6, 7, 'Cue-DCZ', 'fontsize', 8, 'fontname', 'dejavu sans')
            line([0 5], [5 5],  'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            text(6, 5, 'Uncue-Saline', 'fontsize', 8, 'fontname', 'dejavu sans')
            line([0 5], [3 3],  'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            text(6, 3, 'Uncue-DCZ', 'fontsize', 8, 'fontname', 'dejavu sans')

            axis off

            hui_1 = uicontrol('Style', 'text', 'parent', 20, 'units', 'normalized', 'position', [0.1 0.965 0.2 0.03],...
                'string',  ['Subject: ' obj.Subject{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans' );

            hui_2 = uicontrol('Style', 'text', 'parent', 20, 'units', 'normalized', 'position', [0.2 0.965 0.4 0.03],...
                'string', ['Protocol: ' obj.Protocols{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans');

        end

        function Save(obj, savepath)
            if nargin<2
                savepath = pwd;
            end
            save(fullfile(savepath, ['KornblumGroupClass_' (obj.Subject{1})]),  'obj');
        end

        function Print(obj, targetDir)
            if ishghandle(obj.Fig1)
                savename = ['Fig1_Performance_' upper(obj.Subject{1})];
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
                hf = obj.Fig1;
                print (hf,'-dpng', [savename])
                saveas(hf, savename, 'fig')
            end;

            if ishghandle(obj.Fig2)
                savename = ['Fig2_PerformanceSessions_' upper(obj.Subject{1})];
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
                hf = obj.Fig2;
                print (hf,'-dpng', [savename])
                saveas(hf, savename, 'fig')
            end;

            if ishghandle(obj.Fig3)
                savename = ['Fig3_ChemoPerformance_' upper(obj.Subject{1})];
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
                hf = obj.Fig3;
                print (hf,'-dpng', [savename])
                saveas(hf, savename, 'fig')
            end;

        end;

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end