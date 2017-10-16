function wireindata (obj, wirename, data )
% Parse register bank to get addr, size and starting bit from the bank
% Get data from that wireout and pass back

bankindex = 0;

l = length(obj.bank);

for x = 1:l
   
    if(strcmp(wirename, obj.bank(x).name))
        bankindex = x;
        break
    end
end

% Check bank index was set
if (bankindex == 0)
   
    disp(['Error : No wire by that name exists - ' wirename])
    
else

    % If setting a data value to a bit not at zero then need to parse it
    % bit by bit.
    bit = obj.bank(bankindex).bit;
    addr = uint32(hex2dec(obj.bank(bankindex).addr));
   
    banksize = obj.bank(bankindex).size;    
    sz = 2 ^ (banksize) - 1;
    mask = uint32(bitshift(sz,bit));
    
    d = bitshift(data,bit);
 
    setwireinvalue(obj, addr, d, mask);

    updatewireins(obj);

    % Write to log
    %sprintf('- Setting wirein %s to %d', wirename, data)
    
end




end