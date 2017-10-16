function pipedata = blockpipeoutdata (obj, pipename, bsize, psize)
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
    
    pipedata =  readfromblockpipeout(obj, addr, 128, bsize);
    
    
end
end

