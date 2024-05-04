function y = addWGNoise(yData, EbNo, nsamp,M)
%This function adds noise to a baseband QAM signal
%yData --> input symbol data
%EbNo --> Energy per bit to noise power spectral density ratio (Eb/No)in dB
%nsamp --> number of samples per data unit or pulse
%M --> symbol count or M-ary levels

k = log2(M);    %number of bits per symbol
snr = EbNo + 10*log10(k) - 10*log10(nsamp);%calculate SNR 
hChan = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)','SNR',snr);
hChan.SignalPower = (yData' * yData)/ length(yData);
y = step(hChan,yData);