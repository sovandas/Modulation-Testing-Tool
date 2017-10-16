classdef fakechannel < handle
    %FAKECHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data
        snr = 0; 
        bias = 0; 
        freq = 100; 
        xorsim = 1;
    end
    
    properties (Hidden, SetAccess = private)
        spads = 4096;
    end
    
    methods
        
        function setdaccs(obj, cs)
        end
        
        function setsamplefreq(obj, cs)
            obj.freq = cs; 
        end
        
        function starttx(obj, cs)
        end
        
        
        function enableAllSPADs(obj, cs)
            obj.spads = 4096;
        end
        
        
        function setVoffset(obj, cs)
        end
        
        function setnoise(obj, noiselev)
            obj.snr = noiselev;
        end
        
        function setbias(obj, ch, val)
            obj.bias = val; 
        end
            
        function setdata(obj, data)
            obj.data = data; 
        end
                
        function setChipMode(obj, mode)
        end
        
        function dat = getData(obj, len)
            
            len = len * obj.freq / 100; % normalize to account for sample rate difference
            
            if(len > length(obj.data))
                fac = round(len / length(obj.data));
                rest = len - fac*length(obj.data);
                cut = round(rand(1,1) * rest);
                dat = [ones(1,cut)*mean(obj.data), repmat(obj.data,1,fac), ones(1,rest-cut)*mean(obj.data)];
            else
                rest = length(obj.data) - len;
                cut = round(rand(1,1) * rest);
                dat = obj.data(cut:cut+len);
            end
                   
            if(obj.freq < 100)
                offset = mean(dat);
                dat = dat - mean(dat);
                dat = resample(dat, 100, obj.freq); 
                dat = dat + offset; 
            end
            
            % power transfer - we 'should' get about 2000 photons / unit
            % time at 100 sample freq. dat is range 0-255, * 8 ~= 2000. 
            
            % input range is 0-255, mulfac is power in mA up to 192. 64mA -> 80
            % photons. 
                    
            % assume silly laser peroperties
            
            remove = 255 - round(255* ( (obj.bias - 48) / obj.bias ));           
            
            dat(dat < remove) = remove; 
            
            maxd = max(dat);
            dat = dat - min(dat); % make sure the signal is based at 0. 
           
%            dat = dat * maxd / max(dat); % retain range
            
            spadsperperiod = obj.spads * ((1/(obj.freq*1e6)) / 20e-9); % deadtime influences this - we assume 20ns
            
            dat = (dat .* spadsperperiod) ./ (255-remove); % rescale to spad activations per period - assume 8 bit DAC! 
            
%             
%             figure(2)
%             plot(dat)
            
            dat = awgn(dat, obj.snr, 'measured'); % actual channel noise
% 
%             figure(3)
%             plot(dat)

            
            % time jitter in PHOTONTORRENT. modelled as gaussian with 250ps
            % sd
            
            samplepoints = 1/(obj.freq*1e6):1/(obj.freq*1e6):length(dat)*1/(obj.freq*1e6);
            jitterbase = linspace(1/(obj.freq*1e6),length(dat)*1/(obj.freq*1e6),length(dat));
            jitteredsamplepoints = jitterbase + normrnd(0,250e-12,1,length(jitterbase));
            if(jitteredsamplepoints(1) < samplepoints(1))
                jitteredsamplepoints(1) = samplepoints(1);
            end
            if(jitteredsamplepoints(end) > samplepoints(end))
                jitteredsamplepoints(end) = samplepoints(end);
            end
            
            dat = interp1(samplepoints, dat, jitteredsamplepoints,'linear'); 

            dcrlevel = ((1.3664e-3 / 10e-9) * obj.spads) / (obj.freq*1e6);
            
            dat(dat < dcrlevel) = dcrlevel; 
%                         
%             figure(4)
%             plot(dat)
            
            dat = round(dat); 
            
               
%             
%             figure(5)
%             plot(dat)

            
            % SPAD receiver
            dat = poissrnd(dat); 
%                     
%             figure(6)
%             plot(dat)

            if(obj.xorsim == 1)
                
                %the limit is 1100/2 at 100 MHz 
                loglimit = (1100 / (obj.freq*1e6)) * 100e6;
                slope = -0.002 / 100e6 * (obj.freq*1e6)   ;            
                
            % logistic XOR model 
                dat = loglimit ./ (1+exp(slope.*((dat)-0)))-(loglimit/2);  
            end
            dat = round(dat); 
%             
%             figure(1)
%             
        end
        
        function close(obj)
        end
        
    end
    
end

