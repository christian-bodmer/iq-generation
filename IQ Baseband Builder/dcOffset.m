function y = dcOffset(Idc, Qdc, x)
%this function adds a DC amplitude offset to either I or Q data signal
%Idc in-phase DC offset variable in volts
%Qdc quadrature DC offset variable in volts
%x is complex array of the symbol data xr+xi 

xi = imag(x);
xr = real(x);
y = (xr + Idc) + 1i*(xi + Qdc);