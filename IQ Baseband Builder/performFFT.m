function  [x y] = performFFT(readings,sRate)
%This function performs an FFT using the input arguments measurement
%readings and sample rate. It returns two arrays for the x and y axis of an
%FFT plot. It only returns the real numbers of the FFT in dBv. Only one
%half of the FFT is returned. The mirror image is not returned
m = length(readings);          % Window length
n = pow2(nextpow2(m));  % calculate fft length
y = fft(readings,n);           % perform fft on readings
x = (0:((n-1)/2))*(sRate/n);     % Frequency range, divide by 2 to show half result

y = db(abs(y)); %get rid of imaginary components and just get amplitude and convert to dBv
y = y(1:(n/2)); %just get half of the readings, don't want mirror image readings
