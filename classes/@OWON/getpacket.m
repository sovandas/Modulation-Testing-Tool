function [ data, crc ] = getpacket( obj )
%GETPACKET Summary of this function goes here
%   Detailed explanation goes here

data = [];
crc = []; 

so = obj.so; 

tic
while(so.BytesAvailable < 3)
   if(toc > 3)
       return;
   end
end

dat = fread(so,3);

type = dat(1);

if(type == 1)
    len = 128 + 2;
end
if(type == 2)
    len = 1024+2;
end

while(so.BytesAvailable < len)
end

data = fread(so,len);

crc = data(end-1:end);
data = data(1:end-2);

fwrite(so,6);

end

