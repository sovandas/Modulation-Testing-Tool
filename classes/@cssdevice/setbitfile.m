function [ obj ] = setbitfile( obj, bitfile )
%SETBITFILE Summary of this function goes here
%   Detailed explanation goes here

obj.bitfile = bitfile;

if(obj.isopen() == 1)
    obj.configurefpga(); 
end

end
