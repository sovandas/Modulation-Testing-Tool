function [ trig ] = trigoutdata( obj, trigname )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
bankindex = 0;
data = -1;

l = length(bank);

for x = 1:l
   
    if(strcmp(trigname, obj.bank(x).name))
        bankindex = x;
        break
    end
end

% Check bank index was set
if (bankindex == 0)
   
    disp('Error : No Trigger by that name exists')
    
else
    
    bit = obj.bank(bankindex).bit;
    addr = uint16(hex2dec(obj.bank(bankindex).addr));
   
    banksize = obj.bank(bankindex).size;    
    sz = 2 ^ (banksize) - 1;
    mask = uint16(bitshift(sz,bit));

    updatetriggerouts(obj)
    trig = istriggered(obj, addr, mask);

end

end

