classdef OWON < handle
    %OWON Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        
        so
        
    end
    
    methods
        function obj = OWON(port)
            
            if(nargin > 0)
                so =  serial(port);
            else
                so = serial('COM1');
            end
            
            disp('Created Serial object')
            
            so.BaudRate = 115200;
            so.InputBufferSize = 2048;
            fopen(so);
            obj.so = so; 
            disp('Opened serial port')
            
        end
        
        function delete(obj)
            fclose(so);
        end
        
        function [waveform1, waveform2] = getData(obj)
            [fn, dl, d] = receivedatafile(obj); 
            [waveform1, waveform2] =  parsescopedata(obj, d);             
        end
        
        function [waveform] = getDifferential(obj)
            [waveform1, waveform2] = getData(obj);
            
            waveform1.YData = waveform1.YData - waveform2.YData;
            
            waveform = waveform1;
        end
        
    end
    
    methods (Access = private)
        
        [fn, dl, d] = receivedatafile(obj);
        
        [chdata1, chdata2] = parsescopedata(obj, d);
        
        [data, crc] = getpacket(obj);
        
        [chdata, nextoffset] = parsechanneldata(obj, d, offset); 
        
    end
    
end

