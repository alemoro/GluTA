classdef GluTA < matlab.apps.AppBase
    %GLUTA: Glutamate Transients Analysis is used to analysis iGluSnFR
    %recording of spontanoues and/or evoked activity in neuronal network
    %culture
    %   Detailed explanation goes here
    
    % app components
    properties (Access = public)
        UIFigure matlab.ui.Figure
        FileMenu
        FileMenuImport
        FileMenuOpen
        FileMenuSave
        FileMenuExport
        FileMenuLabelCondition
        TabGroup
        MainTab
        UIAxesMovie
        UIAxesPlot
        PlotTypeButtonGroup
        AllAndMeanButton
        SingleTracesButton
        DetrendButton
        ExportTraceButton
        PrevButton
        TextSynNumber
        NextButton
        AddPeaksButton
        DeletePeaksButton
        FixYAxisButton
        ShowMovieButton
        SliderMovie
        TabListRecording
        CellIDTab
        List_CellID
        RecIDTab
        ListRec_ID
        ShowROIsButton
        DetectEventButtonGroup
        AllFOVsButton
        CurrentListButton
        SelectedFOVButton
        DetectionOptionsPanel
        SaveButton
        DefaultButton
        LoadOptionsPanel
        MultipleRecordingCheckBox
        ImagingFrequencyLabel
        ImagingFrequencyEdit
        RecordingIdentifierLabel
        RecordingIdentifierEdit
        StimulationCheckBox
        StimulationIdentifierLabel
        StimulationIdentifierEdit
        StimNumLabel
        StimNumEdit
        ROIDetectionPanel
        ROISizeLabel
        ROISizeEdit
        ROISigmaLabel
        ROISigmaEdit
        ProminenceROIsDropDownLabel
        ProminenceROIsDropDown
        ProminenceROISigmaLabel
        ProminenceROISigmaEdit
        PeakDetectionPanel
        PeakThresholdMethodDropDownLabel
        PeakThresholdMethodDropDown
        PeakSigmaLabel
        PeakSigmaEdit
        PeakMinProminenceLabel
        PeakMinProminenceEdit
        PeakMinDurationLabel
        PeakMinDurationEdit
        MinDistanceLabel
        PeakMinDistanceEdit
        MaxDurationLabel
        PeakMaxDurationEdit
        DetrendOptionsPanel
        MethodDropDownLabel
        MethodDropDown
        WindowSizeLabel
        WindowSizeEdit
        VisualizeDropDownLabel
        VisualizeDropDown
        StimulationProtocolPanel
        MergedRecordingsCheckBox
        BaselineSecLabel
        BaselineSecEdit
        APNumLabel
        APNumEdit
        APFreqLabel
        APFreqEdit
        TrainsNumLabel
        TrainsNumEdit
        TrainsIDsLabel
        TrainsIDsEdit
        ImportROIsButton
        DetectROIsButton
        DetectPeaksButton
        TableTab
        UITable
        UIAxes3
        UIAxes4
    end
    
    % Housekeeping properties
    properties (Access = private)
        
    end
    
    % User properties
    properties (Access = public)
        Opt % store the settings options
        imgT % store the actual data
    end
    % Interaction methods
    methods (Access = private)
    end
    
     % Callbacks methods
    methods (Access = private)
        function FileMenuImportSelected(app, event)
            % First locate the folder with the data
            imgPath = uigetdir(app.Opt.LastPath, 'Select Image folder');
            togglePointer(app)
            try
                if imgPath ~= 0
                    % Store the last path
                    app.Opt.LastPath = imgPath;
                    % Load the info to locate the data
                    imgFiles = dir(fullfile(imgPath, '*.tif'));
                    nFiles = numel(imgFiles);
                    if nFiles == 0
                        warndlg('No tif images in the current folder');
                        togglePointer(app)
                        return
                    end
                    hWait = waitbar(0, 'Loading images data');
                    imgFltr = contains({imgFiles.name}, app.Opt.StimIDs) | contains({imgFiles.name}, app.Opt.RecIDs);
                    nFiles = sum(imgFltr);
                    tempT = cell(nFiles+1, 9);
                    tempT(1,:) = {'Filename', 'CellID', 'Week', 'BatchID', 'ConditionID', 'CoverslipID', 'RecID', 'StimID', 'Fs'};
                    % Get the name info
                    nameParts = regexp({imgFiles.name}, '_', 'split')';
                    nameParts = nameParts(imgFltr);
                    tempT(2:end,1) = fullfile({imgFiles(imgFltr).folder}, {imgFiles(imgFltr).name});
                    tempT(2:end,2) = cellfun(@(x) x(1:end-4), {imgFiles(imgFltr).name}, 'UniformOutput', false);
                    for f = 1:nFiles
                        waitbar(f/nFiles, hWait, sprintf('Loading movie data %0.2f%%', f/nFiles*100));
                        tempT{f+1,3} = weeknum(datetime(nameParts{f}{1}, 'InputFormat', 'yyMMdd'));
                        tempT{f+1,4} = nameParts{f}{3};
                        tempT{f+1,5} = nameParts{f}{2};
                        tempT{f+1,6} = nameParts{f}{4};
                        tempT{f+1,7} = nameParts{f}{5};
                        tempT{f+1,8} = nameParts{f}{6};
                        % Try to get info on the actual timeStamp but not now
                        tempT{f+1,8} = app.Opt.ImgFrequency;
                    end
                    app.imgT = cell2table(tempT(2:end,:), 'VariableNames', tempT(1,:));
                end
            catch ME
            end
        end
        
        function SaveButtonPushed(app, event)
            % Retrieve the settings from the UI and save them in the app
            app.Opt.ImgFrequency = app.ImagingFrequencyEdit.Value;
            app.Opt.MultiRecording = app.MultipleRecordingCheckBox.Value;
            app.Opt.RecIDs = app.RecordingIdentifierEdit.Value;
            app.Opt.MultiStimulation = app.StimulationCheckBox.Value;
            app.Opt.StimIDs = app.StimulationIdentifierEdit.Value;
            app.Opt.StimNum = app.StimNumEdit.Value;
            app.Opt.RoiSize = app.ROISizeEdit.Value;
            app.Opt.RoiSigma = app.ROISigmaEdit.Value;
            app.Opt.RoiProminence = app.ProminenceROIsDropDown.Value;
            app.Opt.RoiProminenceSigma = app.ProminenceROISigmaEdit.Value;
            app.Opt.PeakThreshold = app.PeakThresholdMethodDropDown.Value;
            app.Opt.PeakThrSigma = app.PeakSigmaEdit.Value;
            app.Opt.PeakMinProm = app.PeakMinProminenceEdit.Value;
            app.Opt.PeakMinDistance = app.PeakMinDistanceEdit.Value;
            app.Opt.PeakMinDuration = app.PeakMinDurationEdit.Value;
            app.Opt.PeakMaxDuration = app.PeakMaxDurationEdit.Value;
            app.Opt.Detrending = app.MethodDropDown.Value;
            app.Opt.DetrendSize = app.WindowSizeEdit.Value;
            app.Opt.DetectTrace = app.VisualizeDropDown.Value;
        end
        
        function DefaultButtonPushed(app, event)
            app.Opt.LastPath = pwd;
            app.Opt.ImgFrequency = 50;
            app.Opt.MultiRecording = true;
            app.Opt.RecIDs = 'fov';
            app.Opt.MultiStimulation = true;
            app.Opt.StimIDs = 'Hz';
            app.Opt.StimNum = 4;
            app.Opt.RoiSize = 5;
            app.Opt.RoiSigma = 11;
            app.Opt.RoiProminence = 'Standard Deviation';
            app.Opt.RoiProminenceSigma = 2;
            app.Opt.PeakThreshold = 'MAD';
            app.Opt.PeakThrSigma = 2;
            app.Opt.PeakMinProm = 1;
            app.Opt.PeakMinDistance = 10;
            app.Opt.PeakMinDuration = 5;
            app.Opt.PeakMaxDuration = 60;
            app.Opt.Detrending = 'None';
            app.Opt.DetrendSize = 100;
            app.Opt.DetectTrace = 'Raw';
            updateOptions(app)
        end
    end
    
    % Housekeeping methods
    methods (Access = public)
        function togglePointer(app)
            if strcmp(app.UIFigure.Pointer, 'arrow')
                app.UIFigure.Pointer = 'watch';
            else
                app.UIFigure.Pointer = 'arrow';
            end
            drawnow();
        end
        
        function updateOptions(app)
            app.ImagingFrequencyEdit.Value = app.Opt.ImgFrequency;
            app.MultipleRecordingCheckBox.Value = app.Opt.MultiRecording;
            app.RecordingIdentifierEdit.Value = app.Opt.RecIDs;
            app.StimulationCheckBox.Value = app.Opt.MultiStimulation;
            app.StimulationIdentifierEdit.Value = app.Opt.StimIDs;
            app.StimNumEdit.Value = app.Opt.StimNum;
            app.ROISizeEdit.Value = app.Opt.RoiSize;
            app.ROISigmaEdit.Value = app.Opt.RoiSigma;
            app.ProminenceROIsDropDown.Value = app.Opt.RoiProminence;
            app.ProminenceROISigmaEdit.Value = app.Opt.RoiProminenceSigma;
            app.PeakThresholdMethodDropDown.Value = app.Opt.PeakThreshold;
            app.PeakSigmaEdit.Value = app.Opt.PeakThrSigma;
            app.PeakMinProminenceEdit.Value = app.Opt.PeakMinProm;
            app.PeakMinDistanceEdit.Value = app.Opt.PeakMinDistance;
            app.PeakMinDurationEdit.Value = app.Opt.PeakMinDuration;
            app.PeakMaxDurationEdit.Value = app.Opt.PeakMaxDuration;
            app.MethodDropDown.Value = app.Opt.Detrending;
            app.WindowSizeEdit.Value = app.Opt.DetrendSize;
            app.VisualizeDropDown.Value = app.Opt.DetectTrace;
        end
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
            app.TableTab = uitab(app.TabGroup, 'Title', 'Table');
            
            % Create the visual components: Movie and plot axes with slider
            app.UIAxesMovie = uiaxes(app.MainTab, 'Position', [36 63 806 806], 'Visible', 'off');
            title(app.UIAxesMovie, ''); xlabel(app.UIAxesMovie, ''); ylabel(app.UIAxesMovie, '')
            app.UIAxesPlot = uiaxes(app.MainTab, 'Position', [870 12 990 327], 'Visible', 'on');
            title(app.UIAxesPlot, ''); xlabel(app.UIAxesPlot, 'Time (s)'); ylabel(app.UIAxesPlot, 'iGluSnFR (a.u.)')
            app.SliderMovie = uislider(app.MainTab, 'Position', [36 44 806 3], 'Visible', 'off');
            
            % Create Plot Type Button Group
            app.PlotTypeButtonGroup = uibuttongroup(app.MainTab, 'Title', 'Plot Type', 'Position', [885 381 118 73]);
            app.AllAndMeanButton = uiradiobutton(app.PlotTypeButtonGroup, 'Text', 'All and mean', 'Position', [11 27 92 22],...
                'Value', true, 'Enable', 'off');
            app.SingleTracesButton = uiradiobutton(app.PlotTypeButtonGroup, 'Text', 'Single trace', 'Position', [11 5 91 22],...
                'Enable', 'off');
            
            % Create DetrendButton, Export and Fix Y axis value
            app.DetrendButton = uibutton(app.MainTab, 'state', 'Text', 'Detrend', 'Position', [1560 338 100 22],...
                'Enable', 'off');
            app.ExportTraceButton = uibutton(app.MainTab, 'state', 'Text', 'Export trace', 'Position', [1032 381 100 22],...
                'Enable', 'off');
            app.FixYAxisButton = uibutton(app.MainTab, 'state', 'Text', 'Fix Y Axis', 'Position', [1450 338 100 22],...
                'Enable', 'off');
            
            % Create Synapse navigation panel
            app.PrevButton = uibutton(app.MainTab, 'push', 'Text', 'Prev', 'Position', [1089 338 36 22],...
                'Enable', 'off');
            app.TextSynNumber = uieditfield(app.MainTab, 'text', 'Position', [1128 338 48 22], 'Value', '1',...
                'Enable', 'off');
            app.NextButton = uibutton(app.MainTab, 'push', 'Text', 'Next', 'Position', [1179 338 40 22],...
                'Enable', 'off');
            
            % Create Manual peaks detection panel
            app.AddPeaksButton = uibutton(app.MainTab, 'push', 'Text', 'Add peaks', 'Position', [1230 338 100 22],...
                'Enable', 'off');
            app.DeletePeaksButton = uibutton(app.MainTab, 'push', 'Text', 'Delete peaks', 'Position', [1340 338 100 22],...
                'Enable', 'off');
            
            % Create Movie Toggles
            app.ShowMovieButton = uibutton(app.MainTab, 'state', 'Text', 'Show Movie', 'Position', [36 878 100 22], 'Enable', 'off');
            app.ShowROIsButton = uibutton(app.MainTab, 'state', 'Text', 'Show ROIs', 'Position', [153 878 100 22], 'Enable', 'off');
            
            % Create Tabs for List Recording
            app.TabListRecording = uitabgroup(app.MainTab, 'Position', [883 605 260 274]);
            app.CellIDTab = uitab(app.TabListRecording, 'Title', 'Cell ID');
            app.List_CellID = uilistbox(app.CellIDTab, 'Position', [10 11 239 227], 'Items', {''}, 'Enable', 'off');
            app.RecIDTab = uitab(app.TabListRecording, 'Title', 'Rec ID');
            app.ListRec_ID = uilistbox(app.RecIDTab, 'Position', [10 11 239 227], 'Items', {''}, 'Enable', 'off');

            % Create ROIs Buttons
            app.ImportROIsButton = uibutton(app.MainTab, 'push', 'Text', 'Import ROIs', 'Position', [1038 543 100 22], 'Enable', 'off');
            app.DetectROIsButton = uibutton(app.MainTab, 'push', 'Text', 'Detect ROIs', 'Position', [1038 514 100 22], 'Enable', 'off');
            
            % Create Detect Event Button Group
            app.DetectEventButtonGroup = uibuttongroup(app.MainTab, 'Title', 'Detect events in:', 'Position', [884 483 123 106]);
            app.AllFOVsButton = uiradiobutton(app.DetectEventButtonGroup, 'Text', 'All FOVs', 'Position', [11 60 69 22], 'Enable', 'off');
            app.CurrentListButton = uiradiobutton(app.DetectEventButtonGroup, 'Text', 'Current list', 'Position', [11 38 80 22], 'Enable', 'off');
            app.SelectedFOVButton = uiradiobutton(app.DetectEventButtonGroup, 'Text', 'Selected FOV', 'Position', [11 16 97 22], 'Enable', 'off');
            app.DetectPeaksButton = uibutton(app.MainTab, 'push', 'Text', 'Detect Peaks', 'Position', [1038 485 100 22], 'Enable', 'off');
            
            % Create DetectionOptionsPanel
            app.DetectionOptionsPanel = uipanel(app.MainTab, 'Title', 'Detection Options', 'Position', [1188 381 672 498]);
            app.SaveButton = uibutton(app.DetectionOptionsPanel, 'push', 'Text', 'Save', 'Position', [18 10 75 22],...
                'ButtonPushedFcn', createCallbackFcn(app, @SaveButtonPushed, true));
            app.DefaultButton = uibutton(app.DetectionOptionsPanel, 'push', 'Text', 'Default', 'Position', [102 10 75 22],...
                'ButtonPushedFcn', createCallbackFcn(app, @DefaultButtonPushed, true));
            
            % Create LoadOptionsPanel
            app.LoadOptionsPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Load Options', 'Position', [11 207 177 255]);
            app.ImagingFrequencyLabel = uilabel(app.LoadOptionsPanel, 'Text', 'Frequency', 'Position', [4 204 63 22]);
            app.ImagingFrequencyEdit = uieditfield(app.LoadOptionsPanel, 'numeric', 'Position', [98 204 45 22], 'Value', app.Opt.ImgFrequency);
            app.MultipleRecordingCheckBox = uicheckbox(app.LoadOptionsPanel, 'Text', 'Multiple Recordings', 'Position', [4 166 177 22], 'Value', app.Opt.MultiRecording);
            app.RecordingIdentifierLabel = uilabel(app.LoadOptionsPanel, 'Position', [4 137 52 22], 'Text', 'Identifier');
            app.RecordingIdentifierEdit = uieditfield(app.LoadOptionsPanel, 'text', 'Position', [98 137 45 22], 'Value', app.Opt.RecIDs);
            app.StimulationCheckBox = uicheckbox(app.LoadOptionsPanel,'Text', 'Stimulation', 'Position', [4 91 81 22], 'Value', app.Opt.MultiStimulation);
            app.StimulationIdentifierLabel = uilabel(app.LoadOptionsPanel, 'Position', [4 57 52 22], 'Text', 'Identifier');
            app.StimulationIdentifierEdit = uieditfield(app.LoadOptionsPanel, 'text', 'Position', [98 57 45 22], 'Value', app.Opt.StimIDs);
            app.StimNumLabel = uilabel(app.LoadOptionsPanel, 'Position', [4 23 94 22], 'Text', 'How many stim?');
            app.StimNumEdit = uieditfield(app.LoadOptionsPanel, 'numeric', 'Position', [98 23 45 22], 'Value', app.Opt.StimNum);

            % Create ROIDetectionPanel
            app.ROIDetectionPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'ROI Detection', 'Position', [201 341 453 121]);
            app.ROISizeLabel = uilabel(app.ROIDetectionPanel, 'HorizontalAlignment', 'right', 'Position', [10 69 129 22], 'Text', 'Expected ROI size (px)');
            app.ROISizeEdit = uieditfield(app.ROIDetectionPanel, 'numeric', 'Position', [154 69 24 22], 'Value', app.Opt.RoiSize);
            app.ROISigmaLabel = uilabel(app.ROIDetectionPanel, 'Position', [274 70 124 22], 'Text', 'Gaussian window size');
            app.ROISigmaEdit = uieditfield(app.ROIDetectionPanel, 'numeric', 'Position', [413 70 24 22], 'Value', app.Opt.RoiSigma);
            app.ProminenceROIsDropDownLabel = uilabel(app.ROIDetectionPanel, 'Position', [14 32 128 22], 'Text', 'Prominence estimation');
            app.ProminenceROIsDropDown = uidropdown(app.ROIDetectionPanel, 'Items', {'Standard Deviation', 'MAD'}, 'Position', [157 32 100 22], 'Value', app.Opt.RoiProminence);
            app.ProminenceROISigmaLabel = uilabel(app.ROIDetectionPanel, 'Position', [274 32 128 22], 'Text', 'ROI prominence sigma');
            app.ProminenceROISigmaEdit = uieditfield(app.ROIDetectionPanel, 'numeric', 'Position', [417 32 24 22], 'Value', app.Opt.RoiProminenceSigma);

            % Create PeakDetectionPanel
            app.PeakDetectionPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Peak Detection', 'Position', [201 162 453 159]);
            app.PeakThresholdMethodDropDownLabel = uilabel(app.PeakDetectionPanel, 'HorizontalAlignment', 'right', 'Position', [10 111 102 22], 'Text', 'Threshold method');
            app.PeakThresholdMethodDropDown = uidropdown(app.PeakDetectionPanel, 'Items', {'MAD', 'Rolling StDev'}, 'Position', [127 111 100 22], 'Value', app.Opt.PeakThreshold);
            app.PeakSigmaLabel = uilabel(app.PeakDetectionPanel, 'Position', [270 111 94 22], 'Text', 'Threshold sigma');
            app.PeakSigmaEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [413 111 24 22], 'Value', app.Opt.PeakThrSigma);
            app.PeakMinProminenceLabel = uilabel(app.PeakDetectionPanel, 'Position', [14 79 124 22], 'Text', 'Minumum prominence');
            app.PeakMinProminenceEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [157 79 24 22], 'Value', app.Opt.PeakMinProm);
            app.PeakMinDurationLabel = uilabel(app.PeakDetectionPanel, 'Position', [271 79 107 22], 'Text', 'Minumum Duration');
            app.PeakMinDurationEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [414 79 24 22], 'Value', app.Opt.PeakMinDuration);
            app.MinDistanceLabel = uilabel(app.PeakDetectionPanel, 'Position', [15 41 108 22], 'Text', 'Minumum Distance');
            app.PeakMinDistanceEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [158 41 24 22], 'Value', app.Opt.PeakMinDistance);
            app.MaxDurationLabel = uilabel(app.PeakDetectionPanel, 'Position', [270 41 106 22], 'Text', 'Maximum Duration');
            app.PeakMaxDurationEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [413 41 24 22], 'Value', app.Opt.PeakMaxDuration);
            
            % Create PeakDetectionPanel
            app.DetrendOptionsPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Detrend options', 'Position', [12 48 176 140]);
            app.MethodDropDownLabel = uilabel(app.DetrendOptionsPanel, 'Position', [10 88 56 22], 'Text', 'Method');
            app.MethodDropDown = uidropdown(app.DetrendOptionsPanel, 'Items', {'None', 'Moving median', 'Erosion', 'Polynomial'}, 'Position', [80 88 87 22], 'Value', app.Opt.Detrending);
            app.WindowSizeLabel = uilabel(app.DetrendOptionsPanel, 'Position', [8 53 73 22], 'Text', 'Window size');
            app.WindowSizeEdit = uieditfield(app.DetrendOptionsPanel, 'numeric', 'Position', [122 53 43 22], 'Value', app.Opt.DetrendSize);
            app.VisualizeDropDownLabel = uilabel(app.DetrendOptionsPanel, 'Position', [8 19 56 22], 'Text', 'Visualize');
            app.VisualizeDropDown = uidropdown(app.DetrendOptionsPanel, 'Items', {'Raw', 'Gradient', 'Smooth'}, 'Position', [78 19 87 22], 'Value', app.Opt.DetectTrace);

            % Create StimulationProtocolPanel
            app.StimulationProtocolPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Stimulation protocol', 'Position', [202 5 452 144]);
            app.MergedRecordingsCheckBox = uicheckbox(app.StimulationProtocolPanel, 'Text', 'Merged recordings', 'Position', [179 59 144 22]);
            app.BaselineSecLabel = uilabel(app.StimulationProtocolPanel, 'Position', [184 93 95 22], 'Text', 'Baseline time (s)');
            app.BaselineSecEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [278 93 45 22], 'Value', 1);
            app.APNumLabel = uilabel(app.StimulationProtocolPanel, 'Position', [9 26 81 22], 'Text', 'Number of AP');
            app.APNumEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [103 26 45 22], 'Value', 25);
            app.APFreqLabel = uilabel(app.StimulationProtocolPanel, 'Position', [184 26 78 22], 'Text', 'AP frequency');
            app.APFreqEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [278 26 45 22], 'Value', 5);
            app.TrainsNumLabel = uilabel(app.StimulationProtocolPanel, 'Position', [8 59 94 22], 'Text', 'Number of trains');
            app.TrainsNumEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [102 59 45 22], 'Value', 1);
            app.TrainsIDsLabel = uilabel(app.StimulationProtocolPanel, 'Position', [8 93 52 22], 'Text', 'Identifier');
            app.TrainsIDsEdit = uieditfield(app.StimulationProtocolPanel, 'text', 'Position', [102 93 45 22], 'Value', '5Hz');
            
            % Create UITable
            app.UITable = uitable(app.TableTab, 'ColumnName', {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'}, 'RowName', {}, 'Position', [25 12 381 888]);

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
        
        function startSettings(app)
            s = settings;
            if ~hasGroup(s, 'GluTA')
                % save the settings
                addGroup(s, 'GluTA');
                addSetting(s.GluTA, 'LastPath', 'PersonalValue', pwd);
                addSetting(s.GluTA, 'ImgFrequency', 'PersonalValue', 50);
                addSetting(s.GluTA, 'MultiRecording', 'PersonalValue', true);
                addSetting(s.GluTA, 'RecIDs', 'PersonalValue', 'fov');
                addSetting(s.GluTA, 'MultiStimulation', 'PersonalValue', true);
                addSetting(s.GluTA, 'StimIDs', 'PersonalValue', 'Hz');
                addSetting(s.GluTA, 'StimNum', 'PersonalValue', 4);
                addSetting(s.GluTA, 'RoiSize', 'PersonalValue', 5);
                addSetting(s.GluTA, 'RoiSigma', 'PersonalValue', 11);
                addSetting(s.GluTA, 'RoiProminence', 'PersonalValue', 'Standard Deviation');
                addSetting(s.GluTA, 'RoiProminenceSigma', 'PersonalValue', 2);
                addSetting(s.GluTA, 'PeakThreshold', 'PersonalValue', 'MAD');
                addSetting(s.GluTA, 'PeakThrSigma', 'PersonalValue', 2);
                addSetting(s.GluTA, 'PeakMinProm', 'PersonalValue', 1);
                addSetting(s.GluTA, 'PeakMinDistance', 'PersonalValue', 1);
                addSetting(s.GluTA, 'PeakMinDuration', 'PersonalValue', 2);
                addSetting(s.GluTA, 'PeakMaxDuration', 'PersonalValue', 5);
                addSetting(s.GluTA, 'Detrending', 'PersonalValue', 'None');
                addSetting(s.GluTA, 'DetrendSize', 'PersonalValue', 100);
                addSetting(s.GluTA, 'DetectTrace', 'PersonalValue', 'Raw');
            end
            app.Opt.LastPath = s.GluTA.LastPath.ActiveValue;
            app.Opt.ImgFrequency = s.GluTA.ImgFrequency.ActiveValue;
            app.Opt.MultiRecording = s.GluTA.MultiRecording.ActiveValue;
            app.Opt.RecIDs = s.GluTA.RecIDs.ActiveValue;
            app.Opt.MultiStimulation = s.GluTA.MultiStimulation.ActiveValue;
            app.Opt.StimIDs = s.GluTA.StimIDs.ActiveValue;
            app.Opt.StimNum = s.GluTA.StimNum.ActiveValue;
            app.Opt.RoiSize = s.GluTA.RoiSize.ActiveValue;
            app.Opt.RoiSigma = s.GluTA.RoiSigma.ActiveValue;
            app.Opt.RoiProminence = s.GluTA.RoiProminence.ActiveValue;
            app.Opt.RoiProminenceSigma = s.GluTA.RoiProminenceSigma.ActiveValue;
            app.Opt.PeakThreshold = s.GluTA.PeakThreshold.ActiveValue;
            app.Opt.PeakThrSigma = s.GluTA.PeakThrSigma.ActiveValue;
            app.Opt.PeakMinProm = s.GluTA.PeakMinProm.ActiveValue;
            app.Opt.PeakMinDistance = s.GluTA.PeakMinDistance.ActiveValue;
            app.Opt.PeakMinDuration = s.GluTA.PeakMinDuration.ActiveValue;
            app.Opt.PeakMaxDuration = s.GluTA.PeakMaxDuration.ActiveValue;
            app.Opt.Detrending = s.GluTA.Detrending.ActiveValue;
            app.Opt.DetrendSize = s.GluTA.DetrendSize.ActiveValue;
            app.Opt.DetectTrace = s.GluTA.DetectTrace.ActiveValue;
        end
        
        function saveSettings(app)
            % Before closing save the settings
            s = settings;
            s.GluTA.LastPath.PersonalValue = app.Opt.LastPath;
            s.GluTA.ImgFrequency.PersonalValue = app.Opt.ImgFrequency;
            s.GluTA.MultiRecording.PersonalValue = app.Opt.MultiRecording;
            s.GluTA.RecIDs.PersonalValue = app.Opt.RecIDs;
            s.GluTA.MultiStimulation.PersonalValue = app.Opt.MultiStimulation;
            s.GluTA.StimIDs.PersonalValue = app.Opt.StimIDs;
            s.GluTA.StimNum.PersonalValue = app.Opt.StimNum;
            s.GluTA.RoiSize.PersonalValue = app.Opt.RoiSize;
            s.GluTA.RoiSigma.PersonalValue = app.Opt.RoiSigma;
            s.GluTA.RoiProminence.PersonalValue = app.Opt.RoiProminence;
            s.GluTA.RoiProminenceSigma.PersonalValue = app.Opt.RoiProminenceSigma;
            s.GluTA.PeakThreshold.PersonalValue = app.Opt.PeakThreshold;
            s.GluTA.PeakThrSigma.PersonalValue = app.Opt.PeakThrSigma;
            s.GluTA.PeakMinProm.PersonalValue = app.Opt.PeakMinProm;
            s.GluTA.PeakMinDistance.PersonalValue = app.Opt.PeakMinDistance;
            s.GluTA.PeakMinDuration.PersonalValue = app.Opt.PeakMinDuration;
            s.GluTA.PeakMaxDuration.PersonalValue = app.Opt.PeakMaxDuration;
            s.GluTA.Detrending.PersonalValue = app.Opt.Detrending;
            s.GluTA.DetrendSize.PersonalValue = app.Opt.DetrendSize;
            s.GluTA.DetectTrace.PersonalValue = app.Opt.DetectTrace;
        end
        
    end
    
    % App creation and deletion
    methods (Access = public)
        function app = GluTA
            startSettings(app)
            createComponents(app)
            togglePointer(app)
            % Register the app with App Designer
            %registerApp(app, app.UIFigure);
            togglePointer(app);
            % Do not return an element
            if nargout == 0
                clear app
            end
        end
        
        function delete(app)
            saveSettings(app)
            delete(app.UIFigure);
        end
    end
end

