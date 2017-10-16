function onCaptureDemodulateSignal(~,~)

%% Import global parameters
global systemParameters;
global SISOPAM;

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
    numberPilots = SISOPAM.numberPilots;
    sampleRate = systemParameters.samplingFrequency*1e6;
    samplesSymbol = systemParameters.samplesPerSymbol;
    
    scopeObj = systemParameters.ScopeObj; 
    
    numberBitsSymbol = log2(SISOPAM.maxModulationOrder);
    
    inputType = systemParameters.outputType;
    
    %% Aquire data from Scope
    
    if( isa(scopeObj,'visa') ) % should this probably be in aquitefromScope? yes it should. 
        fprintf(scopeObj,':RUN');
        fprintf(scopeObj,':STOP');
    end
    waveform1 = aquireFromScope(scopeObj, SISOPAM.outputCHP, numberPointsFromScope);
    if inputType == 2,
        waveform2 = aquireFromScope(scopeObj, SISOPAM.outputCHN, numberPointsFromScope);
    end
    if( isa(scopeObj,'visa')) % should this probably be in aquitefromScope? yes it should.
        fprintf(scopeObj,':RUN');
    end
    %% Resample if needed
    target_sampling_frequency = sampleRate;
    SISOPAM.waveformData = waveform1;
    if inputType == 2,
        amplitude_input_resampled = resample_signal((waveform1.YData'-waveform2.YData')./2,waveform1.XData,target_sampling_frequency);
        SISOPAM.waveformData.YData = waveform1.YData-waveform2.YData;
    elseif inputType == 1,
        waveform1
        amplitude_input_resampled = resample_signal(waveform1.YData',waveform1.XData,target_sampling_frequency);
    end
    
    % Automatic trigger for synch
    
    % Confirm trigger position for synch
    synchHandle = figure;
    plot(amplitude_input_resampled);
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
        meanValue = mean(amplitude_input_resampled(userSequenceStart:end));
        amplitude_input_resampled = amplitude_input_resampled - meanValue;
        
        pilotsEndIndex = 2*numberPilots*samplesSymbol;
        sequenceStart = userSequenceStart+pilotsEndIndex-floor(samplesSymbol/2)+1:userSequenceStart+pilotsEndIndex+floor(samplesSymbol/2)-1;
        
        originalSignal = amplitude_input_resampled;
        
        BER = Inf(length(sequenceStart),50);
        
        for i = 1:length(sequenceStart),
        % for i = find(sequenceStart == userSequenceStart+pilotsEndIndex+1),
            % Rescale
            pilots = originalSignal(sequenceStart(i)-pilotsEndIndex:sequenceStart(i));
            % achievedGain = mean(pilots>0);
            % achievedGain = mean(abs(pilots(pilots > min(pilots) + (max(pilots)-min(pilots))/2)));
            pilots = abs(pilots);
%             downBorder = 1:samplesSymbol:length(pilots);
%             upBorder = 1+samplesSymbol-1:samplesSymbol:length(pilots);
%             numberSymbols = min(length(downBorder),length(upBorder));
%             for j = 1:numberSymbols,
%                 downsampledPilots(i) = pilots(floor((upBorder(j) + downBorder(j))/2));
%             end
%             achievedGain = mean(downsampledPilots);
            achievedGain = mean(pilots(pilots> max(pilots)/2));
            
            gainIndex = 1;
            for achievedGain = linspace(0.75*achievedGain,1.25*achievedGain,50),
                % achievedGain= 1.2*achievedGain;
                % achievedGain = max(pilots);
                
                amplitude_input_resampled = originalSignal(sequenceStart(i)+1:end)*SISOPAM.originalScale/achievedGain;
                
                % Truncate
                truncatedSignal = amplitude_input_resampled;
                % Downsample
                downBorder = 1:samplesSymbol:length(truncatedSignal);
                upBorder = 1+samplesSymbol-1:samplesSymbol:length(truncatedSignal);
                numberSymbols = min(length(downBorder),length(upBorder));
                downsampledOutput = zeros(1,numberSymbols);
                downsampledIndex = zeros(1,numberSymbols);
                for j = 1:numberSymbols,
                    % downsampledOutput(i) = sum(comparedOutput(downBorder(i):upBorder(i))) > 0;
                    downsampledIndex(j) = floor((upBorder(j) + downBorder(j))/2);
                    downsampledOutput(j) = truncatedSignal(floor((upBorder(j) + downBorder(j))/2));
                    %downsampledOutput(j) = mean(truncatedSignal(downBorder(j):upBorder(j)));
                end
                demodulatedSignal = pamdemod(downsampledOutput, SISOPAM.maxModulationOrder);
                
                % figure,plot(truncatedSignal),hold on, plot(SISOPAM.signal*SISOPAM.originalScale,'r');% ,scatter(4:8:length(truncatedSignal)-8,downsampledOutput,'x');
                % figure,plot(demodulatedSignal),hold on, plot(reshape(bi2de(reshape(SISOPAM.data,10000,log2(SISOPAM.maxModulationOrder)),'right-msb')',1,[]),'r');
                
                data = reshape(de2bi(demodulatedSignal, numberBitsSymbol,'left-msb')',1,[]);
                if length(SISOPAM.data) > length(data)
                    BER(i, gainIndex) = sum(SISOPAM.data(1:length(data)) ~= data)/length(data);
                else
                    BER(i, gainIndex) = sum(SISOPAM.data ~= data(1:length(SISOPAM.data)))/length(SISOPAM.data);
                end
                tempBER = reshape(BER,1,[]);
                if BER(i, gainIndex) == min(tempBER),
                    bestSynch = truncatedSignal;
                    bestData = downsampledOutput;
                end
                gainIndex = gainIndex + 1;
            end
        end
    else
        BER = [];
    end
    %% Save results
    SISOPAM.BER = min(reshape(BER,1,[]));
    SISOPAM.dataRate = sampleRate / samplesSymbol * log2(SISOPAM.maxModulationOrder)/1e6;
    %% Display results
    delete(h);
    figure,plot(bestSynch),hold on, plot(SISOPAM.signal*SISOPAM.originalScale,'r'), scatter(floor(systemParameters.samplesPerSymbol/2):systemParameters.samplesPerSymbol:length(bestData)*systemParameters.samplesPerSymbol, bestData);
    msgbox({['The achieved BER is ' num2str(SISOPAM.BER) '.'],['The achieved data rate is ' num2str(SISOPAM.dataRate) '.']},'Results', 'help', 'modal');
    
%% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
    disp(ME.message);
    for i = 1:length(ME.stack)
        fprintf('file: %s line %d\n', ME.stack(i).file, ME.stack(i).line);
    end
end