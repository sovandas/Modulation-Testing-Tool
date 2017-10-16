function trigger (obj, ProgResetDACName)
% Toggle trigger

bankindex = 0;

l = length(obj.bank);

for x = 1:l
   
    if(strcmp(ProgResetDACName, obj.bank(x).name))
        bankindex = x;
        break
    end
end

% Check bank index was set
if (bankindex == 0)
   
    disp('Error : No wire by that name exists')
    
else

    addr = uint16(hex2dec(obj.bank(bankindex).addr));
    bit = obj.bank(bankindex).bit;
    % Trigger bit zero for programme / bit one for reset
    activatetriggerin(obj, addr, bit);

end



end
