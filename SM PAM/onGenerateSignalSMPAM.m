function onGenerateSignalSMPAM(~,~)

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
    numberSymbols = 10000;
    SMPAM.numberSymbols = numberSymbols;
    numberPilots = 10;
    SMPAM.numberPilots = numberPilots;
    sampleRate = systemParameters.samplingFrequency*1e6;
    samplesSymbol = systemParameters.samplesPerSymbol;
    
    AWGObj = systemParameters.AWGObj;
    
    numberBitsSymbol = log2(SMPAM.maxModulationOrder);
    
    %% Inits
    channel1 = zeros(1,numberSymbols);
    channel2 = zeros(1,numberSymbols);
    
    %% Data
    PAMData = floor(2*rand(1,numberSymbols*numberBitsSymbol));
    SMData = floor(2*rand(1,numberSymbols));
    
    SMPAM.PAMData = PAMData;
    SMPAM.SMData = SMData;
    
    %% Pilots
    pilotSequence1 = pammod(0:SMPAM.maxModulationOrder-1,SMPAM.maxModulationOrder);
    pilotSequence2 = pammod(0:SMPAM.maxModulationOrder-1,SMPAM.maxModulationOrder);
    
    pilotSequence1 = repmat([pilotSequence1 zeros(1,length(pilotSequence1))],1,numberPilots);
    pilotSequence2 = repmat([zeros(1,length(pilotSequence2)) pilotSequence2],1,numberPilots);
    
    % pilotSequence1 = [repmat([max(pilotSequence1) 0 min(pilotSequence1) 0],numberPilots,[]) pilotSequence1];
    % pilotSequence2 = [repmat([0 max(pilotSequence2) 0 min(pilotSequence2)],numberPilots,[]) pilotSequence2];
    
    %% Data
    for i = 1:numberSymbols,
        if SMData(i),
            % SM 1
            channel1(i) = 0;
            channel2(i) = pammod(bi2de(PAMData((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb'), SMPAM.maxModulationOrder);
        else
            % SM 0
            channel1(i) = pammod(bi2de(PAMData((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb'), SMPAM.maxModulationOrder);
            channel2(i) = 0;
        end
    end
    
    %% Stitch and upsample
    channel1 = real([pilotSequence1 channel1]);
    channel2 = real([pilotSequence2 channel2]);
    
    SMPAM.originalScale = max(channel1);
   
    signal1 = zeros(1,length(channel1)*samplesSymbol);
    signal2 = zeros(1,length(channel2)*samplesSymbol);
    
    for i = 1:length(channel1),
        signal1((i-1)*samplesSymbol+1:i*samplesSymbol) = repmat(channel1(i),1,samplesSymbol);
        signal2((i-1)*samplesSymbol+1:i*samplesSymbol) = repmat(channel2(i),1,samplesSymbol);
    end
    
    %% Scale signal correctly
    signal1 = signal1./SMPAM.originalScale;
    signal2 = signal2./SMPAM.originalScale;
    
    %% Add in synch sequence
    synchSequence = [zeros(1,100*samplesSymbol) ones(1,100*samplesSymbol) zeros(1,100*samplesSymbol)];
    
    signal1 = [synchSequence signal1];
    signal2 = [synchSequence signal2];
    
    %% Send to AWG
    lengthDataSent1 = sendToAWG(signal1, sampleRate, '1', systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
    lengthDataSent2 = sendToAWG(signal2, sampleRate, '2', systemParameters.Vpp, systemParameters.offset, AWGObj, 2);
    synchA33522A(AWGObj);
    
%     figure, subplot(2,1,1), plot(signal1), subplot(2,1,2), plot(signal2);
    
    %% Truncate data signal if needed
    difference1 = length(signal1) - lengthDataSent1;
    if difference1 > 0,
        numberSymbolsToRemove = ceil(difference/samplesSymbol);
        SMPAM.PAMData = SMPAM.PAMData(1:end-numberSymbolsToRemove*numberBitsSymbol);
        SMPAM.SMData = SMPAM.SMData(1:end-numberSymbolsToRemove*numberBitsSymbol);
    end
    delete(h);
    
%% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end