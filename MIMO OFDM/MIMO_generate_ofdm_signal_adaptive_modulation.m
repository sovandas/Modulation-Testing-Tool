function [ofdm_signal_ch1, ofdm_signal_ch2, qam_dco_ch1, qam_dco_ch2] = MIMO_generate_ofdm_signal_adaptive_modulation(M, P, Frames, Nfft, cp_length, omitted_carriers, pulse_shaping_type, samples_per_symbol, upper_clipping, lower_clipping, roll_off_factor, Max_Constellation_Size,number_of_pilot_frames,frame_eq_mult) 


%%%% The standard deviation of the generated signal is 1 before the pulse
%%%% shaping. Square pulse does not change that. RRC might have a small
%%%% effect. 

%%%% Define the QAM modulator (from Communications toolbox)


for k=1:log2(Max_Constellation_Size);
    modulator{k} = modem.qammod('M',2^k,'SymbolOrder','Gray','InputType','Bit'); %Creates a QAM modulator object for constellation sizes up to Max_Constellation_Size
    power_rescale(k) = sqrt(modulator{k}.Constellation()*modulator{k}.Constellation()'/(2^k));
end

%%%% Define the RRC filter

symbol_rate=1;
Ts=1/symbol_rate; %symbol period
Sf=samples_per_symbol/Ts; % Samping frequency (does the oversampling)

lb=-16*Ts; %Lower bound of the RRC filter impulse response (clipped beyond this value)
ub=(15+15/16)*Ts; %Upper bound of the RRC filter impulse response (clipped beyond this value)
t = [lb:1/Sf:ub];
beta = roll_off_factor; %roll-off factor (1+beta)*Nyquist frequency gives the used bandwidth

[dummy,middle_value] = min(abs(t));
p7 = (sin(pi*t/Ts*(1-beta)) + 4*beta*t/Ts.*cos(pi*t/Ts*(1+beta)))./(pi*t/Ts.*(1-(4*beta*t/Ts).^2));
p7(middle_value(1)) = 1-beta+4*beta/pi;
[dummy,first_special_value] = min(abs(t+Ts/(4*beta)));
[dummy,second_special_value] = min(abs(t-Ts/(4*beta)));
p7(first_special_value) = beta/sqrt(2)*((1+2/pi)*sin(pi/(4*beta)) + (1-2/pi)*cos(pi/(4*beta)));
p7(second_special_value) = beta/sqrt(2)*((1+2/pi)*sin(pi/(4*beta)) + (1-2/pi)*cos(pi/(4*beta)));
p7=p7/sqrt(Ts);


%%%% DCO signal generation
%%%% pilot frame generation
 % the pilot frame consists of 4-QAM symbols only because the have constant
 % power and different phase
 input_pilot2 = floor(2*rand(2,number_of_pilot_frames*(Nfft-2)/2-omitted_carriers));
 pilot_frames2 = modulate(modulator{2},input_pilot2)/power_rescale(2);
 
 qam_dco_ch1=[]; %The sequence begins with the pilot frames
 qam_dco_ch2=[];


for k=1:Frames
    if mod((k-1),frame_eq_mult)==0
        qam_dco_ch1 = [qam_dco_ch1,pilot_frames2,zeros(size(pilot_frames2))];
        qam_dco_ch2 = [qam_dco_ch2,zeros(size(pilot_frames2)),pilot_frames2];
    end
    qam_dco_ch1 = [qam_dco_ch1, zeros(1,omitted_carriers)];
    qam_dco_ch2 = [qam_dco_ch2, zeros(1,omitted_carriers)];
    for l=1:(Nfft-2)/2-omitted_carriers
        if M(1,l)~=0
            input_dco = floor(2*rand(log2(M(1,l)),1));
            qam_dco_ch1 = [qam_dco_ch1, modulate(modulator{log2(M(1,l))},input_dco)/power_rescale(log2(M(1,l)))*sqrt(P(1,l))]; 
        else
            qam_dco_ch1 = [qam_dco_ch1,0];
        end
        if M(2,l)~=0
            input_dco = floor(2*rand(log2(M(2,l)),1));
            qam_dco_ch2 = [qam_dco_ch2, modulate(modulator{log2(M(2,l))},input_dco)/power_rescale(log2(M(2,l)))*sqrt(P(2,l))]; 
        else
            qam_dco_ch2 = [qam_dco_ch2,0];
        end
    end
end
%figure, plot(abs(qam_dco))


dco_ofdm_ch1=MIMO_ofdm_modulate_real(qam_dco_ch1,Nfft,cp_length);
dco_ofdm_ch2=MIMO_ofdm_modulate_real(qam_dco_ch2,Nfft,cp_length);
%figure, plot(dco_ofdm_ch1), hold on, plot(dco_ofdm_ch2,'r')

if pulse_shaping_type>0
    
    %%%% Oversampling with zeros
    dco_ofdm_up_ch1 = zeros(1,Ts*Sf*(Nfft+cp_length)*(Frames+2*number_of_pilot_frames*ceil(Frames/frame_eq_mult)));
    dco_ofdm_up_ch1(1:Ts*Sf:end)= dco_ofdm_ch1;
    
    dco_ofdm_up_ch2 = zeros(1,Ts*Sf*(Nfft+cp_length)*(Frames+2*number_of_pilot_frames*ceil(Frames/frame_eq_mult)));
    dco_ofdm_up_ch2(1:Ts*Sf:end)= dco_ofdm_ch2;

    if pulse_shaping_type==1  %%%% Shape with a RRC filter
    
        dco_ofdm_shaped_rrc_ch1 = conv(dco_ofdm_up_ch1,p7);
        %%%% Clipping  the RRC-shaped signal
        dco_ofdm_shaped_rrc_clipped_ch1 = dco_ofdm_shaped_rrc_ch1;
        dco_ofdm_shaped_rrc_clipped_ch1(dco_ofdm_shaped_rrc_clipped_ch1>upper_clipping)=upper_clipping;
        dco_ofdm_shaped_rrc_clipped_ch1(dco_ofdm_shaped_rrc_clipped_ch1<lower_clipping)=lower_clipping;
        ofdm_signal_ch1 = dco_ofdm_shaped_rrc_clipped_ch1;

        dco_ofdm_shaped_rrc_ch2 = conv(dco_ofdm_up_ch2,p7);
        %%%% Clipping  the RRC-shaped signal
        dco_ofdm_shaped_rrc_clipped_ch2 = dco_ofdm_shaped_rrc_ch2;
        dco_ofdm_shaped_rrc_clipped_ch2(dco_ofdm_shaped_rrc_clipped_ch2>upper_clipping)=upper_clipping;
        dco_ofdm_shaped_rrc_clipped_ch2(dco_ofdm_shaped_rrc_clipped_ch2<lower_clipping)=lower_clipping;
        ofdm_signal_ch2 = dco_ofdm_shaped_rrc_clipped_ch2;

        
    else %%%% Shape with a square wave
        square_pulse = ones(1,Ts*Sf);
        dco_ofdm_shaped_square_ch1 = conv(dco_ofdm_up_ch1,square_pulse);
        dco_ofdm_shaped_square_ch2 = conv(dco_ofdm_up_ch2,square_pulse);
        %%%% Clipping  square_pulse signal
        dco_ofdm_shaped_square_clipped_ch1 = dco_ofdm_shaped_square_ch1;
        dco_ofdm_shaped_square_clipped_ch1(dco_ofdm_shaped_square_clipped_ch1>upper_clipping)=upper_clipping;
        dco_ofdm_shaped_square_clipped_ch1(dco_ofdm_shaped_square_clipped_ch1<lower_clipping)=lower_clipping;
        ofdm_signal_ch1 = dco_ofdm_shaped_square_clipped_ch1;
        
        dco_ofdm_shaped_square_clipped_ch2 = dco_ofdm_shaped_square_ch2;
        dco_ofdm_shaped_square_clipped_ch2(dco_ofdm_shaped_square_clipped_ch2>upper_clipping)=upper_clipping;
        dco_ofdm_shaped_square_clipped_ch2(dco_ofdm_shaped_square_clipped_ch2<lower_clipping)=lower_clipping;
        ofdm_signal_ch2 = dco_ofdm_shaped_square_clipped_ch2;
    end
else
    dco_clipped_ch1 = dco_ofdm_ch1;
    dco_clipped_ch1(dco_clipped_ch1>upper_clipping)=upper_clipping;
    dco_clipped_ch1(dco_clipped_ch1<lower_clipping)=lower_clipping;
    ofdm_signal_ch1 = dco_clipped_ch1;
    
    dco_clipped_ch2 = dco_ofdm_ch2;
    dco_clipped_ch2(dco_clipped_ch2>upper_clipping)=upper_clipping;
    dco_clipped_ch2(dco_clipped_ch2<lower_clipping)=lower_clipping;
    ofdm_signal_ch2 = dco_clipped_ch2;
end



