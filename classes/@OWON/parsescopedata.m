function [ch1, ch2] = parsescopedata( obj, data )
%PARSESCOPEDATA Summary of this function goes here
%   Detailed explanation goes here


model = char(data(1:6));

if(model(5) == '0')
    screenw = 500;
    screenh = 400;
end
if(model(5) == '1')
    screenw = 300;
    screenh = 200;
end

filelength = typecast(uint8(data(7:10)),'int32');

[ch1,nextoffset] = parsechanneldata(obj, data, 11);
ch2 = parsechanneldata(obj, data, nextoffset); 

end

