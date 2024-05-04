function y = gaussianFilter(yData, nSamples, nSym, bWidth,plot)
%this function applies Gaussian filtering or pulse shaping to the
%input symbol data. It also sets a sample count for a given symbol
%yData --> input symbol data
%nSamples --> number of samples per pulse
%nSym --> filter order in symbols
%bWidth --> the 3–dB bandwidth-symbol time product. BT is a positive real-valued scalar, which defaults to 0.3. Larger values of BT produce a narrower pulse width in time with poorer concentration of energy in the frequency domain.
%plot is used as a bool to show plot or not

if mod((nSamples*nSym),2) ~= 0
  %number is not even so make it even
   nSamples = 4;
   nSym = 6;
end
 %make use bWidth is positive
if bWidth < 0
    bWidth = 0.3;
end

%create filter definition
filtDef = fdesign.pulseshaping(nSamples, 'Gaussian', 'Nsym,BT', nSym, bWidth);
gaussFilter = design(filtDef);
gaussFilter.Numerator = gaussFilter.Numerator * sqrt(nSamples);

% Plot impulse response.
if plot == 1.0
    fvtool(gaussFilter, 'impulse')
end

% Upsample and apply raised cosine filter.
yUp = upsample(yData, nSamples);
y = filter(gaussFilter, yUp);