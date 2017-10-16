function onGenerateSignalMIMOPAM(~,~)

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
    numberSymbols = 10000;
    numberPilots = 10;
    MIMOPAM.numberPilots = numberPilots;
    sampleRate = systemParameters.samplingFrequency*1e6;
    samplesSymbol = systemParameters.samplesPerSymbol;
    
    AWGObj = systemParameters.AWGObj;
    
    numberBitsSymbol = log2(MIMOPAM.maxModulationOrder);
    
    signal1 = zeros(1,(numberSymbols+4*numberPilots)*samplesSymbol);
    signal2 = zeros(1,(numberSymbols+4*numberPilots)*samplesSymbol);
    
    data1 = floor(2*rand(1,numberSymbols*numberBitsSymbol));
    data2 = floor(2*rand(1,numberSymbols*numberBitsSymbol));
    
    MIMOPAM.data1 = data1;
    MIMOPAM.data2 = data2;
    
    pilotSequence1 = repmat([ones(1,numberBitsSymbol) ones(1,numberBitsSymbol) zeros(1,numberBitsSymbol) zeros(1,numberBitsSymbol)],1,numberPilots);
    pilotSequence2 = repmat([zeros(1,numberBitsSymbol) zeros(1,numberBitsSymbol) ones(1,numberBitsSymbol) ones(1,numberBitsSymbol)],1,numberPilots);
    
    data1 = [pilotSequence1 data1];
    data2 = [pilotSequence2 data2];
    
    decimalData1 = zeros(1,numberSymbols+4*numberPilots);
    decimalData2 = zeros(1,numberSymbols+4*numberPilots);
    
    parfor i = 1:numberSymbols+4*numberPilots,
        decimalData1(i) = bi2de(data1((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb');
        decimalData2(i) = bi2de(data2((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb');
    end
    
    encodedData1 = pammod(decimalData1,MIMOPAM.maxModulationOrder);
    encodedData2 = pammod(decimalData2,MIMOPAM.maxModulationOrder);
    encodedData1 = real(encodedData1);
    encodedData2 = real(encodedData2);
    MIMOPAM.originalScale = encodedData1(1);
    
    % Insert blank spaces in pilots
    blankPilots1 = 2:2:numberPilots*4;
    blankPilots2 = 1:2:numberPilots*4;
    encodedData1(blankPilots1) = 0;
    encodedData2(blankPilots2) = 0;
    
    encodedData1 = encodedData1 ./ MIMOPAM.originalScale;
    encodedData2 = encodedData2 ./ MIMOPAM.originalScale;
    
    for i = 1:numberSymbols+4*numberPilots,
        signal1((i-1)*samplesSymbol+1:i*samplesSymbol) = repmat(encodedData1(i),1,samplesSymbol);
        signal2((i-1)*samplesSymbol+1:i*samplesSymbol) = repmat(encodedData2(i),1,samplesSymbol);
    end
    
    %% Add synchronization sequence
    synchSequence = [zeros(1,100*samplesSymbol) ones(1,100*samplesSymbol) zeros(1,100*samplesSymbol)];
    signal1 = [synchSequence signal1];
    signal2 = [synchSequence signal2];
    
    %% Send to AWG
    lengthDataSent1 = sendToAWG(signal1, sampleRate, 1, systemParameters.Vpp, systemParameters.offset, AWGObj,1);
    lengthDataSent2 = sendToAWG(signal2, sampleRate, 2, systemParameters.Vpp, systemParameters.offset, AWGObj,2);
    synchA33522A(AWGObj);
    
    %% Truncate data signal if needed
    difference1 = length(signal1) - lengthDataSent1;
    difference2 = length(signal2) - lengthDataSent2;
    if difference1 > 0,
        numberSymbolsToRemove = ceil(difference1/samplesSymbol);
        MIMOPAM.data1 = MIMOPAM.data1(1:end-numberSymbolsToRemove*numberBitsSymbol);
    end
    if difference2 > 0,
        numberSymbolsToRemove = ceil(difference2/samplesSymbol);
        MIMOPAM.data2 = MIMOPAM.data2(1:end-numberSymbolsToRemove*numberBitsSymbol);
    end
    
    %% Save variables
    MIMOPAM.signal1 = signal1((300+4*numberPilots)*samplesSymbol+1:end);
    MIMOPAM.signal2 = signal2((300+4*numberPilots)*samplesSymbol+1:end);
    
    delete(h);
    
    %% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end