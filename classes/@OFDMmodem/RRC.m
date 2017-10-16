function [ rrcfilt ] = RRC(obj )
%RRC Summary of this function goes here
%   Detailed explanation goes here

%%%% Define the RRC filter

symbol_rate=1;
Ts=1/symbol_rate; %symbol period
Sf=obj.samples_per_symbol/Ts; % Sampling frequency (does the oversampling)

lb=-16*Ts; %Lower bound of the RRC filter impulse response (clipped beyond this value)
ub=(15+15/16)*Ts; %Upper bound of the RRC filter impulse response (clipped beyond this value)
t = [lb:1/Sf:ub];
beta = obj.filterorder; %roll-off factor (1+beta)*1/(2*Ts) gives the used bandwidth

[dummy,middle_value] = min(abs(t));
rrcfilt = (sin(pi*t/Ts*(1-beta)) + 4*beta*t/Ts.*cos(pi*t/Ts*(1+beta)))./(pi*t/Ts.*(1-(4*beta*t/Ts).^2));
rrcfilt(middle_value(1)) = 1-beta+4*beta/pi;
[dummy,first_special_value] = min(abs(t+Ts/(4*beta)));
[dummy,second_special_value] = min(abs(t-Ts/(4*beta)));
rrcfilt(first_special_value) = beta/sqrt(2)*((1+2/pi)*sin(pi/(4*beta)) + (1-2/pi)*cos(pi/(4*beta)));
rrcfilt(second_special_value) = beta/sqrt(2)*((1+2/pi)*sin(pi/(4*beta)) + (1-2/pi)*cos(pi/(4*beta)));
rrcfilt=rrcfilt/sqrt(Ts);

end

