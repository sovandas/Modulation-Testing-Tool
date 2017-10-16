classdef OFDMmodem < handle
    %OFDMMODEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        samples = 2^16;
        levels = 8192;
        modorder = 4;
        samples_per_symbol = 5;
        number_of_pilot_frames = 2;
        cp_length = 16;
        nfft = 64;
        omitted_carriers = 0;
        clip = 2.7;
        oversampling_factor = 1;
        inputCH = 1;
        filter = 1;
        filterorder = 0.9;
        freq = 100;
        show = 1;
        showpeak = 1;
        getspectrum = 1; 
        minlevel = 0; 
        mapping = []; 
        shortmap;
    end
    
    properties (Dependent)
        preamble_length
        frames
        subcarriers
        datalength
    end
    
    properties (SetAccess = private, Hidden)
        pilotqam;
        dataqam;
        encodedData;
        data;
        nonexpandedsignal;
        leadoutsequence;
        pilotsequence;
        originalSignal;
        powerloading = [];
        ofdmsig = [];
        defaultmapping = []; 
        ofdmsig_nomapping = []; 
       
    end
    
    methods
        function obj = OFDMmodem()
            
        end
        
        wave = modulate(obj, sourcedata);
        
        [sig_amp, flat_noise_amp, photon_top, photon_bot, tbits, terrors, tcerr, const] = demodulate(obj, wave);
        
        rrcfilt = RRC(obj)
        
        [result] = ofdm_demodulate_real (obj, input)
        
        result = ofdm_modulate_real(obj, input)
        
        [ data_frames ] = equalize(obj, pilot_frames, data_frames)
        
        res = derivelinearity(obj, wf, do_ppc, do_linearity)
        
        function value = get.preamble_length(obj)
            value = min(4000, obj.samples / 64);
        end
        
        function value = get.frames(obj)
            if(obj.filter == 1)
                value = floor((obj.samples - obj.preamble_length - length(RRC(obj)) - ((obj.number_of_pilot_frames)*(obj.nfft+obj.cp_length)*obj.samples_per_symbol) - obj.cp_length*obj.samples_per_symbol)/((obj.nfft+obj.cp_length)*obj.samples_per_symbol));
            else
                value = floor((obj.samples - obj.preamble_length - ((obj.number_of_pilot_frames)*(obj.nfft+obj.cp_length)*obj.samples_per_symbol) - obj.cp_length*obj.samples_per_symbol)/((obj.nfft+obj.cp_length)*obj.samples_per_symbol));
            end
        end
        
        function value = get.subcarriers(obj)
            value = obj.nfft;
        end
        
        function value = get.datalength(obj)
            % gets the number of data elements we can modulate in one go,
            % in BITS.
            value =  log2(obj.modorder) * obj.frames * ((obj.nfft-2)/2);
        end
        
        function set_powerloading(obj, profile)
            if( (numel(profile == obj.nfft/2-1)) && (min(profile) > 0) )
                profile = reshape(profile, 1, []);
                if(numel(obj.powerloading) ~= obj.nfft/2-1)
                    obj.powerloading = ones(1, obj.nfft/2-1 );
                end
                obj.powerloading = obj.powerloading .* profile;
            else
                disp('* wrong profile length or size *')
            end
        end
    end
    
    
end

