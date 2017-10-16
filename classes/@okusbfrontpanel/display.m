function display(obj)

%DISPLAY  Display an okfrontpanel object.
%
%  Copyright (c) 2005 Opal Kelly Incorporated
%  $Rev: 424 $ $Date: 2006-12-18 20:27:54 -0800 (Mon, 18 Dec 2006) $

if (0 == isopen(obj))
    devices = getdevicecount(obj);
	fprintf('No device open. %d connected devices.\n', devices);
    if(devices >= 1)
        for(i = 1:devices)
            board = getdevicelistmodel(obj,i-1);
            serial = getdevicelistserial(obj,i-1); 
            fprintf('           Device: %s\n', num2str(i-1)); 
            fprintf('      Board model: %s\n', board);
            fprintf('    Serial number: %s\n', serial); 
        end
    end
else
	stg = sprintf('      Board model: %s', getboardmodel(obj));
	disp(stg)
	stg = sprintf('Firmware revision: %d.%d', ...
		getdevicemajorversion(obj), getdeviceminorversion(obj));
	disp(stg)
	stg = sprintf('    Serial number: %s', getserialnumber(obj));
	disp(stg)
	stg = sprintf('        Device ID: %s', getdeviceid(obj));
	disp(stg)
end
