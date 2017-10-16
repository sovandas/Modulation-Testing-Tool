function pipedata = blockpipeindata (obj, pipename, bsize, data, psize)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
bankindex = 0;
pipedata = -1;

if ~exist('psize', 'var') | isempty(psize), psize = bsize; end

l = length(obj.bank);

for x = 1:l
   
    if(strcmp(pipename, obj.bank(x).name))
        bankindex = x;
        break
    end
end

% Check bank index was set
if (bankindex == 0)
   
    disp('Error : No pipe by that name exists')
    
else

    addr = uint16(hex2dec(obj.bank(bankindex).addr));
    
    pipedata = writetoblockpipein(obj, addr, bsize, data); 
    
    if (pipedata < 0)
        fprintf('Transmit error: %d\n', pipedata); 
    end
end
end

