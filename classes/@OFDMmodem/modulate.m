function wave = modulate(obj, data)
%GENERATESIGNALOFDM Summary of this function goes here
%   Detailed explanation goes here


try
    
%     %obj.constellation = obj.modorder;
%     obj.samples_per_symbol = obj.samples_per_symbol;
%     obj.number_of_pilot_frames = 2; % must be larger than or equal to 2
%     obj.cp_length = 16;
%     obj.preamble_length = min(4000, obj.samples / 64)
%     if(obj.filter == 1)
%         obj.frames = floor((obj.samples - obj.preamble_length - length(RRC(obj.samples_per_symbol, obj.filterorder)) - 17*obj.samples_per_symbol - ((obj.number_of_pilot_frames)*(obj.nfft+obj.cp_length)*obj.samples_per_symbol) - obj.cp_length)/((obj.nfft+obj.cp_length)*obj.samples_per_symbol));
%     else
%         obj.frames = floor((obj.samples - obj.preamble_length - 17*obj.samples_per_symbol - ((obj.number_of_pilot_frames)*(obj.nfft+obj.cp_length)*obj.samples_per_symbol) - obj.cp_length)/((obj.nfft+obj.cp_length)*obj.samples_per_symbol));
%     end
%     obj.nfft = obj.nfft;
%     obj.subcarriers = obj.nfft;
%     obj.omitted_carriers = 0;
%     obj.filter_type = obj.filter;
%     obj.upper_clipping = 10000;
%     obj.lower_clipping = -10000;
%     obj.oversampling_factor = 1;
%     obj.roll_off_factor = obj.filterorder;
    
    if(obj.frames < 1)
        ME = MException('ofdm:nodataframes', ...
            'Number of data frames is less than one.');
        throw(ME)
    end
    
    if(nargin == 1)
        if(numel(obj.data) ~= 0 )
            data = obj.data;
        else
            data = [];
        end
    end
    
    data = double(data); 
    
    if(max(data) > 1)
        error('Data is not binary'); 
    end
    if(min(data) < 0)
        error('data is not binary'); 
    end
    %% Generate signal
    
    numberBitsSymbol = log2(obj.modorder);
    
    %signal = zeros(1,(numberSymbols+3*obj.number_of_pilots)*obj.samples_per_symbol);
    
    data = reshape(data, 1, []);
    
    if(numel(data) > obj.datalength) % if too long, concatenate
        data = data(1:obj.datalength);
    end
    if(numel(data) < obj.datalength) % if too short, add random bits
        data = [data, round(rand(1, obj.datalength - numel(data)))];
    end
    
    obj.inputCH = 1;
    
    modulator = modem.qammod('M',obj.modorder,'SymbolOrder','Gray','InputType','Bit');
    
    %% Generate signal and send to AWG
    % Generate modulation and power
    
    if(numel(obj.pilotqam) ~=   log2(obj.modorder) * obj.number_of_pilot_frames * ((obj.nfft-2)/2) )
        % update pilotqam
        leadinpilot = round(rand(log2(obj.modorder), ceil(obj.number_of_pilot_frames/2) * ((obj.nfft-2)/2) ) );
        leadoutpilot = round(rand(log2(obj.modorder), floor(obj.number_of_pilot_frames/2) * ((obj.nfft-2)/2) ) );
        
        %pilot = round(rand(log2(obj.modorder), obj.number_of_pilot_frames * ((obj.nfft-2)/2) ) );
        
        %leadout = floor(2*rand(log2(obj.modorder),(obj.nfft-2)/2));
        
        leadinpilotqam =  modulate(modulator, leadinpilot);
        leadoutpilotqam = modulate(modulator, leadoutpilot); 
        %leadoutqam = modulate(modulator, leadout);
        
        obj.pilotqam = [ leadinpilotqam leadoutpilotqam ];
        %obj.leadout = leadoutqam;
    end
    
    %pilotqamcoded = repmat(pilotqam, 1, (obj.number_of_pilot_frames));
    pilotqamcoded = obj.pilotqam; 
    %
    %     disp('size(pilotqamcoded)')
    %     size(pilotqamcoded)
    %     disp('size(pilotqam)')
    %     size(pilotqam)
    %     obj.number_of_pilot_frames
    %     disp('frames')
    %     obj.frames
    %
    
    
    obj.encodedData = data;
    obj.data = data;
    
    if(obj.show)
    disp('size(obj.data)')
    size(obj.data)
    end
    dataqamcoded = modulate(modulator, obj.data')';
    obj.dataqam = dataqamcoded; 
    %% Energy per subcarrier mush
    
    % do the channel linearization / sensing
    vpp_new = 0;
    voffs_new = 0;
    
    invpow = ones(1,obj.nfft/2-1);
    
    if( numel(obj.powerloading) == obj.nfft/2-1)
        % apply power loading waveform
        
        pilotqamcoded = obj.pilotqam .* repmat(obj.powerloading, 1, obj.number_of_pilot_frames);
        dataqamcoded = dataqamcoded .* repmat(obj.powerloading, 1, obj.frames);
    end
    
    lipq = pilotqamcoded( 1:(ceil(obj.number_of_pilot_frames/2) * ((obj.nfft-2)/2) ));
    lopq = pilotqamcoded(((ceil(obj.number_of_pilot_frames/2) * ((obj.nfft-2)/2))+1):end);
    
    signal = ofdm_modulate_real(obj, [lipq dataqamcoded lopq]);
    
    obj.nonexpandedsignal = signal;
       
    
    %% obj.filter the signal to length
    
    
    % insert stretching
    
    %OFDMS0 = resample(signal, obj.samples_per_symbol, 1, 0);
    %OFDMS1 = resample(signal, obj.samples_per_symbol, 1, 1);
    %OFDMS2 = resample(signal, obj.samples_per_symbol, 1, 2);
    %OFDMS3 = resample(signal, obj.samples_per_symbol, 1, 3);
    %OFDMS4 = resample(signal, obj.samples_per_symbol, 1, 4);
    
    
    if(obj.filter == 1)
        
        % RRC obj.filter
        
        filt = RRC(obj);
        
        [~,extradata] = max(filt);
        
        OFDM = zeros(1,length(signal) * obj.samples_per_symbol);
        OFDM(1:obj.samples_per_symbol:end)= signal;
        OFDM = conv(OFDM, filt);
        %OFDM = OFDM(extradata-1 : end-extradata+1);
        
    else
        
        % SQUARE obj.filter
        
        OFDM = reshape(repmat(signal, obj.samples_per_symbol, 1), 1, []) ;
        
    end
    
%    obj.ofdmsource = OFDM;
    
    

    % Add 2-PAM end of signal marker
    
%     tail = [ max(max(OFDM))...
%         min(min(OFDM))...
%         max(max(OFDM))...
%         max(max(OFDM))...
%         max(max(OFDM))...
%         min(min(OFDM))...
%         min(min(OFDM))...
%         max(max(OFDM))...
%         min(min(OFDM))...
%         max(max(OFDM))...
%         max(max(OFDM))...
%         min(min(OFDM))...
%         min(min(OFDM))...
%         min(min(OFDM))...
%         max(max(OFDM))...
%         min(min(OFDM))...
%         mean(OFDM)];
%     
%     tail = reshape(repmat(tail, obj.samples_per_symbol*2, 1), 1, []);
    
    %OFDM = [OFDM tail];
    %OFDM = OFDMS1;
    
    %OFDM = interp1(1:obj.samples_per_symbol:(length(signal)*obj.samples_per_symbol), signal, 1:(length(signal)*obj.samples_per_symbol), 'linear', 'extrap');
    
    %figure;
    %plot(OFDM);
    %    plot(OFDMS0, 'color', [0, 0, 1])
    %line(1:length(OFDMS1), OFDMS1, 'color', [0, 0, 0.8]);
    %line(1:length(OFDMS2), OFDMS2, 'color', [0, 0, 0.6]);
    %line(1:length(OFDMS3), OFDMS3, 'color', [0, 1, 0]);
    %line(1:length(OFDMS4), OFDMS4, 'color', [0, 0.6, 0]);
    %   line(1:length(OFDM),OFDM, 'color', 'green')
    %line(1:obj.samples_per_symbol:obj.samples_per_symbol*length(signal), signal, 'color', 'red')
    
    stdev = std(OFDM);
    
    fact = obj.clip;
    
    
    OFDM( OFDM > (mean(OFDM) + fact*stdev) ) = (mean(OFDM) + fact*stdev);
    OFDM( OFDM < (mean(OFDM) - fact*stdev) ) = (mean(OFDM) - fact*stdev);
    
    %plot(OFDM)
    %
    
    obj.encodedData = OFDM;
    
    %obj.leadoutsequence = OFDM((end-(17*2*obj.samples_per_symbol)+1):end);
    
    if(obj.filter == 1)
        obj.pilotsequence = OFDM(1:((ceil(obj.number_of_pilot_frames/2))*(obj.nfft+obj.cp_length)*obj.samples_per_symbol)+(length(filt)/2));
        obj.leadoutsequence = OFDM((end-(((floor(obj.number_of_pilot_frames/2))*(obj.nfft+obj.cp_length)*obj.samples_per_symbol)+(length(filt)/2))+1):end);
    else
        obj.pilotsequence = OFDM(1:((ceil(obj.number_of_pilot_frames/2))*(obj.nfft+obj.cp_length)*obj.samples_per_symbol));
        obj.leadoutsequence = OFDM((end-(((floor(obj.number_of_pilot_frames/2))*(obj.nfft+obj.cp_length)*obj.samples_per_symbol))+1):end);
    end
    %Insert a preamble for manual synchronisation
    data = [zeros(1,obj.preamble_length/4), (max(OFDM))*ones(1,obj.preamble_length/4),(min(OFDM))*ones(1,obj.preamble_length/4), zeros(1,obj.preamble_length/4), OFDM];
    
    %plot(data)
    
    
    % remap data as obj.minlevel to obj.minlevel + obj.levels
    
    % obj.mapping is a power transfer function we should apply. 
    
    if(isempty(obj.mapping))
        obj.mapping = linspace(obj.minlevel, obj.minlevel+obj.levels, obj.minlevel+obj.levels+1); 
        obj.defaultmapping = obj.mapping; 
    end
    
    % reduce range of signal to [0,obj.levels]
    
    data = data - min(data);
    
    data = (data * (obj.levels+obj.minlevel)) / max(data);
    
    %    data = data + 1;
    
    data = round(data);
    
    % apply mapping
    nomapdata = data; 
    data = round(interp1(0:(obj.levels+obj.minlevel), obj.mapping, data)); 
    data_defaultmap = round(interp1(0:(obj.levels+obj.minlevel), obj.defaultmapping, nomapdata)); 
    
    min(data)
    max(data)
       
    obj.ofdmsig = data(obj.preamble_length+1:end);
    obj.ofdmsig_nomapping = data_defaultmap(obj.preamble_length+1:end);
    
    obj.originalSignal = data;
    
    %figure
    %plot(data)
    
    wave = data; 
    
catch ME,
    ME
    for i = 1:length(ME.stack)
        ME.stack(i)
    end
    rethrow(ME)
end

