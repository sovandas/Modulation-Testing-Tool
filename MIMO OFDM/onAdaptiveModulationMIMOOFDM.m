function onAdaptiveModulationMIMOOFDM(~,~)

%% Define global variables
global MIMOOFDM;
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
    OFDMParameters = load(MIMOOFDM.parametersFile);
    OFDMParameters.maxConstellation = MIMOOFDM.maxModulationOrder;
    OFDMParameters.samples_per_symbol = systemParameters.samplesPerSymbol;
    sampleRate = systemParameters.samplingFrequency*1e6;
    numberPointsFromScope = 600000;
    
    AWGObj = systemParameters.AWGObj;
    scopeObj = systemParameters.ScopeObj;
    
    inputType = systemParameters.outputType;
    
    %% Send data to AWG
    figure, plot(10*log10(MIMOOFDM.SINREstimate1))
    figure, plot(10*log10(MIMOOFDM.SINREstimate2))
    [M_theory(1,:), P_theory(1,:)] = MIMO_OFDM_optimal_constellation_allocation(OFDMParameters.maxConstellation,OFDMParameters.Nfft,0,1E-3,MIMOOFDM.SINREstimate1);
    [M_theory(2,:), P_theory(2,:)] = MIMO_OFDM_optimal_constellation_allocation(OFDMParameters.maxConstellation,OFDMParameters.Nfft,0,1E-3,MIMOOFDM.SINREstimate2);
    M_theory(1,124)=0;
    M_theory(1,256)=0;
    M_theory(1,314)=0;
    M_theory(2,124)=0;
    M_theory(2,256)=0;
    M_theory(2,314)=0;
    M_theory
    P_theory
    %Generate the SM OFDM signal
    [MIMO_OFDM1,MIMO_OFDM2,QAM1,QAM2] = MIMO_ofdm_generation_adaptive_modulation(M_theory, P_theory, OFDMParameters);
    
    %Insert a preamble for manual synchronisation
    data1 = [zeros(1,500), max(abs(MIMO_OFDM1))/3*ones(1,1000), zeros(1,500), MIMO_OFDM1];
    data2 = [zeros(1,500), max(abs(MIMO_OFDM2))/3*ones(1,1000), zeros(1,500), MIMO_OFDM2];
    data1 = data1/max(abs([data1,data2]));
    data2 = data2/max(abs([data1,data2]));
    
    sendToAWG(data1, sampleRate, MIMOOFDM.inputCH1, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
    unSynchA33522A(AWGObj, MIMOOFDM.inputCH1);
    sendToAWG(data2, sampleRate, MIMOOFDM.inputCH2, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
    unSynchA33522A(AWGObj, MIMOOFDM.inputCH2);
    
     %% Aquire data from Scope
    fprintf(scopeObj,':RUN');
    fprintf(scopeObj,':STOP');
    waveform1 = aquireFromScope(scopeObj, MIMOOFDM.outputCH1P, numberPointsFromScope);
    waveform3 = aquireFromScope(scopeObj, MIMOOFDM.outputCH2P, numberPointsFromScope);
    if inputType == 2,
        waveform2 = aquireFromScope(scopeObj, MIMOOFDM.outputCH1N, numberPointsFromScope);
        waveform4 = aquireFromScope(scopeObj, MIMOOFDM.outputCH2N, numberPointsFromScope);
    end
    fprintf(scopeObj,':RUN');
    
    %% Estimate channel
   % Resample if needed
    target_sampling_frequency = sampleRate;
    if inputType == 2,
        amplitude_input1_resampled = MIMO_resample_signal(waveform1.YData'-waveform2.YData',waveform1.XData,target_sampling_frequency);
        amplitude_input2_resampled = MIMO_resample_signal(waveform3.YData'-waveform4.YData',waveform3.XData,target_sampling_frequency);
    elseif inputType == 1,
        amplitude_input1_resampled = MIMO_resample_signal(waveform1.YData',waveform1.XData,target_sampling_frequency);
        amplitude_input2_resampled = MIMO_resample_signal(waveform3.YData',waveform3.XData,target_sampling_frequency);
    end
    
    % Automatic trigger for synch
    
    % Confirm trigger position for synch
    synchHandle = figure;
    plot(amplitude_input1_resampled);
    prompt = {'Enter sequence start sample for Channel 1:'};
    dlg_title = 'Synchronization';
    num_lines = 1;
    def = {'1'};
    options.WindowStyle='normal';
    delete(h);
    sampleNumber1 = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
    try
        close(synchHandle);
        drawnow;
    catch ME,
    end
    
    synchHandle = figure;
    plot(amplitude_input2_resampled);
    prompt = {'Enter sequence start sample for Channel 2:'};
    dlg_title = 'Synchronization';
    num_lines = 1;
    def = {'1'};
    options.WindowStyle='normal';
    delete(h);
    sampleNumber2 = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
    try
        close(synchHandle);
        drawnow;
    catch ME,
    end
    
    if ~isempty(sampleNumber1) || ~isempty(sampleNumber2),
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
        [BER, BER_QAM1, BER_QAM2, channel, estimated_channel, SNR1, SNR2] = ...
            MIMO_ofdm_processing_adaptive_modulation(amplitude_input1_resampled, amplitude_input2_resampled, QAM1, QAM2, sampleNumber1, sampleNumber2, M_theory, P_theory, OFDMParameters);
        delete(h);
        %% Fix waveform data
        waveDataOUT = waveform1;
        if inputType == 2,
            MIMOOFDM.waveDataOUT.YData = waveDataOUT.YData - waveform2.YData;
        end
    
        %% Compute data rate
        MIMOOFDM.dataRate = sum(sum(log2(M_theory(M_theory~=0))))/(OFDMParameters.Nfft+OFDMParameters.cp_length)*sampleRate/OFDMParameters.samples_per_symbol/1e6
        % Save other parameters
        MIMOOFDM.M = M_theory;
        MIMOOFDM.P = P_theory;
        MIMOOFDM.OFDM1 = MIMO_OFDM1;
        MIMOOFDM.QAM1 = QAM1;
        MIMOOFDM.OFDM2 = MIMO_OFDM2;
        MIMOOFDM.QAM2 = QAM2;
        MIMOOFDM.BER_ch1 = BER_QAM1;
        MIMOOFDM.BER_ch2 = BER_QAM2;
        MIMOOFDM.BER = BER;
        
        %% Display
        msgbox({['The achieved BER is ' num2str(MIMOOFDM.BER) '.'],['The achieved data rate is ' num2str(MIMOOFDM.dataRate) '.']},'Results', 'help', 'modal');
        delete(h);
    end
    
%% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
end