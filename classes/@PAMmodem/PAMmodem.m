classdef PAMmodem < handle 
    %PAMMODEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        samples = 2^16;
        samples_per_symbol = 5
        number_of_pilots = 100;
        freq = 100;
        modorder = 4;
        levels = 255;
        show = 1;
        showpeak = 1; 
        getspectrum = 1; 
        syncseqlen = 25; 
        filter = 1;
        filterorder = 0.9;
        minlevel = 0; 
    end
    
    properties (Dependent)
        numberSymbols
        datalength
        preamble_length
    end
    
    properties (SetAccess = private, Hidden)
        pilotqam;
        encodedData; 
        data; 
        nonexpandedsignal; 
        expandedsignal; 
        leadoutsequence; 
        pilotsequence; 
        originalSignal; 
        originalScale; 
    end
    
    methods
        function obj = PAMmodem()
        end
        
        rrcfilt = RRC(obj);
        
        wave = modulate(obj, data);
        
        [rxdata, sig_amp, sig_var, flat_noise_amp, flat_noise_var, flat_noise_psd, photon_top, photon_bot, tbits, terrors, calcterr, sampleratio, datasig, dataraw] = demodulate(obj, wave); 
        
        function value = get.numberSymbols(obj)
            value = floor((obj.samples - 3*(obj.number_of_pilots*obj.samples_per_symbol) - obj.samples_per_symbol*300)/obj.samples_per_symbol);
        end
        
        function value = get.datalength(obj) % again, in BITS. 
            value = obj.numberSymbols*log2(obj.modorder); 
        end
        
        function value = get.preamble_length(obj)
            value = 3 * obj.syncseqlen * obj.samples_per_symbol; 
        end
        
    end
    
    
    
end

