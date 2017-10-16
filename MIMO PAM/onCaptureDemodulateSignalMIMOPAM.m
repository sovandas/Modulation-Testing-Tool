function onCaptureDemodulateSignalMIMOPAM(~,~)

%% Import global parameters
global systemParameters;
global MIMOPAM;

%% Display wait window
% Warn user to wait
h = figure('windowstyle','modal', ...
    'NumberTitle','off', ...
    'MenuBar','none',...
    'Toolbar','none',...
    'HandleVisibility','off', ...
    'Position', [1 1 200 50], ...
    'Name','Warning', ...
    'CloseRequestFcn','');
uiextras.set(h, 'DefaultBoxPanelTitleColor', [0.7 1.0 0.7]);
hLayout = uiextras.VBox('Parent',h,'Padding',15,'Spacing',10);
uicontrol('Parent',hLayout,'style','text','string','Please Wait...', 'FontSize',12);
movegui(h,'center');
drawnow;
try
    %% Generate signal
    numberPointsFromScope = 1000000;
    numberPilots = MIMOPAM.numberPilots;
    sampleRate = systemParameters.samplingFrequency*1e6;
    samplesSymbol = systemParameters.samplesPerSymbol;
    
    scopeObj = systemParameters.ScopeObj; 
    
    numberBitsSymbol = log2(MIMOPAM.maxModulationOrder);
    
    inputType = systemParameters.outputType;
    
    %% Aquire data from Scope
    fprintf(scopeObj,':RUN');
    fprintf(scopeObj,':STOP');
    waveform1 = aquireFromScope(scopeObj, MIMOPAM.outputCH1P, numberPointsFromScope);
    if inputType == 2,
        waveform2 = aquireFromScope(scopeObj, MIMOPAM.outputCH1N, numberPointsFromScope);
    end
    waveform3 = aquireFromScope(scopeObj, MIMOPAM.outputCH2P, numberPointsFromScope);
    if inputType == 2,
        waveform4 = aquireFromScope(scopeObj, MIMOPAM.outputCH2N, numberPointsFromScope);
    end
    fprintf(scopeObj,':RUN');
    
    %% Resample if needed
    target_sampling_frequency = sampleRate;
    MIMOPAM.waveformData1 = waveform1;
    MIMOPAM.waveformData2 = waveform3;
    if inputType == 2,
        channel1 = resample_signal((waveform1.YData'-waveform2.YData')./2,waveform1.XData,target_sampling_frequency);
        channel2 = resample_signal((waveform3.YData'-waveform4.YData')./2,waveform3.XData,target_sampling_frequency);
        MIMOPAM.waveformData1.YData = waveform1.YData-waveform2.YData;
        MIMOPAM.waveformData2.YData = waveform3.YData-waveform4.YData;
    elseif inputType == 1,
        channel1 = resample_signal(waveform1.YData',waveform1.XData,target_sampling_frequency);
        channel2 = resample_signal(waveform3.YData',waveform3.XData,target_sampling_frequency);
    end
    
    % Automatic trigger for synch
    
    % Confirm trigger position for synch
    synchHandle = figure;
    subplot(2,1,1), plot(channel1);
    subplot(2,1,2), plot(channel2);
    prompt = {'Enter sequence start sample:'};
    dlg_title = 'Synchronization';
    num_lines = 1;
    def = {'1'};
    options.WindowStyle='normal';
    delete(h);
    sampleNumber = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
    try
        close(synchHandle);
        drawnow;
    catch ME,
    end
    % Warn user to wait
    h = figure('windowstyle','modal', ...
        'NumberTitle','off', ...
        'MenuBar','none',...
        'Toolbar','none',...
        'HandleVisibility','off', ...
        'Position', [1 1 200 50], ...
        'Name','Warning', ...
        'CloseRequestFcn','');
    uiextras.set(h, 'DefaultBoxPanelTitleColor', [0.7 1.0 0.7]);
    hLayout = uiextras.VBox('Parent',h,'Padding',15,'Spacing',10);
    uicontrol('Parent',hLayout,'style','text','string','Please Wait...', 'FontSize',12);
    movegui(h,'center');
    drawnow;
    
    %% Decode
    if ~isempty(sampleNumber),
        % User synch point
        userSequenceStart = sampleNumber + 200*samplesSymbol;
        % Center signal around zero
        meanValue1 = mean(channel1(userSequenceStart:end));
        meanValue2 = mean(channel2(userSequenceStart:end));
        channel1 = channel1 - meanValue1;
        channel2 = channel2 - meanValue2;
        
        % Offline mixing for testing purposes
%         original1 = channel1;
%         original2 = channel2;
%         channel1 = channel1 + 0.75*channel2;
%         channel2 = channel2 + 0.4*channel1;
%         synchHandle = figure;
%         subplot(2,1,1), plot(channel1), hold on, plot(original1,'r');
%         subplot(2,1,2), plot(channel2), hold on, plot(original2,'r');
        
        pilotsEndIndex = 4*numberPilots*samplesSymbol;
        sequenceStart = userSequenceStart+pilotsEndIndex-floor(samplesSymbol/2)+1:userSequenceStart+pilotsEndIndex+floor(samplesSymbol/2)-1;
        
        originalChannel1 = channel1;
        originalChannel2 = channel2;
        
        for i = 1:length(sequenceStart),
            
            pilots1 = originalChannel1(sequenceStart(i)-pilotsEndIndex:sequenceStart(i));
            pilots2 = originalChannel2(sequenceStart(i)-pilotsEndIndex:sequenceStart(i));
            
            pilotsSelf1 = [];
            pilotsSelf2 = [];
            pilotsCross1 = [];
            pilotsCross2 = [];
            for j = 1:2:numberPilots*4,
                pilotsSelf1 = [pilotsSelf1 pilots1((j-1)*samplesSymbol+1:j*samplesSymbol)];
                pilotsCross1 = [pilotsCross1 pilots1(j*samplesSymbol+1:(j+1)*samplesSymbol)];
                
                pilotsSelf2 = [pilotsSelf2 pilots2(j*samplesSymbol+1:(j+1)*samplesSymbol)];
                pilotsCross2 = [pilotsCross2 pilots2((j-1)*samplesSymbol+1:j*samplesSymbol)];
            end
            
            achievedGain1 = median(abs(pilotsSelf1));
            achievedGain2 = median(abs(pilotsSelf2));
            
            crossGain1 = median(abs(pilotsCross1));
            crossGain2 = median(abs(pilotsCross2));
            
            channel1 = originalChannel1 - originalChannel2.*crossGain1./achievedGain2;
            channel2 = originalChannel2 - originalChannel1.*crossGain2./achievedGain1;
            
            pilotsSelf1 = [];
            pilotsSelf2 = [];
            for j = 1:2:numberPilots*4,
                pilotsSelf1 = [pilotsSelf1 pilots1((j-1)*samplesSymbol+j:i*samplesSymbol)];
                pilotsSelf2 = [pilotsSelf2 pilots2(j*samplesSymbol+1:(j+1)*samplesSymbol)];
            end
            achievedGain1 = median(abs(pilotsSelf1));
            achievedGain2 = median(abs(pilotsSelf2));
            
            channel1 = channel1*MIMOPAM.originalScale/achievedGain1;
            channel2 = channel2*MIMOPAM.originalScale/achievedGain2;
            
            
            % Truncate
            truncatedSignal1 = channel1(sequenceStart(i):end);
            truncatedSignal2 = channel2(sequenceStart(i):end);
            % Downsample
            downBorder = 1:samplesSymbol:length(truncatedSignal1);
            upBorder = 1+samplesSymbol-1:samplesSymbol:length(truncatedSignal1);
            numberSymbols = min(length(downBorder),length(upBorder));
            downsampledOutput1 = zeros(1,numberSymbols);
            downsampledOutput2 = zeros(1,numberSymbols);
            % downsampledIndex = zeros(1,numberSymbols);
            for j = 1:numberSymbols,
                % downsampledOutput(i) = sum(comparedOutput(downBorder(i):upBorder(i))) > 0;
                % downsampledIndex(j) = floor((upBorder(j) + downBorder(j))/2);
                % downsampledOutput(j) = truncatedSignal(floor((upBorder(j) + downBorder(j))/2));
                downsampledOutput1(j) = mean(truncatedSignal1(downBorder(j):upBorder(j)));
                downsampledOutput2(j) = mean(truncatedSignal2(downBorder(j):upBorder(j)));
            end
            demodulatedSignal1 = pamdemod(downsampledOutput1, MIMOPAM.maxModulationOrder);
            demodulatedSignal2 = pamdemod(downsampledOutput2, MIMOPAM.maxModulationOrder);
            
            % figure,plot(truncatedSignal1),hold on, plot(MIMOPAM.signal1*MIMOPAM.originalScale,'r');% ,scatter(4:8:length(truncatedSignal)-8,downsampledOutput,'x');
            % figure,plot(demodulatedSignal),hold on, plot(reshape(bi2de(reshape(SISOPAM.data,10000,log2(SISOPAM.maxModulationOrder)),'right-msb')',1,[]),'r');
            
            data1 = reshape(de2bi(demodulatedSignal1, numberBitsSymbol,'left-msb')',1,[]);
            data2 = reshape(de2bi(demodulatedSignal2, numberBitsSymbol,'left-msb')',1,[]);
            if length(MIMOPAM.data1) > length(data1)
                BER1(i) = sum(MIMOPAM.data1(1:length(data1)) ~= data1)/length(data1);
            else
                BER1(i) = sum(MIMOPAM.data1 ~= data1(1:length(MIMOPAM.data1)))/length(MIMOPAM.data1);
            end
            if length(MIMOPAM.data2) > length(data2)
                BER2(i) = sum(MIMOPAM.data2(1:length(data2)) ~= data2)/length(data2);
            else
                BER2(i) = sum(MIMOPAM.data2 ~= data2(1:length(MIMOPAM.data2)))/length(MIMOPAM.data2);
            end
        end
    else
        BER1 = [];
        BER2 = [];
    end
    %% Save results
    MIMOPAM.BER = (min(BER1) + min(BER2))/2;
    MIMOPAM.dataRate = sampleRate / samplesSymbol * log2(MIMOPAM.maxModulationOrder)/1e6*2;
    %% Display results
    delete(h);
    msgbox({['The achieved BER is ' num2str(MIMOPAM.BER) '.'],['The achieved data rate is ' num2str(MIMOPAM.dataRate) 'Mbit/s.']},'Results', 'help', 'modal');
    
    %% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end