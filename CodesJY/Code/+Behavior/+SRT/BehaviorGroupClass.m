classdef BehaviorGroupClass
    % 12/25/2022, Jianing Yu
    % This takes SRT group class from each session, group them together,
    % mark each session with proper statement, and plot the data 
    % Note that our data must be able to deal with both lesion or chemogenetics
    % data

    properties
        Subject
        Strain
        Dates
        Sessions
        SessionIndex
        Experimenter
        Protocols
        NumSessions
        NumTrialsPerSession
        TreatmentSessions  % if this is empty, then it is not a chemogenetics experiment. 
        TreatmentTrials
        DoseSessions  
        DoseTrials
        LesionSessions % if this is empty, then it is not a lesion experiment. If multiple lesions were performed, only take the first one
        LesionSessionsAll % including all lesion sessions, not just the first one
        LesionTrials 
        LesionTrialsAll % all lesion index included. 
%         Cue % is always 1 for SRRT (just cut it out then)
        PressIndex
        PressTime
        ReleaseTime
        HoldTime
        FP             % FP of each trial
        MixedFP    % FP design of a session, eg.., mixed FP: 500, 1000, 1500
        ToneTime
        ReactionTime
        OutcomeSessions
        Outcome
        Stage
        RTbinEdges
        HoldTbinEdges
        RTbinCenters
        HoldTbinCenters
        PerformanceSlidingWindow
        PerformanceSessions
        Control
        IQR_Sessions
        RTbinEdges_Sessions
        HoldTbinEdges_Sessions
        PDF_RT_Sessions
        CDF_RT_Sessions
        PDF_RTLoose_Sessions
        CDF_RTLoose_Sessions
        PDF_HoldT_Sessions
        CDF_HoldT_Sessions
        RT_Sessions
        RTLoose_Sessions
        PreLesionSessions  % how many sessions to take for computting stuff for pre-lesion responses; take everything pre-lesion as default;
        PostLesionSessions % how many sessions to take for computing stuff for post-lesion responses; take everything post-lesion as default 
        PreLesionTrialNum         % number of trials that we will use to compute pre-lesion response properties. 
        PostLesionTrialNum       % number of trials that we will use to compute post-lesion response properties. 
        SessionControl              % for claiming what sessions should be considered 'Control'
        SessionChemo                % for claiming what sessions should be considered 'Chemo'
        Fig1
        Fig2
        Fig3
        Fig4
        Fig5
        Fig6
        SecondLesion  % this is the index when a second lesion is performed. Very important. 
        ProgressTrials
    end;

    properties (Access = private)
        pHoldT_GaussFit_Lesion % for comparing lesion pre- and post effect. We perform the fitting procedure by calling a method      
        pRTLesionResultTable
        pRTChemoResultTable
    end

    properties (Constant)

        PerformanceType = {'Correct', 'Premature', 'Late'}
        Note1 = {'The property "Control" only means something for chemogenetic experiments'}
        Note2 = {'For lesion experiments, "LesionSessions" and "LesionTrials" are not empty'}
        BinSize        = 0.02;
        %         RTCeiling = 5; % RTs over 5 sec will be removed
        ResponseWindow = [0.6 1]; % for cue and uncue trials.
        GaussEqn = 'a1*exp(-((x-b1)/c1)^2)+a2*exp(-((x-b2)/c2)^2)';
        StartPoints = [1 1 1 2 2 1];
        LowerBound = [0 0 0 0 0 0];
        UpperBound = [10 10 10 10 10 10];
        FPLineStyles = {'-', ':', '-.'};


    end
    properties (Dependent)

        Lesion              % 0 not lesion, 1 lesion
        Chemo        
        RT_Chemo
        RT_PreLesion_Sessions   % reaction time before lesion, take a variable as number of sessions, or number of trials. use PreLesionSessions to determine which sesssions to take;  2 rows, first row contains correct responses, second row contains both correct and late responses
        RT_PostLesion_Sessions % reaction time before lesion, take a variable as number of sessions, or number of trials. use PostLesionSessions to determine which sessions to take.  take all pre sessions
        HoldT_PreLesion_Sessions   % reaction time before lesion, take a variable as number of sessions, or number of trials. use PreLesionSessions to determine which sesssions to take;  2 rows, first row contains correct responses, second row contains both correct and late responses
        HoldT_PostLesion_Sessions % reaction time before lesion, take a variable as number of sessions, or number of trials. use PostLesionSessions to determine which sessions to take.  take all pre sessions
        IndexPreLesionTrials  % index of pre lesion trials (e.g., the last N trials before operation)
        IndexPostLesionTrials  % index of post lesion trials (e.g., the last N trials after operation)
        RT_PreLesion_Trials   % reaction time before lesion, take a variable as number of sessions, or number of trials. use PreLesionSessions to determine which sesssions to take;  2 rows, first row contains correct responses, second row contains both correct and late responses
        RT_PostLesion_Trials % reaction time before lesion, take a variable as number of sessions, or number of trials. use PostLesionSessions to determine which sessions to take.  take all pre sessions
        HoldT_PreLesion_Trials
        HoldT_PostLesion_Trials

        PDF_RT_Lesion % this will produce a table including results from  RT_PreLesion_Sessions/RT_PostLesion_Sessions/RT_PreLesion_Trials/RT_PostLesion_Trials
        CDF_RT_Lesion % this will produce a table including results from  RT_PreLesion_Sessions/RT_PostLesion_Sessions/RT_PreLesion_Trials/RT_PostLesion_Trials
        PDF_HoldT_Lesion
        CDF_HoldT_Lesion
        FWHM_HoldT % Full width at half maximum, derived from Gauss model
        % For comparing control(saline) vs chemo sessions
        
        HoldT_Control
        HoldT_Chemo
        IQR_HoldT_Control
        IQR_HoldT_Chemo

        PDF_HoldT_Control
        PDF_HoldT_Chemo
        PDF_RT_Control
        PDF_RT_Chemo
        CDF_HoldT_Control
        CDF_HoldT_Chemo

        OutcomeControl
        OutcomeChemo

        PerformanceTable_Lesion % void
        FastResponseRatio
        IQR
        NewAnalysis
        HoldT_GaussFit_Lesion
        FWHM_HoldT_Lesion
        FWHM_HoldT_Chemo

        IndexSessionsControl   % Index of control sessions
        IndexSessionsChemo    % Index of chemo sessions

        RTLesionResultTable
        PerformanceLesionResultTable

        RTChemoResultTable
        PerformanceChemoResultTable

        PDF_HoldT_Progress % early and late, for tracking progress

    end


    methods
        function obj = BehaviorGroupClass(SRTClassAll)
            % SRTClassAll is a collection of BehaviorClass (in cell format)

            % sessions for a rat
            obj.Subject                                        =               unique(cellfun(@(x)x.Subject, SRTClassAll, 'UniformOutput', false)');
            obj.Strain                                           =               SRTClassAll{1}.Strain;
            obj.Dates                                           =               cellfun(@(x)x.Date, SRTClassAll, 'UniformOutput', false); % dates when these experiments were performed
            obj.Sessions                                      =               cellfun(@(x)x.Session, SRTClassAll, 'UniformOutput', false)'; % similar to dates
            obj.Experimenter                               =                cellfun(@(x)x.Experimenter, SRTClassAll, 'UniformOutput', false)';
            obj.Protocols                                      =               cellfun(@(x)x.Protocol, SRTClassAll, 'UniformOutput', false)';
            obj.NumSessions                               =               length(SRTClassAll);
            obj.NumTrialsPerSession                  =                cellfun(@(x)x.TrialNum, SRTClassAll);
            obj.PressIndex                                   =                cell2mat(cellfun(@(x)x.PressIndex, SRTClassAll, 'UniformOutput',false));
            obj.PressTime                                    =                cell2mat(cellfun(@(x)x.PressTime, SRTClassAll, 'UniformOutput',false));
            obj.ReleaseTime                                =                cell2mat(cellfun(@(x)x.ReleaseTime, SRTClassAll, 'UniformOutput',false));
            obj.HoldTime                                      =                obj.ReleaseTime - obj.PressTime;
            obj.FP                                                 =                cell2mat(cellfun(@(x)x.FP, SRTClassAll, 'UniformOutput',false));
            obj.MixedFP                                       =                [500 1000 1500];
            obj.ToneTime                                      =                cell2mat(cellfun(@(x)x.ToneTime, SRTClassAll, 'UniformOutput',false));
            obj.ReactionTime                                =                cell2mat(cellfun(@(x)x.ReactionTime, SRTClassAll, 'UniformOutput',false));
            obj.OutcomeSessions                         =                cellfun(@(x)x.Outcome', SRTClassAll, 'UniformOutput', false);
            obj.Stage                                             =                cell2mat(cellfun(@(x)x.Stage, SRTClassAll, 'UniformOutput',false));
            rng(0)
            FigNums                                             =                   randperm(1000, 6);

            obj.Fig1                                               =                  FigNums(1);
            obj.Fig2                                               =                  FigNums(2);
            obj.Fig3                                               =                  FigNums(3);
            obj.Fig4                                               =                  FigNums(4);
            obj.Fig5                                               =                  FigNums(5);
            obj.Fig6                                              =                  FigNums(6);

            obj.ProgressTrials                               =                  200;

            obj.RTbinEdges_Sessions                 =             SRTClassAll{1}.RTbinEdges;
            obj.HoldTbinEdges_Sessions           =             SRTClassAll{1}.HoldTbinEdges;
            obj.PDF_RT_Sessions                        =             cell(obj.NumSessions, length(obj.MixedFP));
            obj.CDF_RT_Sessions                        =              cell(obj.NumSessions, length(obj.MixedFP));
            obj.PDF_RTLoose_Sessions              =              cell(obj.NumSessions, length(obj.MixedFP));
            obj.CDF_RTLoose_Sessions              =              cell(obj.NumSessions, length(obj.MixedFP));
            obj.PDF_HoldT_Sessions                  =               cell(obj.NumSessions, length(obj.MixedFP));
            obj.CDF_HoldT_Sessions                  =               cell(obj.NumSessions, length(obj.MixedFP));

            obj.SessionControl                             =                []; 
            obj.SessionChemo                              =                [];

            for i =1:obj.NumSessions
                
                obj.IQR_Sessions(i, :)                   =           SRTClassAll{i}.IQR;
                obj.RT_Sessions{i}                        =           SRTClassAll{i}.AvgRT;
                obj.RTLoose_Sessions{i}              =           SRTClassAll{i}.AvgRTLoose;

                obj.SessionIndex                            =           [obj.SessionIndex  i*ones(1, SRTClassAll{i}.TrialNum)];

                obj.PDF_RT_Sessions(i, :)           = SRTClassAll{i}.PDF_RT;
                obj.PDF_RTLoose_Sessions(i, :)    = SRTClassAll{i}.PDF_RTLoose;
                obj.CDF_RT_Sessions(i, :)            = SRTClassAll{i}.CDF_RT;
                obj.CDF_RTLoose_Sessions(i, :)     = SRTClassAll{i}.PDF_RTLoose;
                obj.PDF_HoldT_Sessions(i, :)      = SRTClassAll{i}.PDF_HoldT;
                obj.CDF_HoldT_Sessions(i, :)       = SRTClassAll{i}.CDF_HoldT;

                if isempty(SRTClassAll{i}.Treatment)
                    obj.TreatmentSessions               =               [];
                    obj.TreatmentTrials                     =              [];
                    obj.DoseSessions                          =             [];
                    obj.DoseTrials                                =             [];
                else
                    obj.TreatmentSessions                  =             [obj.TreatmentSessions {SRTClassAll{i}.Treatment}];
                    obj.TreatmentTrials                        =             [obj.TreatmentTrials; repmat({SRTClassAll{i}.Treatment}, SRTClassAll{i}.TrialNum, 1)];
                    obj.DoseSessions                          =             [obj.DoseSessions SRTClassAll{i}.Dose];
                    obj.DoseTrials                                =             [obj.DoseTrials; repmat(SRTClassAll{i}.Dose, SRTClassAll{i}.TrialNum, 1)];
                end;

                if isempty(SRTClassAll{i}.LesionIndex)
                    obj.LesionSessions          =       [];
                    obj.LesionTrials                =       [];

                else  % LesionIndexAll
                    obj.LesionSessions          =       [obj.LesionSessions SRTClassAll{i}.LesionIndex];
                    obj.LesionSessionsAll      =       [ obj.LesionSessionsAll ; SRTClassAll{i}.LesionIndexAll];
                    obj.LesionTrials                =       [obj.LesionTrials SRTClassAll{i}.LesionIndex*ones(1, SRTClassAll{i}.TrialNum)];
                     obj.LesionTrialsAll           =       [obj.LesionTrialsAll; repmat(SRTClassAll{i}.LesionIndexAll, SRTClassAll{i}.TrialNum, 1)];
                end

                obj.Outcome                                  =             [obj.Outcome; obj.OutcomeSessions{i}];
                obj.PerformanceSessions{i}          =             SRTClassAll{i}.Performance;
                iSlidingWindowTable                     =             SRTClassAll{i}.PerformanceSlidingWindow;
                iSlidingWindowTable.('Session')   =           repmat(i, size(iSlidingWindowTable, 1), 1);
                obj.PerformanceSlidingWindow   =          [obj.PerformanceSlidingWindow; iSlidingWindowTable];
                obj.Control                                    =              {'Saline', 'NaN'};
            end;

            if isempty(obj.LesionSessions)
                obj.PreLesionSessions    =        [];
                obj.PostLesionSessions    =       [];
            else
                obj.PreLesionSessions    =        obj.LesionSessions(obj.LesionSessions<0 & obj.LesionSessions>=-5);
                obj.PostLesionSessions    =      obj.LesionSessions(obj.LesionSessions>0 & obj.LesionSessions<=5);
            end

            obj.RTbinEdges                               =           [0:obj.BinSize:2];
            obj.HoldTbinEdges                         =          [0:obj.BinSize:4];
            obj.RTbinCenters                            =          obj.RTbinEdges(1:end-1)+0.5*obj.BinSize;
            obj.HoldTbinCenters                      =          obj.HoldTbinEdges(1:end-1)+0.5*obj.BinSize;
            obj.PreLesionTrialNum = 500;         %  compute response over 500 trials prelesion
            obj.PostLesionTrialNum =500;       % compute response over 500 trials postlesion
        end

        function value = get.Lesion(obj)
            if isempty(obj.LesionSessions)
                value    =        0;
            else
                value    =        1;
            end
        end;

        function value = get.Chemo(obj)
            if    sum(strcmp(obj.TreatmentSessions, 'DCZ'))>1
                value    =       1;
            else
                value    =        01;
            end
        end;

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

        function value = get.HoldT_Control(obj)
            HoldT                               =        cell(1, length(obj.MixedFP));
            for k = 1:length(obj.MixedFP)
                IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')') & obj.FP == obj.MixedFP(k);
                HoldT{k}                           =       obj.HoldTime(IndexControlTrials);
            end;
            value = HoldT;
        end;

        function value = get.IQR_HoldT_Control(obj)
            if ~isempty(obj.HoldT_Control)
                value = cellfun(@(x)diff(prctile(x, [25 75])), obj.HoldT_Control);
            else
                value = [];
            end;
        end;

        function value = get.IQR_HoldT_Chemo(obj)
            if ~isempty(obj.HoldT_Control)
                value = cellfun(@(x)diff(prctile(x, [25 75])), obj.HoldT_Chemo);
            else
                value = [];
            end;
        end;

        function value = get.HoldT_Chemo(obj)
            HoldT                               =        cell(1, length(obj.MixedFP));
            for k = 1:length(obj.MixedFP)
                IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')') & obj.FP == obj.MixedFP(k);
                HoldT{k}                           =       obj.HoldTime(IndexControlTrials);
            end;
            value = HoldT;
        end;

        function value=get.PDF_HoldT_Control(obj)
            PDF = zeros(length(obj.HoldTbinEdges), length(obj.MixedFP));
            for k = 1:length(obj.MixedFP)
                PDF(:, k) = ksdensity( obj.HoldT_Control{k}, obj.HoldTbinEdges,'function', 'pdf');
            end;
            value = PDF;
        end;

        function value=get.PDF_HoldT_Chemo(obj)
            PDF = zeros(length(obj.HoldTbinEdges), length(obj.MixedFP));
            for k = 1:length(obj.MixedFP)
                PDF(:, k) = ksdensity(obj.HoldT_Chemo{k}, obj.HoldTbinEdges, 'function', 'pdf');
            end;
            value = PDF;
        end;

        function value=get.CDF_HoldT_Control(obj)
            CDF = zeros(length(obj.HoldTbinEdges), length(obj.MixedFP));
            for k = 1:length(obj.MixedFP)
                CDF(:, k) = ksdensity( obj.HoldT_Control{k}, obj.HoldTbinEdges,'function', 'cdf');
            end;
            value = CDF;
        end;

        function value=get.CDF_HoldT_Chemo(obj)
            CDF = zeros(length(obj.HoldTbinEdges), length(obj.MixedFP));
            for k = 1:length(obj.MixedFP)
                CDF(:, k) = ksdensity(obj.HoldT_Chemo{k}, obj.HoldTbinEdges, 'function', 'cdf');
            end;
            value = CDF;
        end;

        function value = get.RTLesionResultTable(obj)
            value = obj.pRTLesionResultTable;
        end;

        function value = get.RTChemoResultTable(obj)
            value = obj.pRTChemoResultTable;
        end;

        function obj = PlotChemoEffect(obj, ind)
            % Compare effect of chemo inactivation on the performance
            set_matlab_default;
            % This is to plot pre and post lesion hold time PDF, which gives
            % a quick show on the effect
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPs = obj.MixedFP;
            tBins = obj.HoldTbinEdges;
            colors = {[0 0 0.6], [255, 201, 60]/255};
            FPColors = [45, 205, 223]/255;
            WhiskerColor = [255, 0, 50]/255;

            SessionsCol = [3, 0, 28]/255;
            TrialsCol = [91, 143, 185]/255;

            figure(obj.Fig5); clf(obj.Fig5)
            set(obj.Fig5, 'unit', 'centimeters', 'position',[2 2 32 15], 'paperpositionmode', 'auto', 'color', 'w')

            StrictSymbol = 'o';
            LooseSymbol = 's';
            CIColor = [0 0 0];

            ylevel = 1.25;
            xlevel = 1.5;

            ha_RT1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', [0.1 0.8], ...
                'xtick',[0.2:0.2:0.8], 'ylim', [0.1 0.8],'ytick', [0:0.2:1], 'ticklength', [0.02 0.1]);
            line([0 1], [0 1], 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            title('Reaction time')
            xlabel('Control (sec)')
            ylabel('Chemo (sec)')

            for i =1:length(obj.MixedFP)
                line(obj.RTChemoResultTable.ControlSessions_RTMedianCI95_Strict{i}, obj.RTChemoResultTable.ChemoSessions_RTMedian_Strict(i)*[1 1], 'linewidth', 1.0, 'color',CIColor);
                line(obj.RTChemoResultTable.ControlSessions_RTMedian_Strict(i)*[1 1], obj.RTChemoResultTable.ChemoSessions_RTMedianCI95_Strict{i}, 'linewidth', 1.0, 'color', CIColor);
                line(obj.RTChemoResultTable.ControlSessions_RTMedianCI95_Loose{i}, obj.RTChemoResultTable.ChemoSessions_RTMedian_Loose(i)*[1 1], 'linewidth', 1.0, 'color', CIColor);
                line(obj.RTChemoResultTable.ControlSessions_RTMedian_Loose(i)*[1 1], obj.RTChemoResultTable.ChemoSessions_RTMedianCI95_Loose{i}, 'linewidth', 1.0, 'color', CIColor);
            end;

            MarkerAlpha = 0.5;

            for i =1:length(obj.MixedFP)
                MarkerSize = 35+35*(i-1);
                scatter(obj.RTChemoResultTable.ControlSessions_RTMedian_Strict(i), ...
                    obj.RTChemoResultTable.ChemoSessions_RTMedian_Strict(i), ...
                    'Marker', StrictSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
                scatter(obj.RTChemoResultTable.ControlSessions_RTMedian_Loose(i), ...
                    obj.RTChemoResultTable.ChemoSessions_RTMedian_Loose(i), ...
                    'Marker', LooseSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            end;

            scatter(0.7, 0.3, 'Marker', StrictSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.75, 0.3, 'Strict', 'fontName', 'dejavu sans', 'fontsize', 8)
            scatter(0.7, 0.25, 'Marker', LooseSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.75, 0.25, 'Loose', 'fontName', 'dejavu sans', 'fontsize' , 8)
            title('RT: Control vs Chemo','fontsize', 8, 'FontWeight','bold','FontName','dejavu sans')

            xlevel = xlevel +6.5;
            maxIQR = max([obj.IQR_HoldT_Control obj.IQR_HoldT_Chemo])*1.25;

            ha_IQR = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', [0 maxIQR], ...
                'xtick',[0:0.1:5], 'ylim', [0 maxIQR],'ytick', [0:0.1:5], 'ticklength', [0.02 0.1]);
            line([0 maxIQR], [0 maxIQR], 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            xlabel('Control (sec)')
            ylabel('Chemo (sec)')
            title('Hold duration IQR')

            SessionsSymbol = 'd';
            TrialsSymbol = 'o';
            MarkerAlpha = 0.6;

            for i =1:length(obj.MixedFP)
                MarkerSize = 35+35*(i-1);
                scatter(obj.IQR_HoldT_Control(i), obj.IQR_HoldT_Chemo(i), ...
                    'Marker', SessionsSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            end;

            ylevel2 = ylevel+7.5;
            xlevel = 8.5 + 6.5;

            % CDF 
            ha1c = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel2 5 5], 'xlim', [0 3], 'xtick', [0:0.5:3], 'ylim', [0 1], 'ticklength', [0.02 0.1]);
            xlabel('Hold duration (s)')
            ylabel('CDF')

            for i =1:length(obj.MixedFP)           
                plot(ha1c, obj.HoldTbinEdges,obj.CDF_HoldT_Control(:, i), 'color', colors{1}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
                plot(ha1c, obj.HoldTbinEdges,obj.CDF_HoldT_Chemo(:, i), 'color', colors{2}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
            end;

            for k =1:length(FPs)    % first, draw FPs
                line(ha1c, [FPs(k) FPs(k)]/1000,  [0 1],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;

            %             % add legend
            %             line(ha1s, [2.5 2.8]-0.5, [maxPDF maxPDF], 'color', colors{1}, 'linewidth', 2)
            %             text(ha1s, 2.85-0.5, maxPDF, 'Control', 'fontname', 'dejavu sans','fontsize',  7);
            %             line(ha1s, [2.5 2.8]-0.5, [maxPDF*0.9 maxPDF*0.9], 'color', colors{2}, 'linewidth', 2)
            %             text(ha1s, 2.85-0.5, maxPDF*0.9, 'Chemo', 'fontname', 'dejavu sans','fontsize',  7);

            xlevel = 8.5;

            % PDF
            ha1s = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel2 5 5], 'xlim', [0 3], 'xtick', [0:0.5:3], 'ylim', [0 5], 'ticklength', [0.02 0.1]);
            xlabel('Hold duration (s)')
            ylabel('PDF (1/s)')

            maxPDF = max([max(obj.PDF_HoldT_Control(:)) max(obj.PDF_HoldT_Chemo(:))])*1.25;

            for i =1:length(obj.MixedFP)           
                plot(ha1s, obj.HoldTbinEdges,obj.PDF_HoldT_Control(:, i), 'color', colors{1}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
                plot(ha1s, obj.HoldTbinEdges,obj.PDF_HoldT_Chemo(:, i), 'color', colors{2}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
            end;
            set(ha1s, 'ylim', [0, maxPDF])
 
            for k =1:length(FPs)    % first, draw FPs
                line(ha1s, [FPs(k) FPs(k)]/1000,  [0 maxPDF],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;
    
            % add legend
            line(ha1s, [2.5 2.8]-0.5, [maxPDF maxPDF], 'color', colors{1}, 'linewidth', 2)
            text(ha1s, 2.85-0.5, maxPDF, 'Control', 'fontname', 'dejavu sans','fontsize',  7);
            line(ha1s, [2.5 2.8]-0.5, [maxPDF*0.9 maxPDF*0.9], 'color', colors{2}, 'linewidth', 2)
            text(ha1s, 2.85-0.5, maxPDF*0.9, 'Chemo', 'fontname', 'dejavu sans','fontsize',  7);
            % Plot data in a violin plot to show all data points





            % Plot data in a violin plot to show all data points

            HoldTimeMax = 3;
            xlevel = 1.5;

            % Violin plot of hold duration distribution 

            ha2s = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel2 5 5], 'xlim', [0 length(FPs)*2+1], 'xtick', [0:1:6], 'ylim', [0 HoldTimeMax], 'ticklength', [0.02 0.1], ...
                'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);
 
            % Violinplot based on sessions
            HoldTimeAll = [];
            HoldTimeFPType = [];
            acc = 0;

            for k =1:length(FPs)
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

                hVio1(iv).ScatterPlot.MarkerFaceAlpha = 0.35;
                hVio1(iv).ViolinPlot.LineWidth  = 0.5;
                hVio1(iv).ScatterPlot.SizeData = 6;
                hVio1(iv).BoxPlot.LineWidth = 1;
                hVio1(iv).BoxColor = [0.8 0 0.2];
                hVio1(iv).ViolinPlot.FaceColor = [0.8 0.8 0.8];
            end;

            for k =1:length(obj.MixedFP)
                line([-0.4 1.4]+1+2*(k-1), [FPs(k) FPs(k)]/1000,  'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;
            set(gca, 'xticklabel', num2cell(obj.MixedFP), 'box', 'off', 'xlim', [0.5 2*length(obj.MixedFP)+.5])
            xlabel('FP (ms)')
            ylabel('Hold time (s)')

            % Plot performance
            xlevel = xlevel +13;
            plotsize_perf = [5 5];
            ha_Performance= axes;

            set(ha_Performance,  'units', 'centimeters', 'position', [xlevel, ylevel, plotsize_perf], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [-5 100], 'yscale', 'linear', ...
                'xtick',[0:20:100], 'TickLength', [0.01 0.1]);
            xlabel('Control')
            ylabel('Chemo')
            title('Performance')
            line([-5 100], [-5 100], 'color', [0.5 0.5 0.5], 'linestyle', '-.');

            for k =1:length(obj.MixedFP)
                symbolSize = 20+20*(k-1);
                ha_scatter_correct= scatter(100*obj.PerformanceChemoResultTable.Control_CorrectRatio(k), ...
                    100*obj.PerformanceChemoResultTable.Chemo_CorrectRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(1, :), 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                ha_scatter_premature = scatter(100*obj.PerformanceChemoResultTable.Control_PrematureRatio(k), ...
                    100*obj.PerformanceChemoResultTable.Chemo_PrematureRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(2, :), 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                ha_scatter_late = scatter(100*obj.PerformanceChemoResultTable.Control_LateRatio(k), ...
                    100*obj.PerformanceChemoResultTable.Chemo_LateRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(3, :), 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
            end;

            symbolSize = 50;
            ha_scatter_correct = scatter(100*obj.PerformanceChemoResultTable.Control_CorrectRatio(k+1), ...
                100*obj.PerformanceChemoResultTable.Chemo_CorrectRatio(k+1), ...
                'Marker', '^', 'MarkerEdgeColor',  'k', 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
            ha_scatter_premature = scatter(100*obj.PerformanceChemoResultTable.Control_PrematureRatio(k+1), ...
                100*obj.PerformanceChemoResultTable.Chemo_PrematureRatio(k+1), ...
                'Marker', '^', 'MarkerEdgeColor',  'k', 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
            ha_scatter_late = scatter(100*obj.PerformanceChemoResultTable.Control_LateRatio(k+1), ...
                100*obj.PerformanceChemoResultTable.Chemo_LateRatio(k+1), ...
                'Marker', '^', 'MarkerEdgeColor', 'k', 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

            uicontrol('Style', 'text', 'parent', obj.Fig5, 'units', 'normalized', 'position', [0.15 0.95 0.5 0.04],...
                'string', [obj.Subject{1} ' | Control vs DCZ'], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 8, 'horizontalalignment', 'left');

            % Control and DCZ trials should appear as pairs
            xlevel = xlevel+7;
            ylevel = 1.5;
            PlotSize1 = [9 5];
            PlotSize2 = [9 3];
            TimeStep = 0;

            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;

            SessionsCol = [3, 0, 28]/255;
            TrialsCol = [91, 143, 185]/255;

            maxHoldTime = obj.MixedFP(end)+1500;

            ha_Session = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel PlotSize1], 'xlim', [0 3600], ...
                'xtick',[0:600:3600], 'ylim', [0 100],'ytick', [0:20:100], 'ticklength', [0.02 0.1]);

            xlabel('Time (sec)')
            ylabel('Performance')

            ylevel = ylevel +9.5; % control sessions
            ha_Trial1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel PlotSize2], 'xlim', [0 3600], ...
                'xtick',[], 'ylim', [0 maxHoldTime],'ytick', [0:500:maxHoldTime], 'ticklength', [0.02 0.1]);

            htl1 = title(['Control ' sprintf('%s|', obj.Dates{find(obj.IndexSessionsControl)})], ...
                'fontname', 'dejavu sans', 'fontsize', 6, 'fontangle', 'italic','color', colors{1})
            htl1.Position(2)=htl1.Position(2)+250;

            ylevel = ylevel - 4; % DCZ sessions
            ha_Trial2 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel PlotSize2], 'xlim', [0 3600], ...
                'xtick',[], 'xticklabel', [], 'ylim', [0 maxHoldTime],'ytick', [0:500:maxHoldTime], 'ticklength', [0.02 0.1]);

            htl2=title(['Chemo ' sprintf('%s|', obj.Dates{find(obj.IndexSessionsChemo)})], ...
                'fontname', 'dejavu sans', 'fontsize', 6, 'fontangle', 'italic', 'color', colors{2})
            htl2.Position(2)=htl2.Position(2)+250;

             if nargin<2
                 ind = 1;
             end;

             %  Plot control sessions first
             IndControlSession = find(obj.IndexSessionsControl == 1);
             IndChemoSession = find(obj.IndexSessionsChemo == 1);

             for k =1:length(IndControlSession)

                 IndControlSession_k = IndControlSession(k);
                 IndChemoSession_k = IndChemoSession(k);

                 IndControlTrials = find(obj.SessionIndex == IndControlSession_k);
                 IndChemoTrials = find(obj.SessionIndex == IndChemoSession_k);

                 ControlTimeSliding                   = obj.PerformanceSlidingWindow.TimeInSession(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlCorrectSliding               = obj.PerformanceSlidingWindow.Correct(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlPrematureSliding         = obj.PerformanceSlidingWindow.Premature(obj.PerformanceSlidingWindow.Session == IndControlSession_k);
                 ControlLateSliding                     = obj.PerformanceSlidingWindow.Late(obj.PerformanceSlidingWindow.Session == IndControlSession_k);


                 ChemoTimeSliding                   = obj.PerformanceSlidingWindow.TimeInSession(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoCorrectSliding               = obj.PerformanceSlidingWindow.Correct(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoPrematureSliding         = obj.PerformanceSlidingWindow.Premature(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);
                 ChemoLateSliding                     = obj.PerformanceSlidingWindow.Late(obj.PerformanceSlidingWindow.Session == IndChemoSession_k);

                 hp1 = plot(ha_Session, ControlTimeSliding+TimeStep, ControlCorrectSliding, 'color', col_perf(1, :), 'linewidth', 2);
                 plot(ha_Session, ControlTimeSliding+TimeStep, ControlPrematureSliding, 'color', col_perf(2, :), 'linewidth', 2)
                 plot(ha_Session, ControlTimeSliding+TimeStep, ControlLateSliding, 'color', col_perf(3, :), 'linewidth', 2)

                 hp2 = plot(ha_Session, ChemoTimeSliding+TimeStep, ChemoCorrectSliding, 'color', col_perf(1, :), 'linewidth', 2, 'linestyle', ':');
                 plot(ha_Session, ChemoTimeSliding+TimeStep, ChemoPrematureSliding, 'color', col_perf(2, :), 'linewidth', 2, 'linestyle', ':')
                 plot(ha_Session, ChemoTimeSliding+TimeStep, ChemoLateSliding, 'color', col_perf(3, :), 'linewidth', 2, 'linestyle', ':')

                 line(ha_Session, [TimeStep TimeStep], [0 100],'color', 'k', 'linestyle', '--')
               
                
                 axes(ha_Trial1)
                 for i =1:length(obj.MixedFP)

                     iIndControlTrials = IndControlTrials(obj.FP(IndControlTrials) == obj.MixedFP(i));
                     symbolSize = 5+15*(i-1);
                     % plot correct
                     IndCorrectControl= iIndControlTrials(strcmp(obj.Outcome(iIndControlTrials), 'Correct'));
                     ha_scatter_correct = scatter(obj.PressTime(IndCorrectControl)+TimeStep, obj.HoldTime(IndCorrectControl)*1000, ...
                         'Marker', 'o', 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                     IndPrematureControl= iIndControlTrials(strcmp(obj.Outcome(iIndControlTrials), 'Premature'));
                     ha_scatter_premature = scatter(obj.PressTime(IndPrematureControl)+TimeStep, obj.HoldTime(IndPrematureControl)*1000, ...
                         'Marker', 'o', 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                     IndLateControl= iIndControlTrials(strcmp(obj.Outcome(iIndControlTrials), 'Late'));
                     HoldTimeLate = obj.HoldTime(IndLateControl)*1000;
                     HoldTimeLate(HoldTimeLate>maxHoldTime) = maxHoldTime;
                     ha_scatter_late = scatter(obj.PressTime(IndLateControl)+TimeStep, HoldTimeLate, ...
                         'Marker', 'o', 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                 end;

                 line(ha_Trial1, [TimeStep TimeStep], [0 maxHoldTime], 'color', 'k', 'linestyle', '--')

                 axes(ha_Trial2)
                % Chemo trials
                for i =1:length(obj.MixedFP)
                    iIndChemoTrials = IndChemoTrials(obj.FP(IndChemoTrials) == obj.MixedFP(i));
                    symbolSize = 5+15*(i-1);
                    IndCorrectChemo= iIndChemoTrials(strcmp(obj.Outcome(iIndChemoTrials), 'Correct'));
                    ha_scatter_correct = scatter(obj.PressTime(IndCorrectChemo)+TimeStep, obj.HoldTime(IndCorrectChemo)*1000, ...
                        'Marker', 'o', 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                    IndPrematureControl= iIndChemoTrials(strcmp(obj.Outcome(iIndChemoTrials), 'Premature'));
                    ha_scatter_premature = scatter(obj.PressTime(IndPrematureControl)+TimeStep, obj.HoldTime(IndPrematureControl)*1000, ...
                        'Marker', 'o', 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

                    IndLateControl= iIndChemoTrials(strcmp(obj.Outcome(iIndChemoTrials), 'Late'));
                    HoldTimeLate = obj.HoldTime(IndLateControl)*1000;
                    HoldTimeLate(HoldTimeLate>maxHoldTime) = maxHoldTime;
                    ha_scatter_late = scatter(obj.PressTime(IndLateControl)+TimeStep, HoldTimeLate, ...
                        'Marker', 'o', 'MarkerEdgeColor',  'none', 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                end
                line(ha_Trial2, [TimeStep TimeStep], [0 maxHoldTime], 'color', 'k', 'linestyle', '--')
                TimeStep = TimeStep + max(max(ControlTimeSliding), max(ChemoTimeSliding));
             end;

             legend([hp1, hp2], 'Control', 'Chemo','location', 'best')
             set(ha_Session, 'xlim', [0 TimeStep], 'xtick', [0:1000:3000])
             set(ha_Trial1, 'xlim', [0 TimeStep], 'xtick', []);
             set(ha_Trial2, 'xlim', [0 TimeStep], 'xtick', []);
             htl1.Position(1)=TimeStep*0.5;
             htl2.Position(1)=TimeStep*0.5;
     
        end


        function obj = CalRTChemo(obj)
            % Control sessions

            ControlSessions_RTMedian_Strict = zeros(length(obj.MixedFP)+1, 1);
            ControlSessions_RTMedianCI95_Strict = cell(length(obj.MixedFP)+1, 1);
            ControlSessions_RTMedian_Loose = zeros(length(obj.MixedFP)+1, 1);
            ControlSessions_RTMedianCI95_Loose = cell(length(obj.MixedFP)+1, 1);

            ControlSession_IQR_Strict = zeros(length(obj.MixedFP)+1, 1);
            ControlSession_IQR_Loose = zeros(length(obj.MixedFP)+1, 1);

            % Chemo sessions
           ChemoSessions_RTMedian_Strict = zeros(length(obj.MixedFP)+1, 1);
            ChemoSessions_RTMedianCI95_Strict = cell(length(obj.MixedFP)+1, 1);
           ChemoSessions_RTMedian_Loose = zeros(length(obj.MixedFP)+1, 1);
           ChemoSessions_RTMedianCI95_Loose = cell(length(obj.MixedFP)+1, 1);
           ChemoSession_IQR_Strict = zeros(length(obj.MixedFP)+1, 1);
           ChemoSession_IQR_Loose = zeros(length(obj.MixedFP)+1, 1);

            for k = 1:length(obj.MixedFP)
                IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')') & obj.FP == obj.MixedFP(k);
                RT_Control_Strict           =       obj.ReactionTime(IndexControlTrials);
                IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')' | strcmp(obj.Outcome, 'Late')') & obj.FP == obj.MixedFP(k);
                RT_Control_Loose          =       obj.ReactionTime(IndexControlTrials);
                ControlSessions_RTMedian_Strict(k) = median(RT_Control_Strict);
                ControlSessions_RTMedianCI95_Strict{k} = [transpose(bootci(1000, @(x)median(x), RT_Control_Strict))];
                ControlSession_IQR_Strict(k)  =       diff(prctile(RT_Control_Strict, [25 75]));
                ControlSessions_RTMedian_Loose(k) = median(RT_Control_Loose);
                ControlSessions_RTMedianCI95_Loose{k} = [transpose(bootci(1000, @(x)median(x), RT_Control_Loose))];
                ControlSession_IQR_Loose(k)  =       diff(prctile(RT_Control_Loose, [25 75]));

                IndexChemoTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')') & obj.FP == obj.MixedFP(k);
                RT_Chemo_Strict           =       obj.ReactionTime(IndexChemoTrials);
                IndexChemoTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')' | strcmp(obj.Outcome, 'Late')') & obj.FP == obj.MixedFP(k);
                RT_Chemo_Loose          =       obj.ReactionTime(IndexChemoTrials);
                ChemoSessions_RTMedian_Strict(k) = median(RT_Chemo_Strict);
                ChemoSession_IQR_Strict(k)  =       diff(prctile(RT_Chemo_Strict, [25 75]));
                ChemoSessions_RTMedianCI95_Strict{k} = [transpose(bootci(1000, @(x)median(x), RT_Chemo_Strict))];
                ChemoSessions_RTMedian_Loose(k) = median(RT_Chemo_Loose);
                ChemoSessions_RTMedianCI95_Loose{k} = [transpose(bootci(1000, @(x)median(x), RT_Chemo_Loose))];
                ChemoSession_IQR_Loose(k)  =       diff(prctile(RT_Chemo_Loose, [25 75]));

            end;

            IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')');
            RT_Control_Strict           =       obj.ReactionTime(IndexControlTrials);
            ControlSessions_RTMedian_Strict(k+1) = median(RT_Control_Strict);
            ControlSessions_RTMedianCI95_Strict{k+1} = [transpose(bootci(1000, @(x)median(x), RT_Control_Strict))];
            ControlSession_IQR_Strict(k+1)  =       diff(prctile(RT_Control_Strict, [25 75]));

            IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')'| strcmp(obj.Outcome, 'Late')');
            RT_Control_Loose           =       obj.ReactionTime(IndexControlTrials);
            ControlSessions_RTMedian_Loose (k+1) = median(RT_Control_Loose );
            ControlSessions_RTMedianCI95_Loose {k+1} = [transpose(bootci(1000, @(x)median(x), RT_Control_Loose))];
            ControlSession_IQR_Loose(k+1)  =       diff(prctile(RT_Control_Loose, [25 75]));

            IndexChemoTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')');
            RT_Chemo_Strict           =       obj.ReactionTime(IndexChemoTrials);
            ChemoSessions_RTMedian_Strict(k+1) = median(RT_Chemo_Strict);
            ChemoSessions_RTMedianCI95_Strict{k+1} = [transpose(bootci(1000, @(x)median(x), RT_Chemo_Strict))];
            ChemoSession_IQR_Strict(k+1)  =       diff(prctile(RT_Chemo_Strict, [25 75]));

            IndexChemoTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (strcmp(obj.Outcome, 'Correct')'| strcmp(obj.Outcome, 'Late')');
            RT_Chemo_Loose           =       obj.ReactionTime(IndexChemoTrials);
            ChemoSessions_RTMedian_Loose(k+1) = median(RT_Chemo_Loose );
            ChemoSessions_RTMedianCI95_Loose {k+1} = [transpose(bootci(1000, @(x)median(x), RT_Chemo_Loose))];
            ChemoSession_IQR_Loose(k+1)  =       diff(prctile(RT_Chemo_Loose, [25 75]));

            FP_Types = [transpose(num2cell(obj.MixedFP)); 'All'];
            % Make the table

            RT_Table = table(FP_Types,...
                ControlSessions_RTMedian_Strict,           ControlSessions_RTMedianCI95_Strict,...
                ControlSession_IQR_Strict, ...
                ControlSessions_RTMedian_Loose,         ControlSessions_RTMedianCI95_Loose,...
                ControlSession_IQR_Loose,...
                ChemoSessions_RTMedian_Strict,                 ChemoSessions_RTMedianCI95_Strict,...
                ChemoSession_IQR_Strict,...
                ChemoSessions_RTMedian_Loose,                ChemoSessions_RTMedianCI95_Loose, ...
                ChemoSession_IQR_Loose);

             obj.pRTChemoResultTable = RT_Table;            

        end;

        function obj = CalRTLesion(obj)
            % Pre-lesion sessions
            RT = obj.RT_PreLesion_Sessions;
            PreLesionSessions_RTMedian_Strict = zeros(length(obj.MixedFP)+1, 1);
            PreLesionSessions_RTMedianCI95_Strict = cell(length(obj.MixedFP)+1, 1);
            PreLesionSessions_RTMedian_Loose = zeros(length(obj.MixedFP)+1, 1);
            PreLesionSessions_RTMedianCI95_Loose = cell(length(obj.MixedFP)+1, 1);
            PreLesionHoldDurationSessions_FWHM  = zeros(length(obj.MixedFP)+1, 1);

            for k =1:length(obj.MixedFP)
                disp(k)
                PreLesionSessions_RTMedian_Strict(k) = median(RT{1, k});
                PreLesionSessions_RTMedianCI95_Strict{k} = [transpose(bootci(1000, @(x)median(x), RT{1, k}))];
                PreLesionSessions_RTMedian_Loose(k) = median(RT{2, k});
                PreLesionSessions_RTMedianCI95_Loose{k} = [transpose(bootci(1000, @(x)median(x), RT{2, k}))];
                PreLesionHoldDurationSessions_FWHM(k) = obj.FWHM_HoldT_Lesion{strcmp(obj.FWHM_HoldT_Lesion(:, 1), ['PreLesion_Sessions_' num2str(obj.MixedFP(k))]), 2};
            end;

            PreLesionSessions_RTMedian_Strict(k+1) = [median(cell2mat(RT(1, :)))];
            PreLesionSessions_RTMedianCI95_Strict{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(1, :))))];
            PreLesionSessions_RTMedian_Loose(k+1) = [median(cell2mat(RT(2, :)))];
            PreLesionSessions_RTMedianCI95_Loose{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(2, :))))];

            % Pre-lesion sessions (trials)
            RT = obj.RT_PreLesion_Trials;
            PreLesionTrials_RTMedian_Strict = zeros(length(obj.MixedFP)+1, 1);
            PreLesionTrials_RTMedianCI95_Strict = cell(length(obj.MixedFP)+1, 1);
            PreLesionTrials_RTMedian_Loose = zeros(length(obj.MixedFP)+1, 1);
            PreLesionTrials_RTMedianCI95_Loose = cell(length(obj.MixedFP)+1, 1);
            PreLesionHoldDurationTrials_FWHM  = zeros(length(obj.MixedFP)+1, 1);

            for k =1:length(obj.MixedFP)
                PreLesionTrials_RTMedian_Strict(k) = median(RT{1, k});
                PreLesionTrials_RTMedianCI95_Strict{k} = [transpose(bootci(1000, @(x)median(x), RT{1, k}))];
                PreLesionTrials_RTMedian_Loose(k) = median(RT{2, k});
                PreLesionTrials_RTMedianCI95_Loose{k} = [transpose(bootci(1000, @(x)median(x), RT{2, k}))];
                PreLesionHoldDurationTrials_FWHM(k) = obj.FWHM_HoldT_Lesion{strcmp(obj.FWHM_HoldT_Lesion(:, 1), ['PreLesion_Trials_' num2str(obj.MixedFP(k))]), 2};
            end;

            PreLesionTrials_RTMedian_Strict(k+1) = [median(cell2mat(RT(1, :)))];
            PreLesionTrials_RTMedianCI95_Strict{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(1, :))))];
            PreLesionTrials_RTMedian_Loose(k+1) = [median(cell2mat(RT(2, :)))];
            PreLesionTrials_RTMedianCI95_Loose{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(2, :))))];

            % Post lesion (sessions)
            RT = obj.RT_PostLesion_Sessions;
            PostLesionSessions_RTMedian_Strict = zeros(length(obj.MixedFP)+1, 1);
            PostLesionSessions_RTMedianCI95_Strict = cell(length(obj.MixedFP)+1, 1);
            PostLesionSessions_RTMedian_Loose = zeros(length(obj.MixedFP)+1, 1);
            PostLesionSessions_RTMedianCI95_Loose = cell(length(obj.MixedFP)+1, 1);
            PostLesionHoldDurationSessions_FWHM  = zeros(length(obj.MixedFP)+1, 1);

            for k =1:length(obj.MixedFP)
                if ~isempty(RT{1, k})
                    PostLesionSessions_RTMedian_Strict(k) = median(RT{1, k});
                    PostLesionSessions_RTMedianCI95_Strict{k} = [transpose(bootci(1000, @(x)median(x), RT{1, k}))];
                else
                    PostLesionSessions_RTMedian_Strict(k) = [NaN];
                    PostLesionSessions_RTMedianCI95_Strict{k} = [NaN NaN];
                end;
                if ~isempty(RT{2, k})
                    PostLesionSessions_RTMedian_Loose(k) = median(RT{2, k});
                    PostLesionSessions_RTMedianCI95_Loose{k} = [transpose(bootci(1000, @(x)median(x), RT{2, k}))];
                    PostLesionHoldDurationSessions_FWHM(k) = obj.FWHM_HoldT_Lesion{strcmp(obj.FWHM_HoldT_Lesion(:, 1), ['PostLesion_Sessions_' num2str(obj.MixedFP(k))]), 2};
                else
                    PostLesionSessions_RTMedian_Loose(k) = NaN;
                    PostLesionSessions_RTMedianCI95_Loose{k} = [NaN NaN];
                    PostLesionHoldDurationSessions_FWHM(k) = NaN;
                end;
            end;

            if ~isempty(RT{1, k})
                PostLesionSessions_RTMedian_Strict(k+1) = [median(cell2mat(RT(1, :)))];
                PostLesionSessions_RTMedianCI95_Strict{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(1, :))))];
            else
                PostLesionSessions_RTMedian_Strict(k+1) = NaN;
                PostLesionSessions_RTMedianCI95_Strict{k+1} = [NaN NaN];
            end;

            if ~isempty(RT{2, k})
                PostLesionSessions_RTMedian_Loose(k+1) = [median(cell2mat(RT(2, :)))];
                PostLesionSessions_RTMedianCI95_Loose{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(2, :))))];
            else
                PostLesionSessions_RTMedian_Loose(k+1) = NaN;
                PostLesionSessions_RTMedianCI95_Loose{k+1} = [NaN NaN];
            end;

            % Pre-lesion sessions (trials)
            RT = obj.RT_PostLesion_Trials;
            PostLesionTrials_RTMedian_Strict = zeros(length(obj.MixedFP)+1, 1);
            PostLesionTrials_RTMedianCI95_Strict = cell(length(obj.MixedFP)+1, 1);
            PostLesionTrials_RTMedian_Loose = zeros(length(obj.MixedFP)+1, 1);
            PostLesionTrials_RTMedianCI95_Loose = cell(length(obj.MixedFP)+1, 1);
            PostLesionHoldDurationTrials_FWHM  = zeros(length(obj.MixedFP)+1, 1);

            for k =1:length(obj.MixedFP)
                PostLesionTrials_RTMedian_Strict(k) = median(RT{1, k});
                PostLesionTrials_RTMedianCI95_Strict{k} = [transpose(bootci(1000, @(x)median(x), RT{1, k}))];
                PostLesionTrials_RTMedian_Loose(k) = median(RT{2, k});
                PostLesionTrials_RTMedianCI95_Loose{k} = [transpose(bootci(1000, @(x)median(x), RT{2, k}))];
                PostLesionHoldDurationTrials_FWHM(k) = obj.FWHM_HoldT_Lesion{strcmp(obj.FWHM_HoldT_Lesion(:, 1), ['PostLesion_Trials_' num2str(obj.MixedFP(k))]), 2};
            end;

            PostLesionTrials_RTMedian_Strict(k+1) = [median(cell2mat(RT(1, :)))];
            PostLesionTrials_RTMedianCI95_Strict{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(1, :))))];
            PostLesionTrials_RTMedian_Loose(k+1) = [median(cell2mat(RT(2, :)))];
            PostLesionTrials_RTMedianCI95_Loose{k+1} = [transpose(bootci(1000, @(x)median(x), cell2mat(RT(2, :))))];

            FP_Types = [transpose(num2cell(obj.MixedFP)); 'All'];
            % Make the table

            RT_Table = table(FP_Types,...
                PreLesionSessions_RTMedian_Strict,           PreLesionSessions_RTMedianCI95_Strict,...
                PreLesionSessions_RTMedian_Loose,         PreLesionSessions_RTMedianCI95_Loose,...
                PreLesionTrials_RTMedian_Strict,                 PreLesionTrials_RTMedianCI95_Strict,...
                PreLesionTrials_RTMedian_Loose,                PreLesionTrials_RTMedianCI95_Loose,...
                PreLesionHoldDurationSessions_FWHM,      PreLesionHoldDurationTrials_FWHM,...
                PostLesionSessions_RTMedian_Strict,          PostLesionSessions_RTMedianCI95_Strict,...
                PostLesionSessions_RTMedian_Loose,        PostLesionSessions_RTMedianCI95_Loose,...
                PostLesionTrials_RTMedian_Strict,                PostLesionTrials_RTMedianCI95_Strict,...
                PostLesionTrials_RTMedian_Loose,              PostLesionTrials_RTMedianCI95_Loose,...
                PostLesionHoldDurationSessions_FWHM,     PostLesionHoldDurationTrials_FWHM);
                obj.pRTLesionResultTable = RT_Table;

        end;

        function obj = FitGauss_Lesion(obj)
            % call this method to fit hold duration data
            if obj.Lesion == 1
                x = obj.PDF_HoldT_Lesion.HoldTbinEdges;
                variableNames = obj.PDF_HoldT_Lesion.Properties.VariableNames(2:end);
                fitGauss = cell(1, length(variableNames));
                for i =1:length(variableNames)
                    y = eval(['obj.PDF_HoldT_Lesion.' variableNames{i}]);
                    % fit it with a double gaussian function
                    f = fit(x, y,obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
                    fitGauss{i} =  f;
                end;
                outputValue = cell(length(variableNames), 2);
                outputValue(:, 1) = variableNames';
                outputValue(:, 2) = fitGauss';
                obj.pHoldT_GaussFit_Lesion = outputValue;
            else
                obj.pHoldT_GaussFit_Lesion = [];
            end
        end;

        function value = get.HoldT_GaussFit_Lesion(obj)
            value = obj.pHoldT_GaussFit_Lesion;
        end

        function value = get.PDF_HoldT_Progress(obj)
            % track this number of trials at the beginnig of training
            % 'obj.ProgressTrials'
            PDFOut = cell(length(obj.MixedFP), 2);

            for i =1:length(obj.MixedFP)
                IndexTrials_iFP = find(obj.Stage ==1 & obj.FP == obj.MixedFP(i)  & ~strcmp(obj.TreatmentTrials', 'DCZ'));
                % Early
                IndexEarly = IndexTrials_iFP(1:min(obj.ProgressTrials, length(IndexTrials_iFP)));
                % Late
                IndexTrials_iFP_Flipped = fliplr(IndexTrials_iFP);
                IndexLate = IndexTrials_iFP_Flipped(1:min(obj.ProgressTrials, length(IndexTrials_iFP_Flipped)));
                HoldTimeEarly = obj.HoldTime(IndexEarly);
                HoldTimeLate  = obj.HoldTime(IndexLate);
                PDFOut{i, 1}                                        =            ksdensity(HoldTimeEarly, obj.HoldTbinEdges, 'function', 'pdf');
                PDFOut{i, 2}                                        =            ksdensity(HoldTimeLate, obj.HoldTbinEdges, 'function', 'pdf');
            end;
            value = PDFOut;
        end

        function value = get.FWHM_HoldT_Lesion(obj)
            % this is to compute full width at half max using the fit
            % function
            if obj.Lesion == 1
                % compute FWHM based on the model
                xnew = [obj.HoldTbinEdges(1):0.001:obj.HoldTbinEdges(end)];
                ynew = [];
                FWHM = zeros(1, size(obj.pHoldT_GaussFit_Lesion, 1));
                % Read names
                variableNames = obj.PDF_HoldT_Lesion.Properties.VariableNames(2:end);
                for i =1:length(obj.pHoldT_GaussFit_Lesion)
                    ifit = obj.HoldT_GaussFit_Lesion{i, 2};
                    ynew = ifit(xnew);
                    x_above = xnew(ynew>0.5*max(ynew));
                    FWHM(i) = x_above(end) - x_above(1);
                end;
                outputValue = cell(length(variableNames), 2);
                outputValue(:, 1) = variableNames';
                outputValue(:, 2) = num2cell(FWHM');
                value = outputValue;
            else
                value = [];
            end;
        end;

        function value = get.FWHM_HoldT_Chemo(obj)
            % this is to compute full width at half max using the fit
            % function
            if obj.Lesion == 1
                % compute FWHM based on the model
                xnew = [obj.HoldTbinEdges(1):0.001:obj.HoldTbinEdges(end)];
                ynew = [];
                FWHM = zeros(1, size(obj.pHoldT_GaussFit_Lesion, 1));
                % Read names
                variableNames = obj.PDF_HoldT_Lesion.Properties.VariableNames(2:end);
                for i =1:length(obj.pHoldT_GaussFit_Lesion)
                    ifit = obj.HoldT_GaussFit_Lesion{i, 2};
                    ynew = ifit(xnew);
                    x_above = xnew(ynew>0.5*max(ynew));
                    FWHM(i) = x_above(end) - x_above(1);
                end;
                outputValue = cell(length(variableNames), 2);
                outputValue(:, 1) = variableNames';
                outputValue(:, 2) = num2cell(FWHM');
                value = outputValue;
            else
                value = [];
            end;
        end;


        function PlotPerformance(obj)
            % Plot performance over sessions. check if there are a
            % chemogenetic sessions. mark those if there is any
            set_matlab_default;
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPColor = [189, 198, 184]/255;
            WhiskerColor = [132, 121, 225]/255;
            ShadeCol = [255, 212, 149]/255;

            figure(obj.Fig3); clf(obj.Fig3)
            set(obj.Fig3, 'unit', 'centimeters', 'position',[2 2 30.5 18], 'paperpositionmode', 'auto', 'color', 'w')

            % Plot press duration across these sessions
            plotsize1 = [8, 4];
            plotsize4 = [4 3];
            plotsize_rt = [8 4];
            plotsize5 = [2 3]; % for writing information
            plotsize6 = [5 3]; % for writing information
            plotsize3 = [2 3];

            plotsize_perf = [3 3];
            plotsize_rt2   = [4 4];

            plotsizeIQR = plotsize1;
            plotRTSessions = plotsize1;
            plotsizePDF = [3 3];

            StartTime = 0;
            maxDur = 3500/1000; % for  plotting purpose
            maxRT = 2000/1000;

            ha(1) = axes;
            xlevel = 2;
            ylevel = 19-plotsize1(2)-2;
            set(ha(1), 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 maxDur*1000], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            haRT = axes;
            xlevel = 2;
            ylevel = ylevel - plotsize1(2) - 1.25;
            set(haRT, 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 maxRT*1000], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Reaction time (msec)')

            haRT2 = axes;
            xlevel = 2;
            ylevel =  ylevel - plotsize1(2) - 1.75;

            set(haRT2, 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize_rt], 'nextplot', 'add', ...
                'ylim', [0 maxRT*1000], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear', ...
                'xtick',[1:obj.NumSessions], ...
                'xticklabels', obj.Dates, 'XTickLabelRotation', 45);        
            xlabel('Sessions')
            ylabel('Reaction time (msec)')

            % Performance score, Cued
            xlevel = 11.5;
            ylevel2 = 19-plotsize1(2)-2;

            ha(2) = axes;
            set(ha(2),  'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')
            ylabel('Performance')
            xlabel('Time in session (sec)')

            ylevel3 = ylevel2 - plotsize1(2) - 1.25;
            jitter = 0.25;

            ha(3) = axes;
            set(ha(3),  'units', 'centimeters', 'position', [xlevel, ylevel3, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear', ...
               'xtick',[1:obj.NumSessions], ...
                'xticklabels', obj.Dates);
            xlabel('Sessions')
            ylabel('Performance')
            PerformMarker = '^';

            ylevel4 = ylevel3 - plotsize1(2) - 1.75;
            ha_HoldT_Distribution = axes;
            set(ha_HoldT_Distribution,  'units', 'centimeters', 'position', [xlevel, ylevel4, [plotsize1(1) plotsize1(2)]], 'nextplot', 'add', ...
                'ylim', [0 max(obj.MixedFP)/1000+1], 'xlim', [0.5 3*obj.NumSessions+0.5], 'yscale', 'linear', ...
                'xtick', [1:3*obj.NumSessions], ...
                'xticklabels', obj.Dates, 'fontsize', 7);
            xlabel('Sessions')
            ylabel('Hold duration (s)')

            for k =1:length(obj.MixedFP)
                line([obj.NumSessions obj.NumSessions]*(k)+0.5, [0 max(obj.HoldTbinEdges_Sessions)], 'color', 'w', 'linewidth', 1, 'linestyle', '-.')
            end;

            % plot IQR over time for different FPs
            xlevel = 22;
            ha_HoldT_IQR = axes;
            set(ha_HoldT_IQR,  'units', 'centimeters', 'position', [xlevel, ylevel3, plotsizeIQR], 'nextplot', 'add', ...
                'ylim', [0 max(obj.MixedFP)/1000+1], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear', ...
                'xtick', [1:3*obj.NumSessions], ...
                'xticklabels', obj.Dates, 'fontsize', 7);
            xlabel('Sessions')
            ylabel('IQR (s)')

            IndDCZ = find(strcmp(obj.TreatmentSessions, 'DCZ'));

            yrange = ylim;
            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    plotshaded([IndDCZ(j)-2*jitter  IndDCZ(j)+2*jitter],  [yrange(1) yrange(1); yrange(2) yrange(2)], ShadeCol, 0.5);
                end;
            end;

            for k =1:length(obj.MixedFP)
                hp(k) = plot([1:obj.NumSessions], obj.IQR_Sessions(:, k), 'Marker', 'none', 'Color', 'k', 'MarkerFaceColor', 'w', ...
                    'MarkerEdgeColor', 'k','linestyle', '-', 'linewidth', 0.5*k, 'markersize', 5+k*2);
            end;

            for k =1:length(obj.MixedFP)
                symbolSize = 25+25*(k-1);
                scatter([1:obj.NumSessions]', obj.IQR_Sessions(:, k), ...
                    'MarkerEdgeColor','w',...
                    'MarkerFaceColor',[0.25 0.25 0.25],'Marker', '^','Markerfacealpha', 0.8, ...
                    'linewidth', 1.5, 'SizeData', symbolSize, 'linewidth', 0.5);
            end;

            % Plot reaction time (median)
            
             % plot RT over time for different FPs
            xlevel = 22;
            ha_RTs = axes;
            set(ha_RTs,  'units', 'centimeters', 'position', [xlevel, ylevel4, plotsizeIQR], 'nextplot', 'add', ...
                'ylim', [0 1000], 'xlim', [0.5 obj.NumSessions+0.5], 'yscale', 'linear', ...
                'xtick', [1:3*obj.NumSessions], ...
                'xticklabels', obj.Dates, 'fontsize', 7);
            xlabel('Sessions')
            ylabel('Reaction time (ms)')

            RT_Range = [1000 0];
 
            yrange = ylim;
            if ~isempty(IndDCZ)
                for j = 1:length(IndDCZ)
                    plotshaded([IndDCZ(j)-2*jitter  IndDCZ(j)+2*jitter],  [0 0;10000 10000], ShadeCol, 0.5);
                end;
            end;

            for k =1:length(obj.MixedFP)                    
                RTs = cellfun(@(x)x.RT_median(k), obj.RTLoose_Sessions);
                RT_Range(1) = min(RT_Range(1), min(RTs));
                RT_Range(2) = max(RT_Range(2), max(RTs));
                hp(k) = plot([1:obj.NumSessions], RTs, 'Marker', 'none', 'Color', 'k', 'MarkerFaceColor', 'w', ...
                    'MarkerEdgeColor', 'k','linestyle', '-', 'linewidth', 0.5*k, 'markersize', 5+k*2);
            end;

            set(ha_RTs, 'ylim', [RT_Range(1)*0.8 RT_Range(2)*1.2]);

            for k =1:length(obj.MixedFP)
                symbolSize = 25+25*(k-1);
                RTs = cellfun(@(x)x.RT_median(k), obj.RTLoose_Sessions);
                scatter([1:obj.NumSessions], RTs, ...
                    'MarkerEdgeColor','w',...
                    'MarkerFaceColor',[0.25 0.25 0.25],'Marker', '^','Markerfacealpha', 0.8, ...
                    'linewidth', 1.5, 'SizeData', symbolSize, 'linewidth', 0.5);
            end;
         
            % Response PDF
            xlevel = 20.5;
            EarlyColor = [62, 84, 172]/255;
            LateColor = [249, 74, 41]/255;
             MaxPDF = max(cell2mat(reshape(obj.PDF_HoldT_Progress, 1, [])));

             for k = 1:length(obj.MixedFP)
                 ha_pdf_progress(k) = axes;
                 xlevel_k = xlevel + (plotsizePDF(1)+ 0.25)*(k-1);
                 set(ha_pdf_progress(k), 'units', 'centimeters', 'position', [xlevel_k, ylevel2+0.5, plotsizePDF], 'nextplot', 'add', ...
                     'ylim', [0 MaxPDF*1.1],...
                     'xlim', [0 max(obj.MixedFP)+1000],'xtick',[0:500:max(obj.HoldTbinEdges)*1000], 'yscale', 'linear');
                 hp1 = plot(ha_pdf_progress(k), obj.HoldTbinEdges*1000, obj.PDF_HoldT_Progress{k, 1}, ...
                     'color', EarlyColor, 'linewidth', 1.5);
                 hp2 = plot(ha_pdf_progress(k), obj.HoldTbinEdges*1000, obj.PDF_HoldT_Progress{k, 2}, ...
                     'color', LateColor, 'linewidth', 1.5);

                 line([obj.MixedFP(k) obj.MixedFP(k)], [0 MaxPDF*1.1], 'color', [0.5 0.5 0.5], 'linewidth', 1, 'linestyle', ':')

                 if k >1
                     set(ha_pdf_progress(k), 'yticklabel', [])
                 else
                     ylabel('PDF (1/s)')
                     xlabel('Hold dur (ms)')
                 end;

                 if k == length(obj.MixedFP)
                     hp_early = hp1;
                     hp_late = hp2;
                 end;
             end
           
           legend([hp_early, hp_late], 'Early', 'Late', 'Box','off', 'Location','northeast')
          
            % Press duration y range
            Lneg                   = -250; % for plotting response time
            PressDurRange = [Lneg, max(obj.MixedFP)+2000];
            MarkerAlpha = 0.4;

            CorrectSessions = [];
            PrematureSessions = [];
            LateSessions = [];

            % for computing reaction time distribution
            RT_FPs              =        [];
            RT_FPs_Types   =        [];

            % For tracking sessions
            FirstSession            =         0;

            % Plot post lesion sessions
            % make shade illustrate postion lesion sessions
            % Plot Lesions
            StartTime = 0;
            HoldTDistributionAll = cell(1, length(obj.MixedFP));
            maxHoldT_PDF =max(cell2mat(reshape(obj.PDF_HoldT_Sessions, 1, [])));

            for i =1:obj.NumSessions
                for k =1:length(obj.MixedFP)
                    HoldTDistributionAll{k} = [HoldTDistributionAll{k} obj.PDF_HoldT_Sessions{i, k}'];
                end
                
                Treatment = 0;
                if ~isempty(obj.TreatmentSessions)
                    if strcmp(obj.TreatmentSessions{i}, 'DCZ')
                        Treatment = 1;
                    end;
                end;
 
                iReleaseTimes                              =           obj.ReleaseTime(obj.SessionIndex == i);
                iTrialsIndx                                     =           obj.SessionIndex == i;                          
                iPressTimes                                  =           obj.PressTime(iTrialsIndx);
                iReleaseTimes                              =           obj.ReleaseTime(iTrialsIndx);
                iPressDurs                                    =           iReleaseTimes - iPressTimes;
                iRTs                                               =           obj.ReactionTime(iTrialsIndx);
                iRTs_Org                                       =           iRTs;
                iRTs(iRTs>maxRT)                        =           maxRT;
                iPressDurs(iPressDurs>maxDur) =            maxDur;
                iOutcome                                      =            [obj.Outcome(iTrialsIndx)]';
                iStage                                           =            obj.Stage(iTrialsIndx);
                iFP                                                =            obj.FP(iTrialsIndx);
                indPerformanceSliding                  =           find(obj.PerformanceSlidingWindow.Session == i);

                % Check if this is a Chemo session
                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(2), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);
                set(haRT, 'xlim', [0 iReleaseTimes(end)+StartTime])

                % draw shades
                if Treatment
                    axes(ha(1))
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [PressDurRange(1) PressDurRange(1); PressDurRange(2) PressDurRange(2)], ShadeCol, 0.5);
                    axes(ha(2))
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [-5 -5; 100 100], ShadeCol, 0.5);
                    axes(ha(3))
                    plotshaded([i-2*jitter  i+2*jitter], [-5 -5; 100 100], ShadeCol, 0.5);
                    axes(haRT)
                    plotshaded([StartTime StartTime + iReleaseTimes(end)], [0 0; maxRT*1000 maxRT*1000], ShadeCol, 0.5);
                    axes(haRT2)
                    plotshaded([i-2*jitter  i+2*jitter], [0 0; maxRT*1000 maxRT*1000], ShadeCol, 0.5);
                end;

                % mark a new session
                line(ha(1), [StartTime StartTime], [0 maxDur*1000], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(haRT, [StartTime StartTime], [0 maxRT*1000], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(2), [StartTime StartTime], [-5 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);

                if i >1
                    line(ha(3), [i i]-jitter*2, [-5 100], ...
                        'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                end;

                % plot press times
                line(ha(1), [iPressTimes; iPressTimes]+StartTime, [Lneg; 0], 'color', 'b'); % all press times

                % Plot premature responses
                for k =1:length(obj.MixedFP)
                    symbolSize = 5+10*(k-1);
                    ind_premature_presses = strcmp(iOutcome, 'Premature') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1),iPressTimes(ind_premature_presses)+StartTime, ...
                        1000*iPressDurs(ind_premature_presses), ...
                        25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                end

                %  Plot dark responses
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iStage == 1;
                scatter(ha(1),iPressTimes(ind_dark_presses)+StartTime, ...
                    1000*iPressDurs(ind_dark_presses), ...
                    8, 'k',  '+', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Plot late and correct responses
                for k =1:length(obj.MixedFP)
                    symbolSize = 5+10*(k-1);
                    ind_late_presses = strcmp(iOutcome, 'Late') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1), iPressTimes(ind_late_presses)+StartTime, ...
                        1000*iPressDurs(ind_late_presses), ...
                        25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                    % also plot reaction time
                    scatter(haRT, iPressTimes(ind_late_presses)+StartTime, ...
                        1000*iRTs(ind_late_presses), ...
                        25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);

                    ind_correct_presses = strcmp(iOutcome, 'Correct') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1),iPressTimes(ind_correct_presses)+StartTime, ...
                        1000*iPressDurs(ind_correct_presses), ...
                        25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);

                    % also plot reaction time
                    scatter(haRT, iPressTimes(ind_correct_presses)+StartTime, ...
                        1000*iRTs(ind_correct_presses), ...
                        25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                end

                ind_rt_presses = (strcmp(iOutcome, 'Correct') | strcmp(iOutcome, 'Late')) & iStage == 1;

                if sum(ind_rt_presses)>0
                    RT_FPs                  =         [RT_FPs 1000*iRTs_Org(ind_rt_presses)];
                    RT_FPs_Types      =          [RT_FPs_Types repmat(i, 1, sum(ind_rt_presses))];
                else
                    RT_FPs                  =         [RT_FPs rand(1, 100)];
                    RT_FPs_Types      =          [RT_FPs_Types repmat(i, 1,100)];
                end;

                % plot performance over time
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :), ...
                    'marker', 'none', 'linestyle', '-', 'markersize', 4)

                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :));

                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :));

                % plot performance over session
                CorrectSessions        =        [CorrectSessions; zeros(1, 1+length(obj.MixedFP))];
                PrematureSessions   =        [PrematureSessions; zeros(1, 1+length(obj.MixedFP))];
                LateSessions             =        [LateSessions; zeros(1, 1+length(obj.MixedFP))];

                axes(ha(3))

                for k =1:length(obj.MixedFP)

                    symbolSize = 20+25*(k-1);
                    iFP = obj.MixedFP(k);
                    xloc = i-jitter+jitter*(k-1);
                    IndFP = cell2mat(cellfun(@(d)isequal(d, iFP), obj.PerformanceSessions{i}.Foreperiod, 'UniformOutput', false));

                    CorrPerc =  obj.PerformanceSessions{i}.CorrectRatio(IndFP);
                    scatter(xloc , CorrPerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(1,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

                    PremPerc =  obj.PerformanceSessions{i}.PrematureRatio(IndFP);
                    scatter(xloc , PremPerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(2,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerAlpha);

                    LatePerc =  obj.PerformanceSessions{i}.LateRatio(IndFP);
                    scatter(xloc , LatePerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(3,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerAlpha);

                    CorrectSessions(end, k)             =        CorrPerc;
                    PrematureSessions(end, k)        =        PremPerc;
                    LateSessions(end, k)                  =        LatePerc;

                end;
                CorrectSessions(end, k+1)             =        obj.PerformanceSessions{i}.CorrectRatio(end);
                PrematureSessions(end, k+1)        =        obj.PerformanceSessions{i}.PrematureRatio(end);
                LateSessions(end, k+1)                  =        obj.PerformanceSessions{i}.LateRatio(end);

                StartTime = iReleaseTimes(end) + StartTime+60;
            end;

            axes(ha_HoldT_Distribution)
            imagesc([1:obj.NumSessions*3], obj.HoldTbinEdges,  cell2mat(HoldTDistributionAll), [0 maxHoldT_PDF*1.2]);
            colormap(turbo)
            hbar = colorbar;
            xlevel = 11.5
            set(hbar, 'units', 'centimeters', 'position', [xlevel+plotsize1(1)+0.1, ylevel4, [0.2 plotsize1(2)]] )
            hbar.Label.String = 'PDF (1/sec)';

            for k =1:length(obj.MixedFP)
                text(0+obj.NumSessions*(k-1)+1, max(obj.MixedFP)/1000+1-0.1, [num2str(obj.MixedFP(k)) ' ms'], 'fontname', 'dejavu sans', 'fontsize', 8, 'color', 'w')
                if ~isempty(IndDCZ)
                    for j = 1:length(IndDCZ)
                        arrow([IndDCZ(j)+obj.NumSessions*(k-1), 0], [IndDCZ(j)+obj.NumSessions*(k-1) 0.15], ...
                            'color', ShadeCol, 'linewidth', 2, 'Length',3, 'TipAngle', 35);
                        pos = [IndDCZ(j)+obj.NumSessions*(k-1)-0.5, 0, 1, max(obj.MixedFP)/1000+1];
                        rectangle('Position',pos, 'EdgeColor', ShadeCol, 'linewidth', 0.5, 'linestyle', ':')
                    end;
                end;
                line(ha_HoldT_Distribution, [obj.NumSessions obj.NumSessions]*(k)+0.5, [0 max(obj.HoldTbinEdges_Sessions)], 'color', 'w', 'linewidth', 1, 'linestyle', '-.')
            end;

            % add average perfromance score: AllPreLesionSessions / AllPostLesionSessions
            hp_correct              =           plot(ha(3), [1:obj.NumSessions], CorrectSessions(:, end), ...
                'linewidth', 2.5, 'color', col_perf(1, :), 'marker', '.', 'markersize', 10);
            hp_premature        =           plot(ha(3), [1:obj.NumSessions], PrematureSessions(:, end), ...
                'linewidth', 2.5, 'color', col_perf(2, :), 'marker', '.', 'markersize', 10);
            hp_late                     =           plot(ha(3), [1:obj.NumSessions], LateSessions(:, end), ...
                'linewidth', 2.5, 'color', col_perf(3, :), 'marker', '.', 'markersize', 10);

            % reaction time violing plot
            axes(haRT2)
            pos_org = get(haRT2, 'Position');
            hVio1 = violinplot(RT_FPs,  RT_FPs_Types, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false, 'EdgeColor', [0 0 0], 'BoxColor', [253, 138, 138]/255, 'ViolinColor', [0.6 0.6 0.6]);
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

            set(haRT2, 'Position', pos_org, 'xlim', [0 obj.NumSessions+1], 'xtick',[1:obj.NumSessions], ...
                'xticklabel',obj.Dates, ...
                'ylim', [0 maxRT*1000])

            hui_1 = uicontrol('Style', 'text', 'parent', obj.Fig3, 'units', 'normalized', 'position', [0.1 0.965 0.2 0.03],...
                'string',  ['Subject: ' obj.Subject{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans' );

            hui_2 = uicontrol('Style', 'text', 'parent', obj.Fig3, 'units', 'normalized', 'position', [0.3 0.965 0.4 0.03],...
                'string', ['Protocol: ' obj.Protocols{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans');
 
        end

        function PlotPerformanceLesion(obj)
                   % Plot group data
            set_matlab_default;
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPColor = [189, 198, 184]/255;
            WhiskerColor = [132, 121, 225]/255;
            ShadeCol = [255, 212, 149]/255;

            figure(obj.Fig2); clf(obj.Fig2)
            set(obj.Fig2, 'unit', 'centimeters', 'position',[2 2 22 18], 'paperpositionmode', 'auto', 'color', 'w')

            % Plot press duration across these sessions
            plotsize1 = [8, 4];
            plotsize4 = [4 3];
            plotsize_rt = [8 4];
            plotsize5 = [2 3]; % for writing information
            plotsize6 = [5 3]; % for writing information
            plotsize3 = [2 3];

            plotsize_perf = [3 3];
            plotsize_rt2   = [4 4];

            StartTime = 0;
            maxDur = 3500/1000; % for  plotting purpose
            maxRT = 2000/1000;

            ha(1) = axes;
            xlevel = 2;
            ylevel = 19-plotsize1(2)-2;
            set(ha(1), 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 maxDur*1000], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            haRT = axes;
            xlevel = 2;
            ylevel = ylevel - plotsize1(2) - 1.25;
            set(haRT, 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 maxRT*1000], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Reaction time (msec)')

            haRT2 = axes;
            xlevel = 2;
            ylevel =  ylevel - plotsize1(2) - 1.25;

            set(haRT2, 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize_rt], 'nextplot', 'add', ...
                'ylim', [0 maxRT*1000], 'xlim', [min(obj.LesionSessions)+0.5 max(obj.LesionSessions)-0.5], 'yscale', 'linear', ...
                'xtick',[obj.LesionSessions(obj.LesionSessions<0) obj.LesionSessions(obj.LesionSessions>0)-1], ...
                'xticklabels', num2cell(obj.LesionSessions));
        
            xlabel('Sessions relative to lesion')
            ylabel('Reaction time (msec)')

            % Performance score, Cued
            xlevel = 12;
            ylevel2 = 19-plotsize1(2)-2;

            ha(2) = axes;
            set(ha(2),  'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')
            ylabel('Performance')
            xlabel('Time in session (sec)')

            ylevel3 = ylevel2 - plotsize1(2) - 1.25;
            jitter = 0.25;

            ha(3) = axes;
            set(ha(3),  'units', 'centimeters', 'position', [xlevel, ylevel3, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [min(obj.LesionSessions)-0.5 max(obj.LesionSessions)-0.5], 'yscale', 'linear', ...
                'xtick',[obj.LesionSessions(obj.LesionSessions<0) obj.LesionSessions(obj.LesionSessions>0)-1], ...
                'xticklabels', num2cell(obj.LesionSessions));
            xlabel('Sessions relative to lesion')
            ylabel('Performance')
            PerformMarker = '^';

            ylevel4 = ylevel3 - plotsize1(2) - 1.25;

            ha(4) = axes;
            set(ha(4),  'units', 'centimeters', 'position', [xlevel, ylevel4, plotsize_perf], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [-5 100], 'yscale', 'linear', ...
                'xtick',[0:20:100], 'TickLength', [0.01 0.1]);
            xlabel('Performance')
            ylabel('Performance')
            line([-5 100], [-5 100], 'color', [0.5 0.5 0.5], 'linestyle', '-.');

            for k =1:length(obj.MixedFP)

                symbolSize = 20+20*(k-1);
                ha_scatter_correct = scatter(100*obj.PerformanceLesionResultTable.PreLesionSessions_CorrectRatio(k), 100*obj.PerformanceLesionResultTable.PostLesionSessions_CorrectRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(1, :), 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                ha_scatter_premature = scatter(100*obj.PerformanceLesionResultTable.PreLesionSessions_PrematureRatio(k), 100*obj.PerformanceLesionResultTable.PostLesionSessions_PrematureRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(2, :), 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                ha_scatter_late = scatter(100*obj.PerformanceLesionResultTable.PreLesionSessions_LateRatio(k), 100*obj.PerformanceLesionResultTable.PostLesionSessions_LateRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(3, :), 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

            end;

            text(0, 110, sprintf('Pre/Post %2.0d/%2.0d sessions', length(obj.PreLesionSessions),  length(obj.PostLesionSessions)),'fontsize', 8, 'FontWeight','bold','FontName','dejavu sans')

            xlevel_new = xlevel + plotsize_perf(2) + 1.5;

            ha(5) = axes;
            set(ha(5),  'units', 'centimeters', 'position', [xlevel_new, ylevel4, plotsize_perf], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [-5 100], 'yscale', 'linear', ...
                'xtick',[0:20:100], 'TickLength', [0.01 0.1]);
            xlabel('Performance')
            ylabel('Performance')
            line([-5 100], [-5 100], 'color', [0.5 0.5 0.5], 'linestyle', '-.');

            for k =1:length(obj.MixedFP)

                symbolSize = 20+20*(k-1);
                ha_scatter_correct = scatter(100*obj.PerformanceLesionResultTable.PreLesionTrials_CorrectRatio(k), 100*obj.PerformanceLesionResultTable.PostLesionTrials_CorrectRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(1, :), 'MarkerFaceColor',  col_perf(1, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                ha_scatter_premature = scatter(100*obj.PerformanceLesionResultTable.PreLesionTrials_PrematureRatio(k), 100*obj.PerformanceLesionResultTable.PostLesionTrials_PrematureRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(2, :), 'MarkerFaceColor',  col_perf(2, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);
                ha_scatter_late = scatter(100*obj.PerformanceLesionResultTable.PreLesionTrials_LateRatio(k), 100*obj.PerformanceLesionResultTable.PostLesionTrials_LateRatio(k), ...
                    'Marker', 'o', 'MarkerEdgeColor',  col_perf(3, :), 'MarkerFaceColor',  col_perf(3, :), 'SizeData', symbolSize, 'MarkerFaceAlpha', 0.6);

            end;

            text(0, 110, sprintf('Pre/Post %2.0d/%2.0d trials', obj.PreLesionTrialNum, obj.PostLesionTrialNum),'fontsize', 8, 'FontWeight','bold','FontName','dejavu sans')

                     % Press duration y range
            Lneg                   = -250; % for plotting response time
            PressDurRange = [Lneg, max(obj.MixedFP)+2000];
            MarkerAlpha = 0.4;

            CorrectSessions = [];
            PrematureSessions = [];
            LateSessions = [];

            % for computing reaction time distribution
            RT_FPs              =        [];
            RT_FPs_Types   =        [];

            % For tracking lesion sessions
            FirstLesionSession            =         0;

            % Plot post lesion sessions
            % make shade illustrate postion lesion sessions
            % Plot Lesions
            for k =1:size(obj.LesionSessionsAll, 2)
                kLesionIndex = obj.LesionSessionsAll(:, k);
                Onset = 0;
                LesionStartTime = 0;
                for i = 1:obj.NumSessions
                    if kLesionIndex(i)<0
                        iReleaseTimes                              =           obj.ReleaseTime(obj.SessionIndex == i);
                        LesionStartTime                            =           LesionStartTime + iReleaseTimes(end);
                     else
                        if FirstLesionSession == 0
                            FirstLesionSession = i;
                        end;
                        if Onset ==0
                            axes(ha(1))
                            plotshaded([LesionStartTime LesionStartTime + 10^6], [0 0; maxDur*1000 maxDur*1000 ], ShadeCol*(1-0.2*(k-1)));
                            axes(haRT)
                            plotshaded([LesionStartTime LesionStartTime + 10^6], [0 0; maxRT*1000 maxRT*1000 ],  ShadeCol*(1-0.2*(k-1)));
                            axes(ha(2))
                            plotshaded([LesionStartTime LesionStartTime + 10^6], [-5 -5; 100 100],  ShadeCol*(1-0.2*(k-1)));
                            axes(ha(3))
                            plotshaded([-jitter*2 -jitter*2+60]+(i-FirstLesionSession),[ -5 -5; 100 100],  ShadeCol*(1-0.2*(k-1)));
                            axes(haRT2)
                            plotshaded([0 60]+i,[0 0; maxRT*1000 maxRT*1000],  ShadeCol*(1-0.2*(k-1)))
                            Onset = 1;
                        end;
                    end;
                end;
            end;

            AllPreLesionSessions = obj.LesionSessions(obj.LesionSessions<0);
            % Plot pre lesion sessions
            for i =1:length(AllPreLesionSessions)
                iLesIndx                                        =           obj.LesionTrials == AllPreLesionSessions(i);                   % find trials corresponding to a pre-lesion session
                iSessionIndx                                 =           find(obj.LesionSessions == AllPreLesionSessions(i));    % find session index corresponding to a pre-lesion session
                iPressTimes                                  =           obj.PressTime(iLesIndx);
                iReleaseTimes                              =           obj.ReleaseTime(iLesIndx);
                iPressDurs                                    =           iReleaseTimes - iPressTimes;
                iRTs                                               =           obj.ReactionTime(iLesIndx);
                iRTs_Org                                       =           iRTs;
                iRTs(iRTs>maxRT)                        =           maxRT;
                iPressDurs(iPressDurs>maxDur) = maxDur;
                iOutcome                                      =            [obj.Outcome(iLesIndx)]';
                iStage                                           =            obj.Stage(iLesIndx);
                iFP                                                =        obj.FP(iLesIndx);
                indPerformanceSliding                  =       find(obj.PerformanceSlidingWindow.Session == iSessionIndx);

                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');

                set(ha(2), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);

                % mark a new session
                line(ha(1), [StartTime StartTime], [0 maxDur*1000], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(haRT, [StartTime StartTime], [0 maxRT*1000], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(2), [StartTime StartTime], [-5 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);

                if i >1
                    line(ha(3), [AllPreLesionSessions(i)  AllPreLesionSessions(i)]-jitter*2, [-5 100], ...
                        'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                end;

                % plot press times
                line(ha(1), [iPressTimes; iPressTimes]+StartTime, [Lneg; 0], 'color', 'b'); % all press times

                % Plot premature responses
                for k =1:length(obj.MixedFP)
                    symbolSize = 5+10*(k-1);
                    ind_premature_presses = strcmp(iOutcome, 'Premature') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1),iPressTimes(ind_premature_presses)+StartTime, ...
                        1000*iPressDurs(ind_premature_presses), ...
                        25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                end

                %  Plot dark responses
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iStage == 1;
                scatter(ha(1),iPressTimes(ind_dark_presses)+StartTime, ...
                    1000*iPressDurs(ind_dark_presses), ...
                    8, 'k',  '+', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Plot late and correct responses
                for k =1:length(obj.MixedFP)
                    symbolSize = 5+10*(k-1);
                    ind_late_presses = strcmp(iOutcome, 'Late') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1), iPressTimes(ind_late_presses)+StartTime, ...
                        1000*iPressDurs(ind_late_presses), ...
                        25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                    % also plot reaction time
                    scatter(haRT, iPressTimes(ind_late_presses)+StartTime, ...
                        1000*iRTs(ind_late_presses), ...
                        25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);

                    ind_correct_presses = strcmp(iOutcome, 'Correct') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1),iPressTimes(ind_correct_presses)+StartTime, ...
                        1000*iPressDurs(ind_correct_presses), ...
                        25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);

                    % also plot reaction time
                    scatter(haRT, iPressTimes(ind_correct_presses)+StartTime, ...
                        1000*iRTs(ind_correct_presses), ...
                        25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                end

                ind_rt_presses = (strcmp(iOutcome, 'Correct') | strcmp(iOutcome, 'Late')) & iStage == 1;
                CatName                =         ['Session_' num2str(AllPreLesionSessions(i))];
                RT_FPs                  =         [RT_FPs 1000*iRTs_Org(ind_rt_presses)];
                RT_FPs_Types      =          [RT_FPs_Types repmat(AllPreLesionSessions(i), 1, sum(ind_rt_presses))];

                % plot performance over time
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :), ...
                    'marker', 'none', 'linestyle', '-', 'markersize', 4)
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :));
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :));

                % plot performance over session
                CorrectSessions        =        [CorrectSessions; zeros(1, 1+length(obj.MixedFP))];
                PrematureSessions   =        [PrematureSessions; zeros(1, 1+length(obj.MixedFP))];
                LateSessions             =        [LateSessions; zeros(1, 1+length(obj.MixedFP))];

                axes(ha(3))

                for k =1:length(obj.MixedFP)

                    symbolSize = 20+25*(k-1);
                    iFP = obj.MixedFP(k);
                    xloc = AllPreLesionSessions(i)-jitter+jitter*(k-1);
                    IndFP = cell2mat(cellfun(@(d)isequal(d, iFP), obj.PerformanceSessions{iSessionIndx}.Foreperiod, 'UniformOutput', false));

                    CorrPerc =  obj.PerformanceSessions{iSessionIndx}.CorrectRatio(IndFP);
                    scatter(xloc , CorrPerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(1,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

                    PremPerc =  obj.PerformanceSessions{iSessionIndx}.PrematureRatio(IndFP);
                    scatter(xloc , PremPerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(2,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerAlpha);

                    LatePerc =  obj.PerformanceSessions{iSessionIndx}.LateRatio(IndFP);
                    scatter(xloc , LatePerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(3,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerAlpha);

                    CorrectSessions(end, k)             =        CorrPerc;
                    PrematureSessions(end, k)        =        PremPerc;
                    LateSessions(end, k)                  =        LatePerc;

                end;
                CorrectSessions(end, k+1)             =        obj.PerformanceSessions{iSessionIndx}.CorrectRatio(end);
                PrematureSessions(end, k+1)        =        obj.PerformanceSessions{iSessionIndx}.PrematureRatio(end);
                LateSessions(end, k+1)                  =        obj.PerformanceSessions{iSessionIndx}.LateRatio(end);
 
                StartTime = iReleaseTimes(end) + StartTime;
            end;

        % sometimes, there is an additional lesion. Check the data and plot
        % the result if necessary

        AllPostLesionSessions = obj.LesionSessions(obj.LesionSessions>0);

        for i =1:length(AllPostLesionSessions)
            iLesIndx                                       =            obj.LesionTrials == AllPostLesionSessions(i);                   % find trials corresponding to a pre-lesion session
            iSessionIndx                                 =           find(obj.LesionSessions == AllPostLesionSessions(i));    % find session index corresponding to a pre-lesion session
            iPressTimes                                  =           obj.PressTime(iLesIndx);
            iReleaseTimes                              =           obj.ReleaseTime(iLesIndx);
            iPressDurs                                    =           iReleaseTimes - iPressTimes;
            iRTs                                               =           obj.ReactionTime(iLesIndx);
            iRTs_Org                                       =           iRTs;
            iRTs(iRTs>maxRT)                        =           maxRT;
            iPressDurs(iPressDurs>maxDur) =             maxDur;
            iOutcome                                      =            [obj.Outcome(iLesIndx)]';
            iStage                                           =            obj.Stage(iLesIndx);
            iFP                                                =        obj.FP(iLesIndx);
            indPerformanceSliding                  =       find(obj.PerformanceSlidingWindow.Session == iSessionIndx);

            if ~isempty(iReleaseTimes)
                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(2), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);
                set(haRT, 'xlim', [0 iReleaseTimes(end)+StartTime]);

                % mark a new session
                line(ha(1), [StartTime StartTime], [0 maxDur*1000], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(2), [StartTime StartTime], [-5 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(haRT, [StartTime StartTime], [0 maxRT*1000], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(3), [AllPostLesionSessions(i)  AllPostLesionSessions(i)]-1-jitter*2, [-5 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);

                % plot press times
                line(ha(1), [iPressTimes; iPressTimes]+StartTime, [Lneg; 0], 'color', 'b'); % all press times

                % Plot premature responses
                for k =1:length(obj.MixedFP)
                    symbolSize = 5+10*(k-1);
                    ind_premature_presses = strcmp(iOutcome, 'Premature') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1),iPressTimes(ind_premature_presses)+StartTime, ...
                        1000*iPressDurs(ind_premature_presses), ...
                        25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                end

                %  Plot dark responses
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iStage == 1;
                scatter(ha(1),iPressTimes(ind_dark_presses)+StartTime, ...
                    1000*iPressDurs(ind_dark_presses), ...
                    8, 'k',  '+', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Plot late responses
                for k =1:length(obj.MixedFP)

                    symbolSize = 5+10*(k-1);
                    ind_late_presses = strcmp(iOutcome, 'Late') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1), iPressTimes(ind_late_presses)+StartTime, ...
                        1000*iPressDurs(ind_late_presses), ...
                        25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                    % also plot reaction time
                    scatter(haRT, iPressTimes(ind_late_presses)+StartTime, ...
                        1000*iRTs(ind_late_presses), ...
                        25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);

                    ind_correct_presses = strcmp(iOutcome, 'Correct') & iFP == obj.MixedFP(k) & iStage == 1;
                    scatter(ha(1),iPressTimes(ind_correct_presses)+StartTime, ...
                        1000*iPressDurs(ind_correct_presses), ...
                        25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                    % also plot reaction time
                    scatter(haRT, iPressTimes(ind_correct_presses)+StartTime, ...
                        1000*iRTs(ind_correct_presses), ...
                        25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
                end

                ind_rt_presses = (strcmp(iOutcome, 'Correct') | strcmp(iOutcome, 'Late')) & iStage == 1;
                CatName                =         ['Session_' num2str(AllPostLesionSessions(i))];

                if sum(ind_rt_presses)>0
                    RT_FPs                  =         [RT_FPs 1000*iRTs_Org(ind_rt_presses)];
                    RT_FPs_Types      =          [RT_FPs_Types repmat(AllPostLesionSessions(i), 1, sum(ind_rt_presses))];
                else
                    RT_FPs                  =         [RT_FPs rand(1, 100)];
                    RT_FPs_Types      =          [RT_FPs_Types repmat(AllPostLesionSessions(i), 1,100)];
                end;

                % plot performance over time
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :), ...
                    'marker', 'none', 'linestyle', '-', 'markersize', 4)
                %                 % plot average
                %                 iCorrect = obj.PerformanceSessions{iSessionIndx}.Correct;
                %                 tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                %                 line(ha(4), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :));
                plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :));

                % plot performance over session
                CorrectSessions        =        [CorrectSessions; zeros(1, 1+length(obj.MixedFP))];
                PrematureSessions   =        [PrematureSessions; zeros(1, 1+length(obj.MixedFP))];
                LateSessions             =        [LateSessions; zeros(1, 1+length(obj.MixedFP))];

                axes(ha(3))
                for k =1:length(obj.MixedFP)
                    symbolSize = 20+25*(k-1);
                    iFP = obj.MixedFP(k);
                    xloc = AllPostLesionSessions(i)-jitter+jitter*(k-1)-1;
                    IndFP = cell2mat(cellfun(@(d)isequal(d, iFP), obj.PerformanceSessions{iSessionIndx}.Foreperiod, 'UniformOutput', false));

                    CorrPerc =  obj.PerformanceSessions{iSessionIndx}.CorrectRatio(IndFP);
                    scatter(xloc , CorrPerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(1,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

                    PremPerc =  obj.PerformanceSessions{iSessionIndx}.PrematureRatio(IndFP);
                    scatter(xloc , PremPerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(2,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerAlpha);

                    LatePerc =  obj.PerformanceSessions{iSessionIndx}.LateRatio(IndFP);
                    scatter(xloc , LatePerc,  'Marker', PerformMarker, 'SizeData', symbolSize, 'LineWidth', 1, ...
                        'MarkerFaceColor', col_perf(3,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerAlpha);

                    CorrectSessions(end, k)             =        CorrPerc;
                    PrematureSessions(end, k)        =        PremPerc;
                    LateSessions(end, k)                  =        LatePerc;
                end;
                CorrectSessions(end, k+1)             =        obj.PerformanceSessions{iSessionIndx}.CorrectRatio(end);
                PrematureSessions(end, k+1)        =        obj.PerformanceSessions{iSessionIndx}.PrematureRatio(end);
                LateSessions(end, k+1)                  =        obj.PerformanceSessions{iSessionIndx}.LateRatio(end);
                StartTime                                         =        iReleaseTimes(end) + StartTime;
            else

                CorrectSessions            =        [CorrectSessions; NaN*ones(1, size(CorrectSessions, 2))];
                PrematureSessions       =        [PrematureSessions; NaN*ones(1, size(PrematureSessions, 2))];
                LateSessions                 =         [LateSessions; NaN*ones(1, size(LateSessions, 2))];

                StartTime = StartTime + 3600; % 3600 sec is one hour
            end;
        end;


            % add average perfromance score: AllPreLesionSessions / AllPostLesionSessions
            hp_correct = plot(ha(3), [AllPreLesionSessions AllPostLesionSessions-1], CorrectSessions(:, end), ...
                'linewidth', 2.5, 'color', col_perf(1, :), 'marker', '.', 'markersize', 10);
            hp_premature= plot(ha(3), [AllPreLesionSessions AllPostLesionSessions-1], PrematureSessions(:, end), ...
                'linewidth', 2.5, 'color', col_perf(2, :), 'marker', '.', 'markersize', 10);
            hp_late = plot(ha(3), [AllPreLesionSessions AllPostLesionSessions-1], LateSessions(:, end), ...
                'linewidth', 2.5, 'color', col_perf(3, :), 'marker', '.', 'markersize', 10);

            % reaction time violing plot
            axes(haRT2)
            pos_org = get(haRT2, 'Position');
            hVio1 = violinplot(RT_FPs,  RT_FPs_Types, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false, 'EdgeColor', [0 0 0], 'BoxColor', [253, 138, 138]/255, 'ViolinColor', [0.6 0.6 0.6]);
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

            set(haRT2, 'Position', pos_org, 'xlim', [0 length(obj.LesionSessions)+1], 'xtick',[1:length(obj.LesionSessions)], ...
                'xticklabel',num2cell(obj.LesionSessions), ...
                'ylim', [0 maxRT*1000])

            hui_1 = uicontrol('Style', 'text', 'parent', obj.Fig2, 'units', 'normalized', 'position', [0.1 0.965 0.2 0.03],...
                'string',  ['Subject: ' obj.Subject{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans' );

            hui_2 = uicontrol('Style', 'text', 'parent', obj.Fig2, 'units', 'normalized', 'position', [0.3 0.965 0.4 0.03],...
                'string', ['Protocol: ' obj.Protocols{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans');
 
        end

        function PlotPrePostLesion(obj, varargin)
            set_matlab_default;
            % This is to plot pre and post lesion hold time PDF, which gives
            % a quick show on the effect
            ToPlot = 'Sessions';
            if nargin>1
                for i=1:2:size(varargin,2)
                    switch varargin{i}
                        case 'ToPlot'
                            ToPlot = varargin{i+1};
                    end
                end
            end;

            FPs = obj.MixedFP;
            variableNames = obj.PDF_HoldT_Lesion.Properties.VariableNames(2:end);
            tBins = obj.PDF_HoldT_Lesion.HoldTbinEdges;
            colors = {[0 0 0.6], [255, 201, 60]/255};
            FPColors = [45, 205, 223]/255;
            WhiskerColor = [255, 0, 50]/255;

            SessionsCol = [3, 0, 28]/255;
            TrialsCol = [91, 143, 185]/255;

            figure(obj.Fig1); clf(obj.Fig1)
            set(obj.Fig1, 'unit', 'centimeters', 'position',[2 2 26  15], 'paperpositionmode', 'auto', 'color', 'w')
            StrictSymbol = 'o';
            LooseSymbol = 's';
            CIColor = [0 0 0];

            ylevel = 1.25;
            xlevel = 1.2;

            ha_RT1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', [0.1 0.8], ...
                'xtick',[0.2:0.2:0.8], 'ylim', [0.1 0.8],'ytick', [0:0.2:1], 'ticklength', [0.02 0.1]);
            line([0 1], [0 1], 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            xlabel('Pre lesion RT (sec)')
            ylabel('Post lesion RT (sec)')

            for i =1:length(obj.MixedFP)
                line(obj.RTLesionResultTable.PreLesionSessions_RTMedianCI95_Strict{i}, obj.RTLesionResultTable.PostLesionSessions_RTMedian_Strict(i)*[1 1], 'linewidth', 1.0, 'color',CIColor);
                line(obj.RTLesionResultTable.PreLesionSessions_RTMedian_Strict(i)*[1 1], obj.RTLesionResultTable.PostLesionSessions_RTMedianCI95_Strict{i}, 'linewidth', 1.0, 'color', CIColor);
                line(obj.RTLesionResultTable.PreLesionSessions_RTMedianCI95_Loose{i}, obj.RTLesionResultTable.PostLesionSessions_RTMedian_Loose(i)*[1 1], 'linewidth', 1.0, 'color', CIColor);
                line(obj.RTLesionResultTable.PreLesionSessions_RTMedian_Loose(i)*[1 1], obj.RTLesionResultTable.PostLesionSessions_RTMedianCI95_Loose{i}, 'linewidth', 1.0, 'color', CIColor);
            end;

            MarkerAlpha = 0.5;

            for i =1:length(obj.MixedFP)
                MarkerSize = 35+35*(i-1);
                scatter(obj.RTLesionResultTable.PreLesionSessions_RTMedian_Strict(i), obj.RTLesionResultTable.PostLesionSessions_RTMedian_Strict(i), ...
                    'Marker', StrictSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
                scatter(obj.RTLesionResultTable.PreLesionSessions_RTMedian_Loose(i), obj.RTLesionResultTable.PostLesionSessions_RTMedian_Loose(i), ...
                    'Marker', LooseSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            end;

            scatter(0.7, 0.3, 'Marker', StrictSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.75, 0.3, 'Strict', 'fontName', 'dejavu sans', 'fontsize', 8)
            scatter(0.7, 0.25, 'Marker', LooseSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.75, 0.25, 'Loose', 'fontName', 'dejavu sans', 'fontsize' , 8)
            title(sprintf('Pre/Post %2.0d/%2.0d sessions', length(obj.PreLesionSessions),  length(obj.PostLesionSessions)),'fontsize', 8, 'FontWeight','bold','FontName','dejavu sans')

             % Based on Trials
            xlevel = xlevel +7.5;
            ha_RT2 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', [0.1 0.8], ...
                'xtick',[0.2:0.2:0.8], 'ylim', [0.1 0.8],'ytick', [0:0.2:1], 'ticklength', [0.02 0.1]);
            line([0 1], [0 1], 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            xlabel('Pre lesion RT (sec)')
            ylabel('Post lesion RT (sec)')
            for i =1:length(obj.MixedFP)
                line(obj.RTLesionResultTable.PreLesionTrials_RTMedianCI95_Strict{i}, obj.RTLesionResultTable.PostLesionTrials_RTMedian_Strict(i)*[1 1], 'linewidth', 1.0, 'color',CIColor);
                line(obj.RTLesionResultTable.PreLesionTrials_RTMedian_Strict(i)*[1 1], obj.RTLesionResultTable.PostLesionTrials_RTMedianCI95_Strict{i}, 'linewidth', 1.0, 'color', CIColor);
                line(obj.RTLesionResultTable.PreLesionTrials_RTMedianCI95_Loose{i}, obj.RTLesionResultTable.PostLesionTrials_RTMedian_Loose(i)*[1 1], 'linewidth', 1.0, 'color', CIColor);
                line(obj.RTLesionResultTable.PreLesionTrials_RTMedian_Loose(i)*[1 1], obj.RTLesionResultTable.PostLesionTrials_RTMedianCI95_Loose{i}, 'linewidth', 1.0, 'color', CIColor);
            end;

            MarkerAlpha = 0.5;
            for i =1:length(obj.MixedFP)
                MarkerSize = 35+35*(i-1);
                scatter(obj.RTLesionResultTable.PreLesionTrials_RTMedian_Strict(i), obj.RTLesionResultTable.PostLesionTrials_RTMedian_Strict(i), ...
                    'Marker', StrictSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', TrialsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
                scatter(obj.RTLesionResultTable.PreLesionTrials_RTMedian_Loose(i), obj.RTLesionResultTable.PostLesionTrials_RTMedian_Loose(i), ...
                    'Marker', LooseSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', TrialsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            end;

            scatter(0.7, 0.3, 'Marker', StrictSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', TrialsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.75, 0.3, 'Strict', 'fontName', 'dejavu sans', 'fontsize', 8)
            scatter(0.7, 0.25, 'Marker', LooseSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', TrialsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.75, 0.25, 'Loose', 'fontName', 'dejavu sans', 'fontsize' , 8)
            title(sprintf('Pre/Post %2.0d/%2.0d trials', (obj.PreLesionTrialNum),  (obj.PostLesionTrialNum)),'fontsize', 8, 'FontWeight','bold','FontName','dejavu sans')

            xlevel = xlevel +7.5;
            maxFWHM = max(1, max(cell2mat(obj.FWHM_HoldT_Lesion(:,2))));
            ha_FWHM1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[xlevel ylevel 5 5], 'xlim', [0 maxFWHM], ...
                'xtick',[0:0.2:5], 'ylim', [0 maxFWHM],'ytick', [0:0.2:5], 'ticklength', [0.02 0.1]);
            line([0 maxFWHM], [0 maxFWHM], 'linestyle','-.', 'linewidth', 1, 'color', [0.6 0.6 0.6])
            xlabel('Pre lesion FWHM (sec)')
            ylabel('Post lesion FWHM (sec)')
            SessionsSymbol = 'd';
            TrialsSymbol = 'o';
            MarkerAlpha = 0.6;

            for i =1:length(obj.MixedFP)

                MarkerSize = 35+35*(i-1);
                iPreLesion = ['PreLesion_Sessions_' num2str(obj.MixedFP(i))];
                IndPre = strcmp(obj.FWHM_HoldT_Lesion(:, 1), iPreLesion);
                iPostLesion = ['PostLesion_Sessions_' num2str(obj.MixedFP(i))];
                IndPost = strcmp(obj.FWHM_HoldT_Lesion(:, 1), iPostLesion);

                scatter(obj.FWHM_HoldT_Lesion{IndPre, 2}, obj.FWHM_HoldT_Lesion{IndPost, 2}, ...
                    'Marker', SessionsSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

                iPreLesion = ['PreLesion_Trials_' num2str(obj.MixedFP(i))];
                IndPre = strcmp(obj.FWHM_HoldT_Lesion(:, 1), iPreLesion);
                iPostLesion = ['PostLesion_Trials_' num2str(obj.MixedFP(i))];
                IndPost = strcmp(obj.FWHM_HoldT_Lesion(:, 1), iPostLesion);

                scatter(obj.FWHM_HoldT_Lesion{IndPre, 2}, obj.FWHM_HoldT_Lesion{IndPost, 2}, ...
                    'Marker', TrialsSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                    'MarkerFaceColor',TrialsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);

            end;

            scatter(0.8, 0.1+0.1*maxFWHM, 'Marker', SessionsSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', SessionsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.85, 0.1+0.1*maxFWHM, 'Sessions', 'fontName', 'dejavu sans', 'fontsize', 8)
            scatter(0.8, 0.1, 'Marker', TrialsSymbol, 'SizeData', MarkerSize, 'LineWidth', 1, ...
                'MarkerFaceColor', TrialsCol, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha',MarkerAlpha);
            text(0.85, 0.1, 'Trials', 'fontName', 'dejavu sans', 'fontsize' , 8)

            ylevel2 = 9;

            ha1s = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[1.2 ylevel2 5 5], 'xlim', [0 3], 'xtick', [0:0.5:3], 'ylim', [0 5], 'ticklength', [0.02 0.1]);

            xlabel('Hold duration (s)')
            ylabel('PDF (1/s)')

            ha1t = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[1.2+13 ylevel2 5 5], 'xlim', [0 3], 'xtick', [0:0.5:3], 'ylim', [0 5], 'ticklength', [0.02 0.1]);

            xlabel('Hold duration (s)')
            ylabel('PDF (1/s)')

            ToPlotSession = 'Sessions';
            ToPlotTrial       = 'Trials';

            maxPDF = 5;

            for i =1:length(FPs)
                % Sessions
                columnName = ['PreLesion_' ToPlotSession '_' num2str(FPs(i))];
                iPDF_Pre = eval(['obj.PDF_HoldT_Lesion.' columnName]);
                plot(ha1s, tBins,iPDF_Pre, 'color', colors{1}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
                maxPDF = max(maxPDF, max(iPDF_Pre));

                columnName = ['PostLesion_' ToPlotSession '_' num2str(FPs(i))];
                iPDF_Post = eval(['obj.PDF_HoldT_Lesion.' columnName]);
                plot(ha1s, tBins,iPDF_Post, 'color', colors{2}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
                maxPDF = max(maxPDF, max(iPDF_Post));

                % Trials
                columnName = ['PreLesion_' ToPlotTrial '_' num2str(FPs(i))];
                iPDF_Pre = eval(['obj.PDF_HoldT_Lesion.' columnName]);
                plot(ha1t, tBins,iPDF_Pre, 'color', colors{1}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
                maxPDF = max(maxPDF, max(iPDF_Pre));

                columnName = ['PostLesion_' ToPlotTrial '_' num2str(FPs(i))];
                iPDF_Post = eval(['obj.PDF_HoldT_Lesion.' columnName]);
                plot(ha1t, tBins,iPDF_Post, 'color', colors{2}, 'linewidth', 2, 'linestyle', obj.FPLineStyles{i});
                maxPDF = max(maxPDF, max(iPDF_Post));
            end;

            set(ha1s, 'ylim', [0, maxPDF])
            set(ha1t, 'ylim', [0, maxPDF])

            for k =1:length(FPs)    % first, draw FPs
                line(ha1s, [FPs(k) FPs(k)]/1000,  [0 maxPDF],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;

            for k =1:length(FPs)    % first, draw FPs
                line(ha1t, [FPs(k) FPs(k)]/1000,  [0 maxPDF],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;

            % add legend
            line(ha1s, [2.5 2.8]-0.5, [4.5 4.5], 'color', colors{1}, 'linewidth', 2)
            text(ha1s, 2.85-0.5, 4.5, 'Pre-lesion', 'fontname', 'dejavu sans','fontsize',  7);

            line(ha1s, [2.5 2.8]-0.5, [4 4], 'color', colors{2}, 'linewidth', 2)
            text(ha1s, 2.85-0.5, 4, 'Post-lesion', 'fontname', 'dejavu sans','fontsize',  7);
            % Plot data in a violin plot to show all data points

            HoldTimeMax = 3;

            ha2s = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[7.5 ylevel2 5 5], 'xlim', [0 length(FPs)*2+1], 'xtick', [0:1:6], 'ylim', [0 HoldTimeMax], 'ticklength', [0.02 0.1], ...
                'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

            ha2t = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[7.5+13 ylevel2 5 5], 'xlim', [0 length(FPs)*2+1], 'xtick', [0:1:6], 'ylim', [0 HoldTimeMax], 'ticklength', [0.02 0.1], ...
                'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

            % Violinplot based on sessions
            HoldTimeAll = [];
            HoldTimeFPType = [];
            acc = 0;

            for k =1:length(FPs)
                acc = acc + 1;
                % pre
                fieldName = ['HoldT_PreLesion_' ToPlotSession];
                HoldTk = eval(['obj.' fieldName '{' num2str(k) '}']);

                HoldTimeAll = [HoldTimeAll HoldTk];
                HoldTimeFPType = [HoldTimeFPType acc*ones(1, length(HoldTk))];

                acc = acc + 1;
                % post
                fieldName = ['HoldT_PostLesion_' ToPlotSession];
                HoldTk = eval(['obj.' fieldName '{' num2str(k) '}']);
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

                hVio1(iv).ScatterPlot.MarkerFaceAlpha = 0.35;
                hVio1(iv).ViolinPlot.LineWidth  = 0.5;
                hVio1(iv).ScatterPlot.SizeData = 6;
                hVio1(iv).BoxPlot.LineWidth = 1;
                hVio1(iv).BoxColor = [0.8 0 0.2];
                hVio1(iv).ViolinPlot.FaceColor = [0.8 0.8 0.8];
            end;

            for k =1:length(obj.MixedFP)
                line([-0.4 1.4]+1+2*(k-1), [FPs(k) FPs(k)]/1000,  'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;
            set(gca, 'xticklabel', num2cell(obj.MixedFP), 'box', 'off', 'xlim', [0.5 2*length(obj.MixedFP)+.5])
            xlabel('FP (ms)')
            ylabel('Hold time (s)')

            uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized', 'position', [0.15 0.95 0.75 0.04],...
                'string', [obj.Subject{1} ' | Pre-vs-Post lesion' ' | ' 'FixedSessions: ' num2str(length(obj.PreLesionSessions)) '/' num2str(length(obj.PostLesionSessions))], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 8, 'horizontalalignment', 'left');

%        Violinplot based on trials 
            HoldTimeAll = [];
            HoldTimeFPType = [];
            acc = 0;

            for k =1:length(FPs)
                acc = acc + 1;
                % pre
                fieldName = ['HoldT_PreLesion_' ToPlotTrial];
                HoldTk = eval(['obj.' fieldName '{' num2str(k) '}']);
                HoldTimeAll = [HoldTimeAll HoldTk];
                HoldTimeFPType = [HoldTimeFPType acc*ones(1, length(HoldTk))];

                acc = acc + 1;
                % post
                fieldName = ['HoldT_PostLesion_' ToPlotTrial];
                HoldTk = eval(['obj.' fieldName '{' num2str(k) '}']);
                HoldTimeAll = [HoldTimeAll HoldTk];
                HoldTimeFPType = [HoldTimeFPType acc*ones(1, length(HoldTk))];

            end;

            axes(ha2t)
            hVio1 = violinplot(HoldTimeAll,  HoldTimeFPType, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false,'Bandwidth', 0.2);

            for iv =1:length(hVio1)
                if rem(iv, 2)~=0
                    hVio1(iv).EdgeColor = 'k';
                    hVio1(iv).ScatterPlot.MarkerFaceColor =colors{1};
                else
                    hVio1(iv).EdgeColor ='k';
                    hVio1(iv).ScatterPlot.MarkerFaceColor =colors{2};
                end;

                hVio1(iv).ScatterPlot.MarkerFaceAlpha = 0.35;
                hVio1(iv).ViolinPlot.LineWidth  = 0.5;
                hVio1(iv).ScatterPlot.SizeData = 6;
                hVio1(iv).BoxPlot.LineWidth = 1;
                hVio1(iv).BoxColor = [0.8 0 0.2];
                hVio1(iv).ViolinPlot.FaceColor = [0.8 0.8 0.8];
            end;

            for k =1:length(obj.MixedFP)
                line([-0.4 1.4]+1+2*(k-1), [FPs(k) FPs(k)]/1000,  'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;
            set(gca, 'xticklabel', num2cell(obj.MixedFP), 'box', 'off', 'xlim', [0.5 2*length(obj.MixedFP)+.5])
            xlabel('FP (ms)')
            ylabel('Hold time (s)')

            RT_Range = [0 600];
            % Plot reaction time in a diagonal plot
            ha3 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',[27 1.2 5 5], 'xlim', RT_Range, 'xtick', [0:200:1000], ...
                'ylim', RT_Range, 'xtick', [0:200:1000], 'ticklength', [0.02 0.1], ...
                'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

            uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized', 'position', [0.65 0.95 0.75 0.04],...
                'string', [obj.Subject{1} ' | Pre-vs-Post lesion' ' | ' 'FixedTrials: ' num2str(obj.PreLesionTrialNum) '/' num2str(obj.PostLesionTrialNum)], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 8, 'horizontalalignment', 'left');

        end;

        function value = get.RT_Chemo(obj)
            if isempty(obj.TreatmentSessions)
                clc
                disp('No chemo data available!')
                value = [];
            else
                % Reaction time
                RT            =        cell(1, 2); % Saline, DCZ
                if sum(strcmp(obj.Control, 'NaN'))>0
                    Ind_Control          =        (transpose(strcmp(obj.TreatmentTrials, 'Saline')|strcmp(obj.TreatmentTrials, 'NaN')) & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
                else
                    Ind_Control          =        (transponse(strcmp(obj.TreatmentTrials, 'Saline')) & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
                end;
                Ind_DCZ               =        (transpose(strcmp(obj.TreatmentSessions, 'DCZ'))& transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
                RT{1}                    =          obj.ReactionTime(Ind_Control);
                RT{2}                    =          obj.ReactionTime(Ind_DCZ);
                value                     =          RT;
            end;
        end;

        function value = get.RT_PreLesion_Sessions(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                RT = cell(2, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PreLesionSessions) & (transpose(strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late'))) & obj.Stage == 1;
                    RT{2, iFP} = obj.ReactionTime(Ind_PreLesionTrials);
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PreLesionSessions) & (transpose(strcmp(obj.Outcome, 'Correct'))) & obj.Stage == 1;
                    RT{1, iFP} = obj.ReactionTime(Ind_PreLesionTrials);
                end;
                value = RT;
            end;
        end;

        function value = get.HoldT_PreLesion_Sessions(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                HoldT = cell(1, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PreLesionSessions) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1;
                    HoldT{iFP} = obj.ReleaseTime(Ind_PreLesionTrials) - obj.PressTime(Ind_PreLesionTrials);
                end;
                value = HoldT;
            end;
        end;

        function value = get.RT_PostLesion_Sessions(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                RT = cell(1, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PostLesionSessions) & (transpose(strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late'))) & obj.Stage == 1;
                    RT{2, iFP} = obj.ReactionTime(Ind_PostLesionTrials);
                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PostLesionSessions) & (transpose(strcmp(obj.Outcome, 'Correct'))) & obj.Stage == 1;
                    RT{1, iFP} = obj.ReactionTime(Ind_PostLesionTrials);
                end;
                value = RT;
            end;
        end;

        function value = get.HoldT_PostLesion_Sessions(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                HoldT = cell(1, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PostLesionSessions) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1;
                    HoldT{iFP} = obj.ReleaseTime(Ind_PostLesionTrials) - obj.PressTime(Ind_PostLesionTrials);
                end;
                value = HoldT;
            end;
        end;

        function value = get.IndexPreLesionTrials(obj)
            % First, figure out the index of prelesion trials
                NtrialsPre                               =           obj.PreLesionTrialNum;
                ListPre                                     =           find(obj.LesionTrials<0 & obj.Stage == 1 & transpose(~strcmp(obj.Outcome, 'Dark')));
                IndPreSelected                      =           ListPre(end-NtrialsPre+1:end);
                Index                                       =           zeros(1, length(obj.ReactionTime));
                Index(IndPreSelected)         =             1;
                value                                       =            Index;
        end;


        function value = get.PerformanceChemoResultTable(obj)

            if sum(obj.IndexSessionsChemo)==0
                value = [];
                return;
            else

                OutComeControl = cell(1, length(obj.MixedFP));
                OutComeChemo= cell(1, length(obj.MixedFP));

                % Sessions
                Control_CorrectRatio            =              zeros(length(obj.MixedFP)+1, 1);
                Control_PrematureRatio       =               zeros(length(obj.MixedFP)+1, 1);
                Control_LateRatio                 =               zeros(length(obj.MixedFP)+1, 1);

                Chemo_CorrectRatio            =              zeros(length(obj.MixedFP)+1, 1);
                Chemo_PrematureRatio       =               zeros(length(obj.MixedFP)+1, 1);
                Chemo_LateRatio                 =               zeros(length(obj.MixedFP)+1, 1);

                for iFP = 1:length(obj.MixedFP)
                    IndexControlTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')') & obj.FP == obj.MixedFP(iFP);
                    OutComeControl{iFP}     = obj.Outcome(IndexControlTrials);

                    Control_CorrectRatio(iFP)         =            sum(strcmp(OutComeControl{iFP}, 'Correct'))/length(OutComeControl{iFP});
                    Control_PrematureRatio(iFP)    =            sum(strcmp(OutComeControl{iFP}, 'Premature'))/length(OutComeControl{iFP});
                    Control_LateRatio(iFP)              =            sum(strcmp(OutComeControl{iFP}, 'Late'))/length(OutComeControl{iFP});


                    IndexChemoTrials          =       ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')') & obj.FP == obj.MixedFP(iFP);
                    OutComeChemo{iFP}     = obj.Outcome(IndexChemoTrials);

                    Chemo_CorrectRatio(iFP)         =            sum(strcmp(OutComeChemo{iFP}, 'Correct'))/length(OutComeChemo{iFP});
                    Chemo_PrematureRatio(iFP)    =            sum(strcmp(OutComeChemo{iFP}, 'Premature'))/length(OutComeChemo{iFP});
                    Chemo_LateRatio(iFP)              =            sum(strcmp(OutComeChemo{iFP}, 'Late'))/length(OutComeChemo{iFP});

                end;

                OutComeControl_All  =  obj.Outcome(ismember(obj.SessionIndex, find(obj.IndexSessionsControl)) & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')'));
                OutComeChemo_All = obj.Outcome(ismember(obj.SessionIndex, find(obj.IndexSessionsChemo)) & obj.Stage == 1 & (~strcmp(obj.Outcome, 'Dark')'));
                
                Control_CorrectRatio(end)         =            sum(strcmp(OutComeControl_All, 'Correct'))/length(OutComeControl_All);
                Control_PrematureRatio(end)    =            sum(strcmp(OutComeControl_All, 'Premature'))/length(OutComeControl_All);
                Control_LateRatio(end)              =            sum(strcmp(OutComeControl_All, 'Late'))/length(OutComeControl_All);

                Chemo_CorrectRatio(end)         =            sum(strcmp(OutComeChemo_All, 'Correct'))/length(OutComeChemo_All);
                Chemo_PrematureRatio(end)    =            sum(strcmp(OutComeChemo_All, 'Premature'))/length(OutComeChemo_All);
                Chemo_LateRatio(end)              =            sum(strcmp(OutComeChemo_All, 'Late'))/length(OutComeChemo_All);

                FP_Types = [transpose(num2cell(obj.MixedFP)); 'All'];

                Performance_Table = table(FP_Types, ...
                    Control_CorrectRatio, Control_PrematureRatio, Control_LateRatio, ...
                    Chemo_CorrectRatio, Chemo_PrematureRatio,Chemo_LateRatio);                
                value = Performance_Table;      
            end;
        end;


        function value = get.PerformanceLesionResultTable(obj)
            % Look at pre and post lesion trials/sessions as a whole to
            % determine performance score
            % by Sessions

            if isempty(obj.LesionSessions)
                value = [];
                return;
            else
                OutComePreLesion = cell(1, length(obj.MixedFP));
                OutComePostLesion= cell(1, length(obj.MixedFP));

                % Sessions
                PreLesionSessions_CorrectRatio            =              zeros(length(obj.MixedFP)+1, 1);
                PreLesionSessions_PrematureRatio       =               zeros(length(obj.MixedFP)+1, 1);
                PreLesionSessions_LateRatio                 =               zeros(length(obj.MixedFP)+1, 1);

                PostLesionSessions_CorrectRatio            =              zeros(length(obj.MixedFP)+1, 1);
                PostLesionSessions_PrematureRatio       =               zeros(length(obj.MixedFP)+1, 1);
                PostLesionSessions_LateRatio                 =               zeros(length(obj.MixedFP)+1, 1);

                for iFP = 1:length(obj.MixedFP)
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PreLesionSessions) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1;
                    OutComePreLesion{iFP} = obj.Outcome(Ind_PreLesionTrials);
                    
                    PreLesionSessions_CorrectRatio(iFP)         =            sum(strcmp(OutComePreLesion{iFP}, 'Correct'))/length(OutComePreLesion{iFP});
                    PreLesionSessions_PrematureRatio(iFP)    =            sum(strcmp(OutComePreLesion{iFP}, 'Premature'))/length(OutComePreLesion{iFP});
                    PreLesionSessions_LateRatio(iFP)              =            sum(strcmp(OutComePreLesion{iFP}, 'Late'))/length(OutComePreLesion{iFP});

                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) &  ismember(obj.LesionTrials, obj.PostLesionSessions) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1;
                    OutComePostLesion{iFP} = obj.Outcome(Ind_PostLesionTrials);

                    PostLesionSessions_CorrectRatio(iFP)         =            sum(strcmp(OutComePostLesion{iFP}, 'Correct'))/length(OutComePostLesion{iFP});
                    PostLesionSessions_PrematureRatio(iFP)    =            sum(strcmp(OutComePostLesion{iFP}, 'Premature'))/length(OutComePostLesion{iFP});
                    PostLesionSessions_LateRatio(iFP)              =            sum(strcmp(OutComePostLesion{iFP}, 'Late'))/length(OutComePostLesion{iFP});
                end;

                OutComePreLesion_All  = obj.Outcome(ismember(obj.LesionTrials, obj.PreLesionSessions) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1);
                OutComePostLesion_All = obj.Outcome(ismember(obj.LesionTrials, obj.PostLesionSessions) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1);

                PreLesionSessions_CorrectRatio(end)         =            sum(strcmp(OutComePreLesion_All, 'Correct'))/length(OutComePreLesion_All);
                PreLesionSessions_PrematureRatio(end)    =            sum(strcmp(OutComePreLesion_All, 'Premature'))/length(OutComePreLesion_All);
                PreLesionSessions_LateRatio(end)              =            sum(strcmp(OutComePreLesion_All, 'Late'))/length(OutComePreLesion_All);

                PostLesionSessions_CorrectRatio(end)         =            sum(strcmp(OutComePostLesion_All, 'Correct'))/length(OutComePostLesion_All);
                PostLesionSessions_PrematureRatio(end)    =            sum(strcmp(OutComePostLesion_All, 'Premature'))/length(OutComePostLesion_All);
                PostLesionSessions_LateRatio(end)              =            sum(strcmp(OutComePostLesion_All, 'Late'))/length(OutComePostLesion_All);

                % Trials
                PreLesionTrials_CorrectRatio            =              zeros(length(obj.MixedFP)+1, 1);
                PreLesionTrials_PrematureRatio       =               zeros(length(obj.MixedFP)+1, 1);
                PreLesionTrials_LateRatio                 =               zeros(length(obj.MixedFP)+1, 1);

                PostLesionTrials_CorrectRatio            =              zeros(length(obj.MixedFP)+1, 1);
                PostLesionTrials_PrematureRatio       =               zeros(length(obj.MixedFP)+1, 1);
                PostLesionTrials_LateRatio                 =               zeros(length(obj.MixedFP)+1, 1);

                for iFP = 1:length(obj.MixedFP)
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) & obj.IndexPreLesionTrials & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1;
                    OutComePreLesion{iFP} = obj.Outcome(Ind_PreLesionTrials);
                    
                    PreLesionTrials_CorrectRatio(iFP)         =            sum(strcmp(OutComePreLesion{iFP}, 'Correct'))/length(OutComePreLesion{iFP});
                    PreLesionTrials_PrematureRatio(iFP)    =            sum(strcmp(OutComePreLesion{iFP}, 'Premature'))/length(OutComePreLesion{iFP});
                    PreLesionTrials_LateRatio(iFP)              =            sum(strcmp(OutComePreLesion{iFP}, 'Late'))/length(OutComePreLesion{iFP});

                    if ~isempty(obj.IndexPostLesionTrials )
                        Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) & obj.IndexPostLesionTrials  & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1;
                        OutComePostLesion{iFP} = obj.Outcome(Ind_PostLesionTrials);

                        PostLesionTrials_CorrectRatio(iFP)         =            sum(strcmp(OutComePostLesion{iFP}, 'Correct'))/length(OutComePostLesion{iFP});
                        PostLesionTrials_PrematureRatio(iFP)    =            sum(strcmp(OutComePostLesion{iFP}, 'Premature'))/length(OutComePostLesion{iFP});
                        PostLesionTrials_LateRatio(iFP)              =            sum(strcmp(OutComePostLesion{iFP}, 'Late'))/length(OutComePostLesion{iFP});
                    else
                        PostLesionTrials_CorrectRatio(iFP)         =            NaN;
                        PostLesionTrials_PrematureRatio(iFP)    =            NaN;
                        PostLesionTrials_LateRatio(iFP)              =            NaN;
                    end;
                end;

                OutComePreLesion_All  = obj.Outcome(obj.IndexPreLesionTrials & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1);
                
                                PreLesionTrials_CorrectRatio(end)         =            sum(strcmp(OutComePreLesion_All, 'Correct'))/length(OutComePreLesion_All);
                PreLesionTrials_PrematureRatio(end)    =            sum(strcmp(OutComePreLesion_All, 'Premature'))/length(OutComePreLesion_All);
                PreLesionTrials_LateRatio(end)              =            sum(strcmp(OutComePreLesion_All, 'Late'))/length(OutComePreLesion_All);


                if ~isempty(obj.IndexPostLesionTrials)
                OutComePostLesion_All = obj.Outcome(obj.IndexPostLesionTrials & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1);

                PostLesionTrials_CorrectRatio(end)         =            sum(strcmp(OutComePostLesion_All, 'Correct'))/length(OutComePostLesion_All);
                PostLesionTrials_PrematureRatio(end)    =            sum(strcmp(OutComePostLesion_All, 'Premature'))/length(OutComePostLesion_All);
                PostLesionTrials_LateRatio(end)              =            sum(strcmp(OutComePostLesion_All, 'Late'))/length(OutComePostLesion_All);

                else
                PostLesionTrials_CorrectRatio(end)         =            NaN;
                PostLesionTrials_PrematureRatio(end)    =            NaN;
                PostLesionTrials_LateRatio(end)              =            NaN;

                end;
                Performance_Table = table( ...
                    PreLesionSessions_CorrectRatio, PostLesionSessions_CorrectRatio, ...
                    PreLesionSessions_PrematureRatio, PostLesionSessions_PrematureRatio, ...
                    PreLesionSessions_LateRatio, PostLesionSessions_LateRatio, ...
                    PreLesionTrials_CorrectRatio, PostLesionTrials_CorrectRatio, ...
                    PreLesionTrials_PrematureRatio, PostLesionTrials_PrematureRatio, ...
                    PreLesionTrials_LateRatio, PostLesionTrials_LateRatio);                
                value = Performance_Table;      
            end;
        end;


        function value = get.RT_PreLesion_Trials(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                Index = obj.IndexPreLesionTrials;
                RT = cell(2, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) & (transpose(strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late'))) & obj.Stage == 1 & Index==1;
                    RT{2, iFP} = obj.ReactionTime(Ind_PreLesionTrials);
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) &  (transpose(strcmp(obj.Outcome, 'Correct'))) & obj.Stage == 1 & Index==1;
                    RT{1, iFP} = obj.ReactionTime(Ind_PreLesionTrials);
                end;
                value = RT;
            end;
        end;

        function value = get.HoldT_PreLesion_Trials(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                Index = obj.IndexPreLesionTrials;
                HoldT = cell(1, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PreLesionTrials =  obj.FP == obj.MixedFP(iFP) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1 & Index==1;
                    HoldT{iFP} = obj.ReleaseTime(Ind_PreLesionTrials) - obj.PressTime(Ind_PreLesionTrials);
                end;
                value = HoldT;
            end;
        end;

        function value = get.IndexPostLesionTrials(obj)
            % First, figure out the index of prelesion trials
            NtrialsPost                              =           obj.PostLesionTrialNum;
            ListPost                                    =           find(obj.LesionTrials>0 & obj.Stage == 1 & transpose(~strcmp(obj.Outcome, 'Dark')));
            if ~isempty(ListPost)
                IndPostSelected                      =           ListPost(1:NtrialsPost);
                Index                                       =           zeros(1, length(obj.ReactionTime));
                Index(IndPostSelected)         =             1;
            else
                Index = [];
            end;
            value                                       =            Index;
        end;

        function value = get.RT_PostLesion_Trials(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                Index = obj.IndexPostLesionTrials;
                RT = cell(2, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) & (transpose(strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late'))) & obj.Stage == 1 & Index==1;
                    RT{2, iFP} = obj.ReactionTime(Ind_PostLesionTrials);
                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) & (transpose(strcmp(obj.Outcome, 'Correct'))) & obj.Stage == 1 & Index==1;
                    RT{1, iFP} = obj.ReactionTime(Ind_PostLesionTrials);
                end;
                value = RT;
            end;
        end;

        function value = get.HoldT_PostLesion_Trials(obj)
            if isempty(obj.LesionSessions)
                value = [];
            else
                Index = obj.IndexPostLesionTrials;
                HoldT = cell(1, length(obj.MixedFP));
                for iFP = 1:length(obj.MixedFP)
                    Ind_PostLesionTrials =  obj.FP == obj.MixedFP(iFP) & transpose(~strcmp(obj.Outcome, 'Dark')) & obj.Stage == 1 & Index==1;
                    HoldT{iFP} = obj.ReleaseTime(Ind_PostLesionTrials) - obj.PressTime(Ind_PostLesionTrials);
                end;
                value = HoldT;
            end;
        end;

        function value = get.PDF_RT_Lesion(obj)
            %     RT_PreLesion_Sessions
            %     RT_PostLesion_Sessions
            %     RT_PreLesion_Trials
            %     RT_PostLesion_Trials

            RT_Table = table(obj.RTbinEdges', 'VariableNames', {'RTbinEdges'});
            for i =1:size(obj.RT_PreLesion_Sessions, 1)
                for j = 1:size(obj.RT_PreLesion_Sessions, 2)
                    FP_ij                                                 =         obj.MixedFP(j);
                    PDF_ij                                              =         transpose(ksdensity(obj.RT_PreLesion_Sessions{i, j}, obj.RTbinEdges, 'function', 'pdf'));
                    if i ==1
                        ColumnName                                 =        ['PreLesionStandard_Sessions_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PreLesionLoose_Sessions_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=PDF_ij;']);
                end;
            end;
            for i =1:size(obj.RT_PostLesion_Sessions, 1)
                for j = 1:size(obj.RT_PostLesion_Sessions, 2)
                     FP_ij                                                 =         obj.MixedFP(j);
                    PDF_ij                                              =         transpose(ksdensity(obj.RT_PostLesion_Sessions{i, j}, obj.RTbinEdges, 'function', 'pdf'));
                    if i ==1
                        ColumnName                                 =        ['PostLesionStandard_Sessions_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PostLesionLoose_Sessions_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=PDF_ij;']);
                end;
            end;
            for i =1:size(obj.RT_PreLesion_Trials, 1)
                for j = 1:size(obj.RT_PreLesion_Trials, 2)
                     FP_ij                                                 =         obj.MixedFP(j);
                    PDF_ij                                               =         transpose(ksdensity(obj.RT_PreLesion_Trials{i, j}, obj.RTbinEdges, 'function', 'pdf'));
                    if i ==1
                        ColumnName                                 =        ['PreLesionStandard_Trials_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PreLesionLoose_Trials_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=PDF_ij;']);
                end;
            end;
            for i =1:size(obj.RT_PostLesion_Trials, 1)
                for j = 1:size(obj.RT_PostLesion_Trials, 2)
                     FP_ij                                                 =         obj.MixedFP(j);
                    PDF_ij                                              =         transpose(ksdensity(obj.RT_PostLesion_Trials{i, j}, obj.RTbinEdges, 'function', 'pdf'));
                    if i ==1
                        ColumnName                                 =        ['PostLesionStandard_Trials_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PostLesionLoose_Trials_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=PDF_ij;']);
                end;
            end;
            value = RT_Table;
        end;

           function value = get.PDF_HoldT_Lesion(obj) % PDF of hold duration in a table 
            %      HoldT_PreLesion_Sessions
            %      HoldT_PostLesion_Sessions
            %      HoldT_PreLesion_Trials
            %      HoldT_PostLesion_Trials
            HoldT_Table = table(obj.HoldTbinEdges', 'VariableNames', {'HoldTbinEdges'});            
            for i =1:length(obj.HoldT_PreLesion_Sessions)
                    FP_i                                                 =         obj.MixedFP(i);
                    PDF_i                                              =         transpose(ksdensity(obj.HoldT_PreLesion_Sessions{i}, obj.HoldTbinEdges, 'function', 'pdf'));
                    ColumnName                                 =        ['PreLesion_Sessions_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=PDF_i;']);
            end;

            for i =1:length(obj.HoldT_PostLesion_Sessions)
                    FP_i                                                 =         obj.MixedFP(i);
                    PDF_i                                              =         transpose(ksdensity(obj.HoldT_PostLesion_Sessions{i}, obj.HoldTbinEdges, 'function', 'pdf'));
                    ColumnName                                 =        ['PostLesion_Sessions_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=PDF_i;']);
            end;

            for i =1:length(obj.HoldT_PreLesion_Trials)
                    FP_i                                                 =         obj.MixedFP(i);
                    PDF_i                                              =         transpose(ksdensity(obj.HoldT_PreLesion_Trials{i}, obj.HoldTbinEdges, 'function', 'pdf'));
                    ColumnName                                 =        ['PreLesion_Trials_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=PDF_i;']);
            end;

            for i =1:length(obj.HoldT_PostLesion_Trials)
                    FP_i                                                 =         obj.MixedFP(i);
                    PDF_i                                              =         transpose(ksdensity(obj.HoldT_PostLesion_Trials{i}, obj.HoldTbinEdges, 'function', 'pdf'));
                    ColumnName                                 =        ['PostLesion_Trials_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=PDF_i;']);
            end;
            value = HoldT_Table;
        end;


           function value = get.CDF_HoldT_Lesion(obj) % CDF of hold duration in a table 
            %      HoldT_PreLesion_Sessions
            %      HoldT_PostLesion_Sessions
            %      HoldT_PreLesion_Trials
            %      HoldT_PostLesion_Trials
            HoldT_Table = table(obj.HoldTbinEdges', 'VariableNames', {'HoldTbinEdges'});            
            for i =1:length(obj.HoldT_PreLesion_Sessions)
                    FP_i                                                 =         obj.MixedFP(i);
                    CDF_i                                              =         transpose(ksdensity(obj.HoldT_PreLesion_Sessions{i}, obj.HoldTbinEdges, 'function', 'cdf'));
                    ColumnName                                 =        ['PreLesion_Sessions_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=CDF_i;']);
            end;

            for i =1:length(obj.HoldT_PostLesion_Sessions)
                    FP_i                                                 =         obj.MixedFP(i);
                    CDF_i                                              =         transpose(ksdensity(obj.HoldT_PostLesion_Sessions{i}, obj.HoldTbinEdges, 'function', 'cdf'));
                    ColumnName                                 =        ['PostLesion_Sessions_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=CDF_i;']);
            end;

            for i =1:length(obj.HoldT_PreLesion_Trials)
                    FP_i                                                 =         obj.MixedFP(i);
                    CDF_i                                              =         transpose(ksdensity(obj.HoldT_PreLesion_Trials{i}, obj.HoldTbinEdges, 'function', 'cdf'));
                    ColumnName                                 =        ['PreLesion_Trials_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=CDF_i;']);
            end;

            for i =1:length(obj.HoldT_PostLesion_Trials)
                    FP_i                                                 =         obj.MixedFP(i);
                    CDF_i                                              =         transpose(ksdensity(obj.HoldT_PostLesion_Trials{i}, obj.HoldTbinEdges, 'function', 'cdf'));
                    ColumnName                                 =        ['PostLesion_Trials_' num2str(FP_i)];
                    eval(['HoldT_Table.' ColumnName '=CDF_i;']);
            end;
            value = HoldT_Table;
        end;

        function value = get.CDF_RT_Lesion(obj)
            %     RT_PreLesion_Sessions
            %     RT_PostLesion_Sessions
            %     RT_PreLesion_Trials
            %     RT_PostLesion_Trials
            % compute RT from prelesion lessions

            RT_Table = table(obj.RTbinEdges', 'VariableNames', {'RTbinEdges'});

            for i =1:size(obj.RT_PreLesion_Sessions, 1)
                for j = 1:size(obj.RT_PreLesion_Sessions, 2)
                    FP_ij                                                 =         obj.MixedFP(j);
                    CDF_ij                                              =         transpose(ksdensity(obj.RT_PreLesion_Sessions{i, j}, obj.RTbinEdges, 'function', 'cdf'));
                    if i ==1
                        ColumnName                                 =        ['PreLesionStandard_Sessions_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PreLesionLoose_Sessions_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=CDF_ij;']);
                end;
            end;

            for i =1:size(obj.RT_PostLesion_Sessions, 1)
                for j = 1:size(obj.RT_PostLesion_Sessions, 2)
                     FP_ij                                                 =         obj.MixedFP(j);
                    CDF_ij                                              =         transpose(ksdensity(obj.RT_PostLesion_Sessions{i, j}, obj.RTbinEdges, 'function', 'cdf'));
                    if i ==1
                        ColumnName                                 =        ['PostLesionStandard_Sessions_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PostLesionLoose_Sessions_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=CDF_ij;']);
                end;
            end;

            for i =1:size(obj.RT_PreLesion_Trials, 1)
                for j = 1:size(obj.RT_PreLesion_Trials, 2)
                     FP_ij                                                 =         obj.MixedFP(j);
                    CDF_ij                                               =         transpose(ksdensity(obj.RT_PreLesion_Trials{i, j}, obj.RTbinEdges, 'function', 'cdf'));
                    if i ==1
                        ColumnName                                 =        ['PreLesionStandard_Trials_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PreLesionLoose_Trials_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=CDF_ij;']);
                end;
            end;

            for i =1:size(obj.RT_PostLesion_Trials, 1)
                for j = 1:size(obj.RT_PostLesion_Trials, 2)
                     FP_ij                                                 =         obj.MixedFP(j);
                    CDF_ij                                              =         transpose(ksdensity(obj.RT_PostLesion_Trials{i, j}, obj.RTbinEdges, 'function', 'cdf'));
                    if i ==1
                        ColumnName                                 =        ['PostLesionStandard_Trials_' num2str(FP_ij)];
                    else
                        ColumnName                                 =        ['PostLesionLoose_Trials_' num2str(FP_ij)];
                    end;
                    eval(['RT_Table.' ColumnName '=CDF_ij;']);
                end;
            end; 
            value = RT_Table;
        end;

        function value = get.NewAnalysis(obj)
            value = 'check';
        end;

        function value = get.FWHM_HoldT(obj)
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
 
        function value = get.PerformanceTable_Lesion(obj)
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
        %

        function Save(obj, savepath)
            if nargin<2
                savepath = pwd;
            end
            save(fullfile(savepath, ['SRTGroupClass_' (obj.Subject{1})]),  'obj');

%             filename = ['RTLesionTable.csv'];
%             if ~isempty(obj.RTLesionResultTable)
%                 writetable(obj.RTLesionResultTable,filename)
%             end;

%             filename = ['PerformanceLesionTable.csv'];
%             if ~isempty(obj.PerformanceLesionResultTable)
%                 writetable(obj.RTLesionResultTable,filename)
%             end;


        end

        function Print(obj, targetDir)
            % Check if the standard figure exist
            if ishghandle(obj.Fig1)
                savename = ['Fig1_ResponseTimeDistribution_' upper(obj.Subject{1})];
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
                print (hf,'-djpeg', [savename])
                saveas(hf, savename, 'fig')
            end;

            % Check if the lite figure exist
            if ishghandle(obj.Fig2)
                savename = ['Fig2_Performance_' upper(obj.Subject{1})];
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
                print (hf,'-djpeg', [savename])
                saveas(hf, savename, 'fig')
            end;

            if ishghandle(obj.Fig3)
                savename = ['Fig3_Performance_' upper(obj.Subject{1})];
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
                print (hf,'-djpeg', [savename])
                saveas(hf, savename, 'fig')
            end;

            if ishghandle(obj.Fig5)
                savename = ['Fig5_ChemoPerformance_' upper(obj.Subject{1})];
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
                hf = obj.Fig5;
                print (hf,'-dpng', [savename])
                print (hf,'-djpeg', [savename])
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