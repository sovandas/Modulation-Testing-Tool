classdef photontorrent_ab < photontorrent
    %PHOTONTORRENT_AA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = photontorrent_ab(serial)
            if(nargin == 0)
                serial = '1447000A9T';
            end
            p = fileparts(mfilename('fullpath'));
            
            obj = obj@photontorrent(serial,[p, '\XC6SLX150-photontorrent-AB.bit'],[ p, '\ok_register_bank_photontorrent_AB.m']);
            success = 0; 
            while(success == 0)
                obj.configurefpga()
                if(obj.isopen())
                    success = configure(obj);
                else
                    disp('*no such device: 1447000A9T *');
                end
            end
            obj.setVquench(1500);
        end
        
        function display(obj)
            display@photontorrent(obj);
            stg = sprintf('          Vquench: %dV', obj.vquench/1000);
            disp(stg)
        end
    end
    
end

