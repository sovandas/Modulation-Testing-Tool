function onAdaptiveModulationSISOOFDM(~,~)

%% Define global variables
global SISOOFDM;
global systemParameters;

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
    %% Setup system parameters
    OFDMParameters = load(SISOOFDM.parametersFile);
    OFDMParameters.maxConstellation = SISOOFDM.maxModulationOrder;
    OFDMParameters.samples_per_symbol = systemParameters.samplesPerSymbol;
    sampleRate = systemParameters.samplingFrequency*1e6;
    numberPointsFromScope = 600000;
    
    AWGObj = systemParameters.AWGObj;
    scopeObj = systemParameters.ScopeObj;
    
    inputType = systemParameters.outputType;
    
    %% Send data to AWG
    [M_theory, P_theory] = OFDM_optimal_constellation_allocation2(OFDMParameters.maxConstellation,OFDMParameters.Nfft,0,10e-4,10.^(SISOOFDM.SINREstimate/10));

    %Generate the OFDM signal
    [OFDM,QAM] = ofdm_generation_adaptive_modulation(M_theory, P_theory, OFDMParameters);

    %Insert a preamble for manual synchronisation
    data = [zeros(1,500), max(abs(OFDM))/3*ones(1,1000), zeros(1,500), OFDM]; 

    data = data(1:floor(length(data)/32)*32); %Cut down the data sequence to a length which is multiple of 32. Minimum length is 320. AWG crashes if the data is not a multiple of 32. 
    data = data/max(abs(data)); %Fit the data sequence within the interval [-1;1];

    if SISOOFDM.inputCH < 3,
        sendToAWG(data, sampleRate, SISOOFDM.inputCH, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
        unSynchA33522A(AWGObj, SISOOFDM.inputCH);
    else
        sendToAWG(data, sampleRate, 1, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
        sendToAWG(data, sampleRate, 2, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
    end
    
    %% Aquire data from Scope
    fprintf(scopeObj,':STOP');
    waveform1 = aquireFromScope(scopeObj, SISOOFDM.outputCHP, numberPointsFromScope);
    if inputType == 2,
        waveform2 = aquireFromScope(scopeObj, SISOOFDM.outputCHN, numberPointsFromScope);
    end
    fprintf(scopeObj,':RUN');
    
    %% Estimate channel
    % Resample if needed
    target_sampling_frequency = sampleRate;
    if inputType == 2,
        amplitude_input_resampled = resample_signal(waveform1.YData'-waveform2.YData',waveform1.XData,target_sampling_frequency);
    elseif inputType == 1,
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
    
    if ~isempty(sampleNumber),
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
        [SISOOFDM.BER, SISOOFDM.channel, estimated_channel, SNR, estimated_SNR, fitted_SNR, fitted_SNR2, SISOOFDM.SINREstimate, ~] = ...
            ofdm_processing_adaptive_modulation(amplitude_input_resampled, OFDM, QAM, sampleNumber, M_theory, P_theory, OFDMParameters);

        %% Fix waveform data
        SISOOFDM.waveDataOUT = waveform1;
        if inputType == 2,
            SISOOFDM.waveDataOUT.YData = SISOOFDM.waveDataOUT.YData - waveform2.YData;
        end
    
        %% Compute data rate
        SISOOFDM.dataRate = sum(log2(M_theory(M_theory~=0)))/(OFDMParameters.Nfft+OFDMParameters.cp_length)*sampleRate/OFDMParameters.samples_per_symbol/1e6;
        % Save other parameters
        SISOOFDM.M = M_theory;
        SISOOFDM.P = P_theory;
        SISOOFDM.OFDM = OFDM;
        SISOOFDM.QAM = QAM;
        
        %% Display
        msgbox({['The achieved BER is ' num2str(SISOOFDM.BER) '.'],['The achieved data rate is ' num2str(SISOOFDM.dataRate) '.']},'Results', 'help', 'modal');
        delete(h);
    end
    
%% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end