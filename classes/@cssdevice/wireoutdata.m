function data = wireoutdata (obj, wirename )
% Parse register bank to get addr, size and starting bit from the bank
% Get data from that wireout and pass back

bankindex = 0;
data = -1;

l = length(obj.bank);

for x = 1:l
   
    if(strcmp(wirename, obj.bank(x).name))
        bankindex = x;
        break
    end
end

% Check bank index was set
if (bankindex == 0)
   
    disp('Error : No wire by that name exists')
    
else
    
    updatewireouts(obj);
    
    addr = uint16(hex2dec(obj.bank(bankindex).addr));
    readvalue = getwireoutvalue(obj, addr);
    bs = obj.bank(bankindex).bit * (-1);
    data = bitshift(readvalue,bs);
    
    % Write to log
    %sprintf('- Wireout %s is value %d', wirename, data)

end

end

