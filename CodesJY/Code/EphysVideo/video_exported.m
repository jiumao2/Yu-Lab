classdef video_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        LeftPanel                 matlab.ui.container.Panel
        GridLayout5               matlab.ui.container.GridLayout
        GridLayout6               matlab.ui.container.GridLayout
        FlexionButton             matlab.ui.control.Button
        FlexTextArea              matlab.ui.control.TextArea
        ExtensionButton           matlab.ui.control.Button
        ExtensionTextArea         matlab.ui.control.TextArea
        TouchButton               matlab.ui.control.Button
        TouchTextArea             matlab.ui.control.TextArea
        LeaveButton               matlab.ui.control.Button
        LeaveTextArea             matlab.ui.control.TextArea
        GridLayout10              matlab.ui.container.GridLayout
        Load                      matlab.ui.control.Button
        ContinueButton            matlab.ui.control.Button
        LastButton                matlab.ui.control.Button
        NSButton                  matlab.ui.control.Button
        GridLayout9               matlab.ui.container.GridLayout
        videoname                 matlab.ui.control.Label
        videostate                matlab.ui.control.Label
        GridLayout18              matlab.ui.container.GridLayout
        PressDropDown             matlab.ui.control.DropDown
        PressDropDownLabel        matlab.ui.control.Label
        HoldDropDown              matlab.ui.control.DropDown
        HoldDropDownLabel         matlab.ui.control.Label
        ReleaseDropDown           matlab.ui.control.DropDown
        ReleaseDropDownLabel      matlab.ui.control.Label
        DateTextAreaLabel         matlab.ui.control.Label
        DateTextArea              matlab.ui.control.TextArea
        performanceDropDownLabel  matlab.ui.control.Label
        PerformanceDropDown       matlab.ui.control.DropDown
        RTTextAreaLabel           matlab.ui.control.Label
        RTTextArea                matlab.ui.control.TextArea
        GridLayout20              matlab.ui.container.GridLayout
        RightPanel                matlab.ui.container.Panel
        GridLayout2               matlab.ui.container.GridLayout
        GridLayout3               matlab.ui.container.GridLayout
        frameSlider               matlab.ui.control.Slider
        FrameLabel                matlab.ui.control.Label
        GridLayout4               matlab.ui.container.GridLayout
        BackButton                matlab.ui.control.Button
        PlayButton                matlab.ui.control.Button
        PauseButton               matlab.ui.control.Button
        AdvanceButton             matlab.ui.control.Button
        UIAxes                    matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    properties (Access = public)
        index_frame % Description
        vidObj
        pause_video
        path
        filename
        index_current
        info
        vidframes
        VidMeta
        b
        ratname
        file
    end
    
    %methods (Access = private)
    
    %             function mycallback(app,src,event)
    %                 display(event.SelectedOption);
    %             end
    
        %         end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: Load
        function loadPushed(app, event)
            [file,app.path] = uigetfile('*.avi',...
                'labeled video');% labeled video
            index=find(file=='_',1,'first');
            videodate=file(index+1:index+8);
            app.ratname=file(1:index-1);
            app.filename=string(arrayfun(@(x)x.name, dir([char(app.path) ['*',char(videodate),'*.avi']]), 'UniformOutput', false));
            app.DateTextArea.Value=videodate;
            fig = app.UIFigure;
            option=uiconfirm(app.UIFigure,'From this video?','Confirm order','Options',{'YES','NO'},'DefaultOption',2);
            if strcmp(option,'YES')
                app.index_current=find(contains(app.filename,file)>0);
            else
                app.index_current=1;
            end
            app.file=char(app.filename(app.index_current));
            app.vidObj = VideoReader([app.path,app.file]);
            app.videoname.Text=app.vidObj.Name(1:end-4);
            app.index_frame=1;
            app.UIAxes.XTick=[];
            app.UIAxes.XTickLabel={'[ ]'};
            app.UIAxes.YTick=[];
            app.UIAxes.Visible = 'off';
            app.frameSlider.Limits=[1 app.vidObj.NumFrames];
            if isfile([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                load([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                app.RTTextArea.Value=cell2mat(name.RT);
                app.PerformanceDropDown.Value=name.performance;
                if isfield(name,'flexsion')
                    app.FlexTextArea.Value=cell2mat(name.flexsion);
                end
                if isfield(name,'extension')
                    app.ExtensionTextArea.Value=cell2mat(name.extension);
                end
                app.PressDropDown.Value=name.press;
                app.HoldDropDown.Value=name.hold;
                app.ReleaseDropDown.Value=name.release;
                if isfield(name,'touch')
                    app.TouchTextArea.Value=cell2mat(name.touch);
                end
                if isfield(name,'leave')
                    app.LeaveTextArea.Value=cell2mat(name.leave);
                end
                if isfield(name,'video')
                    app.vidframes = name.video;
                end
                if isfield(name,'VidMeta')
                    app.VidMeta = name.VidMeta;
                end
                if isfield(name,'b')
                    app.b = name.b;
                end
                app.videoname.Text={app.videoname.Text;'THIS VIDEO WAS ANALYSED'};
            else
                load([app.path,app.file(1:end-3),'mat']);
                app.VidMeta=VidMeta;
                [filem,pathm] = uigetfile('*.txt',...
                    [videodate,'med data']);% med txt
                app.b=my_track_training_progress_advanced([pathm,filem]);
                app.RTTextArea.Value=num2str((app.b.ReleaseTime(app.VidMeta.EventIndex)-app.b.PressTime(app.VidMeta.EventIndex))*1000-app.b.FPs(app.VidMeta.EventIndex));
                app.PerformanceDropDown.Value=app.VidMeta.Performance;
            end
            app.vidframes = read(app.vidObj,[1 app.vidObj.NumFrames]);
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
        end

        % Value changed function: frameSlider
        function frameSliderValueChanged(app, event)
            app.index_frame= round(app.frameSlider.Value);
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
        end

        % Button pushed function: BackButton
        function BackButtonPushed(app, event)
            app.index_frame=app.index_frame-1;
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
            app.frameSlider.Value=app.index_frame;
        end

        % Button pushed function: AdvanceButton
        function AdvanceButtonPushed(app, event)
            app.index_frame=app.index_frame+1;
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
            app.frameSlider.Value=app.index_frame;
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            %uiresume(app.UIFigure);
            for i= app.index_frame:app.vidObj.NumFrames
                app.index_frame=i+1;
                imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
                pause(0.02)
                app.frameSlider.Value=app.index_frame;
                app.index_frame=i;
                if app.pause_video==0
                    app.pause_video=1;
                    break
                end
            end
            %movie(app.UIAxes,mov)
        end

        % Button pushed function: PauseButton
        function PauseButtonPushed(app, event)
            app.pause_video=0;
            %uiwait(app.UIFigure);
        end

        % Button pushed function: ContinueButton
        function ContinueButtonPushed(app, event)
            load('D:\cache\last_cache')
            app.index_current=cache.index_current;
            app.filename=cache.filename;
            app.file=char(app.filename(app.index_current));
            app.DateTextArea.Value=cache.date;
            app.path=cache.path;
            app.videoname.Text=app.file(1:end-4);
            app.index_frame=1;
            app.UIAxes.XTick=[];
            app.UIAxes.XTickLabel={'[ ]'};
            app.UIAxes.YTick=[];
            app.UIAxes.Visible = 'off';
            app.vidObj = VideoReader([app.path,app.file]);
            app.frameSlider.Limits=[1 app.vidObj.NumFrames];
            if isfile([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                load([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                app.RTTextArea.Value=cell2mat(name.RT);
                app.PerformanceDropDown.Value=name.performance;
                if isfield(name,'flexsion')
                    app.FlexTextArea.Value=cell2mat(name.flexsion);
                end
                if isfield(name,'extension')
                    app.ExtensionTextArea.Value=cell2mat(name.extension);
                end
                app.PressDropDown.Value=name.press;
                app.HoldDropDown.Value=name.hold;
                app.ReleaseDropDown.Value=name.release;
                if isfield(name,'touch')
                    app.TouchTextArea.Value=cell2mat(name.touch);
                end
                if isfield(name,'leave')
                    app.LeaveTextArea.Value=cell2mat(name.leave);
                end
                if isfield(name,'video')
                    app.vidframes = name.video;
                end
                if isfield(name,'VidMeta')
                    app.VidMeta = name.VidMeta;
                end
                if isfield(name,'b')
                    app.b = name.b;
                end
                app.videoname.Text={app.videoname.Text;'THIS VIDEO WAS ANALYSED'};
            else
                load([app.path,app.file(1:end-3),'mat']);
                app.VidMeta=VidMeta;
                [filem,pathm] = uigetfile('*.txt',...
                    [char(cache.date),'med data']);% med txt
                app.b=my_track_training_progress_advanced([pathm,filem]);
                app.RTTextArea.Value=num2str((app.b.ReleaseTime(app.VidMeta.EventIndex)-app.b.PressTime(app.VidMeta.EventIndex))*1000-app.b.FPs(app.VidMeta.EventIndex));
                app.PerformanceDropDown.Value=app.VidMeta.Performance;
            end
            app.vidframes = read(app.vidObj,[1 app.vidObj.NumFrames]);
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
        end

        % Button pushed function: LastButton
        function LastButtonPushed(app, event)
            if app.index_current ~=1
                app.index_current=app.index_current-1;
                app.file=char(app.filename(app.index_current));
                app.videoname.Text=app.file(1:end-4);
                app.index_frame=1;
                %             app.UIAxes=uiaxes(app.RightPanel);
                app.UIAxes.XTick=[];
                app.UIAxes.XTickLabel={'[ ]'};
                app.UIAxes.YTick=[];
                app.UIAxes.Visible = 'off';
                app.vidObj = VideoReader([app.path,app.file]);
                app.frameSlider.Limits=[1 app.vidObj.NumFrames];
                app.frameSlider.Value=1;
                app.videostate.Text='';
            else app.videostate.Text='THIS IS THE FIRST ONE';
            end
            if isfile([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                load([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                app.RTTextArea.Value=cell2mat(name.RT);
                app.PerformanceDropDown.Value=name.performance;
                if isfield(name,'flexsion')
                    app.FlexTextArea.Value=cell2mat(name.flexsion);
                end
                if isfield(name,'extension')
                    app.ExtensionTextArea.Value=cell2mat(name.extension);
                end
                app.PressDropDown.Value=name.press;
                app.HoldDropDown.Value=name.hold;
                app.ReleaseDropDown.Value=name.release;
                if isfield(name,'touch')
                    app.TouchTextArea.Value=cell2mat(name.touch);
                end
                if isfield(name,'leave')
                    app.LeaveTextArea.Value=cell2mat(name.leave);
                end
                if isfield(name,'video')
                    app.vidframes = name.video;
                end
                if isfield(name,'VidMeta')
                    app.VidMeta = name.VidMeta;
                end
                if isfield(name,'b')
                    app.b = name.b;
                end
                app.videoname.Text={app.videoname.Text;'THIS VIDEO WAS ANALYSED'};
            else
                load([app.path,app.file(1:end-3),'mat']);
                app.VidMeta=VidMeta;
                app.RTTextArea.Value=num2str((app.b.ReleaseTime(app.VidMeta.EventIndex)-app.b.PressTime(app.VidMeta.EventIndex))*1000-app.b.FPs(app.VidMeta.EventIndex));
                app.PerformanceDropDown.Value=app.VidMeta.Performance;
            end
            app.vidframes = read(app.vidObj,[1 app.vidObj.NumFrames]);
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
        end

        % Button pushed function: NSButton
        function NSButtonPushed(app, event)
            if iscell(app.videoname.Text)
                app.videoname.Text=app.videoname.Text{1};
            end
            %save
            name=struct;
            name.RatName=app.ratname;
            name.SessionDate=app.DateTextArea.Value;
            name.PressIndex=app.VidMeta.EventIndex;
            name.PressTime=app.VidMeta.EventTime;
            name.flexsion=app.FlexTextArea.Value;
            name.extension=app.ExtensionTextArea.Value;
            name.press=app.PressDropDown.Value;
            name.hold=app.HoldDropDown.Value;
            name.release=app.ReleaseDropDown.Value;
            name.performance=app.PerformanceDropDown.Value;
            name.RT=app.RTTextArea.Value;
            name.touch=app.TouchTextArea.Value;
            name.leave=app.LeaveTextArea.Value;
            %name.video=app.vidframes;
            name.b=app.b;
            name.VidMeta=app.VidMeta;
            name.FPs=app.b.FPs(app.VidMeta.EventIndex);
            if ~isfolder([app.path,'videodata\'])
                mkdir([app.path,'videodata\']);
            end
            save([app.path,'videodata\',app.videoname.Text],'name')
            if app.index_current ~= length(app.filename)
                if ~isfolder(['D:\cache'])
                    mkdir(['D:\cache']);
                end
                date=strrep(datestr(now,31),'-','');
                date=strrep(date,' ','_');
                date=strrep(date,':','_');
                cache.path=app.path;
                cache.file=char(app.filename(app.index_current+1));
                cache.index_current=app.index_current+1;
                cache.filename=app.filename;
                cache.date=app.DateTextArea.Value; 
                save(['D:\cache\last_cache'],'cache')
            end
            %next
            if app.index_current ~=length(app.filename)
                app.index_current=app.index_current+1;
                app.file=char(app.filename(app.index_current));
                app.videoname.Text=app.file(1:end-4);
                app.index_frame=1;
                app.UIAxes.XTick=[];
                app.UIAxes.XTickLabel={'[ ]'};
                app.UIAxes.YTick=[];
                app.UIAxes.Visible = 'off';
                app.vidObj = VideoReader([app.path,app.file]);
                app.frameSlider.Limits=[1 app.vidObj.NumFrames];
                app.frameSlider.Value=1;
                app.RTTextArea.Value='';
                app.FlexTextArea.Value='';
                app.ExtensionTextArea.Value='';
                app.TouchTextArea.Value='';
                app.LeaveTextArea.Value='';
                app.videostate.Text='';
            else app.videostate.Text='THIS IS THE LAST ONE';
            end
            if isfile([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                load([app.path,'videodata\',app.videoname.Text,'gui.mat'])
                app.RTTextArea.Value=cell2mat(name.RT);
                app.PerformanceDropDown.Value=name.performance;
                if isfield(name,'flexsion')
                    app.FlexTextArea.Value=cell2mat(name.flexsion);
                end
                if isfield(name,'extension')
                    app.ExtensionTextArea.Value=cell2mat(name.extension);
                end
                app.PressDropDown.Value=name.press;
                app.HoldDropDown.Value=name.hold;
                app.ReleaseDropDown.Value=name.release;
                if isfield(name,'touch')
                    app.TouchTextArea.Value=cell2mat(name.touch);
                end
                if isfield(name,'leave')
                    app.LeaveTextArea.Value=cell2mat(name.leave);
                end
                if isfield(name,'video')
                    app.vidframes = name.video;
                end
                if isfield(name,'VidMeta')
                    app.VidMeta = name.VidMeta;
                end
                if isfield(name,'b')
                    app.b = name.b;
                end
                app.videoname.Text={app.videoname.Text;'THIS VIDEO WAS ANALYSED'};
            else
                load([app.path,app.file(1:end-3),'mat']);
                app.VidMeta=VidMeta;
                app.RTTextArea.Value=num2str((app.b.ReleaseTime(app.VidMeta.EventIndex)-app.b.PressTime(app.VidMeta.EventIndex))*1000-app.b.FPs(app.VidMeta.EventIndex));
                app.PerformanceDropDown.Value=app.VidMeta.Performance;
            end
            app.vidframes = read(app.vidObj,[1 app.vidObj.NumFrames]);
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
        end

        % Value changed function: PerformanceDropDown
        function PerformanceDropDownValueChanged(app, event)
            value = app.PerformanceDropDown.Value;
            if strcmp(value,'correct')
                app.RTTextArea.Enable='on';
            else
                app.RTTextArea.Value='';
                app.RTTextArea.Enable='off';
            end
        end

        % Button pushed function: FlexionButton
        function FlexionButtonPushed(app, event)
            app.FlexTextArea.Value=num2str(app.VidMeta.FrameTimesB(app.index_frame)-app.VidMeta.EventTime);
        end

        % Button pushed function: ExtensionButton
        function ExtensionButtonPushed(app, event)
            app.ExtensionTextArea.Value=num2str(app.VidMeta.FrameTimesB(app.index_frame)-app.VidMeta.EventTime);
        end

        % Button pushed function: TouchButton
        function TouchButtonPushed(app, event)
            app.TouchTextArea.Value=num2str(app.VidMeta.FrameTimesB(app.index_frame)-app.VidMeta.EventTime);
        end

        % Button pushed function: LeaveButton
        function LeaveButtonPushed(app, event)
            app.LeaveTextArea.Value=num2str(app.VidMeta.FrameTimesB(app.index_frame)-app.VidMeta.EventTime);
        end

        % Window scroll wheel function: UIFigure
        function UIFigureWindowScrollWheel(app, event)
            verticalScrollCount = event.VerticalScrollCount;
            app.index_frame=app.index_frame+verticalScrollCount;
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
            app.frameSlider.Value=app.index_frame;
        end

        % Window key press function: UIFigure
        function UIFigureWindowKeyPress(app, event)
            key = event.Key;
            switch key
                case 'rightarrow'
                    app.index_frame=app.index_frame+1;
                case 'leftarrow'
                    app.index_frame=app.index_frame-1;
            end
            imagesc(app.UIAxes,app.vidframes(:,:,:,app.index_frame))
            app.frameSlider.Value=app.index_frame;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {505, 505};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {319, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 839 505];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIFigure.WindowScrollWheelFcn = createCallbackFcn(app, @UIFigureWindowScrollWheel, true);
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @UIFigureWindowKeyPress, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {319, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.LeftPanel);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {'4x', '0x', '1x', '1x', '1.5x', '1x'};
            app.GridLayout5.ColumnSpacing = 2;
            app.GridLayout5.RowSpacing = 1;
            app.GridLayout5.Padding = [1.66666666666667 10 1.66666666666667 10];

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.GridLayout5);
            app.GridLayout6.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout6.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout6.ColumnSpacing = 0;
            app.GridLayout6.RowSpacing = 0;
            app.GridLayout6.Padding = [0 0 0 0];
            app.GridLayout6.Layout.Row = 5;
            app.GridLayout6.Layout.Column = 1;

            % Create FlexionButton
            app.FlexionButton = uibutton(app.GridLayout6, 'push');
            app.FlexionButton.ButtonPushedFcn = createCallbackFcn(app, @FlexionButtonPushed, true);
            app.FlexionButton.Layout.Row = 1;
            app.FlexionButton.Layout.Column = 1;
            app.FlexionButton.Text = 'Flexion';

            % Create FlexTextArea
            app.FlexTextArea = uitextarea(app.GridLayout6);
            app.FlexTextArea.Layout.Row = 1;
            app.FlexTextArea.Layout.Column = 2;

            % Create ExtensionButton
            app.ExtensionButton = uibutton(app.GridLayout6, 'push');
            app.ExtensionButton.ButtonPushedFcn = createCallbackFcn(app, @ExtensionButtonPushed, true);
            app.ExtensionButton.Layout.Row = 2;
            app.ExtensionButton.Layout.Column = 1;
            app.ExtensionButton.Text = 'Extension';

            % Create ExtensionTextArea
            app.ExtensionTextArea = uitextarea(app.GridLayout6);
            app.ExtensionTextArea.Layout.Row = 2;
            app.ExtensionTextArea.Layout.Column = 2;

            % Create TouchButton
            app.TouchButton = uibutton(app.GridLayout6, 'push');
            app.TouchButton.ButtonPushedFcn = createCallbackFcn(app, @TouchButtonPushed, true);
            app.TouchButton.Layout.Row = 1;
            app.TouchButton.Layout.Column = 3;
            app.TouchButton.Text = 'Touch';

            % Create TouchTextArea
            app.TouchTextArea = uitextarea(app.GridLayout6);
            app.TouchTextArea.Layout.Row = 1;
            app.TouchTextArea.Layout.Column = 4;

            % Create LeaveButton
            app.LeaveButton = uibutton(app.GridLayout6, 'push');
            app.LeaveButton.ButtonPushedFcn = createCallbackFcn(app, @LeaveButtonPushed, true);
            app.LeaveButton.Layout.Row = 2;
            app.LeaveButton.Layout.Column = 3;
            app.LeaveButton.Text = 'Leave';

            % Create LeaveTextArea
            app.LeaveTextArea = uitextarea(app.GridLayout6);
            app.LeaveTextArea.Layout.Row = 2;
            app.LeaveTextArea.Layout.Column = 4;

            % Create GridLayout10
            app.GridLayout10 = uigridlayout(app.GridLayout5);
            app.GridLayout10.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout10.RowHeight = {'1x'};
            app.GridLayout10.Layout.Row = 6;
            app.GridLayout10.Layout.Column = 1;

            % Create Load
            app.Load = uibutton(app.GridLayout10, 'push');
            app.Load.ButtonPushedFcn = createCallbackFcn(app, @loadPushed, true);
            app.Load.Layout.Row = 1;
            app.Load.Layout.Column = 1;
            app.Load.Text = 'Load';

            % Create ContinueButton
            app.ContinueButton = uibutton(app.GridLayout10, 'push');
            app.ContinueButton.ButtonPushedFcn = createCallbackFcn(app, @ContinueButtonPushed, true);
            app.ContinueButton.Layout.Row = 1;
            app.ContinueButton.Layout.Column = 2;
            app.ContinueButton.Text = 'Continue';

            % Create LastButton
            app.LastButton = uibutton(app.GridLayout10, 'push');
            app.LastButton.ButtonPushedFcn = createCallbackFcn(app, @LastButtonPushed, true);
            app.LastButton.Layout.Row = 1;
            app.LastButton.Layout.Column = 3;
            app.LastButton.Text = 'Last';

            % Create NSButton
            app.NSButton = uibutton(app.GridLayout10, 'push');
            app.NSButton.ButtonPushedFcn = createCallbackFcn(app, @NSButtonPushed, true);
            app.NSButton.Layout.Row = 1;
            app.NSButton.Layout.Column = 4;
            app.NSButton.Text = 'N&S';

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.GridLayout5);
            app.GridLayout9.ColumnWidth = {'1x'};
            app.GridLayout9.RowHeight = {'1x', '0.5x'};
            app.GridLayout9.ColumnSpacing = 0;
            app.GridLayout9.RowSpacing = 0;
            app.GridLayout9.Padding = [0 0 0 0];
            app.GridLayout9.Layout.Row = 3;
            app.GridLayout9.Layout.Column = 1;

            % Create videoname
            app.videoname = uilabel(app.GridLayout9);
            app.videoname.HorizontalAlignment = 'center';
            app.videoname.Layout.Row = 1;
            app.videoname.Layout.Column = 1;
            app.videoname.Text = 'VideoName';

            % Create videostate
            app.videostate = uilabel(app.GridLayout9);
            app.videostate.HorizontalAlignment = 'center';
            app.videostate.Layout.Row = 2;
            app.videostate.Layout.Column = 1;
            app.videostate.Text = '';

            % Create GridLayout18
            app.GridLayout18 = uigridlayout(app.GridLayout5);
            app.GridLayout18.ColumnWidth = {'1x', '3x'};
            app.GridLayout18.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout18.Layout.Row = 1;
            app.GridLayout18.Layout.Column = 1;

            % Create PressDropDown
            app.PressDropDown = uidropdown(app.GridLayout18);
            app.PressDropDown.Items = {'nan', 'L', 'R', 'B'};
            app.PressDropDown.Layout.Row = 1;
            app.PressDropDown.Layout.Column = 2;
            app.PressDropDown.Value = 'nan';

            % Create PressDropDownLabel
            app.PressDropDownLabel = uilabel(app.GridLayout18);
            app.PressDropDownLabel.HorizontalAlignment = 'center';
            app.PressDropDownLabel.Layout.Row = 1;
            app.PressDropDownLabel.Layout.Column = 1;
            app.PressDropDownLabel.Text = 'Press';

            % Create HoldDropDown
            app.HoldDropDown = uidropdown(app.GridLayout18);
            app.HoldDropDown.Items = {'nan', 'L', 'R', 'B'};
            app.HoldDropDown.Layout.Row = 2;
            app.HoldDropDown.Layout.Column = 2;
            app.HoldDropDown.Value = 'nan';

            % Create HoldDropDownLabel
            app.HoldDropDownLabel = uilabel(app.GridLayout18);
            app.HoldDropDownLabel.HorizontalAlignment = 'center';
            app.HoldDropDownLabel.Layout.Row = 2;
            app.HoldDropDownLabel.Layout.Column = 1;
            app.HoldDropDownLabel.Text = 'Hold';

            % Create ReleaseDropDown
            app.ReleaseDropDown = uidropdown(app.GridLayout18);
            app.ReleaseDropDown.Items = {'nan', 'L', 'R', 'B'};
            app.ReleaseDropDown.Layout.Row = 3;
            app.ReleaseDropDown.Layout.Column = 2;
            app.ReleaseDropDown.Value = 'nan';

            % Create ReleaseDropDownLabel
            app.ReleaseDropDownLabel = uilabel(app.GridLayout18);
            app.ReleaseDropDownLabel.HorizontalAlignment = 'center';
            app.ReleaseDropDownLabel.Layout.Row = 3;
            app.ReleaseDropDownLabel.Layout.Column = 1;
            app.ReleaseDropDownLabel.Text = 'Release';

            % Create DateTextAreaLabel
            app.DateTextAreaLabel = uilabel(app.GridLayout18);
            app.DateTextAreaLabel.HorizontalAlignment = 'center';
            app.DateTextAreaLabel.Layout.Row = 6;
            app.DateTextAreaLabel.Layout.Column = 1;
            app.DateTextAreaLabel.Text = 'Date';

            % Create DateTextArea
            app.DateTextArea = uitextarea(app.GridLayout18);
            app.DateTextArea.Layout.Row = 6;
            app.DateTextArea.Layout.Column = 2;

            % Create performanceDropDownLabel
            app.performanceDropDownLabel = uilabel(app.GridLayout18);
            app.performanceDropDownLabel.HorizontalAlignment = 'right';
            app.performanceDropDownLabel.Layout.Row = 4;
            app.performanceDropDownLabel.Layout.Column = 1;
            app.performanceDropDownLabel.Text = {'performance'; ''};

            % Create PerformanceDropDown
            app.PerformanceDropDown = uidropdown(app.GridLayout18);
            app.PerformanceDropDown.Items = {'Late', 'Premature', 'Correct'};
            app.PerformanceDropDown.ValueChangedFcn = createCallbackFcn(app, @PerformanceDropDownValueChanged, true);
            app.PerformanceDropDown.Layout.Row = 4;
            app.PerformanceDropDown.Layout.Column = 2;
            app.PerformanceDropDown.Value = 'Late';

            % Create RTTextAreaLabel
            app.RTTextAreaLabel = uilabel(app.GridLayout18);
            app.RTTextAreaLabel.HorizontalAlignment = 'center';
            app.RTTextAreaLabel.Layout.Row = 5;
            app.RTTextAreaLabel.Layout.Column = 1;
            app.RTTextAreaLabel.Text = 'RT';

            % Create RTTextArea
            app.RTTextArea = uitextarea(app.GridLayout18);
            app.RTTextArea.Layout.Row = 5;
            app.RTTextArea.Layout.Column = 2;

            % Create GridLayout20
            app.GridLayout20 = uigridlayout(app.GridLayout5);
            app.GridLayout20.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout20.ColumnSpacing = 0;
            app.GridLayout20.RowSpacing = 0;
            app.GridLayout20.Padding = [0 0 0 0];
            app.GridLayout20.Layout.Row = 4;
            app.GridLayout20.Layout.Column = 1;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.RightPanel);
            app.GridLayout2.ColumnWidth = {'1x'};
            app.GridLayout2.RowHeight = {'6x', '1x', '1x'};
            app.GridLayout2.ColumnSpacing = 4.16666666666667;
            app.GridLayout2.RowSpacing = 2;
            app.GridLayout2.Padding = [2 2 2 2];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.GridLayout2);
            app.GridLayout3.ColumnWidth = {'1x', '4x'};
            app.GridLayout3.RowHeight = {'1x'};
            app.GridLayout3.ColumnSpacing = 2;
            app.GridLayout3.RowSpacing = 2;
            app.GridLayout3.Padding = [2 2 2 2];
            app.GridLayout3.Layout.Row = 2;
            app.GridLayout3.Layout.Column = 1;

            % Create frameSlider
            app.frameSlider = uislider(app.GridLayout3);
            app.frameSlider.ValueChangedFcn = createCallbackFcn(app, @frameSliderValueChanged, true);
            app.frameSlider.Layout.Row = 1;
            app.frameSlider.Layout.Column = 2;

            % Create FrameLabel
            app.FrameLabel = uilabel(app.GridLayout3);
            app.FrameLabel.HorizontalAlignment = 'center';
            app.FrameLabel.Layout.Row = 1;
            app.FrameLabel.Layout.Column = 1;
            app.FrameLabel.Text = 'Frame';

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.GridLayout2);
            app.GridLayout4.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout4.RowHeight = {'1x'};
            app.GridLayout4.ColumnSpacing = 2;
            app.GridLayout4.RowSpacing = 2;
            app.GridLayout4.Padding = [2 2 2 2];
            app.GridLayout4.Layout.Row = 3;
            app.GridLayout4.Layout.Column = 1;

            % Create BackButton
            app.BackButton = uibutton(app.GridLayout4, 'push');
            app.BackButton.ButtonPushedFcn = createCallbackFcn(app, @BackButtonPushed, true);
            app.BackButton.Layout.Row = 1;
            app.BackButton.Layout.Column = 1;
            app.BackButton.Text = 'Back';

            % Create PlayButton
            app.PlayButton = uibutton(app.GridLayout4, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Layout.Row = 1;
            app.PlayButton.Layout.Column = 2;
            app.PlayButton.Text = 'Play';

            % Create PauseButton
            app.PauseButton = uibutton(app.GridLayout4, 'push');
            app.PauseButton.ButtonPushedFcn = createCallbackFcn(app, @PauseButtonPushed, true);
            app.PauseButton.Layout.Row = 1;
            app.PauseButton.Layout.Column = 3;
            app.PauseButton.Text = 'Pause';

            % Create AdvanceButton
            app.AdvanceButton = uibutton(app.GridLayout4, 'push');
            app.AdvanceButton.ButtonPushedFcn = createCallbackFcn(app, @AdvanceButtonPushed, true);
            app.AdvanceButton.Layout.Row = 1;
            app.AdvanceButton.Layout.Column = 4;
            app.AdvanceButton.Text = 'Advance';

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout2);
            title(app.UIAxes, 'Video')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = 1;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = video_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end