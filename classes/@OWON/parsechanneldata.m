function [ chdata, nextoffset ] = parsechanneldata(obj, data, offset)
%PARSECHANNELDATA Summary of this function goes here
%   Detailed explanation goes here

voltindex = containers.Map( ...
[0, 1, 2 3 4 5 6 7 8 10 11 12 13 14 15 16 17 1 8 10 20], ...
[0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]); 

msindex = containers.Map( ...
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 21 22 23 24 25 26 27 28 29 30 31 32 33], ...
[0.000001, 0.0000025, 0.000005, 0.00001, 0.000025, 0.00005, 0.0001, 0.00025, 0.0005, 0.001, 0.0025, 0.005, ...
0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000] * 10^-3 ...
);

name1 = char(data(offset:offset+2));
datalength1 = abs(typecast(uint8(data(offset+3:offset+6)),'int32'));
extendedwave1 = typecast(uint8(data(offset+3:offset+6)),'int32') < 0;
extendvalue1 = typecast(uint8(data(offset+7:offset+10)),'int32');

wholescreenpoints = typecast(uint8(data(offset+11:offset+14)),'int32');

collectingpoints = typecast(uint8(data(offset+15:offset+18)),'int32');

slowmovingnumber = typecast(uint8(data(offset+19:offset+22)),'int32');

timebase = typecast(uint8(data(offset+23:offset+26)),'int32');
actualtimebase = msindex(timebase) ;

zeropoint = typecast(uint8(data(offset+27:offset+30)),'int32');

voltagebase = typecast(uint8(data(offset+31:offset+34)),'int32');
actualvoltagebase = voltindex(voltagebase);

attenuationmul =  typecast(uint8(data(offset+35:offset+38)),'int32');
attenuationmul = 10^attenuationmul;

spacinginterval =  typecast(uint8(data(offset+39:offset+42)),'single');

frequency = typecast(uint8(data(offset+43:offset+46)),'int32');

gatheringcycle = typecast(uint8(data(offset+47:offset+50)),'int32');

voltperpoint = typecast(uint8(data(offset+51:offset+54)),'single') * 1e-3;

chdata.YData = (double(typecast(uint8(data(offset+55:offset+55+collectingpoints*2-1)), 'int16')) * double(voltperpoint) * double(attenuationmul)) - (double(zeropoint) * double(voltperpoint));
chdata.XData = linspace(0,actualtimebase*10,length(chdata.YData)+1);
chdata.XData = chdata.XData(1:end-1);
chdata.zeropoint = zeropoint;
chdata.voltperpoint = voltperpoint; 
chdata.attenuation = attenuationmul;


nextoffset = offset+55+collectingpoints*2;

end

