% Begin initialization code - DO NOT EDIT
function varargout = bin_ui(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                    'gui_Singleton',  gui_Singleton, ...
                    'gui_OpeningFcn', @bin_ui_OpeningFcn, ...
                    'gui_OutputFcn',  @bin_ui_OutputFcn, ...
                    'gui_LayoutFcn',  [] , ...
                    'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT

% --- Executes just before bin_ui is made visible.
function bin_ui_OpeningFcn(hObject, ~, h, varargin)
    set(h.pixelsPanel, 'Visible', 'off');
    set(h.metricsPanel, 'Visible', 'on');
    set(h.statsPanel, 'Visible', 'on');
    set(h.grainsPanel, 'Visible', 'off');

    set(h.binarizationFlag, 'Value', true);
    BinarizationFlag_Callback(h);

    axes(h.granulometric);
    set(h.granulometric.XLabel, 'String', 'Diameter [mm]');
    set(h.granulometric.YLabel, 'String', 'Cumulative [%]');
    set(gca,'XLim',[0 2],'YLim',[0 100]);

    rootdir = 'Images';
    filelist = dir(fullfile(rootdir, '**\*.*'));  %get list of files and folders in any subfolder
    filelist = filelist(~[filelist.isdir]);  %remove folders from list
    
    for ind=1:length(filelist)
        splitted = strsplit(filelist(ind).folder, '\');
        solFolder = splitted(length(splitted));
        if contains(solFolder, 'sol')
            fileName = strcat(solFolder, "    ", filelist(ind).name);
        else
            fileName = filelist(ind).name;
        end
        fileNames{ind} = fileName; %compile cell array of names.
    end
    
    h.imageStructs = filelist;
    set(h.otsuFlag, 'value', true);
    set(h.otsuWaterFlag, 'value', true);
    set(h.sharpenRadiusFlag, 'value', true);
    set(h.sharpRadiusVal, 'enable', 'on');
    set(h.binThVal, 'enable', 'off');
    set(h.binWaterThVal, 'enable', 'off');
    set(h.imagesList, 'string', fileNames);

    contents = cellstr(get(h.imagesList,'String'));
    h.selectedImage = contents{get(h.imagesList,'Value')};
    h.SelectedGrain = [];
    h.ClearlyVisibleGrains = [];
    h.WellDetectedGrains = [];

    contents = cellstr(h.imagesList.String);
    fileName = GetFullPath(char(contents(1)), h.imageStructs);
    
    myImage = imread(fileName);
    myImage = histeq(myImage);

    DisplayImage(myImage, h);

    set(gcf,'WindowButtonDownFcn',@display_ButtonDownFcn)
    
    % Choose default command line output for main
    h.output = hObject;

    
    
    
    % Update handles structure
    guidata(hObject, h);

    
% --- Outputs from this function are returned to the command line.
function varargout = bin_ui_OutputFcn(~, ~, h) 
    varargout{1} = h.output;
    

% --- Executes on button press in otsuFlag.
function OtsuFlag_Callback(hObject, ~, h)
    flag = get(hObject, 'Value');
    if flag == true
        set(h.binThVal, 'enable', 'off')
    else
        set(h.binThVal, 'enable', 'on')
    end


% --- Executes on button press in refreshBtn.
function RefreshBtn_Callback(hObject, ~)
    h = guidata(hObject);

    h.ClearlyVisibleGrains = [];
    h.SelectedGrain = [];
    h.WellDetectedGrains = [];
    guidata(hObject, h);
    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    
    radius = Get(h.radiusVal);
    
    if h.saveStepsFlag.Value
        CreateDictionary(fullPath);
    end

    if h.binarizationFlag.Value
        resultImg = Binarization_Callback(h, fullPath, radius);

    elseif h.cannyFlag.Value
        resultImg = Canny_Callback(h, fullPath, radius);

    elseif h.waterFlag.Value
        resultImg = Watershed_Callback(h, fullPath, radius);
    end
    
    resultImg = DeleteObjectsBydiameter(resultImg, Get(h.minDiameterVal), Get(h.maxDiameterVal));
    resultImg = DeleteObjectsByCircularity(resultImg, Get(h.circularityVal));
    
    
    if h.showOriginFlag.Value == false
        DisplayImage(resultImg, h);
    else
        myImage = imread(fullPath);
        myImage = histeq(myImage);
        DisplayImage(myImage, h);
    end
    
    DisplayContours(resultImg, h);
    
    CalculateParams(resultImg, hObject);
    h = guidata(hObject);
    set(h.detectedCountVal, 'string', h.Params.Number);
    DisplayData(hObject);

%     guidata(hObject, h);


% --- Executes on button press in binarizationFlag.
function BinarizationFlag_Callback(h)
    flag_value = h.binarizationFlag.Value;
    if flag_value == true
        set(h.binPanel, 'Visible', 'on');
        set(h.cannyPanel, 'Visible', 'off');
        set(h.waterPanel, 'Visible', 'off');
        set(h.cannyFlag, 'Value', false);
        set(h.waterFlag, 'Value', false);
    end


% --- Executes on button press in cannyFlag.
function CannyFlag_Callback(h)
    flag_value = h.cannyFlag.Value;
    if flag_value == true
        set(h.binPanel, 'Visible', 'off');
        set(h.cannyPanel, 'Visible', 'on');
        set(h.waterPanel, 'Visible', 'off');
        set(h.binarizationFlag, 'Value', false);
        set(h.waterFlag, 'Value', false);
    end


% --- Executes on button press in waterFlag.
function WaterFlag_Callback(h)
    flag_value = h.waterFlag.Value;
    if flag_value == true
        set(h.binPanel, 'Visible', 'off');
        set(h.cannyPanel, 'Visible', 'off');
        set(h.waterPanel, 'Visible', 'on');
        set(h.cannyFlag, 'Value', false);
        set(h.binarizationFlag, 'Value', false);
        set(h.cannyFlag, 'Value', false);
    end


% --- Executes on selection change in imagesList.
function ImagesList_Callback(hObject, ~)
    h = guidata(hObject);
    contents = cellstr(get(h.imagesList,'String'));
    h.selectedImage = contents{get(h.imagesList, 'Value')};
    
    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    myImage = imread(fullPath);
    myImage = histeq(myImage);
    DisplayImage(myImage, h);
    guidata(hObject, h);



% --- CUSTOM FUNCTIONS ---

% --- returns full path for file struct
function path = GetFullPath(fileID, imageStructs)
    parts = strsplit(fileID, ' ');
    fileName = char(parts(length(parts)));

    for ind=1:length(imageStructs)
        if strcmp(fileName,imageStructs(ind).name)
            path = strcat(imageStructs(ind).folder, '\', imageStructs(ind).name);
            break;
        end
    end


% --- Fits image to GUI axes
function resultImg = FitToAxes(image, h)
    set(h.display ,'Units','pixels');
    resizePos = get(h.display ,'Position');
    resultImg = imresize(image, [resizePos(3) resizePos(3)]);


% --- Disaplays image in axes.
function DisplayImage(myImage, h)
    myImage = FitToAxes(myImage, h);
    axes(h.display);
    imshow(myImage);
    set(h.display ,'Units','normalized');


% --- Calls Binarization with correct args
function resultImg = Binarization_Callback(h, path, radius)
    if h.otsuFlag.Value == false
        [s, binThresh] = TryGet(h.binThVal,  @(binTh) 0 < binTh && binTh < 1, "Binarization threshold should be between 0 and 1: 0 < binThresh < 1");
        if s == false
            return;        
        end
        [resultImg, otsu] = Binarization(path, h.saveStepsFlag.Value, radius, binThresh);
    else
        [resultImg, otsu] = Binarization(path, h.saveStepsFlag.Value, radius);
    end    

    set(h.binThVal, 'String', num2str(otsu));


% --- Calls Canny with correct args
function resultImg = Canny_Callback(h, path, radius)
    [s1, low]   = TryGet(h.lowThVal,  @(low) 0 < low && low < 1, "Incorrect low value, should be: 0 < low < high < 1");
    [s2, high]  = TryGet(h.highThVal, @(high) 0 < high && low < high && high < 1, "Incorrect high value, should be: 0 < low < high < 1");
    [s3, sigma] = TryGet(h.sigmaVal, @(sigma) sigma > 0, "Sigma should be bigger than zero: sigma > 0");

    if s1 && s2 && s3
        resultImg = Canny(path, h.saveStepsFlag.Value, radius, [low, high], sigma);
    else
        return;
    end


% --- Calls Watershed with correct args
function resultImg = Watershed_Callback(h, path, radius)
    [s1, sharpRadius]     = TryGet(h.sharpRadiusVal,     @(radius) radius >= 0, "Sharpen Radius should be bigger or equal to zero: radius >= 0");
    [s2, low]             = TryGet(h.waterLowThVal,      @(low) 0 < low && low < 1, "Incorrect low value, should be: 0 < low < high < 1");
    [s3, high]            = TryGet(h.waterHighThVal,     @(high) 0 < high && low < high && high < 1, "Incorrect high value, should be: 0 < low < high < 1");
    [s4, sigma]           = TryGet(h.waterSigmaVal,      @(sigma) sigma > 0, "Sigma should be bigger than zero: sigma > 0");
    [s5, gaussSigma]      = TryGet(h.gaussSigmaVal,      @(gSigma) gSigma > 0, "Gaussian sigma should be bigger than zero: gSigma > 0");
    [s6, gaussFilter]     = TryGet(h.filterVal,          @(gFilter) mod(gFilter, 2) == 1, "Gaussian filter should be odd value");
    
    if h.sharpenRadiusFlag.Value == false
        sharpRadius = 0;
    end
    
    if (s1 && s2 && s3 && s4 && s5 && s6) == false
        return;
    end
    
    if h.otsuWaterFlag.Value == false
        [s7, binThresh] = TryGet(h.binWaterThVal, @(binTh) 0 < binTh && binTh < 1, "Binarization threshold should be between 0 and 1: 0 < binThresh < 1");
        if s7 == false
            return;
        end
        [resultImg, otsu] = Watershed(path, h.saveStepsFlag.Value, radius, sharpRadius, [low, high], sigma, gaussSigma, gaussFilter, binThresh);
    else
        [resultImg, otsu] = Watershed(path, h.saveStepsFlag.Value, radius, sharpRadius, [low, high], sigma, gaussSigma, gaussFilter);
    end

    set(h.binWaterThVal, 'String', num2str(otsu));

% --- Returns double value from handle
function value = Get(handle)
    value = str2double(handle.String);


% --- Returns value with validation
function [success, value] = TryGet(handle, predicate, errMsg)
    value = Get(handle);
    set(handle,'Backgroundcolor','w');
    if predicate(value)
        success = true;
    else
        success = false;
        set(handle,'Backgroundcolor','r');
        uiwait(msgbox(errMsg));
    end


% --- Displays contours on scaled image
function DisplayContours(image, h)
    hold on;
    % displayImage = FitToAxes(image, h);
    displayImage = image;
    [B, ~] = bwboundaries(displayImage,'noholes');
    
    
    set(h.display ,'Units','pixels');
    resizePos = get(h.display ,'Position');
    scale = resizePos(3) / 1024;

    for k = 1:length(B)
        boundary = B{k}.*scale;
        plot(boundary(:,2),boundary(:,1),'r','LineWidth',2)
    end

    for i = 1:length(h.SelectedGrain)
        boundary = B{h.SelectedGrain(i)}.*scale;
        plot(boundary(:,2),boundary(:,1),'b','LineWidth',2)
    end

    for i = 1:length(h.ClearlyVisibleGrains)
        boundary = B{h.ClearlyVisibleGrains(i)}.*scale;
        plot(boundary(:,2),boundary(:,1),'y','LineWidth',2)
    end

    for i = 1:length(h.WellDetectedGrains)
        boundary = B{h.WellDetectedGrains(i)}.*scale;
        plot(boundary(:,2),boundary(:,1),'g','LineWidth',2)
    end



% --- calculates contours/grains parameters from image
function CalculateParams(img,  hObject)
    h = guidata(hObject);
    [B, L] = bwboundaries(img,'noholes');
    stats = regionprops(L,'Area','Centroid', 'MinorAxisLength', 'MajorAxisLength', 'EquivDiameter', 'Perimeter', 'Circularity');
    h.resultImage = img;

    % diameters
    diameters = [stats.EquivDiameter];
    diametersTable = [median(diameters) mean(diameters) std(diameters)];
    
    % short axis
    shortAxisTable = [median([stats.MinorAxisLength]) mean([stats.MinorAxisLength]) std([stats.MinorAxisLength])];
    
    % long axis
    longAxisTable = [median([stats.MajorAxisLength]) mean([stats.MajorAxisLength]) std([stats.MajorAxisLength])];
    
    % Circularity   
    circularityTable = [median([stats.Circularity]) mean([stats.Circularity]) std([stats.Circularity])];
    
    % aspect ratio
    ratios = [stats.MinorAxisLength]./[stats.MajorAxisLength];
    ratioTable = [median(ratios) mean(ratios) std(ratios)];
    
    h.Params.DiametersList = diameters;
    h.Params.Perimeters = [stats.Perimeter];
    h.Params.Area = [stats.Area];
    h.Params.ShortAxisList = [stats.MinorAxisLength];
    h.Params.LongAxisList = [stats.MajorAxisLength];
    h.Params.CircularityList = [stats.Circularity];
    h.Params.RatioList = ratios;
    h.Params.Number = size(stats, 1);
    h.Params.Diameter = diametersTable;
    h.Params.ShortAxis = shortAxisTable;
    h.Params.LongAxis = longAxisTable;
    h.Params.Circularity = circularityTable;
    h.Params.Ratio = ratioTable;

    % -- distribution
    pd = makedist('Normal');
    values = sort(Pixels2MM(diameters));
    y = cdf(pd, sort(Pixels2MM(diameters)));
    axes(h.granulometric);
    plot(values, y.*100);
    set(h.granulometric.XLabel, 'String', 'Diameter [mm]');
    set(h.granulometric.YLabel, 'String', 'Cumulative [%]');
    set(gca,'XLim',[0 2]);

    guidata(hObject, h);


% --- displays data about detected grains
function DisplayData(hObject)
    h = guidata(hObject);
    set(h.grainsNumVal, 'String', h.Params.Number);

    infoPixels = [h.Params.Diameter; h.Params.ShortAxis; h.Params.LongAxis; h.Params.Circularity; h.Params.Ratio];
    set(h.tablePixels, 'Data',  infoPixels);

    infoMetric = [Pixels2MM(h.Params.Diameter); Pixels2MM(h.Params.ShortAxis); Pixels2MM(h.Params.LongAxis); h.Params.Circularity; h.Params.Ratio];
    set(h.tableMetrics, 'Data',  infoMetric);


% --- converts Pixels to MMs, value can be scalar or matrix
function convertedVaue = Pixels2MM(value)
    scale = 0.031;
    convertedVaue = value.* scale;


% --- converts MMs to Pixels, value can be scalar or matrix
function convertedVaue = MMs2Pixels(value)
    scale = 0.031;
    convertedVaue = value./ scale;


% --- writes grains data to file
function WriteDataToFile(hObject, dataTypes)
    h = guidata(hObject);

    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    splited = split(Create_file_name(fullPath, "data"), '.');
    fileName = splited(1) + ".txt";
    file = fopen(fileName, 'wt');

    fprintf(file, 'Choosen detection method: ');
    if h.binarizationFlag.Value
        fprintf(file, 'Binarization\n');
        fprintf(file, '\tMethod was called with parameters:\n');
        fprintf(file, '\t\tOpening radius: %g\n', Get(h.radiusVal));
        fprintf(file, '\t\tBinarization threshold: %g\n', Get(h.binThVal));
                        
    elseif h.cannyFlag.Value
        fprintf(file, 'Canny edge detection\n');
        fprintf(file, '\tMethod was called with parameters:\n');
        fprintf(file, '\t\tOpening radius: %g\n', Get(h.radiusVal));
        fprintf(file, '\t\tLow threshold: %g\n', Get(h.lowThVal));
        fprintf(file, '\t\tHigh threshold: %g\n', Get(h.highThVal));
        fprintf(file, '\t\tSigma: %g\n', Get(h.sigmaVal));

    else h.waterFlag.Value
        fprintf(file, 'Watershed\n');
        fprintf(file, '\tMethod was called with parameters:\n');
        fprintf(file, '\t\tOpening radius: %g\n', Get(h.radiusVal));
        sharpRadius = Get(h.sharpRadiusVal);
        if h.sharpenRadiusFlag.Value == false
            sharpRadius = 0;
        end

        fprintf(file, '\t\tSharpening radius: %g\n', sharpRadius);
        fprintf(file, '\t\tLow threshold: %g\n', Get(h.waterLowThVal));
        fprintf(file, '\t\tHigh threshold: %g\n', Get(h.waterHighThVal));
        fprintf(file, '\t\tSigma: %g\n', Get(h.waterSigmaVal));
        fprintf(file, '\t\tGaussian filtering sigma: %g\n', Get(h.gaussSigmaVal));
        fprintf(file, '\t\tGaussian filtering size: %g\n', Get(h.filterVal));
        fprintf(file, '\t\tBinarization threshold: %g\n', Get(h.binWaterThVal));
        
    end


    fprintf(file, '\nNumber of detected grains: %g\n\n', Get(h.detectedCountVal));

    fprintf(file, 'Filter values:\n');
    fprintf(file, '\tMin diameter: %g\n', Get(h.minDiameterVal));
    fprintf(file, '\tMax diameter: %g\n', Get(h.maxDiameterVal));
    fprintf(file, '\tMin circularity: %g\n\n', Get(h.circularityVal));

    fprintf(file, 'Number of correct grains: %g\n', h.Params.Number);
    fprintf(file, '\nIn pixels:\n');
    dataMatrix = [h.Params.Diameter; h.Params.ShortAxis; h.Params.LongAxis; h.Params.Circularity; h.Params.Ratio];
    for i = 1 : size(dataMatrix, 1)
        data = dataMatrix(i,:);
        fprintf(file, '%s:\n', dataTypes(i));
        fprintf(file, '\tMedian: %g\n', data(1));
        fprintf(file, '\tMean: %g\n', data(2));
        fprintf(file, '\tStandard devation: %g\n', data(3));     
        fprintf(file, '\n');
    end

    fprintf(file, '\nIn MMs:\n');
    dataMatrix = [Pixels2MM(h.Params.Diameter); Pixels2MM(h.Params.ShortAxis); Pixels2MM(h.Params.LongAxis); h.Params.Circularity; h.Params.Ratio];
    for i = 1 : size(dataMatrix, 1)
        data = dataMatrix(i,:);
        fprintf(file, '%s:\n', dataTypes(i));
        fprintf(file, '\tMedian: %g\n', data(1));
        fprintf(file, '\tMean: %g\n', data(2));
        fprintf(file, '\tStandard devation: %g\n', data(3));     
        fprintf(file, '\n');
    end

    fclose(file);


% --- writes grains data to file
function WriteGrainsToFile(hObject)
    h = guidata(hObject);

    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    splited = split(Create_file_name(fullPath, "grains"), '.');
    fileName = splited(1) + ".txt";
    file = fopen(fileName, 'wt');

    dataMatrix = zeros(h.Params.Number, 7);
    dataMatrix(:,1) = 1: 1: h.Params.Number;
    dataMatrix(:,2) = h.Params.DiametersList;
    dataMatrix(:,3) = h.Params.Perimeters;
    dataMatrix(:,4) = h.Params.Area;
    dataMatrix(:,5) = h.Params.ShortAxisList;
    dataMatrix(:,6) = h.Params.LongAxisList;
    dataMatrix(:,7) = h.Params.CircularityList;

    fprintf(file, 'Index\t  EquivDiameter\t  Perimeter\t\t  Area\t\t  MinorAxis\t\t  MajorAxis\t\t  Circularity\n'); 
    for i = 1 : size(dataMatrix, 1)
        data = dataMatrix(i,:);
        fprintf(file, '%g\t\t  ', data);     
        fprintf(file, '\n');
    end

    fclose(file);

% --- Executes on button press in metric2PixelToggle.
function ToMetrics_Callback(hObject)
    h = guidata(hObject);
    set(h.pixelsPanel, 'Visible', 'off');
    set(h.metricsPanel, 'Visible', 'on');
    set(h.toMetricsButton, 'BackgroundColor', [0.301960784313725	0.745098039215686	0.933333333333333]);
    set(h.toPixelsButton, 'BackgroundColor', [0.940000000000000	0.940000000000000	0.940000000000000]);

    guidata(hObject, h);

function ToPixels_Callback(hObject)
    h = guidata(hObject);
    set(h.pixelsPanel, 'Visible', 'on');
    set(h.metricsPanel, 'Visible', 'off');
    set(h.toPixelsButton, 'BackgroundColor', [0.301960784313725	0.745098039215686	0.933333333333333]);
    set(h.toMetricsButton, 'BackgroundColor', [0.940000000000000	0.940000000000000	0.940000000000000]);

    guidata(hObject, h);


function resultImg = DeleteObjectsBydiameter(image, minDiameter, maxDiameter)
    resultImg = bwpropfilt(imbinarize(image), 'EquivDiameter', [MMs2Pixels(minDiameter) MMs2Pixels(maxDiameter)]);


function resultImg = DeleteObjectsByCircularity(image, minCircularity)
    [B, L] = bwboundaries(image,'noholes');
    stats = regionprops(L,'Area');

    circularity = zeros(1, length(B));
    for k = 1:length(B)
        
        % obtain (X,Y) boundary coordinates corresponding to label 'k'
        boundary = B{k};
        
        % compute a simple estimate of the object's perimeter
        delta_sq = diff(boundary).^2;    
        perimeter = sum(sqrt(sum(delta_sq,2)));
        
        % obtain the area calculation corresponding to label 'k'
        area = stats(k).Area;
        
        % compute the roundness metric
        circularity(k) = 4*pi*area/perimeter^2;
    end

    for i = length(circularity):-1:1
        if circularity(i) < minCircularity
            B(i) = [];
            for x = 1:length(L)
                for y = 1:length(L)
                    if L(x ,y) == i
                        L(x,y) = 0;
                    end
                end
            end
        end
    end

    resultImg = L;


function resultImg = DeleteObjectByIndex(image, indexes)
    [~, L] = bwboundaries(image,'noholes');
    for x = 1:length(L)
        for y = 1:length(L)
            for i = 1:length(indexes)
                if L(x ,y) == indexes(i)
                    L(x,y) = 0;
                end
            end
        end
    end

    resultImg = L;


% --- Executes on button press in sharpenRadiusFlag.
function SharpenRadiusFlag_Callback(hObject)
    h = guidata(hObject);
    if h.sharpenRadiusFlag.Value == false
        set(h.sharpenRadiusFlag, 'value', false);
        set(h.sharpRadiusVal, 'enable', 'off');
    else
        set(h.sharpenRadiusFlag, 'value', true);
        set(h.sharpRadiusVal, 'enable', 'on');
    end

    guidata(hObject, h);


% --- Executes on button press in otsuFlag.
function OtsuWaterFlag_Callback(hObject, ~, h)
    flag = get(hObject, 'Value');
    if flag == true
        set(h.binWaterThVal, 'enable', 'off')
    else
        set(h.binWaterThVal, 'enable', 'on')
    end


% --- Executes on button press in statsButton.
function statsButton_Callback(~, ~, handles)
    set(handles.statsPanel, 'Visible', 'on');
    set(handles.grainsPanel, 'Visible', 'off');
    set(handles.statsButton, 'BackgroundColor', [0.301960784313725	0.745098039215686	0.933333333333333]);
    set(handles.grainsButton, 'BackgroundColor', [0.940000000000000	0.940000000000000	0.940000000000000]);



% --- Executes on button press in grainsButton.
function grainsButton_Callback(~, ~, handles)
    set(handles.statsPanel, 'Visible', 'off');
    set(handles.grainsPanel, 'Visible', 'on');
    set(handles.grainsButton, 'BackgroundColor', [0.301960784313725	0.745098039215686	0.933333333333333]);
    set(handles.statsButton, 'BackgroundColor', [0.940000000000000	0.940000000000000	0.940000000000000]);
   

% --- Executes during object creation, after setting all properties.
function grainDataTable_CreateFcn(hObject, eventdata, handles)
set(hObject, 'Data', cell(1));


% --- Executes on button press in deleteGrain.
function deleteGrain_Callback(hObject, ~, ~)
    h = guidata(hObject);
    
    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    h.WellDetectedGrains = [];
    h.ClearlyVisibleGrains = [];
    
    myImage = imread(fullPath);
    myImage = histeq(myImage);
    DisplayImage(myImage, h);
    
    h.resultImage = DeleteObjectByIndex(h.resultImage, h.SelectedGrain);

    h.SelectedGrain = [];
    DisplayContours(h.resultImage, h);

    guidata(hObject, h);

    CalculateParams(h.resultImage, hObject);
    h = guidata(hObject);

    DisplayData(hObject);

    guidata(hObject, h);


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, h)
    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    CreateDictionary(fullPath);

    imwrite(h.resultImage, Create_file_name(fullPath, "result_bin"));
    
    F = getframe(h.display);
    Image = frame2im(F);
    CreateDictionary(fullPath);
    imwrite(Image, Create_file_name(fullPath, "result_display"));

    F = getframe(h.granulometric);
    Image = frame2im(F);
    CreateDictionary(fullPath);
    imwrite(Image, Create_file_name(fullPath, "distribution"));


    WriteDataToFile(hObject, ["Diameter", "Short axis", "Long axis", "Circularity", "Aspect ratio"]);
    WriteGrainsToFile(hObject);


function ShowOrigin_Callback(hObject, eventdata, h)
    resultImageExist = isfield(h, 'resultImage') && length(ishandle(h.resultImage)) > 0;
    if h.showOriginFlag.Value == false && resultImageExist
        DisplayImage(h.resultImage, h);
    else
        fullPath = GetFullPath(h.selectedImage, h.imageStructs);
        myImage = imread(fullPath);
        myImage = histeq(myImage);
        DisplayImage(myImage, h);
    end

    if resultImageExist
        DisplayContours(h.resultImage, h);
    end


% --- Executes on mouse press over axes background.
function display_ButtonDownFcn(hObject, eventdata)
    h = guidata(hObject);

    set(h.display ,'Units','pixels');
    resizePos = get(h.display ,'Position');
    scale = 1024 / resizePos(3);

    p = get(h.display, 'currentpoint');
    p = p.*scale;

    resultImageExist = isfield(h, 'resultImage') && length(ishandle(h.resultImage)) > 0;
    if resultImageExist
        [B, ~] = bwboundaries(h.resultImage,'noholes');
        for i = 1 : length(B)
            if inpolygon(p(1, 1), p(1, 2), B{i}(:,2), B{i}(:,1))
                h.SelectedGrain(length(h.SelectedGrain) + 1) = i;

                DisplayContours(h.resultImage, h);
            
                diameter = Pixels2MM(h.Params.DiametersList(i));
                shortAxis = Pixels2MM(h.Params.ShortAxisList(i));
                longAxis = Pixels2MM(h.Params.LongAxisList(i));
                circularity = h.Params.CircularityList(i);
                ratio = h.Params.RatioList(i);
                data = [diameter, shortAxis, longAxis, circularity, ratio];
                set(h.grainDataTable, 'Data',  data);
                break;
            end
        end


    end

    guidata(hObject, h);


% --- Executes on button press in clearlyVisibleButton.
function clearlyVisibleButton_Callback(hObject, eventdata, handles)
    h = guidata(hObject);
    
    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    
    myImage = imread(fullPath);
    myImage = histeq(myImage);
    DisplayImage(myImage, h);
    

    h.ClearlyVisibleGrains = cat(2, h.ClearlyVisibleGrains, h.SelectedGrain);

    h.SelectedGrain = [];
    DisplayContours(h.resultImage, h);

    DE = (h.Params.Number/ length(h.ClearlyVisibleGrains)) * 100;
    set(h.deValue, 'string', DE);

    guidata(hObject, h);

    CalculateParams(h.resultImage, hObject);
    h = guidata(hObject);

    DisplayData(hObject);

    guidata(hObject, h);

% --- Executes on button press in wellDetectedButton.
function wellDetectedButton_Callback(hObject, eventdata, handles)
    h = guidata(hObject);
    
    fullPath = GetFullPath(h.selectedImage, h.imageStructs);
    
    myImage = imread(fullPath);
    myImage = histeq(myImage);
    DisplayImage(myImage, h);
    

    h.WellDetectedGrains = cat(2, h.WellDetectedGrains, h.SelectedGrain);

    h.SelectedGrain = [];
    DisplayContours(h.resultImage, h);

    DA = (length(h.WellDetectedGrains) / h.Params.Number) * 100;
    set(h.daValue, 'string', DA);

    guidata(hObject, h);

    CalculateParams(h.resultImage, hObject);
    h = guidata(hObject);

    DisplayData(hObject);

    guidata(hObject, h);