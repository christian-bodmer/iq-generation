function y = rootRaisedCosineFilter(yData, nSamples, fOrder, rOff,plot)
%this function applies root raised cosine filtering or pulse shaping to the
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

%create filter definition
filtDef = fdesign.pulseshaping(nSamples, 'Square Root Raised Cosine','Nsym,Beta', fOrder, rOff);
rrcFilter = design(filtDef);
rrcFilter.Numerator = rrcFilter.Numerator * sqrt(nSamples);

% Plot impulse response.
if plot == 1.0
    fvtool(rrcFilter, 'impulse')
end

% Upsample and apply raised cosine filter.
yUp = upsample(yData, nSamples);
y = filter(rrcFilter, yUp);