function y = rectFilter(yData, nSamples)
%this function applies rectangular filtering or pulse shaping to the
%input symbol data. It also sets a sample count for a given symbol
%yData --> input symbol data
%nSamples --> number of samples per pulse

%apply rect filter to symbol data
y = rectpulse(yData,nSamples);
%plot(real(y(1:(nSamples*5))));

