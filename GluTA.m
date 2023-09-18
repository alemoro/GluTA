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
        QuantifyMenu
        QuantifyMenuCellPeaks
        QuantifyMenuFeature
        OptionMenu
        OptionMenuDebug
        TabGroup
        MainTab
        UIAxesMovie
        UIAxesPlot
        PlotTypeButtonGroup
        AllAndMeanRadio
        SingleTracesRadio
        DetrendButton
        KeepCellToggle
        ExportTraceButton
        PrevButton
        TextSynNumber
        NextButton
        AddPeaksButton
        DeletePeaksButton
        FixYAxisButton
        ZoomInButton
        ShowMovieButton
        SliderMovie
        TabListRecording
        CellIDTab
        List_CellID
        RecIDTab
        List_RecID
        ShowROIsButton
        MeasureROIsButton
        DetectEventButtonGroup
        AllFOVsRadio
        CurrentListRadio
        SelectedFOVRadio
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
        TableMenu
        FilterTable
        FilterIntensity
        FilterFrequency
        FilterSNR
        UITableSingle
        UIAxesRaster
        UIAxesOverview
        ZoomRasterButton
        ResetRasterButton
        ExportRasterButton
        UITableAll
        UIAxesBox
        FigureMenu
        BoxMenu
        ToggleActive
    end
    
    % Housekeeping properties
    properties (Access = private)
        patchMask % store the ROIs drawing
        currCell % the raw number of the current selected cell
        currSlice % if the movie is showed, keep in memore which slice we are looking at
        curTime % a line for the current position on the plot
        yLim % Y axis limits for plotting single synapses
        selectedTableCell
        newChange = false; % boolean value to store if there is a major change in the data
    end
    
    % User properties
    properties (Access = public)
        Opt % store the settings options
        imgT % store the actual data
        movieData % store the movie data
        keepColor = [219 68 55;...      % Google RED
                    15 157 88;...       % Google GREEN
                    66 133 244;...      % Google BLUE
                    244 180 0] / 255;	% Google YELLOW
        tempAddPeak = []; % Array to store the temporaney peaks with manual detection
        activeFltr = false; % Boolean to use only the active synapses in "Main"
        regMovie = false; % Boolean to register the stimulation to the naive recording
        stim = table('Size', [1 6], 'VariableTypes', ['string', repmat({'double'},1,5)],...
            'VariableNames', {'StimID' 'Baseline' 'nTrains', 'nAP', 'FreqAP' 'Merged'});
    end
    
    % Interaction methods
    methods (Access = private)
        function FileMenuImportSelected(app, event)
            % First locate the folder with the data
            imgPath = uigetdir(app.Opt.LastPath, 'Select Image folder');
            togglePointer(app)
            figure(app.UIFigure);
            try
                if imgPath ~= 0
                    % Store the last path
                    app.Opt.LastPath = imgPath;
                    % Load the info to locate the data
                    imgFiles = dir(fullfile(imgPath, '*.tif'));
                    nFiles = numel(imgFiles);
                    if nFiles == 0
                        uiconfirm(app.UIFigure, 'no tif images in the current folder!', 'Warning', 'Icon', 'error');
                        togglePointer(app)
                        return
                    end
                    hWait = waitbar(0, 'Loading images data');
                    imgFltr = contains({imgFiles.name}, app.Opt.StimIDs) | contains({imgFiles.name}, app.Opt.RecIDs);
                    nFiles = sum(imgFltr);
                    tempT = cell(nFiles+1, 10);
                    tempT(1,:) = {'Filename', 'CellID', 'Week', 'BatchID', 'ConditionID', 'CoverslipID', 'RecID', 'StimID', 'ExperimentID', 'Fs'};
                    % Get the name info
                    nameParts = regexp({imgFiles.name}, '_', 'split')';
                    nameParts = nameParts(imgFltr);
                    bNew = false;
                    if contains(nameParts{1}{2}, '-')
                        batchID = cellfun(@(x) regexp(x{2},'-','split'), nameParts, 'UniformOutput', false);
                        batchID = cellfun(@(x) x{3}, batchID, 'UniformOutput', false);
                        bNew = true;
                    end
                    tempT(2:end,1) = fullfile({imgFiles(imgFltr).folder}, {imgFiles(imgFltr).name});
                    tempT(2:end,2) = cellfun(@(x) x(1:end-4), {imgFiles(imgFltr).name}, 'UniformOutput', false);
                    for f = 1:nFiles
                        waitbar(f/nFiles, hWait, sprintf('Loading movie data %0.2f%%', f/nFiles*100));
                        tempT{f+1,3} = weeknum(datetime(nameParts{f}{1}, 'InputFormat', 'yyMMdd'));
                        if ~bNew
                            tempT{f+1,4} = nameParts{f}{3};
                            tempT{f+1,5} = nameParts{f}{2};
                            tempT{f+1,6} = nameParts{f}{4};
                            tempT{f+1,7} = nameParts{f}{5};
                            tempT{f+1,8} = regexprep(nameParts{f}{6}, '.tif', '');
                            % Get the experiment ID (batchID + coverslipID + FOV)
                            tempT{f+1,9} = [nameParts{f}{3} '_' nameParts{f}{4} '_' nameParts{f}{5}];
                        else
                            tempT{f+1,4} = batchID{f};
                            tempT{f+1,5} = nameParts{f}{2};
                            tempT{f+1,6} = nameParts{f}{3};
                            tempT{f+1,7} = nameParts{f}{4};
                            tempT{f+1,8} = regexprep(nameParts{f}{5}, '.tif', '');
                            % Get the experiment ID (batchID + coverslipID + FOV)
                            tempT{f+1,9} = [batchID{f} '_' nameParts{f}{3} '_' nameParts{f}{4}];
                        end
                        % Try to get info on the actual timeStamp but not now
                        tempT{f+1,10} = app.Opt.ImgFrequency;
                    end
                    app.imgT = cell2table(tempT(2:end,:), 'VariableNames', tempT(1,:));
                    % Enable button selection
                    app.ImportROIsButton.Enable = 'on';
                    app.DetectROIsButton.Enable = 'on';
                    app.ShowMovieButton.Enable = 'on';
                    % Populate the CellID tab, as well as the RecID tab
                    waitbar(0.5, hWait, 'Populate list of cells');
                    app.currCell = 1;
                    populateCellID(app);
                    waitbar(0.9, hWait, 'Populate list of recordings');
                    populateRecID(app);
                    % Check if the images need to be register
                    if app.regMovie
                        recID = unique(app.imgT.ExperimentID);
                        nRec = numel(recID);
                        for r=1:nRec
                            waitbar(r/nRec, hWait, sprintf('Register the recordings %0.2f%%', r/nRec*100));
                            recList = find(matches(app.imgT.ExperimentID, recID{r}));
                            imgN = find(matches(app.imgT.StimID(recList), 'Naive')) + recList(1) -1;
                            imgS = find(matches(app.imgT.StimID(recList), '05Hz')) + recList(1) -1;
                            imgN = imread(app.imgT.Filename{imgN});
                            imgS = imread(app.imgT.Filename{imgS});
                            regEst = imregcorr(imgS, imgN, 'translation');
                            app.imgT{recList,'RegEst'} = {regEst.T};
                        end
                    end
                    % Show that we are done
                    delete(hWait);
                    togglePointer(app);
                    app.newChange = true;
                end
            catch ME
                delete(hWait);
                togglePointer(app);
                disp(ME)
                uiconfirm(app.UIFigure, 'Failed to load the data. Please check command window for details', 'Error', 'Icon', 'error');
            end
        end
        
        function FileMenuSaveSelected(app, event)
            % First save the settings
            saveSettings(app)
            % Then save the data
            oldDir = cd(app.Opt.LastPath);
            [fileName, filePath] = uiputfile('*.mat', 'Save network data');
            togglePointer(app);
            savePath = fullfile(filePath, fileName);
            figure(app.UIFigure);
            imgT = app.imgT;
            opt = app.Opt;
            stim = app.stim;
            ui.currCell = app.currCell;
            save(savePath, 'imgT', 'opt', 'stim', 'ui');
            cd(oldDir)
            togglePointer(app);
            app.newChange = false;
        end
        
        function FileMenuOpenSelected(app, event)
            if app.Opt.LastPath == 0
                app.Opt.LastPath = pwd;
            end
            [fileName, filePath] = uigetfile(app.Opt.LastPath, 'Select Analysis File');
            togglePointer(app)
            figure(app.UIFigure);
            try
                % Save the path to the settings
                app.Opt.LastPath = filePath;
                tempFiles = load(fullfile(filePath, fileName));
                % First check if there is files at the current path
                app.Opt = tempFiles.opt;
                app.imgT = tempFiles.imgT;
                if isfield(tempFiles, 'stim')
                    app.stim = tempFiles.stim;
                    if height(app.stim) > 1
                        app.TrainsIDsEdit.Value = app.stim.StimID(2);
                        app.BaselineSecEdit.Value = app.stim.Baseline(2);
                        app.TrainsNumEdit.Value = app.stim.nTrains(2);
                        app.APNumEdit.Value = app.stim.nAP(2);
                        app.APFreqEdit.Value = app.stim.FreqAP(2);
                        app.MergedRecordingsCheckBox.Value = app.stim.Merged(2);
                    end
                end
                % Enable button selection
                app.ImportROIsButton.Enable = 'on';
                app.DetectROIsButton.Enable = 'on';
                app.ShowMovieButton.Enable = 'on';
                % Load the last cell that was selected
                app.currCell = tempFiles.ui.currCell;
                % Populate the CellID tab, as well as the RecID tab
                populateCellID(app);
                populateRecID(app);
                togglePointer(app);
                % Check if the are ROIs (at least in the first image)
                if any(strcmp(app.imgT.Properties.VariableNames, 'RoiSet'))
                    app.ShowROIsButton.Enable = 'on';
                    app.MeasureROIsButton.Enable = 'on';
                    if ~isempty(app.imgT.RoiSet{1})
                        showROIs(app);
                    end
                end
                % Check if there is data that can be plotted
                if any(strcmp(app.imgT.Properties.VariableNames, 'DetrendData'))
                    app.AllFOVsRadio.Enable = 'on';
                    app.CurrentListRadio.Enable = 'on';
                    app.SelectedFOVRadio.Enable = 'on';
                    app.AllAndMeanRadio.Enable = 'on';
                    app.SingleTracesRadio.Enable = 'on';
                    app.ExportTraceButton.Enable = 'on';
                    app.DetrendButton.Enable = 'on';
                    app.DetectPeaksButton.Enable = 'on';
                    if ~isempty(app.imgT.DetrendData{1})
                        updatePlot(app);
                    end
                end
                % Check if there are already spikes detected
                if any(strcmp(app.imgT.Properties.VariableNames, 'PeakLoc'))
                    app.AddPeaksButton.Enable = 'on';
                    app.DeletePeaksButton.Enable = 'on';
                    app.KeepCellToggle.Enable = 'on';
                    app.FileMenuExport.Enable = 'on';
                end
                app.newChange = true;
            catch ME
                togglePointer(app);
                disp(ME)
                uiconfirm(app.UIFigure, 'Failed to load the data. Please check command window for details', 'Error', 'Icon', 'error');
            end
        end
        
        function FileMenuExportSelected(app, event)
            expT = app.imgT(:, [2:12 17 26:69]);
            [fileName, filePath] = uiputfile('*.csv', 'Export network data');
            writetable(expT, fullfile(filePath, fileName));
        end
        
        function OptionMenuDebugSelected(app)
            disp(['You are now in debug mode. To exit the debug use "dbquit".',...
                ' Use "dbcont" to continue with the changes made'])
            keyboard
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
            % Save the protocol
            if any(matches(app.stim.StimID, app.TrainsIDsEdit.Value))
                stimID = find(matches(app.stim.StimID, app.TrainsIDsEdit.Value));
                app.stim.Baseline(stimID) = app.BaselineSecEdit.Value;
                app.stim.nTrains(stimID) = app.TrainsNumEdit.Value;
                app.stim.nAP(stimID) = app.APNumEdit.Value;
                app.stim.FreqAP(stimID) = app.APFreqEdit.Value;
                app.stim.Merged(stimID) = app.MergedRecordingsCheckBox.Value;
            else
                app.stim.StimID(end+1) = app.TrainsIDsEdit.Value;
                app.stim.Baseline(end) = app.BaselineSecEdit.Value;
                app.stim.nTrains(end) = app.TrainsNumEdit.Value;
                app.stim.nAP(end) = app.APNumEdit.Value;
                app.stim.FreqAP(end) = app.APFreqEdit.Value;
                app.stim.Merged(end) = app.MergedRecordingsCheckBox.Value;
            end
            app.SaveButton.Enable = 'off';
        end
       
        function populateCellID(app)
            % Get the list of unique cell IDs
            cellIDs = unique(app.imgT.ExperimentID);
            app.List_CellID.Items = cellIDs;
            app.List_CellID.Enable = 'on';
            if app.currCell > numel(app.List_CellID.Items)
                app.currCell = numel(app.List_CellID.Items);
            end
            app.List_CellID.Value = app.List_CellID.Items(app.currCell);
            scroll(app.List_CellID, app.List_CellID.Value);
        end
        
        function populateRecID(app)
            % For the selected cell get the different recording
            cellFltr = matches(app.imgT.ExperimentID, app.List_CellID.Value);
            stimIDs = app.imgT.StimID(cellFltr);
            app.List_RecID.Items = [stimIDs(matches(stimIDs, 'Naive')); stimIDs(~matches(stimIDs, 'Naive'))];
            app.List_RecID.Enable = 'on';
            List_RecID_changed(app, []);
            % Check if we need to show the ROIs
            if numel(app.patchMask) > 0
                delete(app.patchMask)
            end
            if app.ShowROIsButton.Value
                roiSet =  app.imgT.RoiSet(cellFltr);
                if ~isempty(roiSet{1})
                    showROIs(app);
                end
            end
        end
        
        function prevButtonPressed(app)
            nSyn = size(app.imgT.DetrendData{app.currCell}, 2);
            currentSyn = app.TextSynNumber.Value;
            if currentSyn-1 < 1
                app.TextSynNumber.Value = nSyn;
            else
                app.TextSynNumber.Value = currentSyn-1;
            end
            updatePlot(app);
            figure(app.UIFigure);
        end
        
        function nextButtonPressed(app)
            nSyn = size(app.imgT.DetrendData{app.currCell}, 2);
            currentSyn = app.TextSynNumber.Value;
            if currentSyn+1 > nSyn
                app.TextSynNumber.Value = 1;
            else
                app.TextSynNumber.Value = currentSyn+1;
            end
            updatePlot(app);
            if app.ZoomInButton.Value
                app.UIAxesPlot.XLimMode = 'auto';
                oldXAxis = app.UIAxesPlot.XLim;
                newXAxis = [oldXAxis(1), oldXAxis(end)/10];
                app.UIAxesPlot.XLim = newXAxis;
            end
            figure(app.UIFigure);
        end
        
        function DetectPeaksButtonPressed(app)
            % Get the list of recordings for the detection
            switch app.DetectEventButtonGroup.SelectedObject.Text
                case 'All FOVs'
                    cellFltr = matches(app.imgT.StimID, app.List_RecID.Value);
                    %cellFltr = contains(app.imgT.StimID, 'Hz');
                case 'Current list'
                    cellFltr = contains(app.imgT.ExperimentID, app.List_CellID.Value);
                case 'Selected FOV'
                    cellFltr = contains(app.imgT.ExperimentID, app.List_CellID.Value) & matches(app.imgT.StimID, app.List_RecID.Value);
            end
            % Get the cells number
            cellIDs = find(cellFltr);
            nCell = numel(cellIDs);
            peakLoc = cell(nCell,1);
            peakInt = cell(nCell,1);
            peakProm = cell(nCell,1);
            peakSNR = cell(nCell,1);
            keepSyn = cell(nCell,1);
            syncPeak = cell(nCell,1);
            timeToRise = cell(nCell,1);
            endToPeak = cell(nCell,1);
            timeToDecay = cell(nCell,1);
            hWait = waitbar(0, 'Detecting peaks in data', 'Name', sprintf('Detecting %s', app.imgT.StimID{app.currCell}));
%             try
                for cells = 1:nCell
                    waitbar(cells/nCell, hWait, 'Detecting peaks in data');
                    c = cellIDs(cells);
                    tempData = app.imgT.DetrendData{c};
                    Fs = app.imgT.Fs(c);
                    nSyn = size(tempData,2);
                    synLoc = cell(nSyn,1);
                    synInt = cell(nSyn,1);
                    synProm = cell(nSyn,1);
                    synSNR = cell(nSyn,1);
                    synTimeToRise = cell(nSyn,1);
                    synEndToPeak = cell(nSyn,1);
                    synTimeToDecay = cell(nSyn,1);
                    for s = 1:nSyn
                        %waitbar(cells/nCell, hWait, sprintf('Detecting peaks in data (%d/%d synapses)', s, nSyn), 'Name', sprintf('Detecting %s', app.imgT.StimID{app.currCell}));
                        tempThr = calculateThreshold(app, tempData, s);
                        peakInfo = DetectPeaks(app, tempData(:,s), tempThr);
                        if ~isempty(peakInfo)
                            synInt{s} = peakInfo(:,1);
                            synLoc{s} = peakInfo(:,2);
                            synProm{s} = peakInfo(:,3);
                            synSNR{s} = peakInfo(:,4);
                            synTimeToRise{s} = peakInfo(:,5);
                            synEndToPeak{s} = peakInfo(:,6);
                            synTimeToDecay{s} = peakInfo(:,7);
                        else
                            synInt{s} = 0;
                            synLoc{s} = [];
                            synProm{s} = 0;
                            synSNR{s} = 0;
                            synTimeToRise{s} = 0;
                            synEndToPeak{s} = 0;
                            synTimeToDecay{s} = 0;
                        end
                    end
                    peakLoc{cells} = synLoc;
                    peakInt{cells} = synInt;
                    peakProm{cells} = synProm;
                    peakSNR{cells} = synSNR;
                    timeToRise{cells} = synTimeToRise;
                    endToPeak{cells} = synEndToPeak;
                    timeToDecay{cells} = synTimeToDecay;
                    if contains(app.imgT.StimID{app.currCell}, 'Hz')
                        stimID = find(matches(app.stim.StimID, app.imgT.StimID{app.currCell}));
                        if any(matches({'40Hz', '100Hz'}, app.imgT.StimID{app.currCell}))
                            if app.stim.nTrains(stimID) > 1
                                keepSyn{cells} = cellfun(@(x) sum(isnan(x)) < app.stim.nTrains(stimID)*2/3, synLoc);
                            else
                                keepSyn{cells} = cell2mat(synInt) >= mean(cell2mat(synInt), 'omitnan') - 1.5*std(cell2mat(synInt), 'omitnan');
                            end
                        else
                            %keepSyn{cells} = cellfun(@(x) sum(isnan(x)) < (app.stim.nAP(stimID)*app.stim.nTrains(stimID))*4/5, synLoc);
                            keepSyn{cells} = cellfun(@(x) sum(~isnan(x)) >= 2, synLoc);
                        end
                    else
                        keepSyn{cells} = cellfun(@(x) mean(x) >= 2.5, synSNR);
                    end
                    % Calculate the synchronous peaks (based on the minimum distance)
                    syncPeak{cells} = calculateSynchronous(app, synLoc, size(tempData,1), nSyn, keepSyn{cells}, Fs, contains(app.imgT.StimID{app.currCell}, 'Hz'));
                end
                app.imgT.PeakLoc(cellIDs) = peakLoc;
                app.imgT.PeakInt(cellIDs) = peakInt;
                app.imgT.PeakProm(cellIDs) = peakProm;
                app.imgT.PeakSNR(cellIDs) = peakSNR;
                app.imgT.KeepSyn(cellIDs) = keepSyn;
                app.imgT.PeakSync(cellIDs) = syncPeak;
                app.imgT.TimeToRise(cellIDs) = timeToRise;
                app.imgT.EndToPeak(cellIDs) = endToPeak;
                app.imgT.TimeToDecay(cellIDs) = timeToDecay;
                if ~any(strcmp(app.imgT.Properties.VariableNames, 'KeepCell'))
                    app.imgT.KeepCell(cellIDs) = true(height(app.imgT),1);
                end
                DetectCellPeaks(app);
                updatePlot(app);
                delete(hWait);  
                app.AddPeaksButton.Enable = 'on';
                app.DeletePeaksButton.Enable = 'on';
                app.KeepCellToggle.Enable = 'on';
                app.FileMenuExport.Enable = 'on';
                app.newChange = true;
%             catch ME
%                 sprintf('Error in cell %s at synapse %d.', app.imgT.CellID{c}, s)
%                 disp(ME)
%                 delete(hWait);
%                 uiconfirm(app.UIFigure, 'Failed to detect peaks. Please check command window for details', 'Error', 'Icon', 'error');
%             end
        end
        
        function addManualPeak(app, clickedPoint)
            % Get the trace of the synapse
            synN = app.TextSynNumber.Value;
            tempData = app.imgT.DetrendData{app.currCell}(:,synN);
            Fs = app.imgT.Fs(app.currCell);
            % Get the info about the other spikes
            if isempty(app.tempAddPeak)
                allLoc = app.imgT.PeakLoc{app.currCell}{synN};
                allInt = app.imgT.PeakInt{app.currCell}{synN};
                allProm = app.imgT.PeakProm{app.currCell}{synN};
                allSNR = app.imgT.PeakSNR{app.currCell}{synN};
            else
                allLoc = app.tempAddPeak.Loc;
                allInt = app.tempAddPeak.Int;
                allProm = app.tempAddPeak.Prom;
                allSNR = app.tempAddPeak.SNR;
            end
            % Define the searching area
            tempPoint = round(clickedPoint*Fs);
            searchLim = app.PeakMinDistanceEdit.Value + round((app.PeakMinDurationEdit.Value+app.PeakMaxDurationEdit.Value) / 2);
            searchLim = [tempPoint-searchLim tempPoint+searchLim];
            peakLim1 = allLoc(find(allLoc<tempPoint,1,'last'))+1;
            peakLim2 = allLoc(find(allLoc>tempPoint,1,'first'))-1;
            if isempty(peakLim2)
                peakLim2 = numel(tempData);
            end
            searchArea = max(peakLim1, searchLim(1)):min(peakLim2, searchLim(end));
            % Find the maxima of this area
            [newInt, newLoc, ~, newProm] = findpeaks(tempData(searchArea));
            [newInt, newFltr] = max(newInt);
            newLoc = newLoc(newFltr) + searchArea(1) -1;
            newProm = newProm(newFltr);
            newSNR = newInt / median(tempData);
            % Check if there are other spikes in this area
            if any(allLoc >= searchArea(1) & allLoc <= searchArea(end))
                uiconfirm(app.UIFigure, 'Peak already detected in this area', 'Error', 'Icon', 'error');
            else
                % Show the new point
                plot(app.UIAxesPlot, (newLoc-1)/Fs, newInt, 'ob');
                % Add the new peak to the table
                allLoc = [allLoc; newLoc];
                allInt = [allInt; newInt];
                allProm = [allProm; newProm];
                allSNR = [allSNR; newSNR];
                [allLoc, sortIdx] = sort(allLoc);
                allInt = allInt(sortIdx);
                allProm = allProm(sortIdx);
                allSNR = allSNR(sortIdx);
                app.tempAddPeak.Loc = allLoc;
                app.tempAddPeak.Int = allInt;
                app.tempAddPeak.Prom = allProm;
                app.tempAddPeak.SNR = allSNR;
            end
        end
        
        function addNetworkPeak(app, clickedPoint)
            % Get the data and the previous points
            if app.activeFltr
                bSyn = app.imgT.KeepSyn{app.currCell};
            else
                bSyn = true(numel(app.imgT.KeepSyn{app.currCell}),1);
            end
            tempTrace = mean(app.imgT.DetrendData{app.currCell}(:,bSyn), 2);
            tempSynapses = app.imgT.PeakSync{app.currCell};
            Fs = app.imgT.Fs(app.currCell);
            tempPoint = round(clickedPoint*Fs);
            if isempty(app.tempAddPeak)
                tempNetLoc = app.imgT.Sync_PeakLocation{app.currCell}{2};
                tempNetInt = app.imgT.Sync_SynapseCount{app.currCell}{2};
            else
                tempNetLoc = app.tempAddPeak.Loc;
                tempNetInt = app.tempAddPeak.Int;
            end
            % Get the search limits
            searchLim = app.Opt.PeakMinDistance + app.Opt.PeakMaxDuration;
            searchLim = [tempPoint-searchLim tempPoint+searchLim];
            if isempty(tempNetLoc(find(tempNetLoc<tempPoint,1,'last'))+1)
                peakLim = [1 tempNetLoc(find(tempNetLoc>tempPoint,1,'first'))-1];
            elseif isempty(tempNetLoc(find(tempNetLoc>tempPoint,1,'first'))-1)
                peakLim = [tempNetLoc(find(tempNetLoc<tempPoint,1,'last'))+1 numel(tempTrace)];
            else
                peakLim = [tempNetLoc(find(tempNetLoc<tempPoint,1,'last'))+1 tempNetLoc(find(tempNetLoc>tempPoint,1,'first'))-1];
            end
            searchLim = [max(searchLim(1), peakLim(1)), min(searchLim(2), peakLim(2))];
            % Find the maximum
            [maxV, maxI] = max(tempTrace(searchLim(1):searchLim(2)));
            maxI = maxI + searchLim(1) - 1;
            % Plot the new data
            plot(app.UIAxesPlot, (maxI-1)/Fs, maxV, 'sm', 'HitTest', 'off', 'ButtonDownFcn', '');
            % Add the data to the table
            app.tempAddPeak.Loc = [tempNetLoc; maxI];
            app.tempAddPeak.Int = [tempNetInt; tempSynapses(maxI)];
        end
        
        function deleteManualPeak(app, clickedPoint)
             % Get the trace of the synapse
            synN = app.TextSynNumber.Value;
            tempData = app.imgT.DetrendData{app.currCell}(:,synN);
            Fs = app.imgT.Fs(app.currCell);
            % Get the info about the other spikes
            allLoc = app.imgT.PeakLoc{app.currCell}{synN};
            allInt = app.imgT.PeakInt{app.currCell}{synN};
            % Define the searching area
            searchLim = app.PeakMinDistanceEdit.Value + app.PeakMaxDurationEdit.Value;
            tempPoint = round(clickedPoint*Fs);
            searchArea = tempPoint-searchLim:tempPoint+searchLim;
            % Find the peak to delete
            delPeak = find(allLoc > searchArea(1) & allLoc < searchArea(end));
            while numel(delPeak) > 1
                searchLim = searchLim / 2;
                searchArea = tempPoint-searchLim:tempPoint+searchLim;
                delPeak = find(allLoc > searchArea(1) & allLoc < searchArea(end));
            end
            if numel(delPeak) == 1
                % Show that this peak is deleted
                plot(app.UIAxesPlot, (allLoc(delPeak)-1)/Fs, allInt(delPeak), 'xr', 'LineWidth', 1.5);
                allLoc(delPeak) = [];
                allInt(delPeak) = [];
            end
            app.imgT.PeakLoc{app.currCell}{synN} = allLoc;
            app.imgT.PeakInt{app.currCell}{synN} = allInt;
            app.newChange = true;
        end
        
        function deleteNetworkPeak(app, clickedPoint)
            % Define the searching area
            Fs = app.imgT.Fs(app.currCell);
            tempTrace = mean(app.imgT.DetrendData{app.currCell}, 2);
            searchLim = app.Opt.PeakMinDistance + app.Opt.PeakMinDuration;
            tempPoint = round(clickedPoint*Fs);
            searchArea = tempPoint-searchLim:tempPoint+searchLim;
            if isempty(app.tempAddPeak)
                allLoc = app.imgT.Sync_PeakLocation{app.currCell}{2};
                allInt = app.imgT.Sync_SynapseCount{app.currCell}{2};
            else
                allLoc = app.tempAddPeak.Loc;
                allInt = app.tempAddPeak.Int;
            end
            % Find the peak to delete
            delPeak = find(allLoc > searchArea(1) & allLoc < searchArea(end));
            if numel(delPeak) == 1
                % Show that this peak is deleted
                plot(app.UIAxesPlot, (allLoc(delPeak)-1)/Fs, tempTrace(allLoc(delPeak)), 'xr', 'LineWidth', 1.5);
                app.tempAddPeak.Loc = [allLoc(~(allLoc > searchArea(1) & allLoc < searchArea(end))); allLoc(delPeak)];
                app.tempAddPeak.Int = [allInt(~(allLoc > searchArea(1) & allLoc < searchArea(end))); allInt(delPeak)];
            end
        end
        
        function TableFilterSelected(app, event)
            % First get the value to use for filtering
            fltrVal = str2double(inputdlg('Choose the minimum value', 'Filter value'));
            % Get the right cell
            tempKeep = app.UITableSingle.Data.synKeep;
            stimFltr = find(contains(app.imgT.StimID, app.imgT.StimID{app.currCell}));
            switch event.Source.Text
                case 'Mean Intensity'
                    % Get the averave intensity of the synapses
                    tempPeak = app.UITableSingle.Data.synInt;
                    tempKeep = tempPeak > fltrVal;
                    for s = stimFltr'
                        tempPeaks = app.imgT.PeakProm{s};
                        filtered = cellfun(@(x) mean(x, 'omitnan') > fltrVal, tempPeaks);
                        app.imgT.KeepSyn{s} = filtered;
                    end
                case 'Mean Frequency'
                    % Get the frequency of spikes per synapse
                    tempFreq = app.UITableSingle.Data.synFreq;
                    tempKeep = tempFreq > fltrVal;
                    app.imgT.KeepSyn{app.currCell} = tempKeep;
                case 'Mean SNR'
                    tempSNR = app.UITableSingle.Data.snr;
                    tempKeep = tempSNR >= fltrVal;
                    app.imgT.KeepSyn{app.currCell} = tempKeep;
            end
            % Store the new values and update the raster plot
            app.UITableSingle.Data.synKeep = tempKeep;
            updateRaster(app);
            app.newChange = true;
        end
        
        function OptionChanged(app)
            app.SaveButton.Enable = 'on';
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
        
        function List_RecID_changed(app, event)
            % First get the cellID and the filename
            app.currCell = find(matches(app.imgT.ExperimentID, app.List_CellID.Value) & matches(app.imgT.StimID, app.List_RecID.Value));
            fileName = app.imgT.Filename{app.currCell};
            % Load the first frame and display it
            imgFile = imread(fileName);
            imgMin = min(imgFile, [], 'all');
            imgMax = max(imgFile, [], 'all');
            imgDisp = [imgMin imgMax] / 255;
            if app.regMovie
                if contains(app.List_RecID.Value, 'Hz')
                    imgOut = imref2d(size(imgFile));
                    regEst = affine2d(app.imgT.RegEst{app.currCell});
                    imgFile = imwarp(imgFile, regEst, 'OutputView', imgOut);
                end
            end
            imshow(imadjust(imgFile, [0 1]), 'Parent', app.UIAxesMovie);
            app.UIAxesMovie.YLim = [0 size(imgFile,1)];
            app.UIAxesMovie.XLim = [0 size(imgFile,2)];
            set(app.UIAxesMovie, 'YDir', 'reverse');
            showROIs(app);
            % Plot the data
            if any(strcmp(app.imgT.Properties.VariableNames, 'DetrendData'))
                fixYAxis(app);
                updatePlot(app);
                app.KeepCellToggle.BackgroundColor = app.keepColor(app.imgT.KeepCell(app.currCell)+1,:);
                app.KeepCellToggle.Value = app.imgT.KeepCell(app.currCell);
            end
            % Update the stimulation protocol
            if any(matches(app.stim.StimID, app.List_RecID.Value))
                stimID = find(matches(app.stim.StimID, app.List_RecID.Value));
                app.TrainsIDsEdit.Value = app.stim.StimID(stimID);
                app.BaselineSecEdit.Value = app.stim.Baseline(stimID);
                app.TrainsNumEdit.Value = app.stim.nTrains(stimID);
                app.APNumEdit.Value = app.stim.nAP(stimID);
                app.APFreqEdit.Value = app.stim.FreqAP(stimID);
                app.MergedRecordingsCheckBox.Value = app.stim.Merged(stimID);
            end
        end
        
        function ImportROIsButtonPressed(app)
            roiPath = uigetdir(app.Opt.LastPath, 'Select ROI folder');
            roiFiles = dir(fullfile(roiPath, '*.zip'));
            togglePointer(app);
            figure(app.UIFigure);
            try
                % Get the name info
                nameList = regexprep({roiFiles.name}, '.zip', '');
                nameParts = regexp(nameList, '_', 'split')';
                nFiles = numel(nameList);
                allRois = cell(size(app.imgT,1), 1);
                hWait = waitbar(0, 'Importing ROI data');
                for f = 1:nFiles
                    waitbar(f/nFiles, hWait, sprintf('Loading ROIs data %0.2f%%', f/nFiles*100));
                    % Match the ROI to the expetimentID
                    if size(nameParts{1},2) == 6
                        expID = [nameParts{f}{4} '_' nameParts{f}{5} '_' nameParts{f}{6}];
                    else
                        batchID = cellfun(@(x) regexp(x{3},'-','split'), nameParts, 'UniformOutput', false);
                        batchID = cellfun(@(x) x{3}, batchID, 'UniformOutput', false);
                        expID = [batchID{f} '_' nameParts{f}{4} '_' nameParts{f}{5}];
                    end
                    cellFltr = matches(app.imgT.ExperimentID, expID);
                    % Extract the ROIs
                    tempRoi = ReadImageJROI(fullfile({roiFiles(f).folder}, {roiFiles(f).name}));
                    tempRoi = cellfun(@(x) x.vnRectBounds, tempRoi{:}, 'UniformOutput', false);
                    % There might be ROIs that are outside the boundary of the image, fix them
                    tempRoi = cellfun(@(x) min(450, x), tempRoi, 'UniformOutput', false); % need to be adjusted
                    tempRoi = cellfun(@(x) max(1, x), tempRoi, 'UniformOutput', false); % need to be adjusted
                    % Add the ROI to the right cells
                    allRois(cellFltr) = {tempRoi};
                end
                app.imgT.RoiSet = allRois;
                delete(hWait);
                togglePointer(app)
            catch ME
                delete(hWait);
                togglePointer(app);
                disp(ME)
                uiconfirm(app.UIFigure, 'Failed to load the RoiSet. Please check command window for details', 'Error', 'Icon', 'error');
            end
            app.ShowROIsButton.Enable = 'on';
            app.ShowROIsButton.Value = 1;
            app.MeasureROIsButton.Enable = 'on';
            showROIs(app);
        end
        
        function MeasureROIsButtonPressed(app)
            % First get the list of cells where there are ROIs
            cellFltr = cellfun(@(x) ~isempty(x), app.imgT.RoiSet);
            % Create a cell array to contain the intensity values
            rawData = cell(height(app.imgT), 1);
            ff0Data = cell(height(app.imgT), 1);
            detData = cell(height(app.imgT), 1);
            hWait = waitbar(0, 'Measuring ROIs data');
            for c = find(cellFltr)'
                waitbar(c/numel(cellFltr), hWait, sprintf('Loading ROIs data %0.2f%%', c/numel(cellFltr)*100));
                try
                    % Load the movie
                    currMovie = double(loadMovie(app, c, false));
                    nFrames = size(currMovie,3);
                    % Get the ROIs data
                    roiSet = app.imgT.RoiSet{c};
                    nRoi = numel(roiSet);
                    tempData = zeros(nFrames, nRoi);
                    for r = 1:nRoi
                        tempData(:,r) = mean(currMovie(roiSet{r}(1):roiSet{r}(3), roiSet{r}(2):roiSet{r}(4), :), [1 2]);
                    end
                    rawData{c} = tempData;
                    % Calculate the FF0 data
                    if contains(app.imgT.StimID{c}, app.Opt.StimIDs)
                        % There is a baseline, use this to calculate the FF0
                        stimID = matches(app.stim.StimID, app.imgT.StimID{c});
                        if app.stim{stimID, 'Merged'}==0
                            baseFrames = round(0.7 * app.imgT.Fs(c) * app.stim{stimID,'Baseline'});
                            baseInts = mean(tempData(1:baseFrames, :));
                            ff0Data{c} = (tempData - repmat(baseInts, nFrames, 1)) ./ repmat(baseInts, nFrames, 1);
                        else
                            baseFrames = round(0.7 * app.imgT.Fs(c) * app.stim{stimID,'Baseline'});
                            % There are multiple movies merged into 1. Split them and work on each movie separate
                            movDiv = nFrames / app.stim{stimID, 'nTrains'};
                            movS = 1:movDiv:nFrames;
                            movE = movDiv:movDiv:nFrames;
                            for m = 1:numel(movS)
                                baseInts = mean(tempData(movS(m):movS(m)+baseFrames, :));
                                ff0Data{c}(movS(m):movE(m),:) = (tempData(movS(m):movE(m),:) - repmat(baseInts, movDiv, 1)) ./ repmat(baseInts, movDiv, 1);
                            end
                            ff0Data{c}(movS,:) = NaN;
                        end
                    else
                        % There is no baseline (aka spontaneous recording). Detect the median intensity in 10 region of the recordings to calculate the deltaF/F0
                        frameDividers = [1:round(nFrames / 10):nFrames, nFrames];
                        minVals = zeros(10, nRoi);
                        for idx = 1:10
                            minVals(idx, :) = median(tempData(frameDividers(idx):frameDividers(idx+1), :));
                        end
                        baseInts = mean(minVals);
                        ff0Data{c} = (tempData - repmat(baseInts, nFrames, 1)) ./ repmat(baseInts, nFrames, 1);
                    end
                    detData{c} = ff0Data{c};
                catch ME
                    disp(ME);
                end
            end
            delete(hWait);
            app.imgT.RawData(cellFltr) = rawData(cellFltr);
            app.imgT.FF0Data(cellFltr) = ff0Data(cellFltr);
            app.imgT.DetrendData(cellFltr) = detData(cellFltr);
            app.imgT.KeepCell(cellFltr) = true(sum(cellFltr),1);
            app.AllFOVsRadio.Enable = 'on';
            app.CurrentListRadio.Enable = 'on';
            app.SelectedFOVRadio.Enable = 'on';
            app.AllAndMeanRadio.Enable = 'on';
            app.SingleTracesRadio.Enable = 'on';
            app.ExportTraceButton.Enable = 'on';
            app.DetrendButton.Enable = 'on';
            app.DetectPeaksButton.Enable = 'on';
            app.MeasureROIsButton.Enable = 'off';
            app.newChange = true;
            updatePlot(app)
        end
        
        function switchPlotType(app)
            app.PrevButton.Enable = ~app.PrevButton.Enable;
            app.NextButton.Enable = ~app.NextButton.Enable;
            app.TextSynNumber.Enable = ~app.TextSynNumber.Enable;
            app.FixYAxisButton.Enable = ~app.FixYAxisButton.Enable;
            updatePlot(app);
        end
        
        function SliderMovieMoved(app, event)
            if app.SliderMovie.Visible
                if nargin == 2 && isprop(event, 'VerticalScrollCount')
                    sliceToShow = round(app.SliderMovie.Value + event.VerticalScrollCount);
                    if sliceToShow < 1
                        return
                    end
                else
                    sliceToShow = round(event.Value);
                end
                app.SliderMovie.Value = sliceToShow;
                Fs = app.imgT.Fs(app.currCell);
                app.currSlice.CData = app.movieData(:,:,sliceToShow);
                app.curTime.XData = ones(2,1)*sliceToShow/Fs - 1/Fs;
            end
        end
        
        function fixYAxis(app)
            tempData = app.imgT.DetrendData{app.currCell};
            yMin = min(tempData, [], 'all');
            yMax = max(tempData, [], 'all');
            app.yLim = [yMin, yMax];
            if app.FixYAxisButton.Value
                app.UIAxesPlot.YLim = app.yLim;
            else
                app.UIAxesPlot.YLimMode = 'auto';
            end
            figure(app.UIFigure);
        end
        
        function ZoomIn(app, event)
            switch event.Source.Text
                case 'Zoom In'
                    if app.ZoomInButton.Value
                        oldXAxis = app.UIAxesPlot.XLim;
                        newXAxis = [oldXAxis(1), 10]; % 1 is one second
                        app.UIAxesPlot.XLim = newXAxis;
                    else
                        app.UIAxesPlot.XLimMode = 'auto';
                    end
                case 'Zoom'
                    if app.ZoomRasterButton.Value
                        ticks = app.UIAxesRaster.YTick;
                        yInc = mean(diff(ticks));
                        newXAxis = [0, ticks(10)+(2*yInc)];
                        app.UIAxesRaster.YLim = newXAxis;
                    else
                        ticks = app.UIAxesRaster.YTick;
                        yInc = mean(diff(ticks));
                        app.UIAxesRaster.YLim = [0 ticks(end)+(2*yInc)];
                    end
            end
            figure(app.UIFigure);
        end
        
        function keyPressed(app, event)
            if strcmpi(event.Modifier, 'control')
                switch event.Key
                    case "z"
                        if app.AddPeaksButton.Value
                            app.tempAddPeak.Loc = app.tempAddPeak.Loc(1:end-1);
                            app.tempAddPeak.Int = app.tempAddPeak.Int(1:end-1);
                        elseif app.DeletePeaksButton.Value
                            lastMod = app.tempAddPeak.Loc(end);
                            lastIdx = find(app.tempAddPeak.Loc > lastMod, 1, 'first');
                            app.tempAddPeak.Loc = [app.tempAddPeak.Loc(1:lastIdx-1); lastMod; app.tempAddPeak.Loc(lastIdx:end-1)];
                            app.tempAddPeak.Int = [app.tempAddPeak.Int(1:lastIdx-1); app.tempAddPeak.Int(end); app.tempAddPeak.Int(lastIdx:end-1)];
                        end
                        delete(app.UIAxesPlot.Children(1));
                end
            else
                switch event.Key
                    case "a" % Add new peaks
                        app.AddPeaksButton.Value = true;
                        val.Source.Text = 'Add peaks';
                        crosshairCursor(app, val);
                    case "d" % Delete peaks
                        app.DeletePeaksButton.Value = true;
                        val.Source.Text = 'Delete peaks';
                        crosshairCursor(app, val);
                    case "rightarrow" % move to next synapse
                        if app.SingleTracesRadio.Value
                            nextButtonPressed(app)
                        end
                    case "leftarrow" % move to previous synapse
                        if app.SingleTracesRadio.Value
                            prevButtonPressed(app)
                        end
                    case "downarrow" % move to next cell
                        thisCell = find(matches(app.List_CellID.Items, app.List_CellID.Value));
                        nCells = numel(app.List_CellID.Items);
                        if thisCell < nCells
                            app.List_CellID.Value = app.List_CellID.Items{thisCell + 1};
                        else
                            app.List_CellID.Value = app.List_CellID.Items{1};
                        end
                        scroll(app.List_CellID, app.List_CellID.Value);
                        populateRecID(app);
                        populateTable(app, event)
                    case "uparrow" % move to next cell
                        thisCell = find(matches(app.List_CellID.Items, app.List_CellID.Value));
                        nCells = numel(app.List_CellID.Items);
                        if thisCell > 1
                            app.List_CellID.Value = app.List_CellID.Items{thisCell - 1};
                        else
                            app.List_CellID.Value = app.List_CellID.Items{nCells};
                        end
                        scroll(app.List_CellID, app.List_CellID.Value);
                        populateRecID(app);
                        populateTable(app, event)
                    case "z" % Zoom in the trace plot
                        app.ZoomInButton.Value = ~app.ZoomInButton.Value;
                        var.Source.Text = 'Zoom In';
                        ZoomIn(app, var); 
                    case "space" % Toogle if keeping the cell or not
                        keepCell(app);
                end
            end
        end
        
        function ExportPlot(app, event)
            switch event.Source.Text
                case 'Export'
                    tempTraces = app.imgT.DetrendData{app.currCell};
                    hRaster = figure('Name', 'Raster', 'NumberTitle', 'off', 'Color', 'white', 'Position', [433 338 731 562]);
                    aRaster = axes(hRaster);
                    hOverview = figure('Name', 'Overview', 'NumberTitle', 'off', 'Color', 'white', 'Position', [433 12 726 289]);
                    aOverview = axes(hOverview);
                    if contains(app.imgT.StimID{app.currCell}, 'Hz')
                        plotRasterStim(app, tempTraces, aRaster, aOverview);
                    else
                        plotRaster(app, tempTraces, aRaster, aOverview);
                    end
                case 'Export trace'
                    hTrace = figure('Name', 'Trace', 'NumberTitle', 'off', 'Color', 'white');
                    aTrace = axes(hTrace);
                    updatePlot(app, aTrace);
                    aTrace.TickDir = 'out';
                    ylabel(aTrace, 'iGluSnFR intensity (a.u.)')
                    xlabel(aTrace, 'Time (s)')
                case 'Export plot'
                    hBox = figure('Name', 'Boxplot', 'NumberTitle', 'off', 'Color', 'white', 'Position', [1300 340 560 560]);
                    aBox = axes(hBox);
                    var.Key = 'shift';
                    TableSelectedCell(app, var, aBox);
            end
        end
        
        function keepCell(app)
            app.imgT.KeepCell(app.currCell) = ~app.imgT.KeepCell(app.currCell);
            app.KeepCellToggle.BackgroundColor = app.keepColor(app.imgT.KeepCell(app.currCell)+1,:);
            updatePlot(app);
            if strcmp(app.TabGroup.SelectedTab.Title, 'Table')
                togglePointer(app)
                updateRaster(app,[]);
                app.UITableAll.Data.cellKeep(app.currCell) = ~app.UITableAll.Data.cellKeep(app.currCell);
                togglePointer(app)
            end
            figure(app.UIFigure);
            app.newChange = true;
        end
        
        function ExtractPeakFeatures(app)
             % Get the cells where there is data
            dataFltr = find(cellfun(@(x) ~isempty(x), app.imgT.PeakLoc));
            try
                togglePointer(app);
                hWait = waitbar(0, 'Quantify peaks in data');
                for c = dataFltr'
                    waitbar(c/numel(dataFltr), hWait, 'Quantify peaks in data');
                    tempTraces = app.imgT.DetrendData{c};
                    Fs = app.imgT.Fs(c);
                    nFrames = size(tempTraces, 1);
                    synKeep = app.imgT.KeepSyn{c};
                    nSyn = sum(synKeep);
                    meanTrace = mean(tempTraces(:,synKeep),2);
                    % Get the single synapse quantification
                    synInt = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakInt{c});
                    synProm = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakProm{c});
                    SynAUC = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakSNR{c});
                    synFreq = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakInt{c}) / (nFrames/Fs);
                    synISI = cellfun(@(x) diff(x) / Fs, app.imgT.PeakLoc{c}, 'UniformOutput', false);
                    synTimeToRise = cellfun(@(x) mean(x, 'omitnan'), app.imgT.TimeToRise{c});
                    synEndToPeak = cellfun(@(x) mean(x, 'omitnan'), app.imgT.EndToPeak{c});
                    synTimeToDecay = cellfun(@(x) mean(x, 'omitnan'), app.imgT.TimeToDecay{c});
                    % Get the stimulation data if needed
                    bStim = contains(app.imgT.StimID{app.currCell}, 'Hz');
                    if bStim
                        stimID = find(matches(app.stim.StimID, app.imgT.StimID(c)));
                        xStim = app.stim.Baseline(stimID):1/app.stim.FreqAP(stimID):(app.stim.Baseline(stimID))+(1/app.stim.FreqAP(stimID))*(app.stim.nAP(stimID)-1);
                        if app.stim.nTrains(stimID) > 1
                            % There are multiple movies merged into 1. Split them and work on each movie separate
                            movDiv = numel(time) / app.stim.nTrains(stimID);
                            movS = 1:movDiv:numel(time);
                            movS = time(movS);
                            xStim = round((repmat(xStim, 1, app.stim.nTrains(stimID)) + repelem(movS, app.stim.nAP(stimID)))*Fs);
                        else
                            xStim = round(xStim*Fs);
                        end
                        nAP = numel(xStim);
                        stimRes = arrayfun(@(x) app.imgT.PeakSync{c}(x-1:x+1), xStim, 'UniformOutput', false);
                        stimRes = cell2mat(stimRes);
                        stimRes = stimRes(3,:);
                    end
                    if nSyn > 0
                        % Mean, median, and variance for synapse
                        app.imgT.Syn_Mean_Intensity(c) = mean(synInt(synKeep));
                        app.imgT.Syn_Mean_Prominence(c) = mean(synProm(synKeep));
                        app.imgT.Syn_Mean_AUC(c) = mean(SynAUC(synKeep));
                        app.imgT.Syn_Mean_Frequency(c) = mean(synFreq(synKeep));
                        app.imgT.Syn_Mean_ISI(c) = mean(cell2mat(synISI(synKeep)));
                        app.imgT.Syn_Mean_RiseTime(c) = mean(synTimeToRise(synKeep));
                        app.imgT.Syn_Mean_EndToPeak(c) = mean(synEndToPeak(synKeep));
                        app.imgT.Syn_Mean_DecayTime(c) = mean(synTimeToDecay(synKeep));
                        app.imgT.Syn_Median_Intensity(c) = median(synInt(synKeep));
                        app.imgT.Syn_Median_Prominence(c) = median(synProm(synKeep));
                        app.imgT.Syn_Median_AUC(c) = median(SynAUC(synKeep));
                        app.imgT.Syn_Median_Frequency(c) = median(synFreq(synKeep));
                        app.imgT.Syn_Median_ISI(c) = median(cell2mat(synISI(synKeep)));
                        app.imgT.Syn_Median_RiseTime(c) = median(synTimeToRise(synKeep));
                        app.imgT.Syn_Median_EndToPeak(c) = median(synEndToPeak(synKeep));
                        app.imgT.Syn_Median_DecayTime(c) = median(synTimeToDecay(synKeep));
                        app.imgT.Syn_Variance_Intensity(c) = var(synInt(synKeep));
                        app.imgT.Syn_Variance_Prominence(c) = var(synProm(synKeep));
                        app.imgT.Syn_Variance_AUC(c) = var(SynAUC(synKeep));
                        app.imgT.Syn_Variance_Frequency(c) = var(synFreq(synKeep));
                        app.imgT.Syn_Variance_ISI(c) = var(cell2mat(synISI(synKeep)));
                        app.imgT.Syn_Variance_RiseTime(c) = var(synTimeToRise(synKeep));
                        app.imgT.Syn_Variance_EndToPeak(c) = var(synEndToPeak(synKeep));
                        app.imgT.Syn_Variance_DecayTime(c) = var(synTimeToDecay(synKeep));
                        % Histogram description of all the synapses in one cell
                        app.imgT.Syn_Skewness_Intensity(c) = skewness(cell2mat(app.imgT.PeakInt{c}(synKeep)), 0);
                        app.imgT.Syn_Skewness_Prominence(c) = skewness(cell2mat(app.imgT.PeakProm{c}(synKeep)), 0);
                        app.imgT.Syn_Skewness_AUC(c) = skewness(cell2mat(app.imgT.PeakSNR{c}(synKeep)), 0);
                        app.imgT.Syn_Skewness_Frequency(c) = skewness(synFreq(synKeep), 0);
                        app.imgT.Syn_Skewness_ISI(c) = skewness(cell2mat(synISI(synKeep)), 0);
                        app.imgT.Syn_Skewness_RiseTime(c) = skewness(synTimeToRise(synKeep));
                        app.imgT.Syn_Skewness_EndToPeak(c) = skewness(synEndToPeak(synKeep));
                        app.imgT.Syn_Skewness_DecayTime(c) = skewness(synTimeToDecay(synKeep));
                        app.imgT.Syn_Kurtosis_Intensity(c) = kurtosis(cell2mat(app.imgT.PeakInt{c}(synKeep)), 0) -3;
                        app.imgT.Syn_Kurtosis_Prominence(c) = kurtosis(cell2mat(app.imgT.PeakProm{c}(synKeep)), 0) -3;
                        app.imgT.Syn_Kurtosis_AUC(c) = kurtosis(cell2mat(app.imgT.PeakSNR{c}(synKeep)), 0) -3;
                        app.imgT.Syn_Kurtosis_Frequency(c) = kurtosis(synFreq(synKeep), 0) -3;
                        app.imgT.Syn_Kurtosis_ISI(c) = kurtosis(cell2mat(synISI(synKeep)), 0) -3;
                        app.imgT.Syn_Kurtosis_RiseTime(c) = kurtosis(synTimeToRise(synKeep));
                        app.imgT.Syn_Kurtosis_EndToPeak(c) = kurtosis(synEndToPeak(synKeep));
                        app.imgT.Syn_Kurtosis_DecayTime(c) = kurtosis(synTimeToDecay(synKeep));
                        % Coefficient of variation between the synapses
                        app.imgT.Syn_CoV_Intensity(c) = sqrt(app.imgT.Syn_Variance_Intensity(c)) / app.imgT.Syn_Mean_Intensity(c);
                        app.imgT.Syn_CoV_Prominence(c) = sqrt(app.imgT.Syn_Variance_Prominence(c)) / app.imgT.Syn_Mean_Prominence(c);
                        app.imgT.Syn_CoV_AUC(c) = sqrt(app.imgT.Syn_Variance_AUC(c)) / app.imgT.Syn_Mean_AUC(c);
                        app.imgT.Syn_CoV_Frequency(c) = sqrt(app.imgT.Syn_Variance_Frequency(c)) / app.imgT.Syn_Mean_Frequency(c);
                        app.imgT.Syn_CoV_ISI(c) = sqrt(app.imgT.Syn_Variance_ISI(c)) / app.imgT.Syn_Mean_ISI(c);
                        app.imgT.Syn_CoV_RiseTime(c) = sqrt(app.imgT.Syn_Variance_RiseTime(c)) / app.imgT.Syn_Mean_RiseTime(c);
                        app.imgT.Syn_CoV_EndToPeak(c) = sqrt(app.imgT.Syn_Variance_EndToPeak(c)) / app.imgT.Syn_Mean_EndToPeak(c);
                        app.imgT.Syn_CoV_DecayTime(c) = sqrt(app.imgT.Syn_Variance_DecayTime(c)) / app.imgT.Syn_Mean_DecayTime(c);
                        if bStim
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            % QUANTAL ANALYSIS FOR THE PEAKS? SEE 10.1038/s41467-022-31070-4 %
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            % Get the stimulation-based quantifications
                            app.imgT.Stim_Resiliance{c} = stimRes;
                            app.imgT.Stim_FirstEvoked(c) = mean(cellfun(@(x) x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan');
                            if ~any(matches({'40Hz' '100Hz'}, app.imgT.StimID{c}))
                                app.imgT.Stim_PPR(c) = mean(cellfun(@(x) x(2)/x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan');
                                app.imgT.Stim_FFR(c) = mean(cellfun(@(x) x(min(5, nAP))/x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan'); % Fifth to First Ratio
                                app.imgT.Stim_LFR(c) = mean(cellfun(@(x) x(nAP)/x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan'); % Last to First Ratio
                            end
                            app.imgT.Stim_Raw_MaxActiveSynapses(c) = max(app.imgT.PeakSync{c});
                            app.imgT.Stim_Percentage_MaxActiveSynapses(c) = (max(app.imgT.PeakSync{c}) ./ nSyn * 100);
                        end
                        % Get the synchronous-based quantifications
                        if any(contains(app.imgT.Properties.VariableNames, 'Sync_PeakLocation'))
                            app.imgT.Sync_Frequency(c) = numel(app.imgT.Sync_PeakLocation{c}{1}) / (nFrames/Fs);
                            app.imgT.Sync_Raw_MaxActiveSynapses(c) = max(app.imgT.PeakSync{c});
                            app.imgT.Sync_Percentage_MaxActiveSynapses(c) = (max(app.imgT.PeakSync{c}) ./ nSyn * 100);
                            app.imgT.Sync_Percentage_TimeActive(c) = sum(app.imgT.PeakSync{c} > 1) / nFrames * 100;
                            app.imgT.Sync_Percentage_TimeSync(c) = sum(app.imgT.PeakSync{c} > nSyn *.1) / nFrames * 100;
                            % Get the cell-based quantifications
                            tempCellPeak = app.imgT.Sync_PeakLocation{c}{2};
                            cellISI = diff(tempCellPeak) / Fs;
                            app.imgT.Cell_Frequency(c) = numel(tempCellPeak) / (nFrames/Fs);
                            app.imgT.Cell_Mean_ActiveSynapses(c) = mean(app.imgT.Sync_SynapseCount{c}{2});
                            app.imgT.Cell_Mean_PercentageSynapses(c) = app.imgT.Cell_Mean_ActiveSynapses(c) / nSyn * 100;
                            app.imgT.Cell_Mean_Intensity(c) = mean(meanTrace(tempCellPeak));
                            app.imgT.Cell_Mean_InterSpikeInterval(c) = mean(cellISI);
                            app.imgT.Cell_Median_ActiveSynapses(c) = median(app.imgT.Sync_SynapseCount{c}{2});
                            app.imgT.Cell_Median_PercentageSynapses(c) = app.imgT.Cell_Median_ActiveSynapses(c) / nSyn * 100;
                            app.imgT.Cell_Median_Intensity(c) = median(meanTrace(tempCellPeak));
                            app.imgT.Cell_Median_InterSpikeInterval(c) = median(cellISI);
                            app.imgT.Cell_Variance_ActiveSynapses(c) = var(app.imgT.Sync_SynapseCount{c}{2});
                            app.imgT.Cell_Variance_Intensity(c) = var(meanTrace(tempCellPeak));
                            app.imgT.Cell_Variance_InterSpikeInterval(c) = var(cellISI);
                            app.imgT.Cell_CoV_ActiveSynapses(c) = sqrt(app.imgT.Cell_Variance_ActiveSynapses(c)) / app.imgT.Cell_Mean_ActiveSynapses(c);
                            app.imgT.Cell_CoV_Intensity(c) = sqrt(app.imgT.Cell_Variance_Intensity(c)) / app.imgT.Cell_Mean_Intensity(c);
                            app.imgT.Cell_CoV_InterSpikeInterval(c) = sqrt(app.imgT.Cell_Variance_InterSpikeInterval(c)) / app.imgT.Cell_Mean_InterSpikeInterval(c);
                        end
                    else
                        app.imgT.Syn_Mean_Intensity(c) = NaN;
                        app.imgT.Syn_Mean_Prominence(c) = NaN;
                        app.imgT.Syn_Mean_AUC(c) = NaN;
                        app.imgT.Syn_Mean_Frequency(c) = NaN;
                        app.imgT.Syn_Mean_ISI(c) = NaN;
                        app.imgT.Syn_Mean_RiseTime(c) = NaN;
                        app.imgT.Syn_Mean_EndToPeak(c) = NaN;
                        app.imgT.Syn_Mean_DecayTime(c) = NaN;
                        app.imgT.Syn_Median_Intensity(c) = NaN;
                        app.imgT.Syn_Median_Prominence(c) = NaN;
                        app.imgT.Syn_Median_AUC(c) = NaN;
                        app.imgT.Syn_Median_Frequency(c) = NaN;
                        app.imgT.Syn_Median_ISI(c) = NaN;
                        app.imgT.Syn_Median_RiseTime(c) = NaN;
                        app.imgT.Syn_Median_EndToPeak(c) = NaN;
                        app.imgT.Syn_Median_DecayTime(c) = NaN;
                        app.imgT.Syn_Variance_Intensity(c) = NaN;
                        app.imgT.Syn_Variance_Prominence(c) = NaN;
                        app.imgT.Syn_Variance_AUC(c) = NaN;
                        app.imgT.Syn_Variance_Frequency(c) = NaN;
                        app.imgT.Syn_Variance_ISI(c) = NaN;
                        app.imgT.Syn_Variance_RiseTime(c) = NaN;
                        app.imgT.Syn_Variance_EndToPeak(c) = NaN;
                        app.imgT.Syn_Variance_DecayTime(c) = NaN;
                        app.imgT.Syn_Skewness_Intensity(c) = NaN;
                        app.imgT.Syn_Skewness_Prominence(c) = NaN;
                        app.imgT.Syn_Skewness_AUC(c) = NaN;
                        app.imgT.Syn_Skewness_Frequency(c) = NaN;
                        app.imgT.Syn_Skewness_ISI(c) = NaN;
                        app.imgT.Syn_Skewness_RiseTime(c) = NaN;
                        app.imgT.Syn_Skewness_EndToPeak(c) = NaN;
                        app.imgT.Syn_Skewness_DecayTime(c) = NaN;
                        app.imgT.Syn_Kurtosis_Intensity(c) = NaN;
                        app.imgT.Syn_Kurtosis_Prominence(c) = NaN;
                        app.imgT.Syn_Kurtosis_AUC(c) = NaN;
                        app.imgT.Syn_Kurtosis_Frequency(c) = NaN;
                        app.imgT.Syn_Kurtosis_ISI(c) = NaN;
                        app.imgT.Syn_Kurtosis_RiseTime(c) = NaN;
                        app.imgT.Syn_Kurtosis_EndToPeak(c) = NaN;
                        app.imgT.Syn_Kurtosis_DecayTime(c) = NaN;
                        app.imgT.Syn_CoV_Intensity(c) = NaN;
                        app.imgT.Syn_CoV_Prominence(c) = NaN;
                        app.imgT.Syn_CoV_AUC(c) = NaN;
                        app.imgT.Syn_CoV_Frequency(c) = NaN;
                        app.imgT.Syn_CoV_ISI(c) = NaN;
                        app.imgT.Syn_CoV_RiseTime(c) = NaN;
                        app.imgT.Syn_CoV_EndToPeak(c) = NaN;
                        app.imgT.Syn_CoV_DecayTime(c) = NaN;
                        if bStim
                            app.imgT.Stim_Resiliance{c} = NaN;
                            app.imgT.Stim_FirstEvoked(c) = NaN;
                            app.imgT.Stim_PPR(c) = NaN;
                            app.imgT.Stim_FFR(c) = NaN;
                            app.imgT.Stim_LFR(c) = NaN;
                            app.imgT.Stim_Raw_MaxActiveSynapses(c) = NaN;
                            app.imgT.Stim_Percentage_MaxActiveSynapses(c) = NaN;
                        end
                        if any(contains(app.imgT.Properties.VariableNames, 'Sync_PeakLocation'))
                            app.imgT.Sync_Frequency(c) = NaN;
                            app.imgT.Sync_Raw_MaxActiveSynapses(c) = NaN;
                            app.imgT.Sync_Percentage_MaxActiveSynapses(c) = NaN;
                            app.imgT.Sync_Percentage_TimeActive(c) = NaN;
                            app.imgT.Sync_Percentage_TimeSync(c) = NaN;
                            app.imgT.Cell_Frequency(c) = NaN;
                            app.imgT.Cell_Mean_ActiveSynapses(c) = NaN;
                            app.imgT.Cell_Mean_PercentageSynapses(c) = NaN;
                            app.imgT.Cell_Mean_Intensity(c) = NaN;
                            app.imgT.Cell_Mean_InterSpikeInterval(c) = NaN;
                            app.imgT.Cell_Median_ActiveSynapses(c) = NaN;
                            app.imgT.Cell_Median_PercentageSynapses(c) = NaN;
                            app.imgT.Cell_Median_Intensity(c) = NaN;
                            app.imgT.Cell_Median_InterSpikeInterval(c) = NaN;
                            app.imgT.Cell_Variance_ActiveSynapses(c) = NaN;
                            app.imgT.Cell_Variance_Intensity(c) = NaN;
                            app.imgT.Cell_Variance_InterSpikeInterval(c) = NaN;
                            app.imgT.Cell_CoV_ActiveSynapses(c) = NaN;
                            app.imgT.Cell_CoV_Intensity(c) = NaN;
                            app.imgT.Cell_CoV_InterSpikeInterval(c) = NaN;
                        end
                    end
                end
                delete(hWait);
                app.newChange = true;
                togglePointer(app);
            catch
                delete(hWait);
                togglePointer(app);
                disp(c)
            end
        end
    end
    
    % Housekeeping methods
    methods (Access = public)
        function updatePlot(app, varargin)
            if nargin == 2
                plotAx = varargin{1};
            else
                plotAx = app.UIAxesPlot;
            end
            cla(plotAx)
            legend(plotAx, 'off');
            % Filter the cells that needs to be plotted
            tempData = app.imgT.DetrendData{app.currCell};
            if isempty(tempData)
                return
            end
            switch app.VisualizeDropDown.Value
                case 'Gradient'
                    tempData = gradient(tempData);
                case 'Smooth'
                    tempData = wdenoise(tempData, 5, 'DenoisingMethod', 'BlockJS');
            end
            Fs = app.imgT.Fs(app.currCell);
            time = (0:size(tempData,1)-1) / Fs;
            % Add some checks if there is stimulation needed
            if contains(app.imgT.StimID{app.currCell}, 'Hz')
                if any(matches(app.stim.StimID, app.imgT.StimID{app.currCell}))
                    stimID = find(matches(app.stim.StimID, app.imgT.StimID{app.currCell}));
                    xStim = app.stim.Baseline(stimID):1/app.stim.FreqAP(stimID):(app.stim.Baseline(stimID))+(1/app.stim.FreqAP(stimID))*(app.stim.nAP(stimID)-1);
                    if app.stim.nTrains(stimID) > 1
                        % There are multiple movies merged into 1. Split them and work on each movie separate
                        movDiv = numel(time) / app.stim.nTrains(stimID);
                        movS = 1:movDiv:numel(time);
                        movS = time(movS);
                        xStim = repmat(xStim, 1, app.stim.nTrains(stimID)) + repelem(movS, app.stim.nAP(stimID));
                    end
                    xPatch([1 4],:) = ones(2,1) * (xStim - 0.005);
                    xPatch([2 3],:) = ones(2,1) * (xStim + 0.005);
                    yPatch = repmat([0; 0; .1; .1], 1, numel(xStim));
                    hStim = patch(plotAx, xPatch, yPatch, [.0 .8 .8], 'EdgeColor', 'none', 'FaceAlpha', .3, 'HitTest', 'off', 'ButtonDownFcn', '');
                end
            end
            % Add some check for the type of plot (mean or individual)
            switch app.PlotTypeButtonGroup.SelectedObject.Text
                case 'All and mean'
                    if app.activeFltr
                        bSyn = app.imgT.KeepSyn{app.currCell};
                        if isempty(bSyn)
                            expID = app.imgT.ExperimentID{app.currCell};
                            newID = contains(app.imgT.ExperimentID, expID) & cellfun(@(x) ~isempty(x), app.imgT.KeepSyn);
                            bSyn = app.imgT.KeepSyn{newID};
                        end
                        if sum(bSyn) == 0
                            bSyn = true(size(app.imgT.DetrendData{app.currCell},2),1);
                        end
                    else
                        bSyn = true(size(app.imgT.DetrendData{app.currCell},2),1);
                    end
                    hold(plotAx, 'on')
                    hLeg(1) = plot(plotAx, time, tempData(:,1), 'Color', [.8 .8 .8], 'LineWidth', 0.5, 'HitTest', 'off', 'ButtonDownFcn', '');
                    if size(tempData,2) > 1
                        plot(plotAx, time, tempData(:,bSyn), 'Color', [.8 .8 .8], 'LineWidth', 0.5, 'HitTest', 'off', 'ButtonDownFcn', '');
                        hLeg(2) = plot(plotAx, time, max(tempData(:,bSyn),[],2), 'Color', app.keepColor(app.imgT.KeepCell(app.currCell)+1,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                        %hLeg(2) = plot(plotAx, time, mean(tempData(:,bSyn),2), 'Color', app.keepColor(app.imgT.KeepCell(app.currCell)+1,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                    end
                    if any(strcmp(app.imgT.Properties.VariableNames, 'Sync_PeakLocation'))
                        if ~isempty(app.imgT.Sync_PeakLocation{app.currCell})
                            basedOnAverage = false;
                            tempNetInt = mean(tempData(:,bSyn),2);
                            tempNetInt = max(tempData(:,bSyn),[],2);
                            if basedOnAverage
                                tempNetLoc = app.imgT.Sync_PeakLocation{app.currCell}{2};
                            else
                                tempNetLoc = app.imgT.Sync_PeakLocation{app.currCell}{1};
                            end
                            plot(plotAx, time(tempNetLoc), tempNetInt(tempNetLoc), 'sk', 'HitTest', 'off', 'ButtonDownFcn', '');
                        end
                    end
                    legend(hLeg, {'All', 'Mean'}, 'Box', 'off', 'AutoUpdate', 'off');
                case 'Single trace'
                    hold(plotAx, 'on')
                    synN = app.TextSynNumber.Value;
                    synThr = calculateThreshold(app, tempData, synN);
                    plot(plotAx, time, tempData(:,synN), 'Color', 'k', 'HitTest', 'off', 'ButtonDownFcn', '');
                    plot(plotAx, time, synThr, '--', 'Color', [.5 .5 .5], 'HitTest', 'off', 'ButtonDownFcn', '');
                    if any(strcmp(app.imgT.Properties.VariableNames, 'PeakLoc'))
                        if ~isempty(app.imgT.PeakLoc{app.currCell})
                            tempLocs = app.imgT.PeakLoc{app.currCell}{synN};
                            tempInts = app.imgT.PeakInt{app.currCell}{synN};
                            if tempInts == 0
                                tempInts = [];
                            end
                            plot(plotAx, (tempLocs-1) / Fs, tempInts, 'or', 'HitTest', 'off', 'ButtonDownFcn', '');
                        end
                    end
                    if app.FixYAxisButton.Value
                        plotAx.YLim = app.yLim;
                    end
            end
            if contains(app.imgT.StimID{app.currCell}, 'Hz')
                hStim.YData = repmat(repelem(app.yLim',2), 1, numel(xStim));
            end
        end
        
        function togglePointer(app)
            pointer = app.UIFigure.Pointer;
            if strcmp(pointer, 'arrow')
                app.UIFigure.Pointer = 'watch';
            else
                app.UIFigure.Pointer = 'arrow';
            end
            drawnow();
        end
        
        function ToogleActiveClicked(app)
            app.activeFltr = app.ToggleActive.Value;
            updatePlot(app);
            if app.ShowROIsButton.Value
                showROIs(app)
            end
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
        
        function showROIs(app)
            if app.ShowROIsButton.Value
                % Get the selected cell
                roiSet = app.imgT.RoiSet{app.currCell};
                nRoi = numel(roiSet);
                if nRoi == 0
                    uiconfirm(app.UIFigure, 'This image does not have any ROIs', 'Warning', 'Icon', 'warning');
                    return
                end
                % If the are ROIs, show them
                hold(app.UIAxesMovie, 'on')
                p = gobjects(nRoi,1);
                % Check if there are info on the synapses
                if app.activeFltr
                    bSyn = app.imgT.KeepSyn{app.currCell};
                    if isempty(bSyn)
                        expID = app.imgT.ExperimentID{app.currCell};
                        newID = contains(app.imgT.ExperimentID, expID) & cellfun(@(x) ~isempty(x), app.imgT.KeepSyn);
                        bSyn = app.imgT.KeepSyn{newID};
                        if isempty(bSyn)
                            bSyn = false(size(app.imgT.DetrendData{app.currCell},2),1);
                        end
                    end
                else
                    %bSyn = true(size(app.imgT.DetrendData{app.currCell},2),1);
                    bSyn = true(nRoi,1);
                end
                cmap = app.keepColor([1 3],:);
                edgeAlpha = [0.5 1];
                bSyn = bSyn +1;
                for r = 1:nRoi
                    p(r) = patch(app.UIAxesMovie, 'Faces', [1 2 3 4], 'Vertices', [roiSet{r}([2 1]); roiSet{r}([2 3]); roiSet{r}([4 3]); roiSet{r}([4 1])], 'FaceColor', 'none', 'EdgeColor', cmap(bSyn(r),:), 'EdgeAlpha', edgeAlpha(bSyn(r)));
                end
                app.patchMask = p;
            else
                delete(app.patchMask)
            end
        end
        
        function timelapse = loadMovie(app, cellID, useParallel)
            % Get the filename of the cellID
            imgFile = app.imgT.Filename{cellID};
            imgInfo = imfinfo(imgFile);
            nFrames = length(imgInfo);
            pxW = imgInfo(1).Width;
            pxH = imgInfo(1).Height;
            timelapse = zeros(pxW,pxH,nFrames, 'uint8');
            if useParallel
                parfor k=1:nFrames
                    timelapse(:,:,k) = imread(imgFile,k);
                end
            else
                hWait = waitbar(1/nFrames, 'Loading movie');
                for k=1:nFrames
                    waitbar(k/nFrames, hWait, 'Loading movie');
                    timelapse(:,:,k) = imread(imgFile,k);
                end
                delete(hWait);
            end
            % Register the movie if needed
            if app.regMovie
                if contains(app.imgT.StimID{cellID}, 'Hz')
                    imgOut = imref2d(size(timelapse(:,:,1)));
                    regEst = affine2d(app.imgT.RegEst{app.currCell});
                    timelapse = imwarp(timelapse, regEst, 'OutputView', imgOut);
                end
            end
        end
        
        function detrendData(app)
            recList = matches(app.imgT.StimID, app.List_RecID.Value);
            ff0Data = app.imgT{recList, 'FF0Data'};
            nData = numel(ff0Data);
            detData = cell(nData,1);
            switch app.Opt.Detrending
                case 'None'
                    app.imgT.DetrendData(recList) = ff0Data;
                case 'Moving median'
                    for d = 1:nData
                        tempData = ff0Data{d};
                        fitData = movmedian(tempData, [.2 .8]*app.Opt.DetrendSize);
                        detData{d} = tempData - fitData;
                    end
                    app.imgT.DetrendData(recList) = detData;
                case 'Erosion'
                    for d = 1:nData
                        tempData = ff0Data{d};
                        fitData = imerode(tempData, ones(app.Opt.DetrendSize,1));
                        detData{d} = tempData - fitData;
                    end
                    app.imgT.DetrendData(recList) = detData;
                case 'Polynomial'
                    uiconfirm(app.UIFigure, 'not implemented yet!', 'Warning', 'Icon', 'info');
            end
            updatePlot(app);
            figure(app.UIFigure);
        end
        
        function showMovie(app)
            if app.ShowMovieButton.Value
                app.movieData = loadMovie(app, app.currCell, false);
                nImages = size(app.movieData, 3);
                Fs = app.imgT.Fs(app.currCell);
                app.SliderMovie.Visible = 'on';
                app.SliderMovie.Value = 1;
                app.SliderMovie.Limits = [1, nImages];
                app.SliderMovie.MinorTicks = [];
                app.SliderMovie.MajorTicks = linspace(1,nImages,20);
                app.SliderMovie.MajorTickLabels = categorical(round(linspace(1,nImages,20) / Fs));
                s = image(app.movieData(:,:,1), 'Parent', app.UIAxesMovie);
                app.currSlice = s;
                hold(app.UIAxesPlot, 'on');
                hTime = plot(app.UIAxesPlot, zeros(2,1), app.UIAxesPlot.YLim, 'b');
                hLeg = get(app.UIAxesPlot, 'Legend');
                if ~isempty(hLeg)
                    hLeg.String = {hLeg.String{1}, hLeg.String{2}};
                end
                app.curTime = hTime;
            else
                app.SliderMovie.Visible = 'off';
                app.movieData = [];
                app.currSlice = [];
                app.curTime.Visible = 'off';
                app.curTime = [];
            end
        end
        
        function tempThr = calculateThreshold(app, tempData, synN)
            switch app.PeakThresholdMethodDropDown.Value
                case 'MAD'
                    tempThr = median(tempData(:,synN),'omitnan') + mad(tempData(:,synN)) * app.PeakSigmaEdit.Value * (-1 / (sqrt(2) * erfcinv(3/2)));
                    tempThr = repmat(tempThr, size(tempData,1), 1);
                case 'Rolling StDev'
                    winSize = app.PeakMaxDurationEdit.Value + app.PeakMinDistanceEdit.Value;
                    tempMean = movmean(tempData(:,synN), winSize, 'omitnan');
                    tempStDev = std(diff(tempData(:,synN)), 'omitnan');
                    tempThr = tempMean + (app.PeakSigmaEdit.Value*tempStDev);
            end
        end
        
        function peakInfo = DetectPeaks(app, traceData, traceThr)
            minProm = app.PeakMinProminenceEdit.Value;
            % If the user specified a negative prominence, calculate the prominence based on all the peaks
            if minProm < 0
                [~,~,~,tp] = findpeaks(traceData);
                minProm = mean(tp) + abs(minProm) * std(tp);
            end
            Fs = app.imgT.Fs(app.currCell);
            minDura = app.PeakMinDurationEdit.Value / (1000/Fs); % (1000/Fs) = Frame duration in ms
            maxDura = app.PeakMaxDurationEdit.Value / (1000/Fs);
            minDist = app.PeakMinDistanceEdit.Value / (1000/Fs);
            [tempPeak, tempLocs, ~, tempProm] = findpeaks(traceData, 'MinPeakProminence', minProm, 'WidthReference', 'halfprom', 'MinPeakWidth', minDura, 'MaxPeakWidth', maxDura, 'MinPeakDistance', minDist);
            % First remove the peaks below the threshold
            allPeakProm = median(tempProm);
            tempFltr = tempPeak > traceThr(tempLocs);
            tempPeak = tempPeak(tempFltr);
            tempLocs = tempLocs(tempFltr);
            tempProm = tempProm(tempFltr);
            % If there is a stimulation use that to define the peaks
            if contains(app.imgT.StimID{app.currCell}, 'Hz')
                % Define the stimulation protocol
                time = (0:length(traceData)-1) / Fs;
                stimID = find(matches(app.stim.StimID, app.imgT.StimID{app.currCell}));
                xStim = app.stim.Baseline(stimID):1/app.stim.FreqAP(stimID):(app.stim.Baseline(stimID))+(1/app.stim.FreqAP(stimID))*(app.stim.nAP(stimID)-1);
                if app.stim.nTrains(stimID) > 1
                    % There are multiple movies merged into 1. Split them and work on each movie separate
                    movDiv = numel(time) / app.stim.nTrains(stimID);
                    movS = 1:movDiv:numel(time);
                    movS = time(movS);
                    xStim = round((repmat(xStim, 1, app.stim.nTrains(stimID)) + repelem(movS, app.stim.nAP(stimID)))*Fs);
                else
                    xStim = round(xStim*Fs);
                end
                % For the 0.5 / 5 / 10 / 20 Hz work with the detected peaks
                if ~any(matches({'40Hz' '100Hz'}, app.imgT.StimID{app.currCell}))
                    % First define the top N peaks, with N = 2 * number of APs (to make sure that all the possible peaks are selected)
                    if numel(tempPeak) >= 2*numel(xStim)
                        [tempPeak, sortIdx] = sort(tempPeak, 'descend');
                        tempPeak = tempPeak(1:2*numel(xStim));
                        tempLocs = tempLocs(sortIdx);
                        tempLocs = tempLocs(1:2*numel(xStim));
                        tempProm = tempProm(sortIdx);
                        tempProm = tempProm(1:2*numel(xStim));
                        [tempLocs, sortIdx] = sort(tempLocs);
                        tempPeak = tempPeak(sortIdx);
                        tempProm = tempProm(sortIdx);
                    end
                    %Redefine the peaks based on the location of the stimulation
                    tempSNR = nan(numel(xStim),1);
                    for stimN = 1:numel(xStim)
                        newLocs = tempLocs - xStim(stimN);
                        maxDist = 1;
                        minIdx = [];
                        while maxDist < 3 && numel(minIdx) == 0
                            minIdx = find((0 < newLocs) & (newLocs <= maxDist)); % Assume that the peak is always after the AP
                            maxDist = maxDist + 1;
                        end
                        % If no event are detected, check if there is an event at the same location of the AP
                        if numel(minIdx) == 0
                            minIdx = find(newLocs == 0);
                        end
                        % Store the event
                        if numel(minIdx) == 1 && ~any(tempLocs(1:stimN-1) == tempLocs(minIdx))
                            if stimN == 1
                                tempPeak = tempPeak(minIdx:end);
                                tempLocs = tempLocs(minIdx:end);
                                tempProm = tempProm(minIdx:end);
                            elseif stimN == numel(xStim)
                                tempPeak = [tempPeak(1:stimN-1); tempPeak(minIdx)];
                                tempLocs = [tempLocs(1:stimN-1); tempLocs(minIdx)];
                                tempProm = [tempProm(1:stimN-1); tempProm(minIdx)];
                            else
                                tempPeak = [tempPeak(1:stimN-1); tempPeak(minIdx:end)];
                                tempLocs = [tempLocs(1:stimN-1); tempLocs(minIdx:end)];
                                tempProm = [tempProm(1:stimN-1); tempProm(minIdx:end)];
                            end
                        else
                            if stimN < numel(xStim)
                                tempPeak = [tempPeak(1:stimN-1); NaN; tempPeak(stimN:end)];
                                tempLocs = [tempLocs(1:stimN-1); NaN; tempLocs(stimN:end)];
                                tempProm = [tempProm(1:stimN-1); NaN; tempProm(stimN:end)];
                            else
                                tempPeak = [tempPeak(1:stimN-1); NaN];
                                tempLocs = [tempLocs(1:stimN-1); NaN];
                                tempProm = [tempProm(1:stimN-1); NaN];
                            end
                        end
                        % Instead of the SNR, calculate the area under the curve during the stimulation
                        if ~isnan(tempPeak(stimN))
                            % First remove the offset (I don't care if it's goes below 0, that's only due to calculating the DF/F0)
                            aucData = traceData(xStim(stimN)-1:xStim(stimN)+3);
                            aucData = aucData+abs(min(aucData));
                            tempSNR(stimN) = trapz(1/Fs, aucData);
                        end
                    end
                    peakInfo = [tempPeak, tempLocs, tempProm, tempSNR, nan(size(tempPeak)), nan(size(tempPeak)), nan(size(tempPeak))];
                else
                    % For the 40 and 100 Hz there can be only one peak per train
                    nAP = app.stim.nAP(stimID);
                    nTrains = app.stim.nTrains(stimID);
                    if nTrains > 1
                        xStim = reshape(xStim,5,5);
                        % Add two frames at the end of the stimulation
                        xStim(5,:) = xStim(5,:) + 2;
                        tempSNR = nan(nTrains,1);
                        for t = 1:nTrains
                            minIdx = find((xStim(1,t) < tempLocs) & (tempLocs <= xStim(nAP,t)));
                            if numel(minIdx) > 1
                                % find the maximum peak
                                [~, minIdx1] = max(tempPeak(minIdx));
                                minIdx = minIdx(minIdx1);
                            end
                            if numel(minIdx) == 1
                                if t == 1
                                    tempPeak = tempPeak(minIdx:end);
                                    tempLocs = tempLocs(minIdx:end);
                                    tempProm = tempProm(minIdx:end);
                                elseif t == nTrains
                                    tempPeak = [tempPeak(1:t-1); tempPeak(minIdx)];
                                    tempLocs = [tempLocs(1:t-1); tempLocs(minIdx)];
                                    tempProm = [tempProm(1:t-1); tempProm(minIdx)];
                                else
                                    tempPeak = [tempPeak(1:t-1); tempPeak(minIdx:end)];
                                    tempLocs = [tempLocs(1:t-1); tempLocs(minIdx:end)];
                                    tempProm = [tempProm(1:t-1); tempProm(minIdx:end)];
                                end
                            else
                                if t < nTrains
                                    tempPeak = [tempPeak(1:t-1); NaN; tempPeak(t:end)];
                                    tempLocs = [tempLocs(1:t-1); NaN; tempLocs(t:end)];
                                    tempProm = [tempProm(1:t-1); NaN; tempProm(t:end)];
                                else
                                    tempPeak = [tempPeak(1:t-1); NaN];
                                    tempLocs = [tempLocs(1:t-1); NaN];
                                    tempProm = [tempProm(1:t-1); NaN];
                                end
                            end
                            % Instead of the SNR, calculate the area under the curve during the stimulation
                            if ~isnan(tempPeak(t))
                                aucData = traceData(xStim(:,t));
                                aucData = aucData+abs(min(aucData));
                                tempSNR(t) = trapz(1/Fs, aucData);
                            end
                        end
                    else
                        % first filter out the peaks that are outside the stimulation area
                        tempFltr = tempLocs >= xStim(1) & tempLocs <= xStim(end);
                        tempPeak = tempPeak(tempFltr);
                        tempLocs = tempLocs(tempFltr);
                        tempProm = tempProm(tempFltr);
                        if numel(tempLocs) >= 1
                            % find the maximum peak
                            [~, minIdx] = max(tempPeak);
                            tempPeak = tempPeak(minIdx);
                            tempLocs = tempLocs(minIdx);
                            tempProm = tempProm(minIdx);
                        else
                            tempSNR = tempPeak;
                        end
                        % Instead of the SNR, calculate the area under the curve during the stimulation
                        if ~isnan(tempPeak)
                            aucData = traceData(xStim);
                            aucData = aucData+abs(min(aucData));
                            tempSNR = trapz(1/Fs, aucData);
                        end
                        % Here I want to get more info on the stimulation
                        xStim = unique(xStim);
                        timeToRise = NaN;
                        endToPeak = NaN;
                        timeToDecay = NaN;
                        if ~isempty(tempPeak)
                            % Time to rise
                            timeToRise = (tempLocs - xStim(1)) / Fs;
                            % End of stim to peak
                            endToPeak = traceData(xStim(end)) / tempPeak;
                            % Time to decay
                            endPoint = find(traceData(xStim(2):end) <= traceData(xStim(1)) + std(traceData(1:xStim(1))), 1) + xStim(2);
                            if isempty(endPoint)
                                endPoint = numel(traceData);
                            end
                            timeToDecay = (endPoint - tempLocs) / Fs;
                        else
                            tempPeak = NaN;
                            tempLocs = NaN;
                            tempProm = NaN;
                            tempSNR = NaN;
                        end
                    end
                    peakInfo = [tempPeak, tempLocs, tempProm, tempSNR, timeToRise, endToPeak, timeToDecay];
                end
            else
                useDecisionTree = false;
                if useDecisionTree
                    % Load the decision tree classification
                    MdlTree = load('SpontaneousDecisionTree.mat');
                    MdlTree = MdlTree.MdlDefault;
                    % Get additional information on the peaks
                    featVal = cell(1,88);
                    % Raw values
                    featVal(1,1:8) = ratioCalculation(app, traceData, tempLocs);
                    % First derivative
                    featVal(1,9:16) = ratioCalculation(app, [nan; diff(traceData)], tempLocs);
                    % Moving median
                    featVal(1,17:24) = ratioCalculation(app, movmean(traceData, [.2 .8]*5), tempLocs);
                    featVal(1,25:32) = ratioCalculation(app, movmean(traceData, [.2 .8]*10), tempLocs);
                    featVal(1,33:40) = ratioCalculation(app, movmean(traceData, [.2 .8]*20), tempLocs);
                    % Moving standard deviation
                    featVal(1,41:48) = ratioCalculation(app, movstd(traceData, [.8 .2]*5), tempLocs);
                    featVal(1,49:56) = ratioCalculation(app, movstd(traceData, [.8 .2]*10), tempLocs);
                    featVal(1,57:64) = ratioCalculation(app, movstd(traceData, [.8 .2]*20), tempLocs);
                    % Gaussian
                    featVal(1,65:72) = ratioCalculation(app, filter(gausswin(5),1,traceData), tempLocs);
                    featVal(1,73:80) = ratioCalculation(app, filter(gausswin(5),1,traceData), tempLocs);
                    featVal(1,81:88) = ratioCalculation(app, filter(gausswin(5),1,traceData), tempLocs);
                    featVal = cell2mat(featVal);
                    featVal(isinf(featVal)) = 0;
                    % Filter the data based on the decision tree
                    MdlFltr = predict(MdlTree, featVal);
                    tempPeak = tempPeak(MdlFltr);
                    tempLocs = tempLocs(MdlFltr);
                    tempProm = tempProm(MdlFltr);
                end
                % SNR calculate based on https://nl.mathworks.com/matlabcentral/answers/183557-code-to-calculate-snr
                tempSNR = 10*(log10(tempPeak / median(traceData)));
                peakInfo = [tempPeak, tempLocs, tempProm, tempSNR, nan(size(tempPeak)), nan(size(tempPeak)), nan(size(tempPeak))];
            end
            if isempty(peakInfo)
                peakInfo = double.empty(0,7);
            end
        end
        
        function ratioValues = ratioCalculation(app, useTrace, usePeaks)
            ratioValues = cell(1,8);
            % Rise phase
            ratioValues{1,1} = useTrace(usePeaks) ./ useTrace(usePeaks-1);
            ratioValues{1,2} = useTrace(usePeaks) ./ useTrace(usePeaks-2);
            % Peak amplitude
            tempThr = median(useTrace,'omitnan') + mad(useTrace) * 3 * (-1 / (sqrt(2) * erfcinv(3/2)));
            ratioValues{1,3} = useTrace(usePeaks) ./ tempThr;
            % Decay phase
            ratioValues{1,4} = useTrace(usePeaks) ./ useTrace(usePeaks+1);
            ratioValues{1,5} = useTrace(usePeaks) ./ useTrace(usePeaks+3);
            ratioValues{1,6} = useTrace(usePeaks) ./ useTrace(usePeaks+5);
            % Duration
            ratioValues{1,7} = useTrace(usePeaks-1) ./ useTrace(usePeaks+1);
            ratioValues{1,8} = useTrace(usePeaks-2) ./ useTrace(usePeaks+5);
        end

        function syncData = calculateSynchronous(app, peakLocs, nFrames, nSyn, keepSyn, Fs, bStim)
            tempSync = zeros(nFrames, nSyn);
            xVar = round(app.Opt.PeakMinDuration / (1000/Fs));
            for s = 1:nSyn
                if keepSyn(s)
                    sStart = peakLocs{s};
                    for p = 1:length(sStart)
                        if ~isnan(sStart(p))
                            if ~bStim
                                xStart = max(1, sStart(p)-xVar);
                                xEnd = min(nFrames, sStart(p)+xVar);
                            else
                                xStart = sStart(p);
                                xEnd = sStart(p);
                            end
                            tempSync(xStart:xEnd, s) = 1;
                        end
                    end
                end
            end
            syncData = sum(tempSync, 2);
        end
        
        function clickedPoint = GetClickedCoordinate(app, event)
            if event.Button == 3
                if app.ZoomInButton.Value
                    oldXAxis = app.UIAxesPlot.XLim;
                    if event.IntersectionPoint(1) > sum(oldXAxis)/2
                        newXAxis = oldXAxis + 0.8 * 10; % increment of 0.8 s
                    else
                        newXAxis = oldXAxis - 0.8 * 10;
                        if newXAxis(1) < 0
                            newXAxis = oldXAxis;
                        end
                    end
                    app.UIAxesPlot.XLim = newXAxis;
                end
            else
                if app.AddPeaksButton.Value
                    clickedPoint = event.IntersectionPoint(1);
                    switch app.PlotTypeButtonGroup.SelectedObject.Text
                        case 'All and mean'
                            addNetworkPeak(app, clickedPoint);
                        case 'Single trace'
                            addManualPeak(app, clickedPoint);
                    end
                end
                if app.DeletePeaksButton.Value
                    clickedPoint = event.IntersectionPoint(1);
                    switch app.PlotTypeButtonGroup.SelectedObject.Text
                        case 'All and mean'
                            deleteNetworkPeak(app, clickedPoint);
                        case 'Single trace'
                            deleteManualPeak(app, clickedPoint);
                    end
                end
            end
        end
        
        function crosshairCursor(app, event)
            if strcmp(app.UIFigure.Pointer, 'arrow')
                app.UIFigure.Pointer = 'crosshair';
                app.DeletePeaksButton.Enable = app.DeletePeaksButton.Value;
                app.AddPeaksButton.Enable = app.AddPeaksButton.Value;
            else
                app.UIFigure.Pointer = 'arrow';
                app.DeletePeaksButton.Enable = 'on';
                app.AddPeaksButton.Enable = 'on';
                app.AddPeaksButton.Value = false;
                app.DeletePeaksButton.Value = false;
                switch event.Source.Text
                    case 'Add peaks'
                        if ~isempty(app.tempAddPeak)
                            if length(fieldnames(app.tempAddPeak)) == 2
                                [app.imgT.Sync_PeakLocation{app.currCell}{2}, sortIdx] = sort(app.tempAddPeak.Loc);
                                app.imgT.Sync_SynapseCount{app.currCell}{2} = app.tempAddPeak.Int(sortIdx);
                                app.tempAddPeak = [];
                            else
                                synN = app.TextSynNumber.Value;
                                [app.imgT.PeakLoc{app.currCell}{synN}, sortIdx] = sort(app.tempAddPeak.Loc);
                                app.imgT.PeakInt{app.currCell}{synN} = app.tempAddPeak.Int(sortIdx);
                                app.imgT.PeakProm{app.currCell}{synN} = app.tempAddPeak.Prom(sortIdx);
                                app.imgT.PeakSNR{app.currCell}{synN} = app.tempAddPeak.SNR(sortIdx);
                                app.tempAddPeak = [];
                            end
                        end
                    case 'Delete peaks'
                        if ~isempty(app.tempAddPeak)
                            if length(fieldnames(app.tempAddPeak)) == 2
                                lastKeep = find(diff(app.tempAddPeak.Loc) < 0, 1, 'first');
                                app.imgT.Sync_PeakLocation{app.currCell}{2} = sort(app.tempAddPeak.Loc(1:lastKeep));
                                app.imgT.Sync_SynapseCount{app.currCell}{2} = app.tempAddPeak.Int(1:lastKeep);
                                app.tempAddPeak = [];
                            else
                                
                            end
                        end
                end
                drawnow();
                updatePlot(app);
                figure(app.UIFigure);
            end
        end
        
        function DetectCellPeaks(app)
            % Get the cells where there is data
            dataFltr = find(cellfun(@(x) ~isempty(x), app.imgT.PeakLoc));
            switch app.DetectEventButtonGroup.SelectedObject.Text
                case 'Current list'
                    dataFltr = find(contains(app.imgT.ExperimentID, app.List_CellID.Value));
                case 'Selected FOV'
                    dataFltr = find(contains(app.imgT.ExperimentID, app.List_CellID.Value) & contains(app.imgT.StimID, app.List_RecID.Value));
            end
            try
                togglePointer(app);
                hWait = waitbar(0, 'Quantify peaks in data');
                for c = dataFltr'
                    waitbar(c/numel(dataFltr), hWait, 'Quantify peaks in data');
                    tempTraces = app.imgT.DetrendData{c};
                    Fs = app.imgT.Fs(c);
                    [nFrames, nSyn] = size(tempTraces);
                    synKeep = app.imgT.KeepSyn{c};
                    % Get the % of active synapses
                    tempData = calculateSynchronous(app, app.imgT.PeakLoc{c}, nFrames, nSyn, synKeep, Fs, contains(app.imgT.StimID{c}, 'Hz'));
                    nSyn = sum(synKeep);
                    if nSyn > 0
                        % Detect the peaks based on the detected peaks per synapse
                        [netInt, netLoc] = findpeaks(tempData, 'MinPeakHeight', 0.0*nSyn);
                        % Detect the peaks based on the average trace
                        traceData = mean(app.imgT.DetrendData{c}(:,synKeep),2);
                        smoothTrace = smoothdata(traceData);
%                         smoothTrace = wdenoise(traceData);
                        [~, smoothLoc] = findpeaks(smoothTrace, 'MinPeakProminence', std(smoothTrace));
                        % Adjust the location of the peaks
                        maxV = zeros(numel(smoothLoc),1);
                        maxI = zeros(numel(smoothLoc),1);
                        offset = round(app.Opt.PeakMinDistance+(app.Opt.PeakMaxDuration+app.Opt.PeakMinDuration)/2);
                        for p = 1:numel(smoothLoc)
                            offLow = max(1, smoothLoc(p)-offset);
                            offHigh = min(numel(tempData), smoothLoc(p)+offset);
                            [maxV(p), maxI(p)] = max(tempData(offLow:offHigh));
                            maxI(p) = maxI(p) + offLow;
                            if sum(maxI(p) == maxI(1:p)) > 1
                                maxI(p) = 0;
                            end
                        end
                        app.imgT.Sync_PeakLocation{c} = {netLoc+2 maxI(maxI>0)};
                        app.imgT.Sync_SynapseCount{c} = {netInt maxV(maxI>0)};
                    else
                        app.imgT.Sync_PeakLocation{c} = [];
                        app.imgT.Sync_SynapseCount{c} = [];
                    end
                end
                delete(hWait);
                app.newChange = true;
                togglePointer(app);
                updatePlot(app);
            catch
                delete(hWait);
                togglePointer(app);
                disp(c)
            end
            figure(app.UIFigure);
        end
        
        function updateSpikeQuantification(app)
            for c=1:height(app.imgT)
                tempTraces = app.imgT.DetrendData{c};
                Fs = app.imgT.Fs(c);
                [nFrames, nSyn] = size(tempTraces);
                if ~isempty(app.imgT.Sync_PeakLocation{c})
                    app.imgT.Cell_Frequency{c} = numel(app.imgT.Sync_PeakLocation{c}{2}) / (nFrames/Fs);
                end
            end
        end
        
        function ExctractStimFeatures(app)
            % Get the cells where there is data
            dataFltr = find(cellfun(@(x) ~isempty(x), app.imgT.PeakLoc));
            try
                togglePointer(app);
                hWait = waitbar(0, 'Quantify peaks in data');
                for c = dataFltr'
                    waitbar(c/numel(dataFltr), hWait, 'Quantify peaks in data');
                    tempTraces = app.imgT.DetrendData{c};
                    Fs = app.imgT.Fs(c);
                    nFrames = size(tempTraces, 1);
                    synKeep = app.imgT.KeepSyn{c}; % A synapse is consider positive when it responded to 2/3 of the APs
                    nSyn = sum(synKeep);
                    % Get the information on the stimulation
                    stimID = find(matches(app.stim.StimID, app.imgT.StimID(c)));
                    meanTrace = mean(tempTraces(:,synKeep),2, 'omitnan');
                    time = (0:size(tempTraces,1)-1) / Fs;
                    xStim = app.stim.Baseline(stimID):1/app.stim.FreqAP(stimID):(app.stim.Baseline(stimID))+(1/app.stim.FreqAP(stimID))*(app.stim.nAP(stimID)-1);
                    if app.stim.nTrains(stimID) > 1
                        % There are multiple movies merged into 1. Split them and work on each movie separate
                        movDiv = numel(time) / app.stim.nTrains(stimID);
                        movS = 1:movDiv:numel(time);
                        movS = time(movS);
                        xStim = round((repmat(xStim, 1, app.stim.nTrains(stimID)) + repelem(movS, app.stim.nAP(stimID)))*Fs);
                    else
                        xStim = round(xStim*Fs);
                    end
                    nAP = numel(xStim);
                    % Get the single synapse quantification
                    synInt = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakInt{c});
                    synProm = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakProm{c});
                    synRes = cellfun(@(x )sum(~isnan(x)), app.imgT.PeakInt{c}) / nAP * 100;
                    SynAUC = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakSNR{c});
                    stimRes = arrayfun(@(x) app.imgT.PeakSync{c}(x-1:x+1), xStim, 'UniformOutput', false);
                    stimRes = cell2mat(stimRes);
                    stimRes = stimRes(3,:);
                    if nSyn > 0
                        % Mean, median, and variance for synapse
                        app.imgT.Syn_Mean_Intensity(c) = mean(synInt(synKeep));
                        app.imgT.Syn_Mean_Prominence(c) = mean(synProm(synKeep));
                        app.imgT.Syn_Mean_Resiliance(c) = mean(synRes(synKeep));
                        app.imgT.Syn_Mean_AUC(c) = mean(SynAUC(synKeep));
                        app.imgT.Syn_Median_Intensity(c) = median(synInt(synKeep));
                        app.imgT.Syn_Median_Prominence(c) = median(synProm(synKeep));
                        app.imgT.Syn_Median_Resiliance(c) = median(synRes(synKeep));
                        app.imgT.Syn_Median_AUC(c) = median(SynAUC(synKeep));
                        app.imgT.Syn_Variance_Intensity(c) = var(synInt(synKeep));
                        app.imgT.Syn_Variance_Prominence(c) = var(synProm(synKeep));
                        app.imgT.Syn_Variance_Resiliance(c) = var(synRes(synKeep));
                        app.imgT.Syn_Variance_AUC(c) = var(SynAUC(synKeep));
                        % Histogram description of all the synapses in one cell
                        app.imgT.Syn_Skewness_Intensity(c) = skewness(cell2mat(app.imgT.PeakInt{c}(synKeep)), 0);
                        app.imgT.Syn_Skewness_Prominence(c) = skewness(cell2mat(app.imgT.PeakProm{c}(synKeep)), 0);
                        app.imgT.Syn_Skewness_AUC(c) = skewness(cell2mat(app.imgT.PeakSNR{c}(synKeep)), 0);
                        app.imgT.Syn_Kurtosis_Intensity(c) = kurtosis(cell2mat(app.imgT.PeakInt{c}(synKeep)), 0) -3;
                        app.imgT.Syn_Kurtosis_Prominence(c) = kurtosis(cell2mat(app.imgT.PeakProm{c}(synKeep)), 0) -3;
                        app.imgT.Syn_Kurtosis_AUC(c) = kurtosis(cell2mat(app.imgT.PeakSNR{c}(synKeep)), 0) -3;
                        % Coefficient of variation between the synapses
                        app.imgT.Syn_CoV_Intensity(c) = sqrt(app.imgT.Syn_Variance_Intensity(c)) / app.imgT.Syn_Mean_Intensity(c);
                        app.imgT.Syn_CoV_Prominence(c) = sqrt(app.imgT.Syn_Variance_Prominence(c)) / app.imgT.Syn_Mean_Prominence(c);
                        app.imgT.Syn_CoV_Resiliance(c) = sqrt(app.imgT.Syn_Variance_Resiliance(c)) / app.imgT.Syn_Mean_Resiliance(c);
                        app.imgT.Syn_CoV_AUC(c) = sqrt(app.imgT.Syn_Variance_AUC(c)) / app.imgT.Syn_Mean_AUC(c);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % QUANTAL ANALYSIS FOR THE PEAKS? SEE 10.1038/s41467-022-31070-4 %
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Get the stimulation-based quantifications
                        app.imgT.Stim_Resiliance{c} = stimRes;
                        app.imgT.Stim_FirstEvoked(c) = mean(cellfun(@(x) x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan');
                        if numel(app.imgT.PeakProm{c}{synKeep}) > 1
                            app.imgT.Stim_PPR(c) = mean(cellfun(@(x) x(2)/x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan');
                            app.imgT.Stim_FFR(c) = mean(cellfun(@(x) x(min(5, nAP))/x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan'); % Fifth to First Ratio
                            app.imgT.Stim_LFR(c) = mean(cellfun(@(x) x(nAP)/x(1), app.imgT.PeakProm{c}(synKeep)), 'omitnan'); % Last to First Ratio
                        else
                            app.imgT.Stim_PPR(c) = 0;
                            app.imgT.Stim_FFR(c) = 0;
                            app.imgT.Stim_LFR(c) = 0;
                        end
                        app.imgT.Stim_Raw_MaxActiveSynapses(c) = max(app.imgT.PeakSync{c});
                        app.imgT.Stim_Percentage_MaxActiveSynapses(c) = (max(app.imgT.PeakSync{c}) ./ nSyn * 100);
                    else
                        % Mean, median, and variance for synapse
                        app.imgT.Syn_Mean_Intensity(c) = NaN;
                        app.imgT.Syn_Mean_Prominence(c) = NaN;
                        app.imgT.Syn_Mean_Resiliance(c) = NaN;
                        app.imgT.Syn_Mean_AUC(c) = NaN;
                        app.imgT.Syn_Median_Intensity(c) = NaN;
                        app.imgT.Syn_Median_Prominence(c) = NaN;
                        app.imgT.Syn_Median_Resiliance(c) = NaN;
                        app.imgT.Syn_Median_AUC(c) = NaN;
                        app.imgT.Syn_Variance_Intensity(c) = NaN;
                        app.imgT.Syn_Variance_Prominence(c) = NaN;
                        app.imgT.Syn_Variance_Resiliance(c) = NaN;
                        app.imgT.Syn_Variance_AUC(c) = NaN;
                        % Histogram description of all the synapses in one cell
                        app.imgT.Syn_Skewness_Intensity(c) = NaN;
                        app.imgT.Syn_Skewness_Prominence(c) = NaN;
                        app.imgT.Syn_Skewness_AUC(c) = NaN;
                        app.imgT.Syn_Kurtosis_Intensity(c) = NaN;
                        app.imgT.Syn_Kurtosis_Prominence(c) = NaN;
                        app.imgT.Syn_Kurtosis_AUC(c) = NaN;
                        % Coefficient of variation between the synapses
                        app.imgT.Syn_CoV_Intensity(c) = NaN;
                        app.imgT.Syn_CoV_Prominence(c) = NaN;
                        app.imgT.Syn_CoV_Resiliance(c) = NaN;
                        app.imgT.Syn_CoV_AUC(c) = NaN;
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % QUANTAL ANALYSIS FOR THE PEAKS? SEE 10.1038/s41467-022-31070-4 %
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Get the stimulation-based quantifications
                        app.imgT.Stim_Resiliance{c} = NaN;
                        app.imgT.Stim_FirstEvoked(c) = NaN;
                        app.imgT.Stim_PPR(c) = NaN;
                        app.imgT.Stim_FFR(c) = NaN;
                        app.imgT.Stim_Raw_MaxActiveSynapses(c) = NaN;
                        app.imgT.Stim_Percentage_MaxActiveSynapses(c) = NaN;
                        % Since there is no active synapse mark the cell
                        app.imgT.KeepCell(c) = false;
                    end
                end
                delete(hWait);
                togglePointer(app);
            catch ME
                delete(hWait);
                togglePointer(app);
                disp(c)
            end
        end
    end
    
    % Method for table tab for Naive recordings
    methods (Access = private)
        function populateTable(app, event)
            if strcmp(app.TabGroup.SelectedTab.Title, 'Table')
                % Populate the table for all the cells if they are naive recordings
                populateCellTable(app)
                % Get the cell that we are looking at
                tempTraces = app.imgT.DetrendData{app.currCell};
                Fs = app.imgT.Fs(app.currCell);
                [nFrames, nSyn] = size(tempTraces);
                time = (0:nFrames-1) / Fs;
                synN = (1:nSyn)';
                synInt = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakProm{app.currCell});
                snr = cellfun(@(x) mean(x, 'omitnan'), app.imgT.PeakSNR{app.currCell});
                synKeep = app.imgT.KeepSyn{app.currCell};
                if all(contains(app.imgT.StimID, 'Naive'))
                    synFreq = cellfun(@numel, app.imgT.PeakInt{app.currCell}) / (nFrames/Fs);
                    plotRaster(app, tempTraces);
                elseif all(contains(app.imgT.StimID, 'Hz'))
                    % Get the information on the stimulation
                    stimID = find(matches(app.stim.StimID, app.imgT.StimID(app.currCell)));
                    xStim = app.stim.Baseline(stimID):1/app.stim.FreqAP(stimID):(app.stim.Baseline(stimID))+(1/app.stim.FreqAP(stimID))*(app.stim.nAP(stimID)-1);
                    if app.stim.nTrains(stimID) > 1
                        % There are multiple movies merged into 1. Split them and work on each movie separate
                        movDiv = numel(time) / app.stim.nTrains(stimID);
                        movS = 1:movDiv:numel(time);
                        movS = time(movS);
                        xStim = round((repmat(xStim, 1, app.stim.nTrains(stimID)) + repelem(movS, app.stim.nAP(stimID)))*Fs);
                    else
                        xStim = round(xStim*Fs);
                    end
                    nAP = numel(xStim);
                    synFreq = cellfun(@(x )sum(~isnan(x)), app.imgT.PeakInt{app.currCell}) / nAP * 100;
                    plotRasterStim(app, tempTraces);
                end
                app.UITableSingle.Data = table(synN, synInt, synFreq, snr, synKeep);
                app.UITableSingle.ColumnEditable = [false, false, false, false, true];
                app.newChange = true;
            else
                % Clear the table and the axis
                cla(app.UIAxesRaster);
                cla(app.UIAxesOverview, 'reset');
                app.UITableSingle.Data = [];
            end
            figure(app.UIFigure);
        end
        
        function populateCellTable(app)
            if all(contains(app.imgT.StimID, 'Naive'))
                if ~any(strcmp(app.imgT.Properties.VariableNames, 'Cell_CoV_InterSpikeInterval'))
                    ExtractPeakFeatures(app);
                else
%                     updateSpikeQuantification(app)
                end
                dataFltr = find(cellfun(@(x) ~isempty(x), app.imgT.PeakLoc));
                cellID = app.imgT{dataFltr, 'ExperimentID'};
                recID = app.imgT{dataFltr, 'ConditionID'};
                cellKeep = app.imgT{dataFltr, 'KeepCell'};
                Syn_Mean_Intensity = app.imgT.Syn_Mean_Intensity;
                Syn_Mean_Prominence = app.imgT.Syn_Mean_Prominence;
                Syn_Mean_Frequency = app.imgT.Syn_Mean_Frequency;
                Syn_Skewness_Intensity = app.imgT.Syn_Skewness_Intensity;
                Syn_Skewness_Prominence = app.imgT.Syn_Skewness_Prominence;
                Syn_Skewness_Frequency = app.imgT.Syn_Skewness_Frequency;
                Syn_CoV_Intensity = app.imgT.Syn_CoV_Intensity;
                Syn_CoV_Prominence = app.imgT.Syn_CoV_Prominence;
                Syn_CoV_Frequency = app.imgT.Syn_CoV_Frequency;
                Sync_Frequency = app.imgT.Sync_Frequency;
                Sync_Raw_MaxActiveSynapses = app.imgT.Sync_Raw_MaxActiveSynapses;
                Sync_Percentage_MaxActiveSynapses = app.imgT.Sync_Percentage_MaxActiveSynapses;
                Sync_Percentage_TimeActive = app.imgT.Sync_Percentage_TimeActive;
                Sync_Percentage_TimeSync = app.imgT.Sync_Percentage_TimeSync;
                Cell_Frequency = app.imgT.Cell_Frequency;
                Cell_Mean_ActiveSynapses = app.imgT.Cell_Mean_ActiveSynapses;
                Cell_Mean_PercentageSynapses = app.imgT.Cell_Mean_PercentageSynapses;
                Cell_Mean_Intensity = app.imgT.Cell_Mean_Intensity;
                Cell_Mean_InterSpikeInterval = app.imgT.Cell_Mean_InterSpikeInterval;
                Cell_CoV_ActiveSynapses = app.imgT.Cell_CoV_ActiveSynapses;
                Cell_CoV_Intensity = app.imgT.Cell_CoV_Intensity;
                Cell_CoV_InterSpikeInterval = app.imgT.Cell_CoV_InterSpikeInterval;
            elseif all(contains(app.imgT.StimID, 'Hz'))
                if ~any(strcmp(app.imgT.Properties.VariableNames, 'Syn_Skewness_AUC'))
                    %ExctractStimFeatures(app);
                end
                dataFltr = find(cellfun(@(x) ~isempty(x), app.imgT.PeakLoc));
                cellID = app.imgT{dataFltr, 'ExperimentID'};
                recID = app.imgT{dataFltr, 'ConditionID'};
                cellKeep = app.imgT{dataFltr, 'KeepCell'};
                Syn_Mean_Intensity = app.imgT.Syn_Mean_Intensity;
                Syn_Mean_Prominence = app.imgT.Syn_Mean_Prominence;
                Syn_Mean_Frequency = app.imgT.Syn_Mean_AUC;
                Syn_Skewness_Intensity = app.imgT.Syn_Skewness_Intensity;
                Syn_Skewness_Prominence = app.imgT.Syn_Skewness_Prominence;
                Syn_Skewness_Frequency = app.imgT.Syn_Skewness_AUC;
                Syn_CoV_Intensity = app.imgT.Syn_CoV_Intensity;
                Syn_CoV_Prominence = app.imgT.Syn_CoV_Prominence;
                Syn_CoV_Frequency = app.imgT.Syn_CoV_AUC;
                Sync_Frequency = app.imgT.Stim_FirstEvoked;
                Sync_Raw_MaxActiveSynapses = app.imgT.Stim_Raw_MaxActiveSynapses;
                Sync_Percentage_MaxActiveSynapses = app.imgT.Stim_Percentage_MaxActiveSynapses;
                Sync_Percentage_TimeActive = app.imgT.Stim_PPR;
                Sync_Percentage_TimeSync = app.imgT.Stim_FFR;
                Cell_Frequency = nan(height(app.imgT),1);
                Cell_Mean_ActiveSynapses = nan(height(app.imgT),1);
                Cell_Mean_PercentageSynapses = nan(height(app.imgT),1);
                Cell_Mean_Intensity = nan(height(app.imgT),1);
                Cell_Mean_InterSpikeInterval = nan(height(app.imgT),1);
                Cell_CoV_ActiveSynapses = nan(height(app.imgT),1);
                Cell_CoV_Intensity = nan(height(app.imgT),1);
                Cell_CoV_InterSpikeInterval = nan(height(app.imgT),1);
            end
            app.UITableAll.Data = table(cellID, recID, cellKeep, Syn_Mean_Intensity(dataFltr), Syn_Mean_Prominence(dataFltr), Syn_Mean_Frequency(dataFltr),...
                    Syn_Skewness_Intensity(dataFltr), Syn_Skewness_Prominence(dataFltr), Syn_Skewness_Frequency(dataFltr), Syn_CoV_Intensity(dataFltr), Syn_CoV_Prominence(dataFltr),...
                    Syn_CoV_Frequency(dataFltr), Sync_Frequency(dataFltr), Sync_Raw_MaxActiveSynapses(dataFltr), Sync_Percentage_MaxActiveSynapses(dataFltr),...
                    Sync_Percentage_TimeActive(dataFltr), Sync_Percentage_TimeSync(dataFltr), Cell_Frequency(dataFltr), Cell_Mean_ActiveSynapses(dataFltr), Cell_Mean_PercentageSynapses(dataFltr),...
                    Cell_Mean_Intensity(dataFltr), Cell_Mean_InterSpikeInterval(dataFltr), Cell_CoV_ActiveSynapses(dataFltr), Cell_CoV_Intensity(dataFltr), Cell_CoV_InterSpikeInterval(dataFltr));
        end
        
        function plotRaster(app, tempTraces, varargin)
            if nargin == 4
                plotAx1 = varargin{1};
                plotAx2 = varargin{2};
            else
                plotAx1 = app.UIAxesRaster;
                plotAx2 = app.UIAxesOverview;
            end
            tempRaster = tempTraces;
            keepSyn = app.imgT.KeepSyn{app.currCell};
            Fs = app.imgT.Fs(app.currCell);
            time = (0:length(tempRaster)-1) / Fs;
            cellSpace = max(tempRaster,[],'all') / 3;
            cellNum = (1:size(tempRaster,2)) * cellSpace;
            tempRaster = tempRaster + repmat(cellNum,size(tempRaster,1),1);
            plot(plotAx1, time, tempRaster, 'k', 'HitTest', 'off', 'ButtonDownFcn', '');
            % Adjust the color based on the keep data
            if app.imgT.KeepCell(app.currCell)
                cmap = [0 0 0; 0.9 0.9 0.9];
            else
                cmap = app.keepColor([3; 4],:);
            end
            for s = 1:numel(keepSyn)
                keepIdx = numel(keepSyn) - s +1;
                if keepSyn(s)
                    plotAx1.Children(keepIdx).Color = cmap(1,:);
                else
                    plotAx1.Children(keepIdx).Color = cmap(2,:);
                end
            end
            yMin = round(min(tempRaster,[],'all'), 2, 'significant');
            yMax = round(max(tempRaster,[],'all'), 2, 'significant') + cellSpace;
            plotAx1.YLim = [yMin, yMax];
            plotAx1.YTick = linspace(yMin+cellSpace, yMax-cellSpace, size(tempRaster,2));
            plotAx1.YTickLabel = 1:size(tempRaster,2);
            title(plotAx1, regexprep(app.imgT.CellID(app.currCell), '_', ' '))
            box(plotAx1, 'off');
            plotAx1.TickDir = 'out';
            % Plot the average trace
            cla(plotAx2, 'reset')
            tempSync = app.imgT.PeakSync{app.currCell};
            nSyn = size(tempRaster,2);
            yyaxis(plotAx2, 'left');
            area(plotAx2, time, tempSync/nSyn*100, 'EdgeColor', 'none', 'FaceColor', [38 134 197]/255, 'FaceAlpha', .5)
            tempNetwork = app.imgT.Sync_PeakLocation{app.currCell}{2};
            tempNetwork1 = app.imgT.Sync_SynapseCount{app.currCell}{2};
            hold(plotAx2, 'on')
            plot(plotAx2, time(tempNetwork), tempNetwork1/nSyn*100, 'sk');
            ylabel(plotAx2, '% of synapses')
            yyaxis(plotAx2, 'right');
            plot(plotAx2, time, mean(tempTraces(:,keepSyn),2), 'r');
            ylabel(plotAx2, 'iGluSnFR intensity (a.u.)')
            box(plotAx2, 'off');
            plotAx2.TickDir = 'out';
        end
        
        function plotRasterStim(app, tempTraces, varargin)
            if nargin == 4
                plotAx1 = varargin{1};
                plotAx2 = varargin{2};
            else
                plotAx1 = app.UIAxesRaster;
                plotAx2 = app.UIAxesOverview;
            end
            tempRaster = tempTraces;
            keepSyn = app.imgT.KeepSyn{app.currCell};
            Fs = app.imgT.Fs(app.currCell);
            time = (0:size(tempRaster,1)-1) / Fs;
            % Get the information on the stimulation
            stimID = find(matches(app.stim.StimID, app.imgT.StimID(app.currCell)));
            xStim = app.stim.Baseline(stimID):1/app.stim.FreqAP(stimID):(app.stim.Baseline(stimID))+(1/app.stim.FreqAP(stimID))*(app.stim.nAP(stimID)-1);
            if app.stim.nTrains(stimID) > 1
                % There are multiple movies merged into 1. Split them and work on each movie separate
                movDiv = numel(time) / app.stim.nTrains(stimID);
                movS = 1:movDiv:numel(time);
                movS = time(movS);
                xStim = repmat(xStim, 1, app.stim.nTrains(stimID)) + repelem(movS, app.stim.nAP(stimID));
            end
            xPatch([1 4],:) = ones(2,1) * (xStim - 0.005);
            xPatch([2 3],:) = ones(2,1) * (xStim + 0.005);
            yPatch = repmat([0; 0; .1; .1], 1, numel(xStim));
            hStim = patch(plotAx1, xPatch, yPatch, [.0 .8 .8], 'EdgeColor', 'none', 'FaceAlpha', .75, 'HitTest', 'off', 'ButtonDownFcn', '');
            hold(plotAx1, 'on');
            % Space the line in the raster
            cellSpace = max(tempRaster,[],'all') / 3;
            cellNum = (1:size(tempRaster,2)) * cellSpace;
            tempRaster = tempRaster + repmat(cellNum,size(tempRaster,1),1);
            plot(plotAx1, time, tempRaster, 'k', 'HitTest', 'off', 'ButtonDownFcn', '');
            % Adjust the color based on the keep data
            if app.imgT.KeepCell(app.currCell)
                cmap = [0 0 0; 0.9 0.9 0.9];
            else
                cmap = app.keepColor([3; 4],:);
            end
            for s = 1:numel(keepSyn)
                keepIdx = numel(keepSyn) - s +1;
                if keepSyn(s)
                    plotAx1.Children(keepIdx).Color = cmap(1,:);
                else
                    plotAx1.Children(keepIdx).Color = cmap(2,:);
                end
            end
            yMin = round(min(tempRaster,[],'all'), 2, 'significant');
            yMax = round(max(tempRaster,[],'all'), 2, 'significant') + cellSpace;
            plotAx1.YLim = [yMin, yMax];
            plotAx1.YTick = linspace(yMin+cellSpace, yMax-cellSpace, size(tempRaster,2));
            plotAx1.YTickLabel = 1:size(tempRaster,2);
            title(plotAx1, regexprep(app.imgT.CellID(app.currCell), '_', ' '))
            box(plotAx1, 'off');
            plotAx1.TickDir = 'out';
            hStim.YData = repmat(repelem([yMin; yMax],2), 1, numel(xStim));
            % Plot the average trace
            cla(plotAx2, 'reset')
            tempSync = app.imgT.PeakSync{app.currCell};
            nSyn = size(tempRaster,2);
            yyaxis(plotAx2, 'left');
            area(plotAx2, time, tempSync/nSyn*100, 'EdgeColor', 'none', 'FaceColor', [38 134 197]/255, 'FaceAlpha', .5)
            ylabel(plotAx2, '% of synapses')
            yyaxis(plotAx2, 'right');
            plot(plotAx2, time, mean(tempTraces(:,keepSyn),2), 'r');
            ylabel(plotAx2, 'iGluSnFR intensity (a.u.)')
            box(plotAx2, 'off');
            plotAx2.TickDir = 'out';
        end
        
        function updateRaster(app, event)
            newKeep = app.UITableSingle.Data.synKeep;
            nKeep = numel(newKeep);
            if app.imgT.KeepCell(app.currCell)
                cmap = [0 0 0; 0.9 0.9 0.9];
            else
                cmap = app.keepColor([3; 4],:);
            end
            for k = 1:nKeep
                if newKeep(k)
                    app.UIAxesRaster.Children(nKeep+1-k).Color = cmap(1,:);
                else
                    app.UIAxesRaster.Children(nKeep+1-k).Color = cmap(2,:);
                end
            end
            app.imgT.KeepSyn{app.currCell} = newKeep;
            % Calculate the new synchronous and plot the average trace
            cla(app.UIAxesOverview, 'reset')
            tempTraces = app.imgT.DetrendData{app.currCell};
            Fs = app.imgT.Fs(app.currCell);
            time = (0:size(tempTraces,1)-1) / Fs;
            tempSync = calculateSynchronous(app, app.imgT.PeakLoc{app.currCell}, size(tempTraces,1), numel(newKeep), newKeep, Fs, false);
            nSyn = size(tempTraces,2);
            yyaxis(app.UIAxesOverview, 'left');
            area(app.UIAxesOverview, time, tempSync/nSyn*100, 'EdgeColor', 'none', 'FaceColor', [38 134 197]/255, 'FaceAlpha', .5)
            ylabel(app.UIAxesOverview, '% of synapses')
            yyaxis(app.UIAxesOverview, 'right');
            plot(app.UIAxesOverview, time, mean(tempTraces(:,newKeep),2), 'r');
            ylabel(app.UIAxesOverview, 'iGluSnFR intensity (a.u.)')
            box(app.UIAxesOverview, 'off');
            app.UIAxesOverview.TickDir = 'out';
            if app.UIAxesRaster.Toolbar.Visible
                app.UIAxesRaster.Toolbar.Visible = 'off';
            end
        end
        
        function TableClicked(app, event)
            app.selectedTableCell = event.Indices;
        end
        
        function TableSelectedCell(app, event, varargin)
            togglePointer(app)
            if strcmp(event.Key, 'shift')
                if nargin == 3
                    plotAx = varargin{1};
                else
                    plotAx = app.UIAxesBox;
                end
                % First check if there is one or two colum selected
                if size(app.selectedTableCell, 1) == 1
                    switch app.UITableAll.ColumnName{app.selectedTableCell(2)}
                        case {'Cell', 'RecID'}
                            % get the cell selected and show it
                            selected = app.UITableAll.Data.cellID{app.selectedTableCell(1)};
                            selIdx = matches(app.imgT.ExperimentID, selected);
                            cellIDs = app.imgT.ExperimentID{selIdx};
                            app.List_CellID.Value = app.List_CellID.Items{matches(app.List_CellID.Items, cellIDs)};
                            populateRecID(app);
                            populateTable(app, event)
                        case 'Keep'
                            cla(plotAx);
                            reset(plotAx);
                            if ~isempty(plotAx.Legend)
                                plotAx.Legend.Visible = 'off';
                            end
                            hold(plotAx, 'on');
                            uniCond = categories(app.imgT.ConditionID);
                            nCond = numel(uniCond);
                            cmap = getColormap(app);
                            varB = categorical(app.imgT.BatchID);
                            batches = unique(varB);
                            nBatch = numel(batches);
                            for c = 1:nCond
                                condFltr = app.imgT.ConditionID == uniCond(c);
                                tempData = zeros(nBatch,1);
                                x = linspace(c - 0.15, c + 0.15, nBatch);
                                for b = 1:nBatch
                                    batchFltr = varB == batches(b);
                                    tempData(b,1) = sum(app.imgT{condFltr & batchFltr, 'KeepCell'}) / sum(condFltr & batchFltr);
                                end
                                plot(plotAx, x, tempData, 'o', 'MarkerFaceColor', cmap(c,:), 'MarkerSize', 8, 'MarkerEdgeColor', 'none', 'HitTest', 'off', 'ButtonDownFcn', '')
                                plot(plotAx, x, ones(1,nBatch)*mean(tempData), 'Color', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '')
                                plot(plotAx, [c c], [mean(tempData)-std(tempData) mean(tempData)+std(tempData)], 'Color', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '')
                            end
                            % Add the label
                            plotAx.TickDir = 'out';
                            plotAx.XLim = [.5 nCond+.5];
                            plotAx.XTick = 1:nCond;
                            plotAx.XTickLabel = uniCond;
                            plotAx.XTickLabelRotation = 45;
                            ylabel(plotAx, 'Keeped to total recording ratio')
                        otherwise
                            % First make sure that the data is up to date
                            %DetectCellPeaks(app)
                            %populateCellTable(app)
                            cla(plotAx);
                            reset(plotAx);
                            if ~isempty(plotAx.Legend)
                                plotAx.Legend.Visible = 'off';
                            end
                            hold(plotAx, 'on');
                            vars = app.UITableAll.ColumnName;
                            keepFltr = app.UITableAll.Data.cellKeep;
                            varX = app.UITableAll.Data{keepFltr, app.selectedTableCell(2)};
                            varG = app.UITableAll.Data{keepFltr, 'recID'};
                            varB = app.UITableAll.Data{keepFltr, 'cellID'};
                            varB = cellfun(@(x) regexp(x, '_', 'split'), varB, 'UniformOutput', false);
                            varB = cellfun(@(x) x(1), varB);
                            dataBoxPlot(app, varX, varG, varB, vars{app.selectedTableCell(2)}, plotAx)
%                             plotAx.YLim = [0 .1];
                    end
                elseif size(app.selectedTableCell, 1) == 2
                    % Scatter plot of the data
                    cla(plotAx);
                    reset(plotAx);
                    if ~isempty(plotAx.Legend)
                        plotAx.Legend.Visible = 'off';
                    end
                    hold(plotAx, 'on');
                    % Get the data to plot
                    keepFltr = app.UITableAll.Data.cellKeep;
                    varX = app.UITableAll.Data{keepFltr,app.selectedTableCell(1,2)};
                    varY = app.UITableAll.Data{keepFltr,app.selectedTableCell(2,2)};
                    % Get the conditions from the table
                    varG = app.UITableAll.Data{keepFltr,'recID'};
                    uniCond = categories(varG);
                    nCond = numel(uniCond);
                    cmap = getColormap(app);
                    l = 1;
                    for c = 1:nCond
                        if any(c==[1 4 7])
                            condFltr = varG == uniCond(c);
                            hLeg(l) = plot(plotAx, varX(condFltr), varY(condFltr), 'o', 'MarkerFaceColor', cmap(c,:), 'MarkerEdgeColor', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                            l=l+1;
                        end
                    end
                    legend(hLeg, uniCond([1 4 7]), 'Location', 'best')
                    xlabel(plotAx, app.UITableAll.ColumnName(app.selectedTableCell(1,2)))
                    ylabel(plotAx, app.UITableAll.ColumnName(app.selectedTableCell(2,2)))
                else
                    cla(plotAx);
                    reset(plotAx);
                    if ~isempty(plotAx.Legend)
                        plotAx.Legend.Visible = 'off';
                    end
                    hold(plotAx, 'on');
                    % The X axis is the percentage of cell that are active at the same time
                    fillX = [1:100 100:-1:1];
                    % The Y axis if the time that a cell spend active with that amount of synapses
                    netData = cell2mat(app.imgT.PeakSync')';
                    nFrames = size(netData,2);
                    synKeep = cellfun(@sum, app.imgT.KeepSyn);
                    uniCond = categories(app.imgT.ConditionID);
                    nCond = numel(uniCond);
                    cmap = getColormap(app);
                    l=1;
                    for c = 1:nCond
                        tempMean = zeros(1,100);
                        tempSEM = zeros(1,100);
                        for p = 1:100
                            condFltr = app.imgT.ConditionID == uniCond(c);
                            tempData = sum(netData(condFltr,:) >= (synKeep(condFltr,:) * p/100), 2) / nFrames * 100;
                            tempMean(p) = mean(tempData);
                            tempSEM(p) = std(tempData) / sqrt(sum(condFltr));
                        end
                        if any(c==[1 4 7])
                            fillY = [tempMean-tempSEM fliplr(tempMean+tempSEM)];
                            fill(plotAx, fillX, fillY, cmap(c,:), 'EdgeColor', 'none', 'FaceAlpha', .3);
                            hLeg(l) = plot(plotAx, 1:100, tempMean, 'Color', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                            l=l+1;
                        end
                    end
                    legend(hLeg, uniCond([1 4 7]), 'Box', 'off')
                    plotAx.XLim = [0 100];
                    plotAx.YLim = [0 plotAx.YLim(2)];
                    xlabel(plotAx, '% of active synapses');
                    ylabel(plotAx, '% of time');
                end
            end
            togglePointer(app)
        end
        
        function RasterClicked(app, event)
            if app.ZoomRasterButton.Value
                ticks = app.UIAxesRaster.YTick;
                yInc = mean(diff(ticks)) * 2;
                oldY = app.UIAxesRaster.YLim;
                if event.Button == 1
                    oldY = find(ticks >= oldY(2), 1) - 1;
                    newXAxis = [ticks(oldY)-yInc, ticks(min(oldY+10, numel(ticks)))+yInc];
                    app.UIAxesRaster.YLim = newXAxis;
                elseif event.Button == 3
                    oldY = find(ticks >= oldY(1), 1) - 1;
                    newXAxis = [ticks(max(oldY-10, 1))-yInc, ticks(oldY)+yInc];
                    app.UIAxesRaster.YLim = newXAxis;
                end
            end
        end
        
        function dataBoxPlot(app, varX, varG, varB, varLabel, plotAx)
            uniCond = categories(varG);
            nCond = numel(uniCond);
            cmap = getColormap(app);
            varB = categorical(varB);
            batches = unique(varB);
            nBatch = numel(batches);
            for c = 1:nCond
                condFltr = varG == uniCond(c);
                tempY = sort(varX(condFltr));
                quantY = quantile(tempY, [0.25 0.5 0.75]);
                minW = quantY(1) - 1.5*(quantY(3)-quantY(1));
                lowW = find(tempY>=minW,1,'first');
                minW = tempY(lowW);
                maxW = quantY(3) + 1.5*(quantY(3)-quantY(1));
                highW = find(tempY<=maxW,1,'last');
                maxW = tempY(highW);
                % Boxplot
                patch(plotAx, [c-.25 c+.25 c+.25 c-.25], [quantY(1) quantY(1) quantY(3) quantY(3)], cmap(c,:), 'FaceAlpha', .3, 'EdgeColor', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                plot(plotAx, [c-.25 c+.25], [quantY(2) quantY(2)], 'color', cmap(c,:), 'LineWidth', 2, 'HitTest', 'off', 'ButtonDownFcn', '');
                plot(plotAx, [c c], [minW quantY(1)], 'color', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                plot(plotAx, [c c], [quantY(3) maxW], 'color', cmap(c,:), 'HitTest', 'off', 'ButtonDownFcn', '');
                % Add the data points
                x = linspace(c - 0.15, c + 0.15, nBatch);
                for b = 1:nBatch
                    batchFltr = varB == batches(b);
                    if sum(batchFltr & condFltr) > 0
                        plot(plotAx, x(b), varX(batchFltr & condFltr), 'o', 'MarkerEdgeColor', cmap(c,:), 'MarkerSize', 4, 'MarkerFaceColor', 'w', 'HitTest', 'off', 'ButtonDownFcn', '')
                    end
                end
            end
            % Add the label
            plotAx.TickDir = 'out';
            plotAx.XLim = [.5 nCond+.5];
            plotAx.XTick = 1:nCond;
            plotAx.XTickLabel = uniCond;
            plotAx.XTickLabelRotation = 45;
            ylabel(plotAx, varLabel)
        end
        
        function ResetRaster(app)
            oldKeep = app.UITableSingle.Data.synKeep;
            newKeep = true(numel(oldKeep),1);
            app.imgT.KeepSyn{app.currCell} = newKeep;
            app.UITableSingle.Data.synKeep = newKeep;
            updateRaster(app, []);
        end
        
        function cmap = getColormap(app)
            cmap1 = {'#000000', '#4D4D4D', '#8C8C8C',...
                '#9100AD', '#9B00BA', '#D000FA',...
                '#61AD00', '#69BA00', '#8EFA00'};
            cmap = nan(length(cmap1), 3);
            for c = 1:length(cmap1)
                cmap(c,:) = sscanf(cmap1{c}(2:end),'%2x%2x%2x',[1 3])/255;
            end
        end
    end
    
    % Method for table tab for stimulation recordings
    methods (Access = private)
        
    end
    
    % Create the UIFigure and components
    methods (Access = private)
        function createComponents(app)
            % Main UI
            app.UIFigure = uifigure('Units', 'pixels', 'Visible', 'off',...
                'Position', [100 100 1895 942],...
                'Name', 'GluTA: iGluSnFR Trace Analyzer', 'ToolBar', 'none', 'MenuBar', 'none',...
                'NumberTitle', 'off', 'WindowScrollWheelFcn', @(~,event)SliderMovieMoved(app, event),...
                'KeyReleaseFcn', @(~,event)keyPressed(app, event));
            
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
            app.QuantifyMenu = uimenu(app.UIFigure, 'Text', '&Quantify');
            app.QuantifyMenuCellPeaks = uimenu(app.QuantifyMenu, 'Text', 'Cell Peaks',...
                'MenuSelectedFcn', createCallbackFcn(app, @DetectCellPeaks, false));
            app.QuantifyMenuFeature = uimenu(app.QuantifyMenu, 'Text', 'Extract Features',...
                'MenuSelectedFcn', createCallbackFcn(app, @ExtractPeakFeatures, false));
            app.OptionMenu = uimenu(app.UIFigure, 'Text', '&Option');
            app.OptionMenuDebug = uimenu(app.OptionMenu, 'Text', '&Debug',...
                'Accelerator', 'D', 'MenuSelectedFcn', createCallbackFcn(app, @OptionMenuDebugSelected, false));
            
            % Define multiple tabs where to store the UI
            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [2 3 1894 940], 'SelectionChangedFcn', createCallbackFcn(app, @populateTable, true));
            app.MainTab = uitab(app.TabGroup, 'Title', 'Main');
            app.TableTab = uitab(app.TabGroup, 'Title', 'Table');
            
            % Create the visual components: Movie and plot axes with slider
            app.UIAxesMovie = uiaxes(app.MainTab, 'Position', [36 63 806 806], 'Visible', 'off');
            title(app.UIAxesMovie, ''); xlabel(app.UIAxesMovie, ''); ylabel(app.UIAxesMovie, '')
            app.UIAxesPlot = uiaxes(app.MainTab, 'Position', [870 12 990 327], 'Visible', 'on',...
                'ButtonDownFcn', createCallbackFcn(app, @GetClickedCoordinate, true));
            title(app.UIAxesPlot, ''); xlabel(app.UIAxesPlot, 'Time (s)'); ylabel(app.UIAxesPlot, 'iGluSnFR (a.u.)');
            app.UIAxesPlot.Toolbar.Visible = 'off';
            app.SliderMovie = uislider(app.MainTab, 'Position', [36 44 806 3], 'Visible', 'off',...
                'ValueChangingFcn', createCallbackFcn(app, @SliderMovieMoved, true));
            
            % Create Plot Type Button Group
            app.PlotTypeButtonGroup = uibuttongroup(app.MainTab, 'Title', 'Plot Type', 'Position', [885 381 118 73],...
                'SelectionChangedFcn', createCallbackFcn(app, @switchPlotType, false));
            app.AllAndMeanRadio = uiradiobutton(app.PlotTypeButtonGroup, 'Text', 'All and mean', 'Position', [11 27 92 22],...
                'Value', true, 'Enable', 'off');
            app.SingleTracesRadio = uiradiobutton(app.PlotTypeButtonGroup, 'Text', 'Single trace', 'Position', [11 5 91 22],...
                'Enable', 'off');
            
            % Create DetrendButton, Export and Fix Y axis value
            app.ExportTraceButton = uibutton(app.MainTab, 'push', 'Text', 'Export trace', 'Position', [1032 381 100 22],...
                'Enable', 'off', 'ButtonPushedFcn', createCallbackFcn(app, @ExportPlot, true));
            app.KeepCellToggle = uibutton(app.MainTab, 'state', 'Text', 'Keep cell', 'Position', [1032 410 100 22],...
                'Enable', 'off', 'ValueChangedFcn', createCallbackFcn(app, @keepCell, false));
            app.FixYAxisButton = uibutton(app.MainTab, 'state', 'Text', 'Fix Y Axis', 'Position', [1450 338 100 22],...
                'Enable', 'off', 'ValueChangedFcn', createCallbackFcn(app, @fixYAxis, false));
            app.DetrendButton = uibutton(app.MainTab, 'push', 'Text', 'Detrend', 'Position', [1560 338 100 22],...
                'Enable', 'off', 'ButtonPushedFcn', createCallbackFcn(app, @detrendData, false));
            app.ZoomInButton = uibutton(app.MainTab, 'state', 'Text', 'Zoom In', 'Position', [1670 338 100 22],...
                'Enable', 'on', 'ValueChangedFcn', createCallbackFcn(app, @ZoomIn, true));
            
            % Create Synapse navigation panel
            app.PrevButton = uibutton(app.MainTab, 'push', 'Text', 'Prev', 'Position', [1089 338 36 22],...
                'Enable', 'off', 'ButtonPushedFcn', createCallbackFcn(app, @prevButtonPressed, false));
            app.TextSynNumber = uieditfield(app.MainTab, 'numeric', 'Position', [1128 338 48 22], 'Value', 1,...
                'Enable', 'off', 'ValueChangedFcn', createCallbackFcn(app, @updatePlot, false));
            app.NextButton = uibutton(app.MainTab, 'push', 'Text', 'Next', 'Position', [1179 338 40 22],...
                'Enable', 'off', 'ButtonPushedFcn', createCallbackFcn(app, @nextButtonPressed, false));
            
            % Create Manual peaks detection panel
            app.AddPeaksButton = uibutton(app.MainTab, 'state', 'Text', 'Add peaks', 'Position', [1230 338 100 22],...
                'Enable', 'off', 'ValueChangedFcn', createCallbackFcn(app, @crosshairCursor, true));
            app.DeletePeaksButton = uibutton(app.MainTab, 'state', 'Text', 'Delete peaks', 'Position', [1340 338 100 22],...
                'Enable', 'off', 'ValueChangedFcn', createCallbackFcn(app, @crosshairCursor, true));
            
            % Create Movie Toggles
            app.ShowMovieButton = uibutton(app.MainTab, 'state', 'Text', 'Show Movie', 'Position', [36 878 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @showMovie, false));
            app.ShowROIsButton = uibutton(app.MainTab, 'state', 'Text', 'Show ROIs', 'Position', [153 878 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @showROIs, false));
            app.MeasureROIsButton = uibutton(app.MainTab, 'push', 'Text', 'Measure ROIs', 'Position', [270 878 100 22], 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @MeasureROIsButtonPressed, false));
            
            % Create Tabs for List Recording
            app.TabListRecording = uitabgroup(app.MainTab, 'Position', [883 605 260 274]);
            app.CellIDTab = uitab(app.TabListRecording, 'Title', 'Cell ID');
            app.List_CellID = uilistbox(app.CellIDTab, 'Position', [10 11 239 227], 'Items', {''}, 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @populateRecID, false));
            app.RecIDTab = uitab(app.TabListRecording, 'Title', 'Rec ID');
            app.List_RecID = uilistbox(app.RecIDTab, 'Position', [10 11 239 227], 'Items', {''}, 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @List_RecID_changed, true));

            % Create ROIs Buttons
            app.ImportROIsButton = uibutton(app.MainTab, 'push', 'Text', 'Import ROIs', 'Position', [1038 543 100 22], 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @ImportROIsButtonPressed, false));
            app.DetectROIsButton = uibutton(app.MainTab, 'push', 'Text', 'Detect ROIs', 'Position', [1038 514 100 22], 'Enable', 'off');
            
            % Create Detect Event Button Group
            app.DetectEventButtonGroup = uibuttongroup(app.MainTab, 'Title', 'Detect events in:', 'Position', [884 483 123 106]);
            app.AllFOVsRadio = uiradiobutton(app.DetectEventButtonGroup, 'Text', 'All FOVs', 'Position', [11 60 69 22], 'Enable', 'off');
            app.CurrentListRadio = uiradiobutton(app.DetectEventButtonGroup, 'Text', 'Current list', 'Position', [11 38 80 22], 'Enable', 'off');
            app.SelectedFOVRadio = uiradiobutton(app.DetectEventButtonGroup, 'Text', 'Selected FOV', 'Position', [11 16 97 22], 'Enable', 'off');
            app.DetectPeaksButton = uibutton(app.MainTab, 'push', 'Text', 'Detect Peaks', 'Position', [1038 485 100 22], 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @DetectPeaksButtonPressed, false));
            
            % Create Detection Options Panel
            app.DetectionOptionsPanel = uipanel(app.MainTab, 'Title', 'Detection Options', 'Position', [1188 381 672 498]);
            app.SaveButton = uibutton(app.DetectionOptionsPanel, 'push', 'Text', 'Save', 'Position', [18 10 75 22],...
                'ButtonPushedFcn', createCallbackFcn(app, @SaveButtonPushed, true));
            app.DefaultButton = uibutton(app.DetectionOptionsPanel, 'push', 'Text', 'Default', 'Position', [102 10 75 22],...
                'ButtonPushedFcn', createCallbackFcn(app, @DefaultButtonPushed, true));
            
            % Create Load Options Panel
            app.LoadOptionsPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Load Options', 'Position', [11 207 177 255]);
            app.ImagingFrequencyLabel = uilabel(app.LoadOptionsPanel, 'Text', 'Frequency', 'Position', [4 204 63 22]);
            app.ImagingFrequencyEdit = uieditfield(app.LoadOptionsPanel, 'numeric', 'Position', [98 204 45 22], 'Value', app.Opt.ImgFrequency,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.MultipleRecordingCheckBox = uicheckbox(app.LoadOptionsPanel, 'Text', 'Multiple Recordings', 'Position', [4 166 177 22], 'Value', app.Opt.MultiRecording,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.RecordingIdentifierLabel = uilabel(app.LoadOptionsPanel, 'Position', [4 137 52 22], 'Text', 'Identifier');
            app.RecordingIdentifierEdit = uieditfield(app.LoadOptionsPanel, 'text', 'Position', [98 137 45 22], 'Value', app.Opt.RecIDs,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.StimulationCheckBox = uicheckbox(app.LoadOptionsPanel,'Text', 'Stimulation', 'Position', [4 91 81 22], 'Value', app.Opt.MultiStimulation,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.StimulationIdentifierLabel = uilabel(app.LoadOptionsPanel, 'Position', [4 57 52 22], 'Text', 'Identifier');
            app.StimulationIdentifierEdit = uieditfield(app.LoadOptionsPanel, 'text', 'Position', [98 57 45 22], 'Value', app.Opt.StimIDs,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.StimNumLabel = uilabel(app.LoadOptionsPanel, 'Position', [4 23 94 22], 'Text', 'How many stim?');
            app.StimNumEdit = uieditfield(app.LoadOptionsPanel, 'numeric', 'Position', [98 23 45 22], 'Value', app.Opt.StimNum,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));

            % Create ROI Detection Panel
            app.ROIDetectionPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'ROI Detection', 'Position', [201 341 453 121]);
            app.ROISizeLabel = uilabel(app.ROIDetectionPanel, 'HorizontalAlignment', 'right', 'Position', [10 69 129 22], 'Text', 'Expected ROI size (px)');
            app.ROISizeEdit = uieditfield(app.ROIDetectionPanel, 'numeric', 'Position', [154 69 24 22], 'Value', app.Opt.RoiSize,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.ROISigmaLabel = uilabel(app.ROIDetectionPanel, 'Position', [274 70 124 22], 'Text', 'Gaussian window size');
            app.ROISigmaEdit = uieditfield(app.ROIDetectionPanel, 'numeric', 'Position', [413 70 24 22], 'Value', app.Opt.RoiSigma,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.ProminenceROIsDropDownLabel = uilabel(app.ROIDetectionPanel, 'Position', [14 32 128 22], 'Text', 'Prominence estimation');
            app.ProminenceROIsDropDown = uidropdown(app.ROIDetectionPanel, 'Items', {'Standard Deviation', 'MAD'}, 'Position', [157 32 100 22], 'Value', app.Opt.RoiProminence,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.ProminenceROISigmaLabel = uilabel(app.ROIDetectionPanel, 'Position', [274 32 128 22], 'Text', 'ROI prominence sigma');
            app.ProminenceROISigmaEdit = uieditfield(app.ROIDetectionPanel, 'numeric', 'Position', [417 32 24 22], 'Value', app.Opt.RoiProminenceSigma,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));

            % Create Peak Detection Panel
            app.PeakDetectionPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Peak Detection', 'Position', [201 162 453 159]);
            app.PeakThresholdMethodDropDownLabel = uilabel(app.PeakDetectionPanel, 'HorizontalAlignment', 'right', 'Position', [10 111 102 22], 'Text', 'Threshold method');
            app.PeakThresholdMethodDropDown = uidropdown(app.PeakDetectionPanel, 'Items', {'MAD', 'Rolling StDev'}, 'Position', [127 111 100 22], 'Value', app.Opt.PeakThreshold,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.PeakSigmaLabel = uilabel(app.PeakDetectionPanel, 'Position', [240 111 94 22], 'Text', 'Threshold sigma');
            app.PeakSigmaEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [390 111 50 22], 'Value', app.Opt.PeakThrSigma,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.PeakMinProminenceLabel = uilabel(app.PeakDetectionPanel, 'Position', [14 79 124 22], 'Text', 'Minumum prominence');
            app.PeakMinProminenceEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [175 79 50 22], 'Value', app.Opt.PeakMinProm,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.PeakMinDurationLabel = uilabel(app.PeakDetectionPanel, 'Position', [240 79 130 22], 'Text', 'Minumum Duration (ms)');
            app.PeakMinDurationEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [390 79 50 22], 'Value', app.Opt.PeakMinDuration,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.MinDistanceLabel = uilabel(app.PeakDetectionPanel, 'Position', [15 41 140 22], 'Text', 'Minumum Distance (ms)');
            app.PeakMinDistanceEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [175 41 50 22], 'Value', app.Opt.PeakMinDistance,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.MaxDurationLabel = uilabel(app.PeakDetectionPanel, 'Position', [240 41 130 22], 'Text', 'Maximum Duration (ms)');
            app.PeakMaxDurationEdit = uieditfield(app.PeakDetectionPanel, 'numeric', 'Position', [390 41 50 22], 'Value', app.Opt.PeakMaxDuration,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            
            % Create Detrend Options Panel
            app.DetrendOptionsPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Detrend options', 'Position', [12 48 176 140]);
            app.MethodDropDownLabel = uilabel(app.DetrendOptionsPanel, 'Position', [10 88 56 22], 'Text', 'Method');
            app.MethodDropDown = uidropdown(app.DetrendOptionsPanel, 'Items', {'None', 'Moving median', 'Erosion', 'Polynomial'}, 'Position', [80 88 87 22], 'Value', app.Opt.Detrending,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.WindowSizeLabel = uilabel(app.DetrendOptionsPanel, 'Position', [8 53 73 22], 'Text', 'Window size');
            app.WindowSizeEdit = uieditfield(app.DetrendOptionsPanel, 'numeric', 'Position', [122 53 43 22], 'Value', app.Opt.DetrendSize,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.VisualizeDropDownLabel = uilabel(app.DetrendOptionsPanel, 'Position', [8 19 56 22], 'Text', 'Visualize');
            app.VisualizeDropDown = uidropdown(app.DetrendOptionsPanel, 'Items', {'Raw', 'Gradient', 'Smooth'}, 'Position', [78 19 87 22], 'Value', app.Opt.DetectTrace,...
                'ValueChangedFcn', createCallbackFcn(app, @updatePlot, false));

            % Create Stimulation Protocol Panel
            app.StimulationProtocolPanel = uipanel(app.DetectionOptionsPanel, 'Title', 'Stimulation protocol', 'Position', [202 5 452 144]);
            app.MergedRecordingsCheckBox = uicheckbox(app.StimulationProtocolPanel, 'Text', 'Merged recordings', 'Position', [179 59 144 22],...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.BaselineSecLabel = uilabel(app.StimulationProtocolPanel, 'Position', [184 93 95 22], 'Text', 'Baseline time (s)');
            app.BaselineSecEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [278 93 45 22], 'Value', 1,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.APNumLabel = uilabel(app.StimulationProtocolPanel, 'Position', [9 26 81 22], 'Text', 'Number of AP');
            app.APNumEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [103 26 45 22], 'Value', 25,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.APFreqLabel = uilabel(app.StimulationProtocolPanel, 'Position', [184 26 78 22], 'Text', 'AP frequency');
            app.APFreqEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [278 26 45 22], 'Value', 5,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.TrainsNumLabel = uilabel(app.StimulationProtocolPanel, 'Position', [8 59 94 22], 'Text', 'Number of trains');
            app.TrainsNumEdit = uieditfield(app.StimulationProtocolPanel, 'numeric', 'Position', [102 59 45 22], 'Value', 1,...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.TrainsIDsLabel = uilabel(app.StimulationProtocolPanel, 'Position', [8 93 52 22], 'Text', 'Identifier');
            app.TrainsIDsEdit = uieditfield(app.StimulationProtocolPanel, 'text', 'Position', [102 93 45 22], 'Value', '5Hz',...
                'ValueChangedFcn', createCallbackFcn(app, @OptionChanged, false));
            app.ToggleActive = uibutton(app.StimulationProtocolPanel, 'state', 'Text', 'Show active', 'Position', [340 25 100 22],...
                'ValueChangedFcn', createCallbackFcn(app, @ToogleActiveClicked, false));
            
            % Create UITableSingle
            app.UITableSingle = uitable(app.TableTab, 'ColumnName', {'Synapse #'; 'Mean Int'; 'Freq'; 'SNR'; 'Keep'}, 'RowName', {}, 'Position', [25 444 381 444],...
                'ColumnEditable', [false false false true], 'DisplayDataChangedFcn', createCallbackFcn(app, @updateRaster, true));

            % Create the context menu for the table
            app.TableMenu = uicontextmenu(app.UIFigure);
            app.FilterTable = uimenu(app.TableMenu, 'Text', 'Filter');
            app.FilterIntensity = uimenu(app.FilterTable, 'Text', 'Mean Intensity', 'MenuSelectedFcn', createCallbackFcn(app, @TableFilterSelected, true));
            app.FilterFrequency = uimenu(app.FilterTable, 'Text', 'Mean Frequency', 'MenuSelectedFcn', createCallbackFcn(app, @TableFilterSelected, true));
            app.FilterSNR = uimenu(app.FilterTable, 'Text', 'Mean SNR', 'MenuSelectedFcn', createCallbackFcn(app, @TableFilterSelected, true));
            app.UITableSingle.ContextMenu = app.TableMenu;
            
            % Create UIAxesRaster
            app.UIAxesRaster = uiaxes(app.TableTab, 'Position', [433 338 731 562], 'ButtonDownFcn', createCallbackFcn(app, @RasterClicked, true));
            title(app.UIAxesRaster, 'Title'); xlabel(app.UIAxesRaster, 'Time (s)'); ylabel(app.UIAxesRaster, 'Synapse #');
            app.UIAxesRaster.Toolbar.Visible = 'off';

            % Create UIAxesOverview
            app.UIAxesOverview = uiaxes(app.TableTab, 'Position', [433 12 726 289]);
            title(app.UIAxesRaster, ''); xlabel(app.UIAxesRaster, 'Time (s)'); ylabel(app.UIAxesRaster, 'Synapse #')

            % Create the Zoom, Reset, and Export functions
            app.ZoomRasterButton = uibutton(app.TableTab, 'state', 'Text', 'Zoom', 'Position', [438 309 100 22],...
                'Enable', 'on', 'ValueChangedFcn', createCallbackFcn(app, @ZoomIn, true));
            app.ResetRasterButton = uibutton(app.TableTab, 'push', 'Text', 'Reset', 'Position', [549 309 100 22],...
                'Enable', 'on', 'ButtonPushedFcn', createCallbackFcn(app, @ResetRaster, false));
            app.ExportRasterButton = uibutton(app.TableTab, 'push', 'Text', 'Export', 'Position', [667 309 100 22],...
                'Enable', 'on', 'ButtonPushedFcn', createCallbackFcn(app, @ExportPlot, true));
            
            % Create a table to store all the cells info
            app.UITableAll = uitable(app.TableTab, 'ColumnName', {'Cell'; 'Condition'; 'Keep'; 'Syn Mean Intensity'; 'Syn Mean Prominence'; 'Syn Mean Frequency';...
                                                                  'Syn Skewness Intensity'; 'Syn Skewness Prominence'; 'Syn Skewness Frequency'; 'Syn CoV Intensity'; 'Syn CoV Prominence';...
                                                                  'Syn CoV Frequency'; 'Sync Frequency'; 'Sync Raw MaxActiveSynapses'; 'Sync Percentage MaxActiveSynapses';...
                                                                  'Sync Percentage TimeActive'; 'Sync Percentage TimeSync'; 'Cell Frequency'; 'Cell Mean ActiveSynapses'; 'Cell Mean PercentageSynapses';...
                                                                  'Cell Mean Intensity'; 'Cell Mean InterSpikeInterval'; 'Cell CoV ActiveSynapses'; 'Cell CoV Intensity'; 'Cell CoV InterSpikeInterval'},...
                'RowName', {}, 'Position', [1210 12 650 289],...
                'CellSelectionCallback', createCallbackFcn(app, @TableClicked, true),...
                'KeyReleaseFcn', createCallbackFcn(app, @TableSelectedCell, true));
            
            % Create the axis to store the overview of the data
            app.UIAxesBox = uiaxes(app.TableTab, 'Position', [1300 340 560 560]);
            title(app.UIAxesBox, ''); xlabel(app.UIAxesBox, ''); ylabel(app.UIAxesBox, '');
            app.FigureMenu = uicontextmenu(app.UIFigure);
            app.BoxMenu = uimenu(app.FigureMenu, 'Text', 'Export plot', 'MenuSelectedFcn', createCallbackFcn(app, @ExportPlot, true));
            app.UIAxesBox.ContextMenu = app.FigureMenu;
            
            
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
            if app.newChange
                % If the data is not saved, ask if it needs to be saved
                answer = questdlg('Do you want to save the data?', 'Save before closing');
                switch answer
                    case 'Yes'
                        FileMenuSaveSelected(app);
                    case 'No'
                        % Nothing to add
                    case 'Cancel'
                        return
                end
            end
            delete(app.UIFigure);
        end
    end
end

                             