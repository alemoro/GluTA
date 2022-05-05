classdef GluTA < matlab.apps.AppBase
    %GLUTA: Glutamate Transients Analysis is used to analysis iGluSnFR
    %recording of spontanoues and/or evoked activity in neuronal network
    %culture
    %   Detailed explanation goes here
    
    % app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        FileMenu                       matlab.ui.container.Menu
        FileMenuImport                 matlab.ui.container.Menu
        FileMenuOpen                   matlab.ui.container.Menu
        FileMenuSave                   matlab.ui.container.Menu
        FileMenuExport                 matlab.ui.container.Menu
        FileMenuLabelCondition         matlab.ui.container.Menu
        TabGroup                       matlab.ui.container.TabGroup
        MainTab                        matlab.ui.container.Tab
        UIAxesMovie                    matlab.ui.control.UIAxes
        UIAxesPlot                     matlab.ui.control.UIAxes
        PlotTypeButtonGroup            matlab.ui.container.ButtonGroup
        AllandmeanButton               matlab.ui.control.RadioButton
        SingletracesButton             matlab.ui.control.RadioButton
        DetrendButton                  matlab.ui.control.StateButton
        ExporttraceButton              matlab.ui.control.StateButton
        PrevButton                     matlab.ui.control.Button
        TextSynNumber                  matlab.ui.control.EditField
        NextButton                     matlab.ui.control.Button
        AddpeaksButton                 matlab.ui.control.Button
        DeletepeaksButton              matlab.ui.control.Button
        FixYAxisButton                 matlab.ui.control.StateButton
        ShowMovieButton                matlab.ui.control.StateButton
        SliderMovie                    matlab.ui.control.Slider
        TabListRecording               matlab.ui.container.TabGroup
        CellIDTab                      matlab.ui.container.Tab
        ListCell_ID                    matlab.ui.control.ListBox
        RecIDTab                       matlab.ui.container.Tab
        ListRec_ID                     matlab.ui.control.ListBox
        ShowROIsButton                 matlab.ui.control.StateButton
        DetecteventinButtonGroup       matlab.ui.container.ButtonGroup
        AllFOVsButton                  matlab.ui.control.RadioButton
        CurrentlistButton              matlab.ui.control.RadioButton
        SelectedFOVButton              matlab.ui.control.RadioButton
        DetectionoptionsPanel          matlab.ui.container.Panel
        SaveButton                     matlab.ui.control.Button
        DefaultButton                  matlab.ui.control.Button
        LoadoptionsPanel               matlab.ui.container.Panel
        MultiplerecordingCheckBox      matlab.ui.control.CheckBox
        FrequencyEditFieldLabel        matlab.ui.control.Label
        FrequencyEditField             matlab.ui.control.NumericEditField
        IdentifierEditFieldLabel       matlab.ui.control.Label
        IdentifierEditField            matlab.ui.control.EditField
        StimulationCheckBox            matlab.ui.control.CheckBox
        IdentifierEditField_2Label     matlab.ui.control.Label
        IdentifierEditField_2          matlab.ui.control.EditField
        HowmanystimEditFieldLabel      matlab.ui.control.Label
        HowmanystimEditField           matlab.ui.control.NumericEditField
        ROIDetectionPanel              matlab.ui.container.Panel
        ExpectedROIsizepxEditFieldLabel  matlab.ui.control.Label
        ExpectedROIsizepxEditField     matlab.ui.control.NumericEditField
        GaussianwindowsizeEditFieldLabel  matlab.ui.control.Label
        GaussianwindowsizeEditField    matlab.ui.control.NumericEditField
        ProminenceestimationDropDownLabel  matlab.ui.control.Label
        ProminenceestimationDropDown   matlab.ui.control.DropDown
        ROIprominencesigmaEditFieldLabel  matlab.ui.control.Label
        ROIprominencesigmaEditField    matlab.ui.control.NumericEditField
        PeakDetectionPanel             matlab.ui.container.Panel
        ThresholdmethodDropDownLabel   matlab.ui.control.Label
        ThresholdmethodDropDown        matlab.ui.control.DropDown
        ThresholdsigmaEditFieldLabel   matlab.ui.control.Label
        ThresholdsigmaEditField        matlab.ui.control.NumericEditField
        MinumumprominenceEditFieldLabel  matlab.ui.control.Label
        MinumumprominenceEditField     matlab.ui.control.NumericEditField
        MinumumDurationEditFieldLabel  matlab.ui.control.Label
        MinumumDurationEditField       matlab.ui.control.NumericEditField
        MinumumDistanceEditFieldLabel  matlab.ui.control.Label
        MinumumDistanceEditField       matlab.ui.control.NumericEditField
        MaximumDurationEditFieldLabel  matlab.ui.control.Label
        MaximumDurationEditField       matlab.ui.control.NumericEditField
        DetrendoptionsPanel            matlab.ui.container.Panel
        MethodDropDownLabel            matlab.ui.control.Label
        MethodDropDown                 matlab.ui.control.DropDown
        WindowsizeEditFieldLabel       matlab.ui.control.Label
        WindowsizeEditField            matlab.ui.control.NumericEditField
        VisualizeDropDownLabel         matlab.ui.control.Label
        VisualizeDropDown              matlab.ui.control.DropDown
        StimulationprotocolPanel       matlab.ui.container.Panel
        MergedrecordingsCheckBox       matlab.ui.control.CheckBox
        BaselinetimesEditFieldLabel    matlab.ui.control.Label
        BaselinetimesEditField         matlab.ui.control.NumericEditField
        NumberofAPEditFieldLabel       matlab.ui.control.Label
        NumberofAPEditField            matlab.ui.control.NumericEditField
        APfrequencyEditFieldLabel      matlab.ui.control.Label
        APfrequencyEditField           matlab.ui.control.NumericEditField
        NumberoftrainsEditFieldLabel   matlab.ui.control.Label
        NumberoftrainsEditField        matlab.ui.control.NumericEditField
        IdentifierEditField_3Label     matlab.ui.control.Label
        IdentifierEditField_3          matlab.ui.control.EditField
        ImportROIsButton               matlab.ui.control.Button
        DetectROIsButton               matlab.ui.control.Button
        DetectPeaksButton              matlab.ui.control.Button
        TableTab                       matlab.ui.container.Tab
        UITable                        matlab.ui.control.Table
        UIAxes3                        matlab.ui.control.UIAxes
        UIAxes4                        matlab.ui.control.UIAxes
    end
    
    % File storage properties
    properties (Access = private)
    end
    
    % Interaction methods
    methods (Access = private)
    end
    
     % Callbacks methods
    methods (Access = private)
    end
    
    % Create the UIFigure and components
    methods (Access = private)
        function createComponents(app)
            % Main UI
            app.UIFigure = uifigure('Units', 'pixels', 'Visible', 'off',...
                'Position', [100 100 1895 942],...
                'Name', 'GluTA: iGluSnFR Trace Analyzer', 'ToolBar', 'none', 'MenuBar', 'none',...
                'NumberTitle', 'off', 'WindowScrollWheelFcn', @(~,event)SliderImageStackMoved(app, event),...
                'KeyPressFcn', @(~,event)keyPressed(app, event));
            
            % Create the menu bar: file options
            app.FileMenu = uimenu(app.UIFigure, 'Text', '&File');
            app.FileMenuImport = uimenu(app.FileMenu, 'Text', '&Import data',...
                'Accelerator', 'I', 'MenuSelectedFcn', createCallbackFcn(app, @FileMenuImportSelected, true));
            app.FileMenuOpen = uimenu(app.FileMenu, 'Text', '&Open data',...
                'Accelerator', 'O', 'MenuSelectedFcn', createCallbackFcn(app, @FileMenuOpenSelected, true));
            app.FileMenuSave = uimenu(app.FileMenu, 'Text', '&Save data',...
                'Accelerator', 'S', 'MenuSelectedFcn', createCallbackFcn(app, @FileMenuSaveSelected, true));
            app.FileMenuExport = uimenu(app.FileMenu, 'Text', '&Export data',...
                'Accelerator', 'E', 'MenuSelectedFcn', createCallbackFcn(app, @FileMenuExportSelected, true),...
                'Enable', 'off');
            app.FileMenuLabelCondition = uimenu(app.FileMenu, 'Text', 'Label condition',...
                'MenuSelectedFcn', createCallbackFcn(app, @FileLabelConditionSelected, true), 'Separator', 'on');
            
            % Define multiple tabs where to store the UI
            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [2 3 1894 940]);
            app.MainTab = uitab(app.TabGroup, 'Title', 'Main');
            
            % Create the visual components: Movie and plot axes with slider
            app.UIAxesMovie = uiaxes(app.MainTab, 'Position', [36 63 806 806], 'Visible', 'on');
            title(app.UIAxesMovie, ''); xlabel(app.UIAxesMovie, ''); ylabel(app.UIAxesMovie, '')
            app.UIAxesMovie.YLabel.String = ''; app.UIAxesMovie.XLabel.String = ''; app.UIAxesMovie.Title.String = '';
            app.UIAxesPlot = uiaxes(app.MainTab, 'Position', [870 12 990 327], 'Visible', 'on');
            title(app.UIAxesPlot, ''); xlabel(app.UIAxesPlot, 'Time (s)'); ylabel(app.UIAxesPlot, 'iGluSnFR (a.u.)')
            
            % Create PlotTypeButtonGroup
            app.PlotTypeButtonGroup = uibuttongroup(app.MainTab);
            app.PlotTypeButtonGroup.Title = 'Plot Type';
            app.PlotTypeButtonGroup.Position = [885 381 118 73];

            % Create AllandmeanButton
            app.AllandmeanButton = uiradiobutton(app.PlotTypeButtonGroup);
            app.AllandmeanButton.Text = 'All and mean';
            app.AllandmeanButton.Position = [11 27 92 22];
            app.AllandmeanButton.Value = true;

            % Create SingletracesButton
            app.SingletracesButton = uiradiobutton(app.PlotTypeButtonGroup);
            app.SingletracesButton.Text = 'Single traces';
            app.SingletracesButton.Position = [11 5 91 22];

            % Create DetrendButton
            app.DetrendButton = uibutton(app.MainTab, 'state');
            app.DetrendButton.Text = 'Detrend';
            app.DetrendButton.Position = [1560 338 100 22];

            % Create ExporttraceButton
            app.ExporttraceButton = uibutton(app.MainTab, 'state');
            app.ExporttraceButton.Text = 'Export trace';
            app.ExporttraceButton.Position = [1032 381 100 22];

            % Create PrevButton
            app.PrevButton = uibutton(app.MainTab, 'push');
            app.PrevButton.Position = [1089 338 36 22];
            app.PrevButton.Text = 'Prev';

            % Create TextSynNumber
            app.TextSynNumber = uieditfield(app.MainTab, 'text');
            app.TextSynNumber.Position = [1128 338 48 22];
            app.TextSynNumber.Value = '1';

            % Create NextButton
            app.NextButton = uibutton(app.MainTab, 'push');
            app.NextButton.Position = [1179 338 40 22];
            app.NextButton.Text = 'Next';

            % Create AddpeaksButton
            app.AddpeaksButton = uibutton(app.MainTab, 'push');
            app.AddpeaksButton.Position = [1230 338 100 22];
            app.AddpeaksButton.Text = 'Add peaks';

            % Create DeletepeaksButton
            app.DeletepeaksButton = uibutton(app.MainTab, 'push');
            app.DeletepeaksButton.Position = [1340 338 100 22];
            app.DeletepeaksButton.Text = 'Delete peaks';

            % Create FixYAxisButton
            app.FixYAxisButton = uibutton(app.MainTab, 'state');
            app.FixYAxisButton.Text = 'Fix Y Axis';
            app.FixYAxisButton.Position = [1450 338 100 22];

            % Create ShowMovieButton
            app.ShowMovieButton = uibutton(app.MainTab, 'state');
            app.ShowMovieButton.Text = 'Show Movie';
            app.ShowMovieButton.Position = [36 878 100 22];

            % Create SliderMovie
            app.SliderMovie = uislider(app.MainTab);
            app.SliderMovie.Position = [36 44 806 3];

            % Create TabListRecording
            app.TabListRecording = uitabgroup(app.MainTab);
            app.TabListRecording.Position = [883 605 260 274];

            % Create CellIDTab
            app.CellIDTab = uitab(app.TabListRecording);
            app.CellIDTab.Title = 'Cell ID';

            % Create ListCell_ID
            app.ListCell_ID = uilistbox(app.CellIDTab);
            app.ListCell_ID.Position = [10 11 239 227];

            % Create RecIDTab
            app.RecIDTab = uitab(app.TabListRecording);
            app.RecIDTab.Title = 'Rec ID';

            % Create ListRec_ID
            app.ListRec_ID = uilistbox(app.RecIDTab);
            app.ListRec_ID.Position = [10 11 239 227];

            % Create ShowROIsButton
            app.ShowROIsButton = uibutton(app.MainTab, 'state');
            app.ShowROIsButton.Text = 'Show ROIs';
            app.ShowROIsButton.Position = [153 878 100 22];

            % Create DetecteventinButtonGroup
            app.DetecteventinButtonGroup = uibuttongroup(app.MainTab);
            app.DetecteventinButtonGroup.Title = 'Detect event in:';
            app.DetecteventinButtonGroup.Position = [884 483 123 106];

            % Create AllFOVsButton
            app.AllFOVsButton = uiradiobutton(app.DetecteventinButtonGroup);
            app.AllFOVsButton.Text = 'All FOVs';
            app.AllFOVsButton.Position = [11 60 69 22];
            app.AllFOVsButton.Value = true;

            % Create CurrentlistButton
            app.CurrentlistButton = uiradiobutton(app.DetecteventinButtonGroup);
            app.CurrentlistButton.Text = 'Current list';
            app.CurrentlistButton.Position = [11 38 80 22];

            % Create SelectedFOVButton
            app.SelectedFOVButton = uiradiobutton(app.DetecteventinButtonGroup);
            app.SelectedFOVButton.Text = 'Selected FOV';
            app.SelectedFOVButton.Position = [11 16 97 22];

            % Create DetectionoptionsPanel
            app.DetectionoptionsPanel = uipanel(app.MainTab);
            app.DetectionoptionsPanel.Title = 'Detection options';
            app.DetectionoptionsPanel.Position = [1188 381 672 498];

            % Create SaveButton
            app.SaveButton = uibutton(app.DetectionoptionsPanel, 'push');
            app.SaveButton.Position = [18 10 75 22];
            app.SaveButton.Text = 'Save';

            % Create DefaultButton
            app.DefaultButton = uibutton(app.DetectionoptionsPanel, 'push');
            app.DefaultButton.Position = [102 10 75 22];
            app.DefaultButton.Text = 'Default';

            % Create LoadoptionsPanel
            app.LoadoptionsPanel = uipanel(app.DetectionoptionsPanel);
            app.LoadoptionsPanel.Title = 'Load options';
            app.LoadoptionsPanel.Position = [11 207 177 255];

            % Create MultiplerecordingCheckBox
            app.MultiplerecordingCheckBox = uicheckbox(app.LoadoptionsPanel);
            app.MultiplerecordingCheckBox.Text = 'Multiple recording';
            app.MultiplerecordingCheckBox.Position = [4 166 117 22];

            % Create FrequencyEditFieldLabel
            app.FrequencyEditFieldLabel = uilabel(app.LoadoptionsPanel);
            app.FrequencyEditFieldLabel.Position = [4 204 62 22];
            app.FrequencyEditFieldLabel.Text = 'Frequency';

            % Create FrequencyEditField
            app.FrequencyEditField = uieditfield(app.LoadoptionsPanel, 'numeric');
            app.FrequencyEditField.Position = [98 204 45 22];
            app.FrequencyEditField.Value = 50;

            % Create IdentifierEditFieldLabel
            app.IdentifierEditFieldLabel = uilabel(app.LoadoptionsPanel);
            app.IdentifierEditFieldLabel.Position = [4 137 52 22];
            app.IdentifierEditFieldLabel.Text = 'Identifier';

            % Create IdentifierEditField
            app.IdentifierEditField = uieditfield(app.LoadoptionsPanel, 'text');
            app.IdentifierEditField.Position = [98 137 45 22];
            app.IdentifierEditField.Value = 'fov';

            % Create StimulationCheckBox
            app.StimulationCheckBox = uicheckbox(app.LoadoptionsPanel);
            app.StimulationCheckBox.Text = 'Stimulation';
            app.StimulationCheckBox.Position = [4 91 81 22];

            % Create IdentifierEditField_2Label
            app.IdentifierEditField_2Label = uilabel(app.LoadoptionsPanel);
            app.IdentifierEditField_2Label.Position = [4 57 52 22];
            app.IdentifierEditField_2Label.Text = 'Identifier';

            % Create IdentifierEditField_2
            app.IdentifierEditField_2 = uieditfield(app.LoadoptionsPanel, 'text');
            app.IdentifierEditField_2.Position = [98 57 45 22];
            app.IdentifierEditField_2.Value = 'fov';

            % Create HowmanystimEditFieldLabel
            app.HowmanystimEditFieldLabel = uilabel(app.LoadoptionsPanel);
            app.HowmanystimEditFieldLabel.Position = [4 23 94 22];
            app.HowmanystimEditFieldLabel.Text = 'How many stim?';

            % Create HowmanystimEditField
            app.HowmanystimEditField = uieditfield(app.LoadoptionsPanel, 'numeric');
            app.HowmanystimEditField.Position = [98 23 45 22];
            app.HowmanystimEditField.Value = 4;

            % Create ROIDetectionPanel
            app.ROIDetectionPanel = uipanel(app.DetectionoptionsPanel);
            app.ROIDetectionPanel.Title = 'ROI Detection';
            app.ROIDetectionPanel.Position = [201 341 453 121];

            % Create ExpectedROIsizepxEditFieldLabel
            app.ExpectedROIsizepxEditFieldLabel = uilabel(app.ROIDetectionPanel);
            app.ExpectedROIsizepxEditFieldLabel.HorizontalAlignment = 'right';
            app.ExpectedROIsizepxEditFieldLabel.Position = [10 69 129 22];
            app.ExpectedROIsizepxEditFieldLabel.Text = 'Expected ROI size (px)';

            % Create ExpectedROIsizepxEditField
            app.ExpectedROIsizepxEditField = uieditfield(app.ROIDetectionPanel, 'numeric');
            app.ExpectedROIsizepxEditField.Position = [154 69 24 22];
            app.ExpectedROIsizepxEditField.Value = 5;

            % Create GaussianwindowsizeEditFieldLabel
            app.GaussianwindowsizeEditFieldLabel = uilabel(app.ROIDetectionPanel);
            app.GaussianwindowsizeEditFieldLabel.Position = [274 70 124 22];
            app.GaussianwindowsizeEditFieldLabel.Text = 'Gaussian window size';

            % Create GaussianwindowsizeEditField
            app.GaussianwindowsizeEditField = uieditfield(app.ROIDetectionPanel, 'numeric');
            app.GaussianwindowsizeEditField.Position = [413 70 24 22];
            app.GaussianwindowsizeEditField.Value = 11;

            % Create ProminenceestimationDropDownLabel
            app.ProminenceestimationDropDownLabel = uilabel(app.ROIDetectionPanel);
            app.ProminenceestimationDropDownLabel.Position = [14 32 128 22];
            app.ProminenceestimationDropDownLabel.Text = 'Prominence estimation';

            % Create ProminenceestimationDropDown
            app.ProminenceestimationDropDown = uidropdown(app.ROIDetectionPanel);
            app.ProminenceestimationDropDown.Items = {'Standard Deviation', 'MAD'};
            app.ProminenceestimationDropDown.Position = [157 32 100 22];
            app.ProminenceestimationDropDown.Value = 'Standard Deviation';

            % Create ROIprominencesigmaEditFieldLabel
            app.ROIprominencesigmaEditFieldLabel = uilabel(app.ROIDetectionPanel);
            app.ROIprominencesigmaEditFieldLabel.Position = [274 32 128 22];
            app.ROIprominencesigmaEditFieldLabel.Text = 'ROI prominence sigma';

            % Create ROIprominencesigmaEditField
            app.ROIprominencesigmaEditField = uieditfield(app.ROIDetectionPanel, 'numeric');
            app.ROIprominencesigmaEditField.Position = [417 32 24 22];
            app.ROIprominencesigmaEditField.Value = 2;

            % Create PeakDetectionPanel
            app.PeakDetectionPanel = uipanel(app.DetectionoptionsPanel);
            app.PeakDetectionPanel.Title = 'Peak Detection';
            app.PeakDetectionPanel.Position = [201 162 453 159];

            % Create ThresholdmethodDropDownLabel
            app.ThresholdmethodDropDownLabel = uilabel(app.PeakDetectionPanel);
            app.ThresholdmethodDropDownLabel.HorizontalAlignment = 'right';
            app.ThresholdmethodDropDownLabel.Position = [10 111 102 22];
            app.ThresholdmethodDropDownLabel.Text = 'Threshold method';

            % Create ThresholdmethodDropDown
            app.ThresholdmethodDropDown = uidropdown(app.PeakDetectionPanel);
            app.ThresholdmethodDropDown.Items = {'MAD', 'Rolling StDev'};
            app.ThresholdmethodDropDown.Position = [127 111 100 22];
            app.ThresholdmethodDropDown.Value = 'MAD';

            % Create ThresholdsigmaEditFieldLabel
            app.ThresholdsigmaEditFieldLabel = uilabel(app.PeakDetectionPanel);
            app.ThresholdsigmaEditFieldLabel.Position = [270 111 94 22];
            app.ThresholdsigmaEditFieldLabel.Text = 'Threshold sigma';

            % Create ThresholdsigmaEditField
            app.ThresholdsigmaEditField = uieditfield(app.PeakDetectionPanel, 'numeric');
            app.ThresholdsigmaEditField.Position = [413 111 24 22];
            app.ThresholdsigmaEditField.Value = 2;

            % Create MinumumprominenceEditFieldLabel
            app.MinumumprominenceEditFieldLabel = uilabel(app.PeakDetectionPanel);
            app.MinumumprominenceEditFieldLabel.Position = [14 79 124 22];
            app.MinumumprominenceEditFieldLabel.Text = 'Minumum prominence';

            % Create MinumumprominenceEditField
            app.MinumumprominenceEditField = uieditfield(app.PeakDetectionPanel, 'numeric');
            app.MinumumprominenceEditField.Position = [157 79 24 22];
            app.MinumumprominenceEditField.Value = 2;

            % Create MinumumDurationEditFieldLabel
            app.MinumumDurationEditFieldLabel = uilabel(app.PeakDetectionPanel);
            app.MinumumDurationEditFieldLabel.Position = [271 79 107 22];
            app.MinumumDurationEditFieldLabel.Text = 'Minumum Duration';

            % Create MinumumDurationEditField
            app.MinumumDurationEditField = uieditfield(app.PeakDetectionPanel, 'numeric');
            app.MinumumDurationEditField.Position = [414 79 24 22];
            app.MinumumDurationEditField.Value = 2;

            % Create MinumumDistanceEditFieldLabel
            app.MinumumDistanceEditFieldLabel = uilabel(app.PeakDetectionPanel);
            app.MinumumDistanceEditFieldLabel.Position = [15 41 108 22];
            app.MinumumDistanceEditFieldLabel.Text = 'Minumum Distance';

            % Create MinumumDistanceEditField
            app.MinumumDistanceEditField = uieditfield(app.PeakDetectionPanel, 'numeric');
            app.MinumumDistanceEditField.Position = [158 41 24 22];
            app.MinumumDistanceEditField.Value = 2;

            % Create MaximumDurationEditFieldLabel
            app.MaximumDurationEditFieldLabel = uilabel(app.PeakDetectionPanel);
            app.MaximumDurationEditFieldLabel.Position = [270 41 106 22];
            app.MaximumDurationEditFieldLabel.Text = 'Maximum Duration';

            % Create MaximumDurationEditField
            app.MaximumDurationEditField = uieditfield(app.PeakDetectionPanel, 'numeric');
            app.MaximumDurationEditField.Position = [413 41 24 22];
            app.MaximumDurationEditField.Value = 2;

            % Create DetrendoptionsPanel
            app.DetrendoptionsPanel = uipanel(app.DetectionoptionsPanel);
            app.DetrendoptionsPanel.Title = 'Detrend options';
            app.DetrendoptionsPanel.Position = [12 48 176 140];

            % Create MethodDropDownLabel
            app.MethodDropDownLabel = uilabel(app.DetrendoptionsPanel);
            app.MethodDropDownLabel.Position = [10 88 56 22];
            app.MethodDropDownLabel.Text = 'Method';

            % Create MethodDropDown
            app.MethodDropDown = uidropdown(app.DetrendoptionsPanel);
            app.MethodDropDown.Items = {'None', 'Moving median', 'Erosion', 'Polynomial'};
            app.MethodDropDown.Position = [80 88 87 22];
            app.MethodDropDown.Value = 'None';

            % Create WindowsizeEditFieldLabel
            app.WindowsizeEditFieldLabel = uilabel(app.DetrendoptionsPanel);
            app.WindowsizeEditFieldLabel.Position = [8 53 73 22];
            app.WindowsizeEditFieldLabel.Text = 'Window size';

            % Create WindowsizeEditField
            app.WindowsizeEditField = uieditfield(app.DetrendoptionsPanel, 'numeric');
            app.WindowsizeEditField.Position = [122 53 43 22];
            app.WindowsizeEditField.Value = 100;

            % Create VisualizeDropDownLabel
            app.VisualizeDropDownLabel = uilabel(app.DetrendoptionsPanel);
            app.VisualizeDropDownLabel.Position = [8 19 56 22];
            app.VisualizeDropDownLabel.Text = 'Visualize';

            % Create VisualizeDropDown
            app.VisualizeDropDown = uidropdown(app.DetrendoptionsPanel);
            app.VisualizeDropDown.Items = {'Raw', 'Gradient', 'Smooth'};
            app.VisualizeDropDown.Position = [78 19 87 22];
            app.VisualizeDropDown.Value = 'Raw';

            % Create StimulationprotocolPanel
            app.StimulationprotocolPanel = uipanel(app.DetectionoptionsPanel);
            app.StimulationprotocolPanel.Title = 'Stimulation protocol';
            app.StimulationprotocolPanel.Position = [202 5 452 144];

            % Create MergedrecordingsCheckBox
            app.MergedrecordingsCheckBox = uicheckbox(app.StimulationprotocolPanel);
            app.MergedrecordingsCheckBox.Text = 'Merged recordings';
            app.MergedrecordingsCheckBox.Position = [179 59 144 22];

            % Create BaselinetimesEditFieldLabel
            app.BaselinetimesEditFieldLabel = uilabel(app.StimulationprotocolPanel);
            app.BaselinetimesEditFieldLabel.Position = [184 93 95 22];
            app.BaselinetimesEditFieldLabel.Text = 'Baseline time (s)';

            % Create BaselinetimesEditField
            app.BaselinetimesEditField = uieditfield(app.StimulationprotocolPanel, 'numeric');
            app.BaselinetimesEditField.Position = [278 93 45 22];
            app.BaselinetimesEditField.Value = 1;

            % Create NumberofAPEditFieldLabel
            app.NumberofAPEditFieldLabel = uilabel(app.StimulationprotocolPanel);
            app.NumberofAPEditFieldLabel.Position = [9 26 81 22];
            app.NumberofAPEditFieldLabel.Text = 'Number of AP';

            % Create NumberofAPEditField
            app.NumberofAPEditField = uieditfield(app.StimulationprotocolPanel, 'numeric');
            app.NumberofAPEditField.Position = [103 26 45 22];
            app.NumberofAPEditField.Value = 25;

            % Create APfrequencyEditFieldLabel
            app.APfrequencyEditFieldLabel = uilabel(app.StimulationprotocolPanel);
            app.APfrequencyEditFieldLabel.Position = [184 26 78 22];
            app.APfrequencyEditFieldLabel.Text = 'AP frequency';

            % Create APfrequencyEditField
            app.APfrequencyEditField = uieditfield(app.StimulationprotocolPanel, 'numeric');
            app.APfrequencyEditField.Position = [278 26 45 22];
            app.APfrequencyEditField.Value = 5;

            % Create NumberoftrainsEditFieldLabel
            app.NumberoftrainsEditFieldLabel = uilabel(app.StimulationprotocolPanel);
            app.NumberoftrainsEditFieldLabel.Position = [8 59 94 22];
            app.NumberoftrainsEditFieldLabel.Text = 'Number of trains';

            % Create NumberoftrainsEditField
            app.NumberoftrainsEditField = uieditfield(app.StimulationprotocolPanel, 'numeric');
            app.NumberoftrainsEditField.Position = [102 59 45 22];
            app.NumberoftrainsEditField.Value = 1;

            % Create IdentifierEditField_3Label
            app.IdentifierEditField_3Label = uilabel(app.StimulationprotocolPanel);
            app.IdentifierEditField_3Label.Position = [8 93 52 22];
            app.IdentifierEditField_3Label.Text = 'Identifier';

            % Create IdentifierEditField_3
            app.IdentifierEditField_3 = uieditfield(app.StimulationprotocolPanel, 'text');
            app.IdentifierEditField_3.Position = [102 93 45 22];
            app.IdentifierEditField_3.Value = '5Hz';

            % Create ImportROIsButton
            app.ImportROIsButton = uibutton(app.MainTab, 'push');
            app.ImportROIsButton.Position = [1038 543 100 22];
            app.ImportROIsButton.Text = 'Import ROIs';

            % Create DetectROIsButton
            app.DetectROIsButton = uibutton(app.MainTab, 'push');
            app.DetectROIsButton.Position = [1038 514 100 22];
            app.DetectROIsButton.Text = 'Detect ROIs';

            % Create DetectPeaksButton
            app.DetectPeaksButton = uibutton(app.MainTab, 'push');
            app.DetectPeaksButton.Position = [1038 485 100 22];
            app.DetectPeaksButton.Text = 'Detect Peaks';

            % Create Table
            app.TableTab = uitab(app.TabGroup);
            app.TableTab.Title = 'Table';

            % Create UITable
            app.UITable = uitable(app.TableTab);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [25 12 381 888];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.TableTab);
            title(app.UIAxes3, 'Title')
            xlabel(app.UIAxes3, 'X')
            ylabel(app.UIAxes3, 'Y')
            app.UIAxes3.Position = [433 338 731 562];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.TableTab);
            title(app.UIAxes4, 'Title')
            xlabel(app.UIAxes4, 'X')
            ylabel(app.UIAxes4, 'Y')
            app.UIAxes4.Position = [433 12 726 289];
            
            
            % Create the visual components of the table tab

            
            
            
            movegui(app.UIFigure, 'center');
            app.UIFigure.Visible = 'on';
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        function app = GluTA
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)
        end
        
         function delete(app)
            delete(app.UIFigure);
        end
    end
end

