function onEstimateChannelSISOOFDM(~,~)

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
    OFDMParameters.subcarriers = OFDMParameters.Nfft;
    sampleRate = systemParameters.samplingFrequency*1e6;
    numberPointsFromScope = 600000;
    
    AWGObj = systemParameters.AWGObj;
    scopeObj = systemParameters.ScopeObj;
    
    inputType = systemParameters.outputType;
    
    %% Generate signal and send to AWG
    % Generate modulation and power
    M = repmat(4,1,(OFDMParameters.subcarriers-2)/2);
    P = repmat(OFDMParameters.subcarriers/2/((OFDMParameters.subcarriers-2)/2),1,(OFDMParameters.subcarriers-2)/2);
    OFDMParameters.Max_Constellation_Size = max(M);
    % Setup frame structure
    OFDMParameters.number_of_pilot_frames = (OFDMParameters.frames + 2*OFDMParameters.number_of_pilot_frames - 10)/2;
    OFDMParameters.frames = 10;
    OFDMParameters.frame_eq_mult = OFDMParameters.frames;
    
    %Generate the OFDM signal
    [OFDM,QAM] = ofdm_generation_adaptive_modulation(M, P, OFDMParameters);
    
    %Insert a preamble for manual synchronisation
    data = [zeros(1,500), max(abs(OFDM))/3*ones(1,1000), zeros(1,500), OFDM];
    
    if SISOOFDM.inputCH < 3,
        sendToAWG(data, sampleRate, SISOOFDM.inputCH, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
        unSynchA33522A(AWGObj, SISOOFDM.inputCH);
    else
        sendToAWG(data, sampleRate, 1, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
        sendToAWG(data, sampleRate, 2, systemParameters.Vpp, systemParameters.offset, AWGObj, 1);
    end
    
    %% Aquire data from Scope
    if( isa(scopeObj,'visa') ) % should this probably be in aquitefromScope? yes it should. 
        fprintf(scopeObj,':RUN');
        fprintf(scopeObj,':STOP');
    end
    waveform1 = aquireFromScope(scopeObj, SISOOFDM.outputCHP, numberPointsFromScope);
    if inputType == 2,
        waveform2 = aquireFromScope(scopeObj, SISOOFDM.outputCHN, numberPointsFromScope);
    end
    if( isa(scopeObj,'visa')) % should this probably be in aquitefromScope? yes it should.
        fprintf(scopeObj,':RUN');
    end
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
        % Estimate channel
        [BER, channel, estimated_channel, SNR, estimated_SNR, fitted_SNR, fitted_SNR2, SISOOFDM.SINREstimate, ~] = ...
            ofdm_processing_adaptive_modulation(amplitude_input_resampled, OFDM, QAM, sampleNumber, M, P, OFDMParameters);
        delete(h);
    else
        SISOOFDM.SINREstimate = [];
    end
%% Exit gracefully if something fails
catch ME,
    delete(h);
    warndlg(ME.message, 'Error','modal');
    disp(ME.message);
    for i = 1:length(ME.stack)
        fprintf('file: %s line %d\n', ME.stack(i).file, ME.stack(i).line);
    end
end