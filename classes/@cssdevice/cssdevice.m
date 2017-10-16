classdef cssdevice < okusbfrontpanel
    %CSSDEVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        bank;
        bitfile;
    end
    
    methods
        function obj = cssdevice(serial, bitfile, registerfile)
            if(nargin > 2)
                run(registerfile);
            else
                run('ok_register_bank.m') % this sets the bank property
            end
            obj.bank = bank; 
            if(nargin > 1)
                obj.bitfile = bitfile;
                obj.openbyserial(serial);
                if(obj.isopen())
                    obj.configurefpga();
                end
            end
            if(nargin == 1)
                obj.bitfile = '';
                obj.openbyserial(serial);
            end
        end
        
        pipedata = blockpipeoutdata (obj, pipename, bsize, psize)
        
        function display(obj)
            display@okusbfrontpanel(obj);
        end
        
    end
end
