classdef Agilent_81180A < handle
    %AGILENT_81180A Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        address
        visaobj
        channel = 1;
        txon = 0;
    end
    
    methods
        
        function obj = Agilent_81180A(address)
            
            obj.address = address;
            obj.connect();
            
        end
        
        function connect(obj)
            
            props = regexp(obj.address,'::','split');
            obj.visaobj = instrfind('Type', 'tcpip', 'RemoteHost', props{2}, 'RemotePort', str2num(props{3}));
            % Create the VISA object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.visaobj),
                obj.visaobj = tcpip(props{2},str2num(props{3}));
            else
                fclose(obj.visaobj);
                obj.visaobj = obj.visaobj(1);
            end
            % Set the buffer size
            obj.visaobj.OutputBufferSize = 80000000;
            try
                
                fopen(obj.visaobj);
            catch ME
                if(strcmp(ME.identifier, 'instrument:fopen:opfailed'))
                    disp(['Failed to connect to ' obj.address ': operation time out']);
                    return;
                else
                    rethrow(ME)
                end
            end
            
            fprintf(obj.visaobj, '*RST'); % Reset instrument
            operationComplete = str2double(query(obj.visaobj,'*OPC?'));
            while ~operationComplete
                operationComplete = str2double(query(obj.visaobj,'*OPC?'));
            end
            
            fprintf(obj.visaobj, ':INST:COUP:STAT ON'); % Couple sampling clock on channels
            
        end
        
        function setdccs(obj, val)
            if(~obj.txon)
                obj.channel = val;
            end
        end
        
        
        function enableexternalsync(obj)
            if(~(isempty(obj.visaobj)) && strcmp(obj.visaobj.Status, 'open'))
                fprintf(obj.visaobj, ':SOUR:ROSC:SOUR EXT'); % Set oscillator clock to EXT
                fprintf(obj.visaobj, ':SOUR:ROSC:EXT:FREQ 10e6'); % Set frequency to 10MHz
            else
                disp('operation failed: not connected')
            end
        end
        
        function setbias(obj,channel,value)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                
                fprintf(obj.visaobj,[':INST:SEL CH' num2str(channel)]);
                fprintf(AWGObj,[':VOLTage:OFFSet ' num2str(value)]);
                
            else
                disp('operation failed: not connected')
            end
        end
        
        function setoffset(obj, channel, value)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                
                fprintf(obj.visaobj,[':INST:SEL CH' num2str(channel)]);
                fprintf(obj.visaobj,[':VOLT ' num2str(value)]);
                
            else
                disp('operation failed: not connected')
            end
        end
        
        function realsamplerate = setsamplefreq(obj, samplerate)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                
                realsamp = samplerate*1e6;
                
                if(realsamp < 10e6)
                    realsamp = 10e6;
                end
                if(realsamp > 4.2e9)
                    realsamp = 4.2e9;
                end
                
                for(i = 1:2)
                    fprintf(obj.visaobj,[':INST:SEL CH' num2str(i)]);
                    realsampret = query(obj.visaobj, sprintf(':FREQ:RAST %d', realsamp));
                end
                realsamplerate = realsampret / 1e6;
                
            else
                disp('operation failed: not connected')
                realsamplerate = 0;
            end
        end
        
        function starttx(obj)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                for(i = 1:2)
                    if(bitset(obj.channel,i))
                        fprintf(obj.visaobj,[':INST:SEL CH' num2str(i)]);
                        fprintf(obj.visaobj, ':FUNC:MODE USER');
                        fprintf(obj.visaobj, sprintf(':TRAC:SEL %d', 1));
                        fprintf(obj.visaobj, ':OUTP ON');
                    end
                end
                obj.txon = 1;
            else
                disp('operation failed: not connected')
            end
        end
        
        function stoptx(obj)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                for(i = 1:2)
                    if(bitset(obj.channel,i))
                        fprintf(obj.visaobj,[':INST:SEL CH' num2str(i)]);
                        fprintf(obj.visaobj, ':OUTP OFF');
                    end
                end
                obj.txon = 0;
            else
                disp('operation failed: not connected')
            end
        end
        
        
        function success = setdata(obj,data)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                
                % data is in some range.
                % need it to be in [0,4095]
                
                data = data - min(data);
                data = data * 4095 / max(data);
                data = round(data);
                
                dataAsUint = swapbytes(uint16(data));
                
                % select output
                
                % select and define segment number
                fprintf(obj.visaobj, sprintf(':TRAC:DEF %d,%d', 1, length(data)));
                binblockwrite(obj.visaobj, dataAsUint, 'uint16', ':TRAC:DATA ');
                fprintf(obj.visaobj, '');  % complete the binblock command
                % turn the output on
                operationComplete = str2double(query(obj.visaobj,'*OPC?'));
                while ~operationComplete
                    operationComplete = str2double(query(obj.visaobj,'*OPC?'));
                end
                
                success = 1;
                
            else
                disp('operation failed: not connected')
                success = 0;
            end
        end
        
        function close(obj)
            if(~(isempty(obj.visaobj))&& strcmp(obj.visaobj.Status, 'open'))
                fclose(obj.visaobj);
                disp('Closed file handle to instrument')
            end
        end
        
        
        
    end
    
end

