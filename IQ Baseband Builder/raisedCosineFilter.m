function y = raisedCosineFilter(yData, nSamples, fOrder, rOff,plot)
%this function applies raised cosine filtering or pulse shaping to the
%input symbol data. It also sets a sample count for a given symbol
%yData --> input symbol data
%nSamples --> number of samples per pulse
%fOrder --> filter order, must be an even number
%fOff --> roll off factor, must be between 0 and 1
%plot is used as a bool to show plot or not

%make sure roll off is within 0 to 1 if not set to .25 
if rOff > 1 || rOff < 0
    rOff = 0.25;
end

%if symbols * filter order is not even make it even
if mod((fOrder*nSamples),2)~=0
    fOrder = fOrder + 1;
    uiwait(msgbox('Samples per symbol x filter order must be even, filter order was increased by 1','Warning','warn'));
end

%create filter definition
filtDef = fdesign.pulseshaping(nSamples, 'Raised Cosine','Nsym,Beta', fOrder, rOff);
rcFilter = design(filtDef);
rcFilter.Numerator = rcFilter.Numerator * sqrt(nSamples);

% Plot impulse response.
if plot == 1.0
    fvtool(rcFilter, 'impulse')
end

% Upsample and apply raised cosine filter.
yUp = upsample(yData, nSamples);
y = filter(rcFilter, yUp);