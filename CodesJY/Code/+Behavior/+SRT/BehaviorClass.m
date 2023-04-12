classdef BehaviorClass
    % Takes the original bdata from MED, build a class for computing and plotting
    %  Jianing Yu 8/28/2022

    properties

        Subject
        Strain
        Date
        Session
        Protocol
        WinSize
        StepSize
        LesionType
        LesionIndex
        LesionIndexAll % additional lesion performed.
        Treatment
        Dose
        TrialNum
        PressIndex
        PressTime
        ReleaseTime
        FP
        MixedFP
        ToneTime
        ReactionTime
        Outcome
        Experimenter
        RTbinEdges
        HoldTbinEdges
        RTbinCenters
        HoldTbinCenters
        Fig1
        Fig2

    end;

    properties (SetAccess = private)

    end

    properties (Constant)

        PerformanceType = {'Correct', 'Premature', 'Late'}
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
        Performance
        AvgRT
        AvgRTLoose
        PerformanceSlidingWindow
        Stage

        PDF_RT
        PDF_RTLoose
        CDF_RT
        CDF_RTLoose
        PDF_HoldT
        FWHM_HoldT % Full width at half maximum, derived from Gauss model
        CDF_HoldT
        PerformanceTable
        FastResponseRatio
        PDF_HoldT_Gauss
        IQR
        PassedWarmedUp

    end

    methods
        function obj = BehaviorClass(bdata)

            if nargin<1 || isempty(bdata)
                iMED = dir(['*.txt']);
                [~, obj] =Behavior.MED.track_training_progress_advanced(iMED.name);
                return
            end;

            %UNTITLED9 Construct an instance of this class
            %   Detailed explanation goes here
            % number of trials
            obj.TrialNum        =       length(bdata.PressTime);
            obj.PressIndex     =       [1:obj.TrialNum];

            % Session information
            obj.Subject         =       extractAfter(bdata.SessionName, 'Subject ');
            obj.Session        =       extractBefore(bdata.SessionName, '-Subject ');
            obj.Date             =        bdata.Metadata.Date;
            obj.Protocol       =        extractAfter(bdata.Metadata.ProtocolName, 'FR1_');

            % Press
            obj.PressTime = bdata.PressTime;
            obj.ReleaseTime = bdata.ReleaseTime;
            obj.ReactionTime = [];
            obj.ToneTime = [];
            obj.FP = bdata.FPs;

            uFPs = unique(bdata.FPs);
            if any(uFPs == 750)
                obj.MixedFP = [750 1500];
            else
                obj.MixedFP = [500 1000 1500] ; % default, subject to change though.
            end;
            obj.Outcome = [];

            for i =1:length(bdata.PressTime)
                if ~isempty(find(bdata.Correct == i, 1))
                    obj.Outcome{i} = 'Correct';
                    % find tone time
                    obj.ToneTime(i) = bdata.TimeTone(find(bdata.TimeTone-bdata.PressTime(i)>0, 1, 'first'));
                    obj.ReactionTime(i) = obj.ReleaseTime(i) - obj.ToneTime(i);
                elseif  ~isempty(find(bdata.Premature == i, 1))
                    obj.Outcome{i} = 'Premature';
                    obj.ToneTime(i)= -1;
                    obj.ReactionTime(i) = -1;
                elseif ~isempty(find(bdata.Late == i, 1))
                    obj.Outcome{i} = 'Late';
                    obj.ToneTime(i) = bdata.TimeTone(find(bdata.TimeTone-bdata.PressTime(i)>0, 1, 'first'));
                    obj.ReactionTime(i) = obj.ReleaseTime(i) - obj.ToneTime(i);
                elseif ~isempty(find(bdata.Dark == i, 1))
                    obj.Outcome{i} = 'Dark';
                    obj.ToneTime(i)= 0;
                    obj.ReactionTime(i) = 0;
                else
                    obj.Outcome{i} = 'NAN';
                    obj.ToneTime(i)= 0;
                    obj.ReactionTime(i) = 0;
                end;
            end;

            obj.WinSize         =           [];
            obj.StepSize        =           [];

            obj.RTbinEdges                              =          [0:obj.BinSize:2];
            obj.HoldTbinEdges                         =          [0:obj.BinSize:4];
            obj.RTbinCenters                            =           obj.RTbinEdges(1:end-1)+0.5*obj.BinSize;
            obj.HoldTbinCenters                       =            obj.HoldTbinEdges(1:end-1)+0.5*obj.BinSize;

            obj.Fig1 = randperm(100, 1);
            obj.Fig2 = randperm(100, 1);

        end

        function obj = set.Experimenter(obj,person_name)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Experimenter = string(person_name);
        end

        function obj = set.LesionType(obj,lesiontype)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.LesionType = string(lesiontype);
        end


        function obj = set.Strain(obj,strain)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Strain = string(strain);
        end

        function obj = set.MixedFP(obj, FPs)
            % compute mixed FP
            if isnumeric(FPs)
                obj.MixedFP = FPs;
            end;
        end

        function obj = set.WinSize(obj, WinSize)
            if isnumeric(WinSize)
                obj.WinSize = WinSize;
            end;
        end

        function obj = set.StepSize(obj, StepSize)
            if isnumeric(StepSize)
                obj.StepSize = StepSize;
            end;
        end

        function value = get.IQR(obj)
            IQR_Out = NaN*ones(1, length(obj.MixedFP));
            for i =1:length(IQR_Out)
                IndSelected                                      =          find(obj.FP==obj.MixedFP(i) & obj.Stage ==1& ~strcmp(obj.Outcome, 'Dark'));
                HoldTime                                          =          obj.ReleaseTime(IndSelected)- obj.PressTime(IndSelected);
                if ~isempty(HoldTime)
                    IQR_Out(i)                                        =            diff(prctile(HoldTime, [25 75]));
                else
                    IQR_Out(i) = NaN;
                end;
            end;
            value = IQR_Out;
        end;


        function value = get.PDF_RT(obj)         % this is the strict version, only counting correct responses
            PDFOut = cell(1, length(obj.MixedFP));
            for i =1:length(PDFOut)
                RT_Cue                                          =          obj.ReactionTime(obj.FP==obj.MixedFP(i) & obj.Stage ==1& strcmp(obj.Outcome, 'Correct'));
                if ~isempty(RT_Cue)
                    PDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i} = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.PDF_RTLoose(obj)         % this is the loose version,  counting both correct and late responses
            PDFOut = cell(1, length(obj.MixedFP));
            for i =1:length(PDFOut)
                RT_Cue                                          =          obj.ReactionTime(obj.FP==obj.MixedFP(i) & obj.Stage ==1 &  (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
                if ~isempty(RT_Cue)
                    PDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i} = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_RT(obj)         % this is the strict version, only counting correct responses
            CDFOut = cell(1, length(obj.MixedFP));
            for i =1:length(CDFOut)
                RT_Cue                                          =          obj.ReactionTime(obj.FP==obj.MixedFP(i) & obj.Stage ==1& strcmp(obj.Outcome, 'Correct'));
                if ~isempty(RT_Cue)
                    CDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i} = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.CDF_RTLoose(obj)         % this is the loose version,  counting both correct and late responses
            CDFOut = cell(1, length(obj.MixedFP));
            for i =1:length(CDFOut)
                RT_Cue                                          =          obj.ReactionTime(obj.FP==obj.MixedFP(i) & obj.Stage ==1 &  (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
                if ~isempty(RT_Cue)
                    CDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i} = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.CDF_HoldT(obj)
            CDFOut = cell(1, length(obj.MixedFP));
            for i =1:length(CDFOut)
                IndSelected                                      =          find(obj.FP==obj.MixedFP(i) & obj.Stage ==1& ~strcmp(obj.Outcome, 'Dark'));
                HoldTime                                          =          obj.ReleaseTime(IndSelected)- obj.PressTime(IndSelected);
                if ~isempty(HoldTime)
                    CDFOut{i}                                        =            ksdensity(HoldTime, obj.HoldTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i} = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_HoldT(obj)
            PDFOut = cell(1, length(obj.MixedFP));
            for i =1:length(PDFOut)
                IndSelected                                      =          find(obj.FP==obj.MixedFP(i) & obj.Stage ==1& ~strcmp(obj.Outcome, 'Dark'));
                HoldTime                                          =          obj.ReleaseTime(IndSelected)- obj.PressTime(IndSelected);
                if ~isempty(HoldTime)
                    PDFOut{i}                                        =            ksdensity(HoldTime, obj.HoldTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i} = [];
                end;
            end;
            value = PDFOut;
        end;


        function value = get.Stage(obj)
            stage_index = zeros(1, obj.TrialNum);
            if length(obj.MixedFP)>1
                ind_first = find(obj.FP>=max(obj.MixedFP), 1, "first");
                stage_index(ind_first:end) = 1;
                value = stage_index;
            else
                ind_last =  find(abs(diff(obj.FP))~=0, 1, 'last');
                stage_index(ind_last+1:end) = 1;
                value = stage_index;
            end;
        end

        function value = get.PassedWarmedUp(obj)

            if sum(obj.Stage)==0
                value = 0;
            else
                value =1;
            end;
        end;



        function value = get.PerformanceSlidingWindow(obj)

            if isempty(obj.WinSize)
                WinSize = floor(obj.TrialNum/5);
                obj.WinSize = WinSize;
            end;
            WinSize = obj.WinSize;

            if isempty(obj.StepSize)
                StepSize = max(1, floor(WinSize/5));
                obj.StepSize = StepSize;
            end;
            StepSize = obj.StepSize;

            CountStart = 1;
            thisWin = [];

            TrialIndex = [];
            WinPos = [];
            CorrectRatio=[];
            PrematureRatio=[];
            LateRatio=[];

            while CountStart+WinSize < obj.TrialNum
                thisWin                     =           [CountStart:CountStart + WinSize];
                thisOutcome             =           obj.Outcome(thisWin);
                NumOutcome           =           length(thisOutcome) - sum(strcmp(thisOutcome, 'Dark')); % remove Dark trials
                CorrectRatio             =           [CorrectRatio 100*sum(strcmp(thisOutcome, 'Correct'))/NumOutcome];
                PrematureRatio        =           [PrematureRatio 100*sum(strcmp(thisOutcome, 'Premature'))/NumOutcome];
                LateRatio                  =           [LateRatio, 100*sum(strcmp(thisOutcome, 'Late'))/NumOutcome];
                WinPos                     =           [WinPos obj.PressTime(round(median(thisWin)))];
                TrialIndex                  =           [TrialIndex CountStart + floor(WinSize/2)];
                CountStart                =           CountStart + StepSize;

            end;

            sliding_table = table(TrialIndex', WinPos', CorrectRatio', PrematureRatio', LateRatio', 'VariableNames', ...
                {'TrialIndex', 'TimeInSession', 'Correct', 'Premature', 'Late'});
            value = sliding_table;

        end;

        function value = get.Performance(obj)

            Foreperiod          =       [num2cell(obj.MixedFP) 'all']';
            N_press               =        zeros(length(Foreperiod), 1);
            CorrectRatio        =       zeros(length(Foreperiod), 1);
            PrematureRatio  =       zeros(length(Foreperiod), 1);
            LateRatio              =       zeros(length(Foreperiod), 1);

            for i = 1:length(obj.MixedFP)
                n_correct                =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Correct'));
                n_premature          =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Premature'));
                n_late                      =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Late'));
                n_legit                     =       n_correct+n_premature+n_late;
                N_press(i)               =       n_legit;

                CorrectRatio(i)  =  100*n_correct/n_legit;
                PrematureRatio(i)  =  100*n_premature/n_legit;
                LateRatio(i)  =  100*n_late/n_legit;
            end;

            % takes everything
            n_correct            =    sum(strcmp(obj.Outcome, 'Correct'));
            n_premature     =    sum(strcmp(obj.Outcome, 'Premature'));
            n_late                =    sum(strcmp(obj.Outcome, 'Late'));
            n_legit               =    n_correct+n_premature+n_late;
            i = i+1;
            N_press(i)               =       n_legit;
            CorrectRatio(i)  =  100*n_correct/n_legit;
            PrematureRatio(i)  =  100*n_premature/n_legit;
            LateRatio(i)  =  100*n_late/n_legit;
            rt_table = table(Foreperiod, N_press, CorrectRatio, PrematureRatio, LateRatio);
            value = rt_table;
        end

        function value = get.AvgRT(obj)
            % Use calRT to compute RT
            RT.median=[];
            RT.median_ksdensity=[];
            N_press = [];

            for i = 1:length(obj.MixedFP)
                iFP = obj.MixedFP(i);
                ind_press = find(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Correct'));
                HoldDurs = 1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms
                iRTOut = calRT(HoldDurs, iFP, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                N_press(i) = length(HoldDurs);
                RT.median(i) = iRTOut.median;
                RT.median_ksdensity(i) = iRTOut.median_ksdensity;
            end;

            iFP = 'all';
            i=i+1;
            ind_press        =          find(strcmp(obj.Outcome, 'Correct'));
            FPs                   =           obj.FP(ind_press);
            HoldDurs        =           1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms

            iRTOut = calRT(HoldDurs, FPs, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);

            N_press(i) = length(HoldDurs);
            RT.median(i) = iRTOut.median;
            RT.median_ksdensity(i) = iRTOut.median_ksdensity;

            Foreperiod = [num2cell(obj.MixedFP'); {'all'}];
            RT_median = RT.median';
            RT_median_ksdensity = RT.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, N_press, RT_median, RT_median_ksdensity);
            value = rt_table;
        end


        function value = get.AvgRTLoose(obj)
            % Use calRT to compute RT
            RT.median=[];
            RT.median_ksdensity=[];
            N_press = [];
            for i = 1:length(obj.MixedFP)
                iFP = obj.MixedFP(i);
                ind_press = find(obj.FP == obj.MixedFP(i) & (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
                HoldDurs = 1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms
                iRTOut = calRT(HoldDurs, iFP, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                N_press(i) = length(HoldDurs);
                RT.median(i) = iRTOut.median;
                RT.median_ksdensity(i) = iRTOut.median_ksdensity;
            end;

            iFP = 'all';
            i=i+1;
            ind_press        =          find(strcmp(obj.Outcome, 'Correct')|strcmp(obj.Outcome, 'Late'));
            FPs                   =           obj.FP(ind_press);
            HoldDurs        =           1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms

            iRTOut = calRT(HoldDurs, FPs, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            N_press(i) = length(HoldDurs);
            RT.median(i) = iRTOut.median;
            RT.median_ksdensity(i) = iRTOut.median_ksdensity;
            Foreperiod = [num2cell(obj.MixedFP'); {'all'}];
            RT_median = RT.median';
            RT_median_ksdensity = RT.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, N_press, RT_median, RT_median_ksdensity);
            value = rt_table;
        end

        function Save(obj, savepath)
            if nargin<2
                savepath = pwd;
                save(fullfile(savepath, ['BClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]]),  'obj');
            end
        end

        function Print(obj, targetDir)
            % Check if the standard figure exist
            if ishghandle(obj.Fig1)
                savename = ['FigFull_BClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]];
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
                %                 print (hf,'-dpdf', [savename], '-bestfit')
                print (hf,'-dpng', [savename])
                saveas(hf, savename, 'fig')
            end;

            % Check if the lite figure exist
            if ishghandle(obj.Fig2)
                savename = ['FigLite_BClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]];
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
                %                 print (hf,'-dpdf', [savename], '-bestfit')
                print (hf,'-dpng', [savename])
                saveas(hf, savename, 'fig')
            end;

        end;

        function PlotDistribution(obj)
            % only plot PDF, CDF, and performance score, grouped by FP
            % plot the entire session
            col_perf = [85 225 0
                255 0 0
                200 200 200]/255;
            FPColors = [45, 205, 223]/255;

            figure(obj.Fig2); clf(obj.Fig2)
            set(obj.Fig2, 'unit', 'centimeters', 'position',[2 2 11.5 11.5], 'paperpositionmode', 'auto', 'color', 'w')

            plotsize2 = [3, 3.5];
            plotsize4 = [4 2.5];
            WhiskerColor = [255, 0, 50]/255;

            xloc_secondcol= 6.5+0.25;
            xloc_pdf = 1.25;

            yloc_bottomrow          =      1.5;
            yloc_1strow                 =        8;
            yloc_1strowright          =       7;

            HoldTimeMax = 2500;
            SessionMaxInSecs = 3600;

            if isempty(obj.Treatment)
                uicontrol('Style', 'text', 'parent', obj.Fig2, 'units', 'normalized', 'position', [0.25 0.95 0.5 0.04],...
                    'string', [obj.Subject ' | ' obj.Session(1:end-7)], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 10);
            else
                uicontrol('Style', 'text', 'parent', obj.Fig2, 'units', 'normalized', 'position', [0.25 0.95 0.5 0.04],...
                    'string', [obj.Subject ' | ' obj.Session(1:end-7) ' | ' obj.Treatment], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 10);
            end;


            if obj.PassedWarmedUp
                % Plot PDF of hold duration, again
                axes('parent', obj.Fig2, 'units', 'centimeters', 'position', [xloc_pdf  yloc_bottomrow plotsize4], 'nextplot', 'add', 'ylim', [0 prctile(cell2mat(obj.PDF_HoldT), 99.9)*1.25], 'ytick', [0:1:12], ...
                    'xtick', [0:500:HoldTimeMax],'xlim', [0 HoldTimeMax], 'yscale', 'linear', 'xticklabelrotation', 30, 'FontSize', 7);

                for k =1:length(obj.MixedFP)    % first, draw FPs
                    line([obj.MixedFP(k) obj.MixedFP(k)],  [0 prctile(cell2mat(obj.PDF_HoldT), 99.9)*1.25],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
                end;

                for k =1:length(obj.MixedFP);
                    if ~isempty(obj.PDF_HoldT{k})
                        plot(obj.HoldTbinEdges*1000, obj.PDF_HoldT{k},  'color', 'k', 'linewidth', 1,  'linestyle', obj.FPLineStyles{k});
                    end;
                end;

                xlabel('Hold time (ms)')
                ylabel('PDF(1/s)')

                % Plot CDF of hold duration
                axes('parent', obj.Fig2, 'units', 'centimeters', 'position', [xloc_pdf  yloc_bottomrow+3 plotsize4], 'nextplot', 'add', 'ylim', [0 1], 'ytick', [0:0.2:1], ...
                    'xtick', [0:500:HoldTimeMax], 'xticklabel', [],'xlim', [0 HoldTimeMax], 'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

                % Plot CDF of press duration for different FPs
                % first, draw FPs
                for k =1:length(obj.MixedFP)
                    line([obj.MixedFP(k) obj.MixedFP(k)],  [0 1],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
                end;

                for k =1:length(obj.MixedFP);
                    if ~isempty(obj.CDF_HoldT{k})
                        plot(obj.HoldTbinEdges*1000, obj.CDF_HoldT{k}, 'color', 'k', 'linewidth', 1, 'linestyle', obj.FPLineStyles{k});
                    end
                end;
                ylabel('CDF')

                % Violin plot of the responses
                axes('parent', obj.Fig2, 'units', 'centimeters', 'position', [xloc_pdf  yloc_1strow plotsize4], 'nextplot', 'add', 'ylim', [0 HoldTimeMax ], ...
                    'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

                HoldTimeAll = [];
                HoldTimeFPType = [];

                for k =1:length(obj.MixedFP)
                    Ind_k = ~strcmp(obj.Outcome, 'Dark') & obj.FP == obj.MixedFP(k);
                    HoldTimeAll = [HoldTimeAll obj.ReleaseTime(Ind_k) - obj.PressTime(Ind_k)];
                    HoldTimeFPType = [HoldTimeFPType k*ones(1, sum(Ind_k))];
                end;

                HoldTimeAll =HoldTimeAll*1000;

                hVio1 = violinplot(HoldTimeAll,  HoldTimeFPType, 'Width', 0.4, 'ViolinAlpha', 0.2, 'ShowWhiskers', false);
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

                for k =1:length(obj.MixedFP)
                    line([-0.4 0.4]+k, [obj.MixedFP(k) obj.MixedFP(k)],  'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
                end;
                set(gca, 'xticklabel', num2cell(obj.MixedFP), 'box', 'off', 'xlim', [0.5 length(obj.MixedFP)+.5])
                xlabel('FP (ms)')
                ylabel('Hold time (ms)')

                % Plot performance for different FPs
                axes('parent', obj.Fig2, 'units', 'centimeters', 'position', [xloc_secondcol, yloc_bottomrow, plotsize2], 'nextplot', 'add', 'ylim', [0 100], ...
                    'xlim', [-0.5 2+4*(length(obj.MixedFP)-1)+2], 'xtick', [2:4:2+4*(length(obj.MixedFP)-1)], 'xticklabel', num2cell(obj.MixedFP),...
                    'xticklabelrotation', 30);

                for i =1:length(obj.MixedFP)
                    bar(1+4*(i-1), obj.Performance.CorrectRatio(i), ...
                        'Edgecolor', 'none','Facecolor', col_perf(1, :), 'linewidth', 1);
                    bar(2+4*(i-1), obj.Performance.PrematureRatio(i), ...
                        'Edgecolor', 'none', 'Facecolor', col_perf(2, :), 'linewidth', 1);
                    bar(3+4*(i-1), obj.Performance.LateRatio(i), ...
                        'Edgecolor', 'none','Facecolor', col_perf(3, :), 'linewidth', 1);
                end;

                title('Performance|FP', 'fontweight', 'normal')
                ylabel('Performance (%)')
            end;

            % Plot symbols and their meanings
            hainfo=axes;
            set(hainfo,'parent', obj.Fig2,  'units', 'centimeters', 'position', [xloc_secondcol+plotsize2(1) 1+yloc_bottomrow 2 1], ...
                'xlim', [2 9], 'ylim', [5 8], 'nextplot', 'add');

            plot(2, 8, 's', 'linewidth', 1, 'color', col_perf(1, :),'markerfacecolor', col_perf(1, :));
            text(3, 8, 'Correct', 'fontsize', 8);
            plot(2, 7, 's', 'linewidth', 1, 'color', col_perf(2, :),'markerfacecolor', col_perf(2, :));
            text(3, 7, 'Premature', 'fontsize', 8);
            plot(2, 6 , 's', 'linewidth', 1,'color', col_perf(3, :),'markerfacecolor', col_perf(3, :));
            text(3, 6, 'Late', 'fontsize', 8);
            axis off


            if obj.PassedWarmedUp
                % plot reaction time
                ha5 = axes;
                set(ha5,'parent', obj.Fig2, 'units', 'centimeters', 'position', [xloc_secondcol, yloc_1strowright, plotsize2], 'nextplot', 'add', ...
                    'ylim', [100 500], ...
                    'xlim', [obj.MixedFP(1)-100 obj.MixedFP(end)+100], 'xtick', obj.MixedFP, 'xticklabel', num2cell(obj.MixedFP),...
                    'xticklabelrotation', 0);

                plot(cell2mat(obj.AvgRTLoose.Foreperiod(1:end-1)), obj.AvgRTLoose.RT_median_ksdensity(1:end-1), ...
                    'ko', 'linestyle', '-', 'linewidth', 1, 'color', [0.2 0.2 0.2], 'markerfacecolor', 'k', ...
                    'markersize', 8, 'markeredgecolor', 'w');

                plot(cell2mat(obj.AvgRTLoose.Foreperiod(1:end-1)), obj.AvgRT.RT_median_ksdensity(1:end-1), ...
                    'k^', 'linestyle', '-', 'linewidth', 1, 'color', [0.2 0.2 0.2], 'markerfacecolor', [255 178 0]/255, ...
                    'markersize', 7, 'markeredgecolor', 'w');

                if max(obj.AvgRTLoose.RT_median_ksdensity)>500
                    set(ha5, 'ylim',[100 max(obj.AvgRTLoose.RT_median_ksdensity)+100]);
                end;

            end;
            legend('Loose', 'Strict', 'location', 'best')
            legend('boxoff')
            xlabel('Foreperiod (ms)')
            ylabel('Reaction time (ms)')

        end;
        function Plot(obj)
            try
                set_matlab_default
            catch
                disp('You do not have "set_matlab_default"' )
            end

            if isempty(obj.PressTime)
                clc
                disp('No responses in this session')
                return
            end

            % plot the entire session
            col_perf = [85 225 0
                255 0 0
                200 200 200]/255;

            FPColors = [45, 205, 223]/255;

            figure(obj.Fig1); clf(obj.Fig1)
            set(obj.Fig1, 'unit', 'centimeters', 'position',[2 2 18 15.5], 'paperpositionmode', 'auto', 'color', 'w')

            plotsize1 = [6, 3.5];
            plotsize2 = [3, 3.5];
            plotsize3 = [2, 3.5]; % this is the pdf plot
            plotsize4 = [3 1.7];

            xloc_secondcol = 13;
            xloc_pdf = 8.25;

            yloc_bottomrow          =      1.5;
            yloc_2ndrow                =       6;
            yloc_1strow                 =       10.8;

            HoldTimeMax = 2500;
            SessionMaxInSecs = 3600;

            if isempty(obj.Treatment)
                uicontrol('Style', 'text', 'parent',obj.Fig1, 'units', 'normalized', 'position', [0.25 0.95 0.5 0.04],...
                    'string', [obj.Subject ' | ' obj.Session], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 10);
            else
                uicontrol('Style', 'text', 'parent',obj.Fig1, 'units', 'normalized', 'position', [0.25 0.95 0.5 0.04],...
                    'string', [obj.Subject ' | ' obj.Session ' | ' obj.Treatment], 'fontweight', 'bold', 'backgroundcolor', [1 1 1], 'fontsize', 10);
            end;

            ha1 = axes;
            set(ha1, 'parent', obj.Fig1,'units', 'centimeters', 'position', [2 yloc_1strow, plotsize1], 'nextplot', 'add', 'ylim', [0 HoldTimeMax], 'xlim', [1 SessionMaxInSecs], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % draw FPs
            for k =1:length(obj.MixedFP)
                line(ha1, [1 SessionMaxInSecs], [obj.MixedFP(k) obj.MixedFP(k)], 'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
            end;

            % plot press times
            line(ha1, [obj.PressTime; obj.PressTime], [0 250], 'color', 'b')

            % responses from different FPs should have diference sizes
            for k = 1:length(obj.MixedFP)
                symbolSize = 5+10*(k-1);
                ind_premature_presses = strcmp(obj.Outcome, 'Premature') & obj.FP == obj.MixedFP(k) & obj.Stage == 1;
                scatter(ha1, obj.ReleaseTime(ind_premature_presses), ...
                    1000*(obj.ReleaseTime(ind_premature_presses) - obj.PressTime(ind_premature_presses)), ...
                    25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

                ind_late_presses = strcmp(obj.Outcome, 'Late')& obj.FP == obj.MixedFP(k) & obj.Stage == 1;
                LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
                LateDur(LateDur>2500) = 2499;
                scatter(ha1, obj.ReleaseTime(ind_late_presses), LateDur, ...
                    25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

                ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.FP == obj.MixedFP(k) & obj.Stage == 1;
                scatter(ha1, obj.ReleaseTime(ind_good_presses), ...
                    1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses)), ...
                    25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);
            end;

            % warm-up stage
            symbolSize = 5;
            ind_premature_presses = strcmp(obj.Outcome, 'Premature') & obj.Stage == 0;
            axes(ha1)
            scatter(ha1, obj.ReleaseTime(ind_premature_presses), ...
                1000*(obj.ReleaseTime(ind_premature_presses) - obj.PressTime(ind_premature_presses)), ...
                25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

            ind_late_presses = strcmp(obj.Outcome, 'Late')& obj.Stage == 0;
            LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
            LateDur(LateDur>2500) = 2499;
            scatter(ha1, obj.ReleaseTime(ind_late_presses), LateDur, ...
                25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Stage == 0;
            scatter(ha1, obj.ReleaseTime(ind_good_presses), ...
                1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses)), ...
                25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05, 'SizeData', symbolSize);

            % Dark presses
            ind_dark_presses = strcmp(obj.Outcome, 'Dark');
            scatter(ha1, obj.ReleaseTime(ind_dark_presses), ...
                1000*(obj.ReleaseTime(ind_dark_presses) - obj.PressTime(ind_dark_presses)), ...
                15, 'k', 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

            % add Press duration distribution to the side. The axis is
            % rotated such that y axis represents press duration (matching
            % ha1) and x axis represents probability density

            if obj.PassedWarmedUp
                ha1_pdf = axes('parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_pdf yloc_1strow, plotsize3], 'nextplot', 'add', 'ylim', [0 2500], 'ytick', [], ...
                    'xtick', [1:10],'xlim', [0 prctile(cell2mat(obj.PDF_HoldT), 99.9)*1.25], 'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

                for k =1:length(obj.MixedFP);
                    if ~isempty(obj.PDF_HoldT{k})
                        plot(ha1_pdf, obj.PDF_HoldT{k}, obj.HoldTbinEdges*1000, 'color', 'k', 'linewidth', 1,  'linestyle', obj.FPLineStyles{k});
                    end;
                end;
                xlabel('PDF(1/s)')


                % draw FPs
                for k =1:length(obj.MixedFP)
                    line(ha1_pdf, [0 prctile(cell2mat(obj.PDF_HoldT), 99.9)*1.25], [obj.MixedFP(k) obj.MixedFP(k)], 'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
                end;

            end

            % Plot symbols and their meanings
            hainfo=axes;
            set(hainfo, 'parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_secondcol+plotsize2(1)+0.25 yloc_bottomrow, 2 plotsize2(2)], ...
                'xlim', [1.95 10], 'ylim', [0 9], 'nextplot', 'add');
            axes(hainfo)
            plot(hainfo, 2, 8, 'o', 'linewidth', 1, 'color', col_perf(1, :),'markerfacecolor', col_perf(1, :));
            text(hainfo, 3, 8, 'Correct', 'fontsize', 8);
            plot(hainfo, 2, 7, 'o', 'linewidth', 1, 'color', col_perf(2, :),'markerfacecolor', col_perf(2, :));
            text(3, 7, 'Premature', 'fontsize', 8);
            plot(2, 6 , 'o', 'linewidth', 1,'color', col_perf(3, :),'markerfacecolor', col_perf(3, :));
            text(3, 6, 'Late', 'fontsize', 8);
            plot(2, 5, 'ko', 'linewidth', 1,'markerfacecolor', 'k');
            text(3, 5, 'Dark', 'fontsize', 8);
            axis off

            % Plot reaction time
            RTMax                        =      1000;
            ha2 = axes;
            set(ha2,'parent', obj.Fig1,  'units', 'centimeters', 'position', [2 yloc_2ndrow, plotsize1], 'nextplot', 'add', 'ylim', [0 RTMax], 'xlim', [1 SessionMaxInSecs], 'yscale', 'linear');
            xlabel ('Time in session (s)')
            ylabel ('Reaction time (ms)')
            axes(ha2);

            for k = 1:length(obj.MixedFP)
                symbolSize = 5+10*(k-1);
                % late in red
                ind_late_presses = strcmp(obj.Outcome, 'Late') & obj.FP == obj.MixedFP(k) & obj.Stage == 1;
                lateRT =  1000*obj.ReactionTime(ind_late_presses);
                lateRT(lateRT>1000) = 999;
                scatter(obj.ToneTime(ind_late_presses), lateRT, ...
                    25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);
                ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.FP == obj.MixedFP(k) & obj.Stage == 1;
                scatter(obj.ToneTime(ind_good_presses), 1000*obj.ReactionTime(ind_good_presses), ...
                    25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);
            end;

            symbolSize = 5;
            ind_late_presses = strcmp(obj.Outcome, 'Late') &  obj.Stage == 0;
            lateRT =  1000*obj.ReactionTime(ind_late_presses);
            lateRT(lateRT>1000) = 999;
            scatter(obj.ToneTime(ind_late_presses), lateRT, ...
                25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Stage == 0;
            scatter(obj.ToneTime(ind_good_presses), 1000*obj.ReactionTime(ind_good_presses), ...
                25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize);

            % add reaction time distribution to the side. The axis is
            % rotated such that y axis represents rt (matching
            % ha2) and x axis represents probability density; Here we
            % include late reponses

            if obj.PassedWarmedUp
                ha2_pdf = axes('parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_pdf yloc_2ndrow, plotsize3], 'nextplot', 'add', 'ylim', [0 RTMax], 'ytick', [], ...
                    'xtick', [1:10],'xlim', [0 prctile(cell2mat(obj.PDF_RTLoose), 99.9)*1.25], 'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);
                axes(ha2_pdf)
                for k =1:length(obj.MixedFP);
                    if ~isempty(obj.PDF_RTLoose{k})
                        plot(obj.PDF_RTLoose{k}, obj.RTbinEdges*1000, 'color', 'k', 'linewidth', 1, 'linestyle', obj.FPLineStyles{k});
                    end;
                end;
                xlabel('PDF(1/s)')
            end

            % Plot performance score
            % Define size of sliding window
            ha3 = axes;
            set(ha3, 'parent', obj.Fig1, 'units', 'centimeters', 'position', [2 yloc_bottomrow, plotsize1], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 3600], 'yscale', 'linear', 'FontSize', 7)
            axes(ha3)
            WinPos                  =          obj.PerformanceSlidingWindow.TimeInSession;
            CorrectRatio          =         obj.PerformanceSlidingWindow.Correct;
            PrematureRatio     =        obj.PerformanceSlidingWindow.Premature;
            LateRatio               =          obj.PerformanceSlidingWindow.Late;

            plot(WinPos, CorrectRatio, 'o', 'linestyle', '-', 'color', col_perf(1, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w');
            plot(WinPos, PrematureRatio, 'o', 'linestyle', '-', 'color', col_perf(2, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w');
            plot(WinPos, LateRatio, 'o', 'linestyle', '-', 'color', col_perf(3, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w');
            xlabel('Time in session (sec)')
            ylabel('Performance')

            %Plot response number, grouped by performance
            ind_premature_presses = strcmp(obj.Outcome, 'Premature') & obj.Stage == 1;
            ind_late_presses = strcmp(obj.Outcome, 'Late') & obj.Stage == 1;
            ind_good_presses = strcmp(obj.Outcome, 'Correct') & obj.Stage == 1;
            ind_dark_presses = strcmp(obj.Outcome, 'Dark') & obj.Stage == 1;

            ha3 = axes; %
            set(ha3,'parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_secondcol, yloc_bottomrow, plotsize2], 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 5], 'xtick', [])
            hb1=bar([1], (sum(ind_good_presses)));
            set(hb1, 'EdgeColor', 'none', 'facecolor',col_perf(1, :), 'linewidth', 2);
            hb2=bar([2], (sum(ind_premature_presses)));
            set(hb2, 'EdgeColor',  'none', 'facecolor', col_perf(2, :), 'linewidth', 2);
            hb2=bar([3], (sum(ind_late_presses)));
            set(hb2, 'EdgeColor',  'none', 'facecolor',col_perf(3, :), 'linewidth', 2);
            hb3=bar([4], (sum(ind_dark_presses)));
            set(hb3, 'EdgeColor',  'none', 'facecolor', 'k', 'linewidth', 2);
            axis 'auto y'
            ylabel('Number')

            % Plot PDF of hold duration, again
            if obj.PassedWarmedUp
                axes('parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_pdf+0.5 yloc_bottomrow plotsize4], 'nextplot', 'add', 'ylim', [0 prctile(cell2mat(obj.PDF_HoldT), 99.9)*1.25], 'ytick', [0:1:12], ...
                    'xtick', [0:500:HoldTimeMax],'xlim', [0 HoldTimeMax], 'yscale', 'linear', 'xticklabelrotation', 30, 'FontSize', 7);

                for k =1:length(obj.MixedFP)    % first, draw FPs
                    line([obj.MixedFP(k) obj.MixedFP(k)],  [0 prctile(cell2mat(obj.PDF_HoldT), 99.9)*1.25],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
                end;

                for k =1:length(obj.MixedFP);
                    if ~isempty(obj.PDF_HoldT{k})
                        plot(obj.HoldTbinEdges*1000, obj.PDF_HoldT{k},  'color', 'k', 'linewidth', 1,  'linestyle', obj.FPLineStyles{k});
                    end;
                end;

                xlabel('Hold time (ms)')
                ylabel('PDF(1/s)')

                % Plot CDF of hold duration
                axes('parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_pdf+0.5 yloc_bottomrow+1.8, plotsize4], 'nextplot', 'add', 'ylim', [0 1], 'ytick', [0:0.2:1], ...
                    'xtick', [0:500:HoldTimeMax], 'xticklabel', [],'xlim', [0 HoldTimeMax], 'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 7);

                % Plot CDF of press duration for different FPs
                % first, draw FPs
                for k =1:length(obj.MixedFP)
                    line([obj.MixedFP(k) obj.MixedFP(k)],  [0 1],'linestyle', obj.FPLineStyles{k}, 'color', FPColors, 'linewidth', 1)
                end;

                for k =1:length(obj.MixedFP);
                    if ~isempty(obj.CDF_HoldT{k})
                        plot(obj.HoldTbinEdges*1000, obj.CDF_HoldT{k}, 'color', 'k', 'linewidth', 1, 'linestyle', obj.FPLineStyles{k});
                    end;
                end;
                ylabel('CDF')

                % Plot performance for different FPs
                ha4 = axes;
                set(ha4,'parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_secondcol, yloc_2ndrow, plotsize2], 'nextplot', 'add', 'ylim', [0 100], ...
                    'xlim', [-0.5 2+4*(length(obj.MixedFP)-1)+2], 'xtick', [2:4:2+4*(length(obj.MixedFP)-1)], 'xticklabel', num2cell(obj.MixedFP),...
                    'xticklabelrotation', 30);

                for i =1:length(obj.MixedFP)
                    bar(1+4*(i-1), obj.Performance.CorrectRatio(i), ...
                        'Edgecolor', 'none','Facecolor', col_perf(1, :), 'linewidth', 1);
                    bar(2+4*(i-1), obj.Performance.PrematureRatio(i), ...
                        'Edgecolor', 'none', 'Facecolor', col_perf(2, :), 'linewidth', 1);
                    bar(3+4*(i-1), obj.Performance.LateRatio(i), ...
                        'Edgecolor', 'none','Facecolor', col_perf(3, :), 'linewidth', 1);
                end;

                title('Performance|FP', 'fontweight', 'normal')
                ylabel('Performance (%)')

                % plot reaction time
                ha5 = axes;
                set(ha5,'parent', obj.Fig1,'units', 'centimeters', 'position', [xloc_secondcol, yloc_1strow, plotsize2], 'nextplot', 'add', ...
                    'ylim', [100 500], ...
                    'xlim', [obj.MixedFP(1)-100 obj.MixedFP(end)+100], 'xtick', obj.MixedFP, 'xticklabel', num2cell(obj.MixedFP),...
                    'xticklabelrotation', 0);

                plot(cell2mat(obj.AvgRTLoose.Foreperiod(1:end-1)), obj.AvgRTLoose.RT_median_ksdensity(1:end-1), ...
                    'ko', 'linestyle', '-', 'linewidth', 1, 'color', [0.2 0.2 0.2], 'markerfacecolor', 'k', ...
                    'markersize', 8, 'markeredgecolor', 'w');

                plot(cell2mat(obj.AvgRTLoose.Foreperiod(1:end-1)), obj.AvgRT.RT_median_ksdensity(1:end-1), ...
                    'k^', 'linestyle', '-', 'linewidth', 1, 'color', [0.2 0.2 0.2], 'markerfacecolor', [255 178 0]/255, ...
                    'markersize', 7, 'markeredgecolor', 'w');

                if max(obj.AvgRTLoose.RT_median_ksdensity)>500
                    set(ha5, 'ylim',[100 max(obj.AvgRTLoose.RT_median_ksdensity)+100]);
                end;

                legend('Loose', 'Strict','Location', 'best')
                legend('boxoff')
                xlabel('Foreperiod (ms)')
                ylabel('Reaction time (ms)')
            end;

        end;
    end
end
