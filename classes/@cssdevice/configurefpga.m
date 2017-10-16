function obj = configurefpga(obj)
%CONFIGUREFPGA Summary of this function goes here
%   Detailed explanation goes here

if(obj.isopen() == 1)
    if(isempty(obj.bitfile))
        disp('* No bitfile specified. not programmed. use setbitfile() instead. *')
    else
        configurefpga@okusbfrontpanel(obj, obj.bitfile); 

    end
end
end

