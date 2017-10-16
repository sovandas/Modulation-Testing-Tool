function numSamples = sendToAWG(data, sampleRate, inputChannel, Vpp, offset, AWGObj, segmNum)
global systemParameters;

Agilent81180A = 0;
Agilent81180B = 0;
Agilent33522A = 0;
Agilent33622A = 0;

if systemParameters.AWGType ~= 3,
    AWGModel = regexp(query(AWGObj,'*IDN?'),',','split');
    AWGModel = AWGModel{2};
    Agilent81180A = isequal(AWGModel,'81180A');
    Agilent81180B = isequal(AWGModel,'81180B');
    Agilent33522A = isequal(AWGModel,'33522A');
    Agilent33622A = isequal(AWGModel,'33622A');
end

numSamples = length(data);

if Agilent81180A || Agilent81180B,
    data = data(1:floor(length(data)/32)*32); %Cut down the data sequence to a length which is multiple of 32. Minimum length is 320. AWG crashes if the data is not a multiple of 32. 
    data = data/max(abs(data)); %Fit the data sequence within the interval [-1;1];

    % number of samples must be >= 320 and a multiple of 32. The generator crashes if this condition is not met

    % move to the DAC range of 0...4095, convert to ushort and swap bytes
    dataAsUint = swapbytes(uint16(round(data * 2047 + 2048)));
    % select output
    fprintf(AWGObj,[':INST:SEL CH' num2str(inputChannel)]);
    % set arbitrary mode
    fprintf(AWGObj, ':FUNC:MODE USER');
    % select Vpp
    fprintf(AWGObj,[':VOLT ' num2str(Vpp)]);
    % select Offset
    fprintf(AWGObj,[':VOLTage:OFFSet ' num2str(offset)]);
    % set sampling frequency
    fprintf(AWGObj, sprintf(':FREQ:RAST %d', sampleRate));
    % select and define segment number
    fprintf(AWGObj, sprintf(':TRAC:DEF %d,%d', segmNum, numSamples));
    fprintf(AWGObj, sprintf(':TRAC:SEL %d', segmNum));
    binblockwrite(AWGObj, dataAsUint, 'uint16', ':TRAC:DATA ');
    fprintf(AWGObj, '');  % complete the binblock command
    % Set Synch Channel
    fprintf(AWGObj, [':OUTPut:SYNC:SOURce CH' num2str(inputChannel)]);
    % Turn Synch ON
    fprintf(AWGObj, ':OUTPut:SYNC ON');
    % turn the output on
    fprintf(AWGObj, ':OUTP ON');
    operationComplete = str2double(query(AWGObj,'*OPC?'));
    while ~operationComplete
        operationComplete = str2double(query(AWGObj,'*OPC?'));
    end
elseif Agilent33522A || Agilent33622A,
    amp = Vpp;
    channel = inputChannel;
    filter = 'OFF';
    name = ['testData' int2str(channel)];
    sRate = sampleRate;
        
    %create waitbar for sending waveform to 33500
    mes = ['Connected to ' AWGModel ' sending waveforms.....'];
    h = waitbar(0,mes);
    fprintf(AWGObj,['OUTPUT' int2str(channel) ' OFF']); %Disable Output
    %make sure waveform data is in column vector
    if isrow(data) == 0
        data = data';
    end   
    %set the waveform data to single precision
    data = single(data);  
    %scale data between 1 and -1
    mx = max(abs(data));
    data = (1*data)/mx;
    
    %update waitbar
    waitbar(.1,h,mes);
    
    %send waveform to 33500/33600
    fprintf(AWGObj, ['SOURce' int2str(channel) ':DATA:VOLatile:CLEar']); %Clear volatile memory
    fprintf(AWGObj, 'FORM:BORD SWAP');  %configure the box to correctly accept the binary data points
    arbBytes=num2str(length(data) * 4); %# of bytes
    header= ['SOURce' int2str(channel) ':DATA:ARBitrary ' name ', #' num2str(length(arbBytes)) arbBytes]; %create header
    binblockBytes = typecast(data, 'uint8');  %convert datapoints to binary before sending
    fwrite(AWGObj, [header binblockBytes], 'uint8'); %combine header and datapoints then send to instrument
    fprintf(AWGObj, '*WAI');   %Make sure no other commands are exectued until data is done downloading
    pause(10);
    %update waitbar
    waitbar(.8,h,mes);
    %Set desired configuration for channel 1
    command = ['SOURce' int2str(channel) ':FUNCtion:ARBitrary ' name]; 
    fprintf(AWGObj,command);
    % set current data waveform to defined data
    command = ['MMEM:STOR:DATA1 "INT:\' name '.arb"'];
    fprintf(AWGObj,command);
    fprintf(AWGObj, '*WAI');   %Make sure no other commands are exectued until data is done downloading
    pause(10);
    %update waitbar
    waitbar(.9,h,mes);
    command = ['SOURCE' int2str(channel) ':FUNCtion:ARB:SRATe ' num2str(sRate)]; %create sample rate command
    fprintf(AWGObj,command);%set sample rate
    fprintf(AWGObj,['SOURce' int2str(channel) ':FUNCtion ARB']); % turn on arb function
    command = ['SOURce' int2str(channel) ':VOLT ' num2str(amp)]; %create amplitude command
    fprintf(AWGObj,command); %send amplitude command
    fprintf(AWGObj,['SOURce' int2str(channel) ':VOLT:OFFSET ' num2str(offset)]); % set offset
    fprintf(AWGObj,['SOURce' int2str(channel) ':FUNCtion:ARB:FILTER ' filter]);
    fprintf(AWGObj,['OUTPUT' int2str(channel) ' ON']); %Enable Output
    fprintf('Arb waveform downloaded to channel 1\n\n') %print waveform has been downloaded
    
    %get rid of message box
    waitbar(1,h,mes);
    delete(h);
    
    %Read Error
    fprintf(AWGObj, 'SYST:ERR?');
    errorstr = fscanf (AWGObj);
    
    % error checking
    if strncmp (errorstr, '+0,"No error"',13)
        errorcheck = 'Arbitrary waveform generated without any error\n';
        fprintf (errorcheck)
    else
        errorcheck = ['Error reported: ', errorstr];
        fprintf (errorcheck)
    end
elseif systemParameters.AWGType == 3,
    % UP-VLC DAC
    % mean-pad the data to a multiple of 256 bytes
    rem = 256 - mod(length(data),256);
    data = [data ones(1,rem)*mean(data)]; 
    
    %map to 0 .. 255 
    data = data - min(data);
    data = data * 255 / max(data); 
    
    data = round(data); 
    
    success = AWGObj.setdata(data); 
    if(success == 0)
        error('Data cannot fit in DAC, decrease data length')
    end
    %AWGObj.setsamplefreq(sampleRate);
    
    %PAY ATTENTION! BOTH offset and Vpp are in mA if we are using the
    %UPVLCDAC!
    
    for i = 1:4 
        AWGObj.setoffset(i, offset);
        AWGObj.setbias(i,Vpp);
    end
    
    AWGObj.starttx(); 
end