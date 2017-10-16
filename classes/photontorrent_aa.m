classdef photontorrent_aa < photontorrent
    %PHOTONTORRENT_AA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = photontorrent_aa(serial)
            if(nargin == 0)
                serial = '1447000A9T';
            end
            p = fileparts(mfilename('fullpath'));
            
            obj = obj@photontorrent(serial,[p, '\XC6SLX150-photontorrent-AA.bit'],[ p, '\ok_register_bank_photontorrent_AA.m']);
            %          success = 0;
            %          while(success == 0)
            %              obj.configurefpga()
            %               if(obj.isopen())
            %                    success = configure(obj);
            %                else
            %                    disp(['*no such device: ', serial, '*']);
            %                end
            %            end
        end
        
    end
    
end

