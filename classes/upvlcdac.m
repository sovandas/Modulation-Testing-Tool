classdef upvlcdac < cssdevice
    %UPVLCDAC Class for accessing a specific OK instance.
    %   contains routies that ONLY make sense with the associated firmware.
    %
    
    properties
        channel1;
        channel2;
        channel3;
        channel4;
    end
    
    properties (SetAccess = private)
        daccs = 15;
        swing = [16, 16, 16, 16];
        offset = [0 0 0 0];        
    end
    methods
        function obj = upvlcdac(serial)
            if(nargin == 0)
                serial = '1447000A98';
            end
            p = fileparts(mfilename('fullpath'));
            obj = obj@cssdevice(serial,[p '\XC6SLX150-upvlcdac.bit'],[p '\ok_register_bank_upvlcdac.m']);
            success = 0;
            while(success == 0)
                obj.configurefpga()
                if(obj.isopen())
                    success = configure(obj);
                else
                    disp('*no such device: 1447000A98 *');
                    success = 0;
                end
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function success = configure(obj)
            success = 0;
            fprintf('Firmware Revision: %d\n', obj.wireoutdata('FIRMWARE_REVISION'));
            
            obj.wireindata('ACTIVATE_DAC', 1); % does nothing!
            obj.wireindata('TRANSMIT', 0);
            obj.wireindata('EMPTY', 0);
            obj.wireindata('GANG_MIMO', 0);
            obj.wireindata('SYS_RESET', 1);
            pause on
            pause(1)
            obj.wireindata('SYS_RESET', 0);
            
            status = obj.wireoutdata('DRIVER_STATUS');
            timeout = 0;
            while(status ~= 11) % bit 0 set, bit1 set, bit 3 set = reset_config done, fifo_is empty, not transmitting, locked to PLL, not in mimo mode
                pause(0.1)
                timeout = timeout +1;
                if(timeout == 200)
                    success = 0;
                    return;
                end
                status = obj.wireoutdata('DRIVER_STATUS');
            end
            
            obj.wireindata('DRIVER_DAC_CS', 15); % enables DACs via the external LVDS interface
            
            obj.daccs = 15; 
            
            obj.wireindata('DAC_SEL', 3); % enables dacs via the internal shift register interface
            
            obj.wireindata('DAC1_DC_OFFSET0', 0); % sets the offset, i.e. the distance from 0 to the minumum signal level. in steps of 8mA.
            obj.wireindata('DAC2_DC_OFFSET0', 0);
            obj.wireindata('DAC3_DC_OFFSET0', 0);
            obj.wireindata('DAC4_DC_OFFSET0', 0);
            
            obj.offset = [0 0 0 0];
            
            obj.wireindata('DAC1_BIAS', 15); % sets the output swing in steps of 16mA. 15 = 16mA, 0 = 256 mA.
            obj.wireindata('DAC2_BIAS', 15);
            obj.wireindata('DAC3_BIAS', 15);
            obj.wireindata('DAC4_BIAS', 15);
            
            obj.swing = [16 16 16 16]; 
            
            obj.wireindata('DEM_EN', 0); % not used really.
            
            obj.wireindata('CLK_SEL',0);
            
            obj.trigger('CONFIGURE_SHIFT_REG');
            pause(0.5);
            success = 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setdaccs(obj, select)
            status = obj.wireoutdata('DRIVER_STATUS');
            restarttx = 0;
            if(bitand(status, 4)) % bit 2 is 'transmit'
                restarttx = 1;
                obj.wireindata('TRANSMIT', 0);
            end
            pause(0.1);
            select = round(select);
            if((select > -1) && (select < 16))
                obj.wireindata('DRIVER_DAC_CS', select);
            end
            pause(0.1)
            if(restarttx == 1)
                obj.wireindata('TRANSMIT', 1);
            end
            
            obj.daccs = select; 
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setdacsel(obj, select)
            status = obj.wireoutdata('DRIVER_STATUS');
            restarttx = 0;
            if(bitand(status, 4)) % bit 2 is 'transmit'
                restarttx = 1;
                obj.wireindata('TRANSMIT', 0);
            end
            
            if(select == 3)
                obj.wireindata('DAC_SEL', 3);
            end
            if(select == 2)
                obj.wireindata('DAC_SEL', 2);
            end
            if(select == 1)
                obj.wireindata('DAC_SEL', 1);
            end
            if(select == 0)
                obj.wireindata('DAC_SEL', 0);
            end
            obj.trigger('CONFIGURE_SHIFT_REG');
            pause on;
            pause(0.1);
            if(restarttx == 1)
                obj.wireindata('TRANSMIT', 1);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setoffset(obj, channel, level) % sets level in mA
            
            level = round(level);
            
            %if(level >= 16)
                if(level >= 128)
                    level = 15; 
                else
                    level = floor(level/8); 
                end
            %end
            if(level < 0)
                level = 0;
            end
            
            if(channel == 1)
                obj.wireindata('DAC1_DC_OFFSET0', level);
            end
            if(channel == 2)
                obj.wireindata('DAC2_DC_OFFSET0', level);
            end
            if(channel == 3)
                obj.wireindata('DAC3_DC_OFFSET0', level);
            end
            if(channel == 4)
                obj.wireindata('DAC4_DC_OFFSET0', level);
            end
            fprintf('set channel %i to %i mA offset\n', channel, 8 * level); 
            obj.offset(channel) = 8 * level; 
            obj.trigger('CONFIGURE_SHIFT_REG');
        end
        
        %%%%%%%%%%%%%%%%%%%%%
        
        function setbias(obj, channel, level) % sets output swing
            
            level = round(level); 
            
            %if(level >= 16) % more than 16, assume we meant mA directly
                if(level > 256)
                    level = 0;
                elseif(level < 16)
                    level = 15;
                else
                    level = 16 - floor(level/16);
                end
            %end
            if(channel == 1)
                obj.wireindata('DAC1_BIAS', level);
            end
            if(channel == 2)
                obj.wireindata('DAC2_BIAS', level);
            end
            if(channel == 3)
                obj.wireindata('DAC3_BIAS', level);
            end
            if(channel == 4)
                obj.wireindata('DAC4_BIAS', level);
            end
            fprintf('set channel %i to %i mA swing\n', channel, (16 - level)*16);
                
            obj.swing(channel) = (16 - level)*16; 
            
            obj.trigger('CONFIGURE_SHIFT_REG');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
        function realsamplerate = setsamplefreq(obj, samplerate)

            if(samplerate > 475)
                samplerate = 475;
            end
            
            lookuptab = [950,900,850,800,750,700,650,550]';
            for(i = 2:63)
                lookuptab = [lookuptab, lookuptab(:,1)/i];
            end
            
            delta = max(max(lookuptab));
            loc = [0,0];
            
            for i = 1:size(lookuptab,1)
                for(j = 1:size(lookuptab,2))
                    diff = abs(samplerate - lookuptab(i,j));
                    if(diff <= delta)
                        loc = [i,j];
                        delta = diff;
                    end
                end
            end
            
            % at this point we know that the minimum difference is
            % delta and the location
            % now derive the divider and the base f
            
            divider = loc(2);
            baseidx = loc(1);
            base = lookuptab(loc(1),1);
            
            fprintf('Setting sample rate of %d MHz (%d base divided by %d)\n', lookuptab(baseidx,divider), base, divider);
            if(delta ~= 0)
                fprintf('This is the closest available approximation to the requested %d MHz\n', samplerate);
            end
            
            realsamplerate = lookuptab(baseidx,divider); 
            
            fset = baseidx-1;
            
            status = obj.wireoutdata('DRIVER_STATUS');
            restarttx = 0;
            if(bitand(status, 4)) % bit 2 is 'transmit'
                restarttx = 1;
                obj.wireindata('TRANSMIT', 0);
            end
            
            wireindata(obj, 'CLOCK_DIVIDE',divider);
            wireindata(obj, 'CLOCK_MODE', fset);
            trigger(obj, 'SET_CLOCK_MODE');
            
            %% wait for lock again
            status = obj.wireoutdata('DRIVER_STATUS');
            while(bitand(status, 8) == 0)
                status = obj.wireoutdata('DRIVER_STATUS');
            end
            
            if(restarttx)
                obj.wireindata('TRANSMIT', 1);
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%
        
        function success = setdata(obj, data)
            % data is in the range of 0-255.
            %data = uint8(data);
            data = reshape(data,1,[]);
            if( mod(size(data,2),256) > 0 )
                data = [data ones(1,  256 - mod(size(data,2),256) )*mean(data)];
            end
            
            if(size(data) <= (2^17+2^15))
                
                status = obj.wireoutdata('DRIVER_STATUS');
                
                restarttx = 0;
                if(bitand(status, 4)) % bit 2 is 'transmit'
                    restarttx = 1;
                    obj.wireindata('TRANSMIT', 0);
                end
                
                % empty the device FIFO
                %obj.wireindata('TRANSMIT', 0);
                obj.wireindata('EMPTY', 1);
                
                status = obj.wireoutdata('DRIVER_STATUS');
                
                while(bitand(status, 2) == 0) % bit 1 is 'empty' from the FIFO
                    status = obj.wireoutdata('DRIVER_STATUS');
                end
                
                obj.wireindata('EMPTY', 0);
                
                %% upload the new data
                
                txfer = blockpipeindata(obj,'SIGNAL_MEMORY',64,data);
                
                fprintf('transferred %d bytes\n', txfer);
                
                if(restarttx)
                    obj.wireindata('TRANSMIT', 1);
                end
                success = 1; 
            else
                fprintf('data too long: %d bytes\n', size(data,2));
                success = 0; 
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%
        
        function starttx(obj)
            obj.wireindata('TRANSMIT', 1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%
        
        function stoptx(obj)
            obj.wireindata('TRANSMIT', 0);
        end
        
        %%%%%%%%%%%%%%%%%%%
        
        function obj = setchanneldata(obj)
            
       
            
            outpdata = zeros(1,max([size(obj.channel1,2), size(obj.channel2,2), size(obj.channel3,2), size(obj.channel4,2)])*4);
            
            outpdata(1:4:(length(obj.channel1)*4)) = obj.channel1;
            outpdata(2:4:(length(obj.channel2)*4+1)) = obj.channel2;
            outpdata(3:4:(length(obj.channel3)*4+2)) = obj.channel3;
            outpdata(4:4:(length(obj.channel4)*4+3)) = obj.channel4;
            
            fprintf('data length is %d bytes\n', size(outpdata,2));
            
            % scale to 0-255 incl
            outpdata = outpdata - min(outpdata);
            outpdata = (outpdata * 255) / max(outpdata);

            status = obj.wireoutdata('DRIVER_STATUS');
            
            restarttx = 0;
            if(bitand(status, 4)) % bit 2 is 'transmit'
                restarttx = 1;
                obj.wireindata('TRANSMIT', 0);
            end     
            setmimomodeon(obj);
            
            setdata(obj, outpdata);
            if(restarttx)
                obj.wireindata('TRANSMIT', 1);
                pause(0.1);
            end
            
        end
        %%%%%%%%%%%%%%%%%%%
        function setmimomodeon( obj) %% set the mimo mode to 1, e.g. each DAC gets every 4th sample
            obj.wireindata('CLK_SEL',2); % divide by 4 internally
            obj.wireindata('GANG_MIMO', 1);
            obj.trigger('CONFIGURE_SHIFT_REG');
            pause(0.2)
        end
        %%%%%%%%%%%%%%%%
        function setmimomodeoff( obj) %% set the mimo mode off, e.g. each dac gets every sample.
            obj.wireindata('CLK_SEL',0); % no internal divide
            obj.wireindata('GANG_MIMO', 0);
            obj.trigger('CONFIGURE_SHIFT_REG');
            pause(0.2)
        end
        
        function set.channel1(obj, data)
            if(numel(data) > (2^15+2^13))
                fprintf('channel 1 data too long: %d bytes. concatenated to %d bytes..\n', numel(data), 2^15+2^13);
                obj.channel1 = data(1:(2^15+2^13));
            else
                obj.channel1 = data;
            end
        end
        function set.channel2(obj, data)
            if(numel(data) > (2^15+2^13))
                fprintf('channel 2 data too long: %d bytes. concatenated to %d bytes..\n', numel(data), 2^15+2^13);
                obj.channel2 = data(1:(2^15+2^13));
            else
                obj.channel2 = data;
            end
        end
        function set.channel3(obj, data)
            if(numel(data) > (2^15+2^13))
                fprintf('channel 3 data too long: %d bytes. concatenated to %d bytes..\n', numel(data), 2^15+2^13);
                obj.channel3 = data(1:(2^15+2^13));
            else
                obj.channel3 = data;
            end
        end
        function set.channel4(obj, data)
            if(numel(data) > (2^15+2^13))
                fprintf('channel 4 data too long: %d bytes. concatenated to %d bytes..\n', numel(data), 2^15+2^13);
                obj.channel4 = data(1:(2^15+2^13));
            else
                obj.channel4 = data;
            end
        end
        
        function display(obj)
            display@cssdevice(obj)
            for(i = 1:4)
                ena = bitget(obj.daccs, i);
                status = 'off';
                if(ena == 1)
                    status = 'on';
                end
                stg = sprintf('        Channel %d: %s, %d mA swing, %d mA offset', i, status, obj.swing(i), obj.offset(i));
                disp(stg)
            end
        end
        
    end
    
end
