function obj = setChipMode(obj, mode)
%SETCHIPMODE Summary of this function goes here
%   Detailed explanation goes here

%wireindata(obj.okComms, obj.bank, 'CHIP_RESET', 1)
%wireindata(obj.okComms, obj.bank, 'CHIP_RESET', 0)

wireindata(obj, 'CHIP_MODE', mode);

trigger(obj, 'SET_CHIP_MODE');

obj.mode = mode; 

disp(['set chip mode ', num2str(mode)])

end