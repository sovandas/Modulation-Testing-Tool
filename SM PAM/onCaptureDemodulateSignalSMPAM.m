function onCaptureDemodulateSignalSMPAM(~,~)

%% Import global parameters
global systemParameters;
global SMPAM;

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
    %% Variables
    numberPointsFromScope = 1000000;
    numberPilots = SMPAM.numberPilots;
    sampleRate = systemParameters.samplingFrequency*1e6;
    samplesSymbol = systemParameters.samplesPerSymbol;
    
    scopeObj = systemParameters.ScopeObj; 
    
    numberBitsSymbol = log2(SMPAM.maxModulationOrder);
    
    inputType = systemParameters.outputType;
    
    %% Aquire data from Scope
    fprintf(scopeObj,':RUN');
    fprintf(scopeObj,':STOP');
    waveform1 = aquireFromScope(scopeObj, SMPAM.outputCH1P, numberPointsFromScope);
    if inputType == 2,
        waveform2 = aquireFromScope(scopeObj, SMPAM.outputCH1N, numberPointsFromScope);
    end
    waveform3 = aquireFromScope(scopeObj, SMPAM.outputCH2P, numberPointsFromScope);
    if inputType == 2,
        waveform4 = aquireFromScope(scopeObj, SMPAM.outputCH2N, numberPointsFromScope);
    end
    fprintf(scopeObj,':RUN');
    
    %% Resample if needed
    target_sampling_frequency = sampleRate;
    SMPAM.waveformData1 = waveform1;
    SMPAM.waveformData2 = waveform3;
    if inputType == 2,
        channel1 = resample_signal((waveform1.YData'-waveform2.YData')./2,waveform1.XData,target_sampling_frequency);
        channel2 = resample_signal((waveform3.YData'-waveform4.YData')./2,waveform3.XData,target_sampling_frequency);
        SMPAM.waveformData1.YData = waveform1.YData-waveform2.YData;
        SMPAM.waveformData2.YData = waveform3.YData-waveform4.YData;
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
        
        pilotsEndIndex = length(0:SMPAM.maxModulationOrder-1)*numberPilots*samplesSymbol*2;
        pilotsSetLength = length(0:SMPAM.maxModulationOrder-1)*samplesSymbol*2;
        sequenceStart = userSequenceStart-floor(samplesSymbol/2)+1:userSequenceStart+floor(samplesSymbol/2)-1;
        
        % Center signal around zero
        meanValue1 = mean(channel1(userSequenceStart:end));
        meanValue2 = mean(channel2(userSequenceStart:end));
        channel1 = channel1 - meanValue1;
        channel2 = channel2 - meanValue2;
        
        BER = zeros(1,length(sequenceStart));
        
        for i = 1:length(sequenceStart),
            % Extract Pilots
            pilots1 = channel1(sequenceStart(i):sequenceStart(i)+pilotsEndIndex);
            pilots2 = channel2(sequenceStart(i):sequenceStart(i)+pilotsEndIndex);

            symbolMatrix = zeros(2,length(0:SMPAM.maxModulationOrder-1)*2);

            for j = 1:numberPilots,
                for k = 1:length(0:SMPAM.maxModulationOrder-1)*2,
                    symbolMatrix(1,k) = symbolMatrix(1,k) + median(pilots1((j-1)*pilotsSetLength+(k-1)*samplesSymbol+1:(j-1)*pilotsSetLength+k*samplesSymbol));
                    symbolMatrix(2,k) = symbolMatrix(2,k) + median(pilots2((j-1)*pilotsSetLength+(k-1)*samplesSymbol+1:(j-1)*pilotsSetLength+k*samplesSymbol));
                end
            end

            symbolMatrix = symbolMatrix ./numberPilots;
%             figure, scatter(0:length(symbolMatrix(1,:))-1,symbolMatrix(1,:)), hold on, scatter(0:length(symbolMatrix(1,:))-1,symbolMatrix(2,:),'r');
            
            % Decode
            truncatedSignal1 = channel1(sequenceStart(i)+pilotsEndIndex+1:end);
            truncatedSignal2 = channel2(sequenceStart(i)+pilotsEndIndex+1:end);
            
            numberSymbols = floor(length(truncatedSignal1)/samplesSymbol);
            decodedSymbolsPAM = zeros(1,numberSymbols);
            decodedSymbolsSM = zeros(1,numberSymbols);
            
            for j = 1:numberSymbols,
                currentSymbol1(j) = mean(truncatedSignal1((j-1)*samplesSymbol+1:j*samplesSymbol));
                currentSymbol2(j) = mean(truncatedSignal2((j-1)*samplesSymbol+1:j*samplesSymbol));
                
                distances = zeros(1,size(symbolMatrix,2));
                for k = 1:size(symbolMatrix,2),
                    distances(k) = sqrt(abs(symbolMatrix(1,k) - currentSymbol1(j))^2 + abs(symbolMatrix(2,k) - currentSymbol2(j))^2);
                end
                [~, symbolIndex] = min(distances);
                decodedSymbolsPAM(j) = mod(symbolIndex-1,SMPAM.maxModulationOrder);
                decodedSymbolsSM(j) = floor((symbolIndex-1)/SMPAM.maxModulationOrder);
            end
%             figure, subplot(2,1,1), hold on, plot(truncatedSignal1), scatter(4:8:length(currentSymbol1)*8,currentSymbol1), subplot(2,1,2), hold on, plot(truncatedSignal2), scatter(4:8:length(currentSymbol2)*8, currentSymbol2);
            % Compute BER
            data = reshape(de2bi(decodedSymbolsPAM, numberBitsSymbol,'left-msb')',1,[]);
            if numberSymbols > length(SMPAM.SMData),
                % Trim local data
                BERPAM = sum(SMPAM.PAMData ~= data(1:length(SMPAM.PAMData)))/length(SMPAM.PAMData);
                BERSM = sum(SMPAM.SMData ~= decodedSymbolsSM(1:length(SMPAM.SMData)))/length(SMPAM.SMData);
            else
                % Trim sent data
                BERPAM = sum(SMPAM.PAMData(1:length(data)) ~= data)/length(data);
                BERSM = sum(SMPAM.SMData(1:length(decodedSymbolsSM)) ~= decodedSymbolsSM)/length(decodedSymbolsSM);
            end
            BER(i) = BERPAM + BERSM/numberBitsSymbol;
        end
    else
        BER = [];
    end
    
    %% Save results
    SMPAM.BER = min(BER);
    SMPAM.dataRate = sampleRate / samplesSymbol * (log2(SMPAM.maxModulationOrder)+1)/1e6;
    %% Display results
    delete(h);
    msgbox({['The achieved BER is ' num2str(SMPAM.BER) '.'],['The achieved data rate is ' num2str(SMPAM.dataRate) 'Mbit/s.']},'Results', 'help', 'modal');
    
    %% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end