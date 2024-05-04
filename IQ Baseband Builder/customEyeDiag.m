function customEyeDiag(axesHndle, data,iorQ, nSamp,nSym)
% Customized function to produce Eye Diagram data that can then be used to
% generate a plot.

% INPUTS:
% axesHandle: Handle to the axes object on which the eye diagram will be
%             plotted on.
% data      : signal
% nSamp     : number samples used to represent each symbol
%
% Test & Measurement
% Copyright 2012 The MathWorks, Inc.

% Determine the maximum and minimum amplitude values
maxAmp = ceil(max(max(real(data)), max(imag(data))));
minAmp = floor(min(min(real(data)), min(imag(data))));


% Calculate available number of traces
sampsPerTrace = nSym*nSamp;
% Total number of traces available
numTraces = floor(length(data) / sampsPerTrace);

% Calculate the delay value to place the first sample at the center of the
% eye diagram
delay = round(sampsPerTrace/2)+1;

% Create a commscope eye diagram object with the required parameters
eyeObj = commscope.eyediagram( ...
    'MinimumAmplitude', minAmp, ...
    'MaximumAmplitude', maxAmp, ...
    'SamplingFrequency', 1, ...
    'SamplesPerSymbol', nSamp, ...
    'SymbolsPerTrace', nSym, ...
    'MeasurementDelay', delay, ...
    'PlotType', '2D Line', ...
    'NumberOfStoredTraces', numTraces, ...
    'RefreshPlot', 'off');

reset(eyeObj);

% Update the eye diagram data
eyeObj.update(data);

% Export the eye diagram data
[~, eyel] = exportdata(eyeObj);

% Calculate time axis in term of symbols
t = 0:1/nSamp:sampsPerTrace/nSamp;

%choose I or Q data to plot
if iorQ == 0
    sig = real(eyel);
else
    sig = imag(eyel);
end
% Plot the eye diagram on the specified axes
plot(axesHndle, t, sig, 'black', 'LineWidth', 1);
title(axesHndle, 'Eye Diagram for I or Q Signal');
xlabel(axesHndle, 'Time (Symbols)'); ylabel(axesHndle, 'Amplitude'); grid on;