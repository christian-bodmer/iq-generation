function varargout = IQ_Baseband_Builder(varargin)
% IQ_BASEBAND_BUILDER MATLAB code for IQ_Baseband_Builder.fig
%      IQ_BASEBAND_BUILDER, by itself, creates a new IQ_BASEBAND_BUILDER or raises the existing
%      singleton*.

% Last Modified by GUIDE v2.5 25-Sep-2012 15:18:51
% Last modified by cbo 2024-05-04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @IQ_Baseband_Builder_OpeningFcn, ...
    'gui_OutputFcn',  @IQ_Baseband_Builder_OutputFcn, ...
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


% --- Executes just before IQ_Baseband_Builder is made visible.
function IQ_Baseband_Builder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to IQ_Baseband_Builder (see VARARGIN)

% Choose default command line output for IQ_Baseband_Builder
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%set up plotting titles, labels, etc
title(handles.fftPlot,'FFT of I and Q Signal'); %add title to plot
xlabel(handles.fftPlot,'Frequency'); %x axis label
ylabel(handles.fftPlot,'Power'); %y axis label
title(handles.filterPlot,'Time Domain Plot of I or Q'); %add title to plot
xlabel(handles.filterPlot,'Samples'); %x axis label
ylabel(handles.filterPlot,'Amplitude'); %y axis label
ylabel(handles.constPlot, 'Quadrature')
xlabel(handles.constPlot, 'In-Phase')
title(handles.constPlot, 'Scatter plot')
title(handles.eyePlot, 'Eye Diagram for I or Q Signal');
xlabel(handles.eyePlot, 'Time (Symbols)'); ylabel(handles.eyePlot, 'Amplitude');
%global variable for storing digital data for reuse (send to CSV or 33522B
global dData;
dData = [];

%The following statements set up all the default states of the UI controls
set(handles.bitCountBox,'string',num2str(10e3));
set(handles.samplesSymBox,'string',num2str(8));
set(handles.filterBetaAdjust,'value',0.5); %set beta slider to default value
set(handles.betaValueText,'string', get(handles.filterBetaAdjust,'value')); %set slider value text
set(handles.orderAdjustSlider,'value',1);%set filter order to default value
set(handles.orderValueText,'string', get(handles.orderAdjustSlider,'value')); %set slider value text
set(handles.addNoiseSlider,'value',101);%set add noise value to max
set(handles.noiseValueText,'string', 'Max'); %set slider value text
set(handles.phaseBalSlider,'value',0.0); %set phase balance default to 0
set(handles.phaseBalValueText,'string', get(handles.phaseBalSlider,'value')); %set slider value text
set(handles.ampBalSlider,'value',0.0); %set phase balance default to 0
set(handles.ampBalValueText,'string', get(handles.ampBalSlider,'value')); %set slider value text
set(handles.iOffsetAmpSlider,'value',0.0);%set slider initial condition
set(handles.iOffsetAmpValueText,'string', get(handles.iOffsetAmpSlider,'value')); %set slider value text
set(handles.qOffsetAmpSlider,'value',0.0);%set slider initial condition
set(handles.qOffsetAmpValueText,'string', get(handles.qOffsetAmpSlider,'value')); %set slider value text
set(handles.symOrderToggle,'value',0)%set mod type to binary for default

% --- Outputs from this function are returned to the command line.
function varargout = IQ_Baseband_Builder_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;


%This function is for the main button that builds the IQ baseband signal
function buildButton_Callback(hObject, eventdata, handles)

global dData; %global variable for storing digital data
M = getSymCount(get(handles.modTypeList,'Value')); %number of symbols
k = log2(M);    %number of bits per symbol

% Create a binary data stream as a column vector.
if isempty(dData)==1 || get(handles.dDataCheckBox,'Value')==0 %if binary data has not been generated then make it
    n = setBitCount(k,str2double(get(handles.bitCountBox,'String'))); %set number of bits based on user entry and # of symbols
    dData = randi([0 1],n,1); % Random binary data stream
else
    n = setBitCount(k,length(dData));
end

%based on above calculations set bit count in UI box
set(handles.bitCountBox,'string',num2str(n));% Number of bits to process
%get samples per symbol from UI edit box
nsamp = str2double(get(handles.samplesSymBox,'string'));   % samples per symbols
% Convert the bits in x into k-bit symbols.
%%% 240504 cbo
%%% old code
%%% hBitToInt = comm.BitToInteger(k);
%%% xsym = step(hBitToInt,dData(1:n));
%%% beginning of new code:
% Assume n is defined and is a multiple of k
% Reshape dData to have k rows and compute number of columns as n/k
reshapedData = reshape(dData(1:n), k, []);
% Convert each column of reshaped data to an integer
% Apply bit2int across each column
xsym = arrayfun(@(col) bit2int(reshapedData(:, col), k), 1:size(reshapedData, 2));
%%% end of new code
%modulate the random number into symbols
y = modulate(getModType(get(handles.modTypeList,'Value'),handles),xsym);
%add phase, amplitude imbalance, or DC offset from UI sliders
y = phaseImbalance(get(handles.phaseBalSlider,'value'), y); %0 to 360 degrees
y = ampImbalance(get(handles.ampBalSlider,'value'), y);%in dB 50 to -50
y = dcOffset(get(handles.iOffsetAmpSlider,'value'), get(handles.qOffsetAmpSlider,'value'), y);%5 to -5
%Get filter setting from UI list and send data through filter
ytx = getFilter(y,handles,get(handles.filterTypeList,'Value'));%returns a filtered IQ data

%function to add noise, get noise value from slider, if 101 set to 500
nDB = get(handles.addNoiseSlider,'value');
if nDB ~= 101
    yN = addWGNoise(ytx, nDB, nsamp, M);
else
    yN = addWGNoise(ytx, 500, nsamp, M);
end

% Create eye diagram for part of filtered signal.
if length(yN) < 100e3 %if less than 50e3 points plot all
    customEyeDiag(handles.eyePlot, yN, get(handles.eyePlotToggle,'Value'),nsamp*2,2)   %custom function for doing eye diagram
else
    customEyeDiag(handles.eyePlot, yN(1:100e3),get(handles.eyePlotToggle,'Value'), nsamp*2,2)   %custom function for doing eye diagram
end

%create FFT of I and Q signal and plot it
[xF yF] = performFFT(yN,1e8);
plot(handles.fftPlot,xF,yF);
title(handles.fftPlot,'FFT of I and Q Signal'); %add title to plot
xlabel(handles.fftPlot,'Frequency'); %x axis label
ylabel(handles.fftPlot,'Power'); %y axis label
%build scatterplot to show constellation diagram
yData = yN;
dsampData = yData(1 : nsamp : size(yData, 1));
plot(handles.constPlot, real(dsampData), imag(dsampData), 'g.');
ylabel(handles.constPlot, 'Quadrature')
xlabel(handles.constPlot, 'In-Phase')
title(handles.constPlot, 'Scatter plot')

%converter data into I (real) and Q (imag) parts
Q = scaleData(imag(ytx),1);
I = scaleData(real(ytx),1);

%plot part of I or Q signal in the time domain
if get(handles.timeDomainPlotToggle,'Value') == 0
    if length(I) > (nsamp*20)
        plot(handles.filterPlot,I(1:(nsamp*20)));
    else
        plot(handles.filterPlot,I);
    end
else
    if length(Q) > (nsamp*20)
        plot(handles.filterPlot,Q(1:(nsamp*20)));
    else
        plot(handles.filterPlot,Q);
    end
end
title(handles.filterPlot,'Time Domain Plot of I or Q'); %add title to plot
xlabel(handles.filterPlot,'Samples'); %x axis label
ylabel(handles.filterPlot,'Amplitude'); %y axis label
global Z;
Z = [I Q];
%*****************end of build button function***********************

%slider control for adjusting beta of raised cosine filter
function filterBetaAdjust_Callback(hObject, eventdata, handles)
d = get(hObject,'value')*100; %this is done to ensure value to two decimals places
d = d + .1; %had to add this hack bc floor is not working right at .57
d = floor(d); %use floor to get rid of decimal places
d = d/100; %convert to orginal value with 2 decimal precision
set(hObject,'value',d);
set(handles.betaValueText,'string', d);
%************end of function **********************************


% --- Executes during object creation, after setting all properties.
function filterBetaAdjust_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
%*******************end of function ********************************

% --- Executes on selection change in modTypeList.
function modTypeList_Callback(hObject, eventdata, handles)
% hObject    handle to modTypeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns modTypeList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modTypeList


% --- Executes during object creation, after setting all properties.
function modTypeList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modTypeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%sets slider for setting raised cosine or gaussian filter
function filterTypeList_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 3
    set(handles.betaAdjustText,'String','3–dB Bandwidth-Symbol Time Product');
else
    set(handles.betaAdjustText,'String','Beta Roll Off');
end
%********************************** end of function *******************


% --- Executes during object creation, after setting all properties.
function filterTypeList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filterTypeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%slider for adjusting filter order
function orderAdjustSlider_Callback(hObject, eventdata, handles)
%the following code sets integer resolution
d = get(hObject,'value');
d = floor(d);
set(hObject,'value',d);
set(handles.orderValueText,'string', get(hObject,'value')); %set slider value text
%****************************** end of function ***************

% --- Executes during object creation, after setting all properties.
function orderAdjustSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orderAdjustSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function samplesSymBox_Callback(hObject, eventdata, handles)
% hObject    handle to samplesSymBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of samplesSymBox as text
%        str2double(get(hObject,'String')) returns contents of samplesSymBox as a double


% --- Executes during object creation, after setting all properties.
function samplesSymBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samplesSymBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bitCountBox_Callback(hObject, eventdata, handles)
% hObject    handle to bitCountBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bitCountBox as text
%        str2double(get(hObject,'String')) returns contents of bitCountBox as a double


% --- Executes during object creation, after setting all properties.
function bitCountBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bitCountBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function addNoiseSlider_Callback(hObject, eventdata, handles)
% hObject    handle to addNoiseSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject,'value')*10;
val = floor(val)/10;
set(hObject,'value',val);
if val ~= 101
    set(handles.noiseValueText,'string', val); %set slider value text
else
    set(handles.noiseValueText,'string', 'Max');
end

% --- Executes during object creation, after setting all properties.
function addNoiseSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to addNoiseSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


%slider for setting phase balence
function phaseBalSlider_Callback(hObject, eventdata, handles)
%the following code sets resolution to one decimal place
ph = get(hObject,'value')*10;
ph = floor(ph)/10;
set(hObject,'value',ph);
set(handles.phaseBalValueText,'string', ph); %set slider value text
%*************************** end of function ***********************

% --- Executes during object creation, after setting all properties.
function phaseBalSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseBalSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


%amplitude balence slider
function ampBalSlider_Callback(hObject, eventdata, handles)
%the following code sets one decimal resolution
aB = get(hObject,'value')*10;
aB = aB + .1; %this is added bc floor is not working right
aB = floor(aB)/10;
set(hObject,'value',aB);
set(handles.ampBalValueText,'string', aB); %set slider value text
%************************ end of function *****************

% --- Executes during object creation, after setting all properties.
function ampBalSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampBalSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%slider for setting the I signal amplitude offset
function iOffsetAmpSlider_Callback(hObject, eventdata, handles)
%the following code sets control to 2 deciamls of resolution
iOff = get(hObject,'value')*100;
iOff = iOff + .1; %this is to correct for floor
iOff = floor(iOff)/100;
set(hObject,'value',iOff);
set(handles.iOffsetAmpValueText,'string', iOff); %set slider value text
%***************************** end of function ***********************

% --- Executes during object creation, after setting all properties.
function iOffsetAmpSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iOffsetAmpSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%slider for setting the I signal amplitude offset
function qOffsetAmpSlider_Callback(hObject, eventdata, handles)
%the following code sets control to 2 deciamls of resolution
qOff = get(hObject,'value')*100;
qOff = qOff + .1; %this was added to corrent for floor bug
qOff = floor(qOff)/100;
set(hObject,'value',qOff);
set(handles.qOffsetAmpValueText,'string', qOff); %set slider value text
%***************************** end of function ***********************

% --- Executes during object creation, after setting all properties.
function qOffsetAmpSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to qOffsetAmpSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


%button toggles between plotting I or Q time domain data
function timeDomainPlotToggle_Callback(hObject, eventdata, handles)

if get(hObject,'Value')==0
    set(hObject,'String','I Baseband Plot');
else
    set(hObject,'String','Q Baseband Plot');
end
%*******************************end of function ***********************

%button toggles between plotting I or Q eye diagram
function eyePlotToggle_Callback(hObject, eventdata, handles)

if get(hObject,'Value')==0
    set(hObject,'String','I Eye Diagram');
else
    set(hObject,'String','Q Eye Diagram');
end
%******************** end of function ********************************

%Used to determine which modulation type was selected from modTypeList
function mType = getModType(item,handles)%modem.qammod(M)

if get(handles.symOrderToggle,'Value')== 1 %check to set symbol mapping
    map = 'Binary';
else
    map = 'Gray';
end

if item == 1
    mType = modem.qammod('M',4,'SymbolOrder',map); %4 QAM
elseif item == 2
    mType = modem.qammod('M',8,'SymbolOrder',map); %8 QAM
elseif item == 3
    mType = modem.qammod('M',16,'SymbolOrder',map); %16 QAM
elseif item == 4
    mType = modem.qammod('M',32,'SymbolOrder',map); %32 QAM
elseif item == 5
    mType = modem.qammod('M',64,'SymbolOrder',map); %64 QAM
elseif item == 6
    mType = modem.qammod('M',128,'SymbolOrder',map); %128 QAM
else
    mType = modem.qammod('M',256,'SymbolOrder',map); %256 QAM
end
%********************************** end of function *****************

%Used to determine current symbol count
function sCount = getSymCount(item)%modem.qammod(M)

if item == 1
    sCount = 4; %4 QAM
elseif item == 2
    sCount = 8; %8 QAM
elseif item == 3
    sCount = 16; %16 QAM
elseif item == 4
    sCount = 32; %32 QAM
elseif item == 5
    sCount = 64; %64 QAM
elseif item == 6
    sCount = 128; %128 QAM
else
    sCount = 256; %256 QAM
end
%************************* end of function *************************

function fY = getFilter(y,handles,item)%returns a filtered IQ data

if item == 1 %raised cosine filter
    fY = raisedCosineFilter(y, str2double(get(handles.samplesSymBox,'string')), get(handles.orderAdjustSlider,'value'), get(handles.filterBetaAdjust,'value'),get(handles.pulseResponseBox,'value'));
elseif item == 2 %root raised cosine filter
    fY = rootRaisedCosineFilter(y, str2double(get(handles.samplesSymBox,'string')), get(handles.orderAdjustSlider,'value'), get(handles.filterBetaAdjust,'value'),get(handles.pulseResponseBox,'value'));
elseif item == 3
    fY = gaussianFilter(y,str2double(get(handles.samplesSymBox,'string')), get(handles.orderAdjustSlider,'value'), get(handles.filterBetaAdjust,'value'),get(handles.pulseResponseBox,'value'));
else
    fY = rectFilter(y,str2double(get(handles.samplesSymBox,'string')));
end
%************************************** end of function ***********

%function sets bit count bits must equal mod(bits,k) = 0
function bits = setBitCount(k,bCount)

r = mod(bCount,k); %see if k into bcount has no remainder
if r == 0 %ok user enter amount is ok
    bits = bCount;
else %adjust bit count
    bits = bCount - r;
end
%************************** end of function *****************


%toggle button to select binary or gray mapping for const
function symOrderToggle_Callback(hObject, eventdata, handles)

if get(hObject,'Value')==0
    set(hObject,'String','Binary');
else
    set(hObject,'String','Gray');
end
%***************************** end of function ***********

function exportBox_Callback(hObject, eventdata, handles)
% hObject    handle to exportBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function exportBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exportBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%checkbox function for exporting IQ signals to 33522 or CSV
function exportCheckBox_Callback(hObject, eventdata, handles)

if get(hObject,'Value') == 1
    set(handles.exportButton,'String','Export IQ Signals to 33522');
    set(handles.exportBox,'String','Enter IP Address');
else
    set(handles.exportButton,'String','Export IQ Signals to CSV file');
    set(handles.exportBox,'String','Enter CSV file Name');
end
%*******************end of function*************************

%button for exporting IQ signals to CSV or 33522
function exportButton_Callback(hObject, eventdata, handles)

global Z;

if ~isempty(Z)
    if get(handles.exportCheckBox,'Value')==1
        %send data to 33522A
        sendTo33522(Z(:,1),Z(:,2),get(handles.exportBox,'String'));
    else %send data to CSV file
        csvName = [get(handles.exportBox,'String') '.csv'];
        try %exception if CSV write fails
            csvwrite(csvName,Z,0,0);
        catch exception
            uiwait(msgbox(exception.message,'Error Message','error'));
            rethrow(exception);
        end
    end
else
    uiwait(msgbox('No signal data','Error Message','error'));
end
%**************** end of function ************************************

%button for importing digital data from CSV file
function importButton_Callback(hObject, eventdata, handles)
%global variable for storing imported digital data
global dData;
try %try reading data from CSV file
    dData = csvread(get(handles.importBox,'String'));
catch exception %if it fails catch and send error message
    uiwait(msgbox(exception.message,'Error Message','error'));
    rethrow(exception);
end
%**************** end of function ************************************

function importBox_Callback(hObject, eventdata, handles)
% hObject    handle to importBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function importBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to importBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in dDataCheckBox.
function dDataCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to dDataCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pulseResponseBox.
function pulseResponseBox_Callback(hObject, eventdata, handles)
% hObject    handle to pulseResponseBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
