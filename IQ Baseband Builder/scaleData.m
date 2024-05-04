function y = scaleData(data,sFactor)
%this function allows you to scale data
%data--> is the data that needs to be scaled
%sFactor --> the max number to scale data to

mx = max(abs(data));
y = (sFactor*data)/mx;