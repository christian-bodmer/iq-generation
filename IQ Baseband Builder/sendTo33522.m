function sendTo33522(I,Q,IP)
%This function connects to a 33522 and uploads an I and Q baseband signal
%opens and creates a visa session for communication with function generator

vAddress = ['TCPIP0::' IP '::inst0::INSTR']; %build visa address string to connect
fgen = visa('AGILENT',vAddress); %build IO object
fgen.Timeout = 15; %set IO time out
%calculate output buffer size
buffer = length(I)*8;
set (fgen,'OutputBufferSize',(buffer+125));

%open connection to 33522
try
   fopen(fgen);
catch exception %problem occurred throw error message
    uiwait(msgbox('Error occurred trying to connect to the 33522, verify correct IP address','Error Message','error'));
    rethrow(exception);
end

%Query Idendity string and report
fprintf (fgen, '*IDN?');
idn = fscanf (fgen);
fprintf (idn)
fprintf ('\n\n')

mes = ['Connected to ' idn ' sending waveforms.....'];
h = waitbar(0,mes);

%Reset instrument
fprintf (fgen, '*RST');

%turn it to column vector
I = single(I');
Q = single(Q');


%Clear volatile memory
fprintf(fgen, 'SOURce1:DATA:VOLatile:CLEar');
fprintf(fgen, 'SOURce2:DATA:VOLatile:CLEar');
fprintf(fgen, 'FORM:BORD SWAP');  %configure the box to correctly accept the binary arb points
%update waitbar
waitbar(.1,h,mes);
%send I data to 33522 and setup channel 1
iBytes=num2str(length(I) * 4); %# of bytes
header= ['SOURce1:DATA:ARBitrary IDATA, #' num2str(length(iBytes)) iBytes]; %create header
%header= ['SOURce1:DATA:ARBitrary IDATA, #' num2str(length(iBytes)) iBytes]; %create header
binblockBytes = typecast(I, 'uint8');  %convert datapoints to binary before sending
fwrite(fgen, [header binblockBytes], 'uint8'); %combine header and datapoints then send to instrument
fprintf(fgen, '*WAI');   %Make sure no other commands are exectued until arb is done downloadin
%Set desired configuration for channel 1
%update waitbar
waitbar(.4,h,mes);
fprintf(fgen,'SOURce1:FUNCtion:ARBitrary IDATA'); % set current arb waveform to defined arb testrise
fprintf(fgen,'MMEM:STOR:DATA1 "INT:\IDATA.arb"');%store arb in intermal NV memory
fprintf(fgen,'SOURCE1:VOLT 1.0'); % set max waveform amplitude to 2 Vpp
fprintf(fgen,'SOURCE1:VOLT:OFFSET 0'); % set offset to 0 V
fprintf(fgen,'OUTPUT1:LOAD 50'); % set output load to 50 ohms
fprintf(fgen,'SOURCE1:FUNCtion:ARB:SRATe 1e6'); % set sample rate
fprintf(fgen,'SOURce1:FUNCtion ARB'); % turn on arb function
%Enable Output for channel 1
fprintf(fgen,'OUTPUT1 ON');
fprintf('"I" signal downloaded to channel 1\n\n')
%update waitbar
waitbar(.55,h,mes);
%send Q data to 33522 and setup channel 2
qBytes=num2str(length(Q) * 4); %# of bytes
header= ['SOURce2:DATA:ARBitrary QDATA, #' num2str(length(qBytes)) qBytes]; %create header
binblockBytes = typecast(Q, 'uint8');  %convert datapoints to binary before sending
fwrite(fgen, [header binblockBytes], 'uint8'); %combine header and datapoints then send to instrument
fprintf(fgen, '*WAI');   %Make sure no other commands are exectued until arb is done downloading
%update waitbar
waitbar(.85,h,mes);
%Set desired configuration for channel 2
fprintf(fgen,'SOURce2:FUNCtion:ARBitrary QDATA'); % set current arb waveform to defined arb testrise
fprintf(fgen,'MMEM:STOR:DATA2 "INT:\QDATA.arb"'); %store arb in non V memory
fprintf(fgen,'SOURCE2:VOLT:OFFSET 0'); % set offset to 0 V
fprintf(fgen,'OUTPUT2:LOAD 50'); % set output load to 50 ohms
fprintf(fgen,'SOURCE2:FUNCtion:ARB:SRATe 1e6'); % set sample rate
fprintf(fgen,'SOURce2:FUNCtion ARB'); % turn on arb function
%Enable Output for channel 2
fprintf(fgen,'OUTPUT2 ON');
fprintf('"Q" signal downloaded to channel 2\n\n')

%set the amplitude for each channel
fprintf(fgen,'SOUR:VOLT 1'); % set max waveform amplitude to 2 Vpp
fprintf(fgen,'SOURCE2:VOLT 1'); % set max waveform amplitude to 2 Vpp
%Phase sync both channels
fprintf(fgen,'PHAS:SYNC');

%get rid of message box
waitbar(1,h,mes);
delete(h);

%Read Error
fprintf(fgen, 'SYST:ERR?');
errorstr = fscanf (fgen);

% error checking
if strncmp (errorstr, '+0,"No error"',13)
   errorcheck = 'Arbitrary waveform generated without any error\n';
   fprintf (errorcheck)
else
   errorcheck = ['Error reported: ', errorstr];
   fprintf (errorcheck)
end

fclose(fgen);