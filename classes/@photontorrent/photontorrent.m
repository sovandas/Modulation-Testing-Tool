classdef photontorrent < cssdevice
    %PHOTONTORRENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        SPADarray = ones(64,64);
        mode = 3;
        voffset = 1000;
        vxor = 1200;
        vbias = 1200;
        vquench = 1200;
    end
    
    methods
        
        function obj = photontorrent(serial, bitfile, bankfile)
            if(nargin == 0)
                p = fileparts(mfilename('fullpath'));
                serial = '1447000A9T';
                bitfile = [p '\..\XC6SLX150-photontorrent.bit'];
                bankfile = [p '\..\ok_register_bank_photontorrent.m'];
            end
            
            
            
            obj = obj@cssdevice(serial,bitfile,bankfile);
            success = 0;
            while(success == 0)
                obj.configurefpga()
                if(obj.isopen())
                    success = configure(obj);
                else
                    disp(['*no such device: ', serial, '*']);
                end
            end
            
        end
        
        function success = configure(obj)
            
            fprintf('Firmware Revision: %d\n', obj.wireoutdata('FIRMWARE_REVISION'));
            
            wireindata(obj, 'CHIP_RESET', 1)
            pause on
            pause(0.25)
            pause off
            wireindata(obj, 'CHIP_RESET', 0)
            
            wireindata(obj, 'LHSDATA_LSB',bin2dec('11111111111111111111111111111111'));
            wireindata(obj, 'LHSDATA_MSB',bin2dec('11111111111111111111111111111111'));
            wireindata(obj, 'RHSDATA_LSB',bin2dec('11111111111111111111111111111111'));
            wireindata(obj, 'RHSDATA_MSB',bin2dec('11111111111111111111111111111111'));
            wireindata(obj, 'ROWDATATOP',bin2dec('11111111111111111111111111111111'));
            wireindata(obj, 'ROWDATABOT',bin2dec('11111111111111111111111111111111'));
            
            obj.setChipMode(obj.mode);
            
            obj.SetSPADs();
            
            obj.setVoffset(obj.voffset);
            obj.setVxor(obj.vxor);
            obj.setVbias(obj.vbias);
            
            %trigger(obj.okComms, obj.bank, 'PROGRAM_LSR')
            
            %obj.DisableAllSPADs;
            
            %pause on
            %pause(1)
            %pause off
            
            pause on
            pause(1)
            pause off
            success = 1;
        end
        
        function obj = setVoffset(obj, value)
            wireindata(obj, 'VSPADOFF_VOLTAGE', value);
            
            trigger(obj, 'PROGRAM_VHV');
            obj.voffset = value;
            disp(['set VSPADOFF to ', num2str(value / 1000), ' V'])
        end
        
        function obj = setVxor(obj, value)
            wireindata(obj, 'VXOR_VOLTAGE', value);
            
            trigger(obj, 'PROGRAM_VHV');
            obj.vxor = value;
            disp(['set VXOR to ', num2str(value / 1000), ' V'])
        end
        
        function obj = setVbias(obj, value)
            wireindata(obj, 'VBIAS_VOLTAGE', value);
            
            trigger(obj, 'PROGRAM_VHV');
            obj.vbias = value;
            disp(['set VBIAS to ', num2str(value / 1000), ' V'])
        end
        
        function obj = setVquench(obj, value)
            wireindata(obj, 'VQUENCH_VOLTAGE', value);
            
            trigger(obj, 'PROGRAM_VHV');
            obj.vquench = value;
            disp(['set VQUENCH to ', num2str(value / 1000), ' V'])
        end
        
        function obj = SetVHV( obj, value )
            %SETVHV Summary of this function goes here
            %   Detailed explanation goes here
            
            wireindata(obj, 'VHV_BASE_VOLTAGE', value);
            
            trigger(obj, 'PROGRAM_VHV');
            
            disp(['set VHV to ', num2str( (double(value) / 1000) * (100/(27/2)) ), ' V'])
            
        end
        
        function obj = disableAllSPADs( obj )
            %DISABLESPADS Summary of this function goes here
            %   Detailed explanation goes here
            
            obj.SPADarray = zeros(64,64);
            obj.SetSPADs;
        end
        function obj = enableAllSPADs( obj )
            %DISABLESPADS Summary of this function goes here
            %   Detailed explanation goes here
            
            obj.SPADarray = ones(64,64);
            obj.SetSPADs;
        end
        
        function setspadarray(obj, array)
            if(size(array) ~= [64, 64])
                return;
            end
            if(max(array) > 1)
                return
            end
            if(min(array) < 0)
                return
            end
            array = round(array);
            obj.SPADarray = array;
            obj.SetSPADs; 
        end
        
        function obj = SetSPADs(obj)
            %SETSPADS Programme the SPAD array given a 32x32 map of 1s,0s
            %   Detailed explanation goes here
            
            map = obj.SPADarray;
            
            ptime = 0.005;
            
            if size(map) == [64 64],
                for cur_row = 1:32
                    
                    pause on;
                    % set write enables to 0
                    wireindata(obj, 'ROWDATATOP',0);
                    wireindata(obj,'ROWDATABOT',0);
                    
                    trigger(obj, 'PROGRAM_LSR');
                    pause(ptime)
                    % set the data to program
                    col1 = bin2dec(num2str(map(cur_row,1:32), '%i'));
                    col2 = bin2dec(num2str(map(cur_row,33:64), '%i'));
                    wireindata(obj,'LHSDATA_LSB',col1);
                    wireindata(obj,'LHSDATA_MSB',col2);
                    col1 = bin2dec(num2str(map(cur_row+32,1:32), '%i'));
                    col2 = bin2dec(num2str(map(cur_row+32,33:64), '%i'));
                    wireindata(obj,'RHSDATA_LSB',col1);
                    wireindata(obj,'RHSDATA_MSB',col2);
                    
                    trigger(obj, 'PROGRAM_LSR');
                    pause(ptime)
                    %set the column program enables
                    
                    wireindata(obj,'ROWDATATOP',2^(cur_row-1));
                    wireindata(obj,'ROWDATABOT',2^(cur_row-1));
                    
                    trigger(obj, 'PROGRAM_LSR');
                    pause(ptime)
                    
                    %
                    
                    
                end
                
                % set the write enables to 0 again to not write to any line.
                
                wireindata(obj,'ROWDATATOP',0);
                wireindata(obj,'ROWDATABOT',0);
                
                trigger(obj, 'PROGRAM_LSR');
                pause(ptime)
                % enable the column output muxes.
                
                wireindata(obj,'LHSDATA_LSB',2^32-1);
                wireindata(obj,'LHSDATA_MSB',2^32-1);
                wireindata(obj,'RHSDATA_LSB',2^32-1);
                wireindata(obj,'RHSDATA_MSB',2^32-1);
                
                trigger(obj, 'PROGRAM_LSR');
                pause(ptime)
                % trigger the column mux programming
                %    trigger(obj.okComms, obj.bank, 'PROGRAM_ROWDATA');
                
                disp(' * SPAD array updated on sensor.');
                pause  off
                
            else
                
                
                disp('SPAD map needs to be 64x64');
            end
        end
        
        obj = getData(obj, samples);
        
        obj = getnoxordata(obj, samples, prelude);
        
        obj = setChipMode(obj, mode);
        
        function status = readstatus(obj)
            status = wireoutdata(obj , 'STATUS_BITS');
        end
        
        function display(obj)
            display@cssdevice(obj);
            stg = sprintf('        Chip Mode: %d', obj.mode);
            disp(stg)
            stg = sprintf('      SPAD offset: %dV', obj.voffset/1000);
            disp(stg)
            stg = sprintf('         XOR tree: %dV', obj.vxor/1000);
            disp(stg)
            stg = sprintf('         DAC Bias: %dV', obj.vbias/1000);
            disp(stg)
            
        end
        
        function rate = getSampleRate(obj)
            switch(obj.mode)
                case(3)
                    rate = 100e6;
                case(5)
                    rate = 50e6;
                case(6)
                    rate = 25e6;
                case({16,17,18,19,20,21,22,23})
                    rate = 200e6;
                case({24,25,26,27,28,29,30,31})
                    rate = 400e6;
            end
        end
        
    end
    
end

