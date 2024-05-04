function y = randomBinaryError(yData, prob)
%This function adds random binary error to a baseband QAM signal
%yData --> input symbol data
%prob --> error probability

 H = comm.BinarySymmetricChannel('ErrorProbability',prob);
 y = step(H, yData);
    