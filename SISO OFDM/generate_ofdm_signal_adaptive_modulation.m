function [ofdm_signal,qam_dco] = generate_ofdm_signal_adaptive_modulation(M, P, Frames, Nfft, cp_length, ...
    omitted_carriers, pulse_shaping_type, samples_per_symbol, upper_clipping, lower_clipping, roll_off_factor, ...
    Max_Constellation_Size,number_of_pilot_frames,frame_eq_mult) 
%% This function generates OFDM signal from given modulation and power allocation

% Note: The standard deviation of the generated signal is 1 before the pulse
% shaping. Square pulse does not change that. RRC might have a small effect. 

%% Define the QAM modulator (from Communications toolbox)
for k=1:log2(Max_Constellation_Size);
    modulator{k} = modem.qammod('M',2^k,'SymbolOrder','Gray','InputType','Bit'); %Creates a QAM modulator object for constellation sizes up to Max_Constellation_Size
    power_rescale(k) = sqrt(modulator{k}.Constellation()*modulator{k}.Constellation()'/(2^k));
end

%% Define the RRC filter
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


%% DCO signal generation

% Pilot frame generation
% Note: the pilot frame consists of 4-QAM symbols only because they have constant
% power and different phase
input_pilot = floor(2*rand(2,(Nfft-2)/2-omitted_carriers));

% append the pilot multiple copies of the pilot frame
pilot_frames = repmat([zeros(1,omitted_carriers),modulate(modulator{2},input_pilot)/power_rescale(2)],1,number_of_pilot_frames); % Replicate one pilot frame
input_pilot2 = floor(2*rand(2,number_of_pilot_frames*((Nfft-2)/2-omitted_carriers)));
pilot_frames2 = modulate(modulator{2},input_pilot2)/power_rescale(2); % Generate different pilot frames
 
qam_dco=[]; 

% Signal generation
for k=1:Frames
    if mod((k-1),frame_eq_mult)==0
        qam_dco = [qam_dco,pilot_frames,pilot_frames2]; %The sequence begins with the pilot frames
    end
    qam_dco = [qam_dco, zeros(1,omitted_carriers)];
    for l=1:(Nfft-2)/2-omitted_carriers
        if M(l)~=0
            input_dco = floor(2*rand(log2(M(l)),1));
            qam_dco = [qam_dco, modulate(modulator{log2(M(l))},input_dco)/power_rescale(log2(M(l)))*sqrt(P(l))];
        else
            qam_dco = [qam_dco,0];
        end
    end
end

dco_ofdm = ofdm_modulate_real(qam_dco,Nfft,cp_length);

%% Pusle shaping
if pulse_shaping_type>0
    
    %%%% Oversampling with zeros
    dco_ofdm_up = zeros(1,Ts*Sf*(Nfft+cp_length)*(Frames+2*number_of_pilot_frames*ceil(Frames/frame_eq_mult)));
    dco_ofdm_up(1:Ts*Sf:end)= dco_ofdm;

    if pulse_shaping_type==1  %%%% Shape with a RRC filter
    
        dco_ofdm_shaped_rrc = conv(dco_ofdm_up,p7);
        %%%% Clipping  the RRC-shaped signal
        dco_ofdm_shaped_rrc_clipped = dco_ofdm_shaped_rrc;
        dco_ofdm_shaped_rrc_clipped(dco_ofdm_shaped_rrc_clipped>upper_clipping)=upper_clipping;
        dco_ofdm_shaped_rrc_clipped(dco_ofdm_shaped_rrc_clipped<lower_clipping)=lower_clipping;
        ofdm_signal = dco_ofdm_shaped_rrc_clipped;

    else %%%% Shape with a square wave
        square_pulse = ones(1,Ts*Sf);
        dco_ofdm_shaped_square = conv(dco_ofdm_up,square_pulse);

        %%%% Clipping  square_pulse signal
        dco_ofdm_shaped_square_clipped = dco_ofdm_shaped_square;
        dco_ofdm_shaped_square_clipped(dco_ofdm_shaped_square_clipped>upper_clipping)=upper_clipping;
        dco_ofdm_shaped_square_clipped(dco_ofdm_shaped_square_clipped<lower_clipping)=lower_clipping;
        ofdm_signal = dco_ofdm_shaped_square_clipped;
    end
else
    dco_clipped = dco_ofdm;
    dco_clipped(dco_clipped>upper_clipping)=upper_clipping;
    dco_clipped(dco_clipped<lower_clipping)=lower_clipping;
    ofdm_signal = dco_clipped;
end
