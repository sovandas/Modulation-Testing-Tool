function onGenerateSignalSISOPAM(~,~)

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
    numberSymbols = 2000;
    numberPilots = 100;
    SISOPAM.numberPilots = numberPilots;
    sampleRate = systemParameters.samplingFrequency*1e6;
    samplesSymbol = systemParameters.samplesPerSymbol;
    
    AWGObj = systemParameters.AWGObj;
    
    numberBitsSymbol = log2(SISOPAM.maxModulationOrder);
        
    signal = zeros(1,(numberSymbols+2*numberPilots)*samplesSymbol);
    data = floor(2*rand(1,numberSymbols*numberBitsSymbol));
    SISOPAM.data = data;
    
    pilotSequence = repmat([ones(1,numberBitsSymbol) zeros(1,numberBitsSymbol)],1,numberPilots);
    data = [pilotSequence data];
    
    decimalData = zeros(1,numberSymbols+2*numberPilots);
    
    parfor i = 1:numberSymbols+2*numberPilots,
        decimalData(i) = bi2de(data((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb');
    end
        
    encodedData = pammod(decimalData,SISOPAM.maxModulationOrder);
    encodedData = real(encodedData);
    SISOPAM.originalScale = encodedData(1);
    encodedData = encodedData ./ (max(encodedData)-min(encodedData)) .* 2;
    % encodedData = encodedData -1 - min(encodedData);
    
    for i = 1:numberSymbols+2*numberPilots,
        signal((i-1)*samplesSymbol+1:i*samplesSymbol) = repmat(encodedData(i),1,samplesSymbol);
    end
    
    %% Add synchronization sequence
    synchSequence = [zeros(1,100*samplesSymbol) ones(1,100*samplesSymbol) zeros(1,100*samplesSymbol)];
    signal = [synchSequence signal];
    
    %% Send to AWG
    if SISOPAM.inputCH < 3,
        lengthDataSent = sendToAWG(signal, sampleRate, SISOPAM.inputCH, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
        unSynchA33522A(AWGObj, SISOPAM.inputCH);
    else
        lengthDataSent = sendToAWG(signal, sampleRate, 1, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
        lengthDataSent = sendToAWG(signal, sampleRate, 2, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
    end
    
    
    %% Truncate data signal if needed
    difference = length(signal) - lengthDataSent;
    if difference > 0,
        numberSymbolsToRemove = ceil(difference/samplesSymbol);
        SISOPAM.data = SISOPAM.data(1:end-numberSymbolsToRemove*numberBitsSymbol);
    end
    
    %% Save variables
    SISOPAM.signal = signal((300 + 2*numberPilots)*samplesSymbol+1:end);
    
    delete(h);

%% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end