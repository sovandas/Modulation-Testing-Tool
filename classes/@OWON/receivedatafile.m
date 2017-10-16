function [filename, datalength, data] = receivedatafile(obj)
%RECEIVEDATAFILE Summary of this function goes here
%   Detailed explanation goes here

% request initial file - has filename and file length

so = obj.so;

data = []; 
while(isempty(data))
    flushinput(so)
    fwrite(so,'C');
    [data, crc] = getpacket(obj); 
end    

i = 1;
while(data(i) ~= 0)
    i = i + 1;
end
i = i -1;
filename = reshape(char(data(1:i)),1,[]);

start = i+2;
i = start;
while(data(i) ~=0 )
    i = i + 1;
end
datalength = str2double(reshape(char(data(start:i)),1,[]));

% request the file contents

fwrite(so,'C');

flen = 0;

fd = []; 

while(flen <= datalength)
    [data,crc] = getpacket(obj); 
    if(isempty(data))
        data = [];
        return;
    end
    fd = [fd data'];
    flen = length(fd);
end

data = fd; 


end

