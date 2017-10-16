function [result] = MIMO_recover_ofdm_signal(input, offset_position, filter_type, roll_off_factor, Frames, Nfft, CP, samples_per_symbol)

%%%% Define the RRC filter

symbol_rate=1;
Ts=1/symbol_rate; %symbol period
Sf=samples_per_symbol/Ts; % Sampling frequency (does the oversampling)

lb=-16*Ts; %Lower bound of the RRC filter impulse response (clipped beyond this value)
ub=(15+15/16)*Ts; %Upper bound of the RRC filter impulse response (clipped beyond this value)
t = [lb:1/Sf:ub];
beta = roll_off_factor; %roll-off factor (1+beta)*1/(2*Ts) gives the used bandwidth

[dummy,middle_value] = min(abs(t));
p7 = (sin(pi*t/Ts*(1-beta)) + 4*beta*t/Ts.*cos(pi*t/Ts*(1+beta)))./(pi*t/Ts.*(1-(4*beta*t/Ts).^2));
p7(middle_value(1)) = 1-beta+4*beta/pi;
[dummy,first_special_value] = min(abs(t+Ts/(4*beta)));
[dummy,second_special_value] = min(abs(t-Ts/(4*beta)));
p7(first_special_value) = beta/sqrt(2)*((1+2/pi)*sin(pi/(4*beta)) + (1-2/pi)*cos(pi/(4*beta)));
p7(second_special_value) = beta/sqrt(2)*((1+2/pi)*sin(pi/(4*beta)) + (1-2/pi)*cos(pi/(4*beta)));
p7=p7/sqrt(Ts);

square_pulse = ones(1,floor(Ts*Sf));

if filter_type==0 %This is the case without pulse shaping
    
    
    dco_ofdm_pilot_distorted = input(offset_position+1:Ts*Sf:(Nfft+CP)*Ts*Sf*Frames+offset_position); %Downsample the match-filtered signal
    result = MIMO_ofdm_demodulate_real(dco_ofdm_pilot_distorted,Nfft,CP); %Demodulate the downsampled OFDM signal
    
end
if filter_type==1 %This is the case with a RRC filter
     
    [dummy,sample_position] = max(p7); %Find the position of the middle value of the RRC filter
    dco_ofdm_pilot_filtered = conv(input,p7)/Sf; %Match filter the signal with a RRC filter
    dco_ofdm_pilot_distorted = dco_ofdm_pilot_filtered(2*sample_position+offset_position-1:Ts*Sf:(Nfft+CP)*Ts*Sf*Frames+2*sample_position-1+offset_position); %Downsample the match-filtered signal
    result = MIMO_ofdm_demodulate_real(dco_ofdm_pilot_distorted,Nfft,CP); %Demodulate the downsampled OFDM signal
    
end
if filter_type==2 %This is the case with a square pulse 
    
    dco_ofdm_pilot_filtered2 = conv(input,square_pulse)/(Sf*Ts); %Match filter the signal with a square pulse
    sample_position2=Ts*Sf; %Sample position for the square pulse
    dco_ofdm_pilot_distorted2 = dco_ofdm_pilot_filtered2(sample_position2+offset_position:Ts*Sf:(Nfft+CP)*Ts*Sf*Frames+sample_position2+offset_position); %Downsample the match-filtered signal
    result = MIMO_ofdm_demodulate_real(dco_ofdm_pilot_distorted2,Nfft,CP); %Demodulate the downsampled OFDM signal
    
end



