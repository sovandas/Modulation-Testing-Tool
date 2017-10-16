
function [BER, BER_QAM1, BER_QAM2, channel, estimated_channel, SNR1, SNR2] = MIMO_test_est_with_ch_est_adaptive_modulation(input_from_diode_ch1, input_from_diode_ch2, qam_dco_ch1, qam_dco_ch2, M, P, Frames, Nfft, cp_length, omitted_carriers, preamble_length, offset, frame_eq_mult, samples_per_symbol, filter_type, roll_off_factor, Max_Constellation_Size, number_of_pilot_frames)

for k=1:log2(Max_Constellation_Size)
    demodulator{k} = modem.qamdemod('M',2^k,'SymbolOrder','Gray','OutputType','Bit'); %Creates a QAM modulator object for constellation sizes up to Max_Constellation_Size
    power_rescale(k) = sqrt(demodulator{k}.Constellation()*demodulator{k}.Constellation()'/(2^k));
end

BER=[];
BER_QAM1=[];
BER_QAM2=[];
% channel_ch1=[];
% estimated_channel_ch1=[];
% estimated_SNR_ch1=[];
% fitted_SNR_ch1=[];

for counter=1:floor(Frames/frame_eq_mult)
    
    [channel_ch11(counter,:), estimated_channel_ch11(counter,:), estimated_SNR_ch11(counter,:), fitted_SNR_ch11(counter,:)] = SM_channel_estimation(input_from_diode_ch1, qam_dco_ch1((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)*(Nfft-2)/2+1:((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames)*(Nfft-2)/2), number_of_pilot_frames, Nfft, cp_length, omitted_carriers, preamble_length, offset+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)*(Nfft+cp_length)*samples_per_symbol, samples_per_symbol, filter_type, roll_off_factor);
    [channel_ch21(counter,:), estimated_channel_ch21(counter,:), estimated_SNR_ch21(counter,:), fitted_SNR_ch21(counter,:)] = SM_channel_estimation(input_from_diode_ch2, qam_dco_ch1((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)*(Nfft-2)/2+1:((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames)*(Nfft-2)/2), number_of_pilot_frames, Nfft, cp_length, omitted_carriers, preamble_length, offset+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)*(Nfft+cp_length)*samples_per_symbol, samples_per_symbol, filter_type, roll_off_factor);
    
    [channel_ch12(counter,:), estimated_channel_ch12(counter,:), estimated_SNR_ch12(counter,:), fitted_SNR_ch12(counter,:)] = SM_channel_estimation(input_from_diode_ch1, qam_dco_ch2(((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames)*(Nfft-2)/2+1:((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2), number_of_pilot_frames, Nfft, cp_length, omitted_carriers, preamble_length, offset+((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames)*(Nfft+cp_length)*samples_per_symbol, samples_per_symbol, filter_type, roll_off_factor);
    [channel_ch22(counter,:), estimated_channel_ch22(counter,:), estimated_SNR_ch22(counter,:), fitted_SNR_ch22(counter,:)] = SM_channel_estimation(input_from_diode_ch2, qam_dco_ch2(((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames)*(Nfft-2)/2+1:((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2), number_of_pilot_frames, Nfft, cp_length, omitted_carriers, preamble_length, offset+((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames)*(Nfft+cp_length)*samples_per_symbol, samples_per_symbol, filter_type, roll_off_factor);
    
    channel = [channel_ch11; channel_ch12; channel_ch21; channel_ch22];
    estimated_channel = [estimated_channel_ch11; estimated_channel_ch12; estimated_channel_ch21; estimated_channel_ch22];
    estimated_SNR = [estimated_SNR_ch11; estimated_SNR_ch12; estimated_SNR_ch21; estimated_SNR_ch22];
    fitted_SNR = [fitted_SNR_ch11; fitted_SNR_ch12; fitted_SNR_ch21; fitted_SNR_ch22];
    
    qam_recovered_diode_ch1 = recover_ofdm_signal(input_from_diode_ch1, preamble_length+offset+((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft+cp_length)*samples_per_symbol, filter_type, roll_off_factor, frame_eq_mult, Nfft, cp_length, samples_per_symbol);

    qam_recovered_diode_ch2 = recover_ofdm_signal(input_from_diode_ch2, preamble_length+offset+((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft+cp_length)*samples_per_symbol, filter_type, roll_off_factor, frame_eq_mult, Nfft, cp_length, samples_per_symbol);
    
    %qam_recovered_diode_no_zeros_equalized_ch1=qam_recovered_diode_no_zeros_ch1;
    qam_recovered_diode_equalized_ch1=[];
    qam_recovered_diode_equalized_ch2=[];
    current_channel_ch11 = channel_ch11(counter,:);
    current_channel_ch12 = channel_ch12(counter,:);
    current_channel_ch21 = channel_ch21(counter,:);
    current_channel_ch22 = channel_ch22(counter,:);
    block_length = length(qam_recovered_diode_ch1)/frame_eq_mult;
    for k=1:frame_eq_mult
        for l=1:block_length
            iH = inv([current_channel_ch11(end-block_length+l),current_channel_ch12(end-block_length+l);current_channel_ch21(end-block_length+l),current_channel_ch22(end-block_length+l)]); %Compute the inverse of the channel matrix
            working_sample_equalized = iH*[qam_recovered_diode_ch1((k-1)*block_length+l);qam_recovered_diode_ch2((k-1)*block_length+l)]; % Equalize a pair of received samples. Since this is OFDM, both the spatial and the temporal channel are equalized
            qam_recovered_diode_equalized_ch1 = [qam_recovered_diode_equalized_ch1,working_sample_equalized(1)];
            qam_recovered_diode_equalized_ch2 = [qam_recovered_diode_equalized_ch2,working_sample_equalized(2)];
        end
    end
    
    qam_recovered_diode_no_zeros_ch1=[];
    for k=1:frame_eq_mult
        work_block = qam_recovered_diode_ch1((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros_ch1 = [qam_recovered_diode_no_zeros_ch1,work_block([zeros(1,omitted_carriers),M(1,:)]~=0)./sqrt(P(1,M(1,:)~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
    
    qam_recovered_diode_no_zeros_ch2=[];
    for k=1:frame_eq_mult
        work_block = qam_recovered_diode_ch2((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros_ch2 = [qam_recovered_diode_no_zeros_ch2,work_block([zeros(1,omitted_carriers),M(2,:)]~=0)./sqrt(P(2,M(2,:)~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
        
    qam_recovered_diode_no_zeros_equalized_ch1=[];
    for k=1:frame_eq_mult
        work_block = qam_recovered_diode_equalized_ch1((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros_equalized_ch1 = [qam_recovered_diode_no_zeros_equalized_ch1,work_block([zeros(1,omitted_carriers),M(1,:)]~=0)./sqrt(P(1,M(1,:)~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
    
    qam_recovered_diode_no_zeros_equalized_ch2=[];
    for k=1:frame_eq_mult
        work_block = qam_recovered_diode_equalized_ch2((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros_equalized_ch2 = [qam_recovered_diode_no_zeros_equalized_ch2,work_block([zeros(1,omitted_carriers),M(2,:)]~=0)./sqrt(P(2,M(2,:)~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
    
    qam_dco_no_zeros_ch1=[];
    for k=1:frame_eq_mult
        work_block = qam_dco_ch1((k-1+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2+1:(k+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2);
        qam_dco_no_zeros_ch1 = [qam_dco_no_zeros_ch1,work_block([zeros(1,omitted_carriers),M(1,:)]~=0)./sqrt(P(1,M(1,:)~=0))];
    end
    
    qam_dco_no_zeros_ch2=[];
    for k=1:frame_eq_mult
        work_block = qam_dco_ch2((k-1+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2+1:(k+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2);
        qam_dco_no_zeros_ch2 = [qam_dco_no_zeros_ch2,work_block([zeros(1,omitted_carriers),M(2,:)]~=0)./sqrt(P(2,M(2,:)~=0))];
    end
    
    for k=1:log2(Max_Constellation_Size)
        points_of_same_size_received{k}=[];
        points_of_same_size_received_equalized{k}=[];
        points_of_same_size_original{k}=[];
    end
    
    original_QAM_bits1=[];
    original_QAM_bits2=[];
    received_QAM_bits1=[];
    received_QAM_bits2=[];
    M_without_zeros1 = M(1,M(1,:)~=0);
    M_without_zeros2 = M(2,M(2,:)~=0);
    
    block_length = length(qam_recovered_diode_no_zeros_equalized_ch1)/frame_eq_mult;
    for k=1:frame_eq_mult
        for l=1:block_length
            qam_recovered_diode_no_zeros_rescaled_ch1((k-1)*block_length+l) = qam_recovered_diode_no_zeros_ch1((k-1)*block_length+l)*power_rescale(log2(M_without_zeros1(l)));
            
            points_of_same_size_received{log2(M_without_zeros1(l))} = [points_of_same_size_received{log2(M_without_zeros1(l))},qam_recovered_diode_no_zeros_rescaled_ch1((k-1)*block_length+l)];
            
            qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+l) = qam_recovered_diode_no_zeros_equalized_ch1((k-1)*block_length+l)*power_rescale(log2(M_without_zeros1(l)));
            
            points_of_same_size_received_equalized{log2(M_without_zeros1(l))} = [points_of_same_size_received_equalized{log2(M_without_zeros1(l))},qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+l)]; 
            
            qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+l) = qam_dco_no_zeros_ch1((k-1)*block_length+l)*power_rescale(log2(M_without_zeros1(l)));
            
            points_of_same_size_original{log2(M_without_zeros1(l))} = [points_of_same_size_original{log2(M_without_zeros1(l))},qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+l)];
            
            received_QAM_bits1 = [received_QAM_bits1,demodulate(demodulator{log2(M_without_zeros1(l))}, qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+l)).'];
        
            original_QAM_bits1 = [original_QAM_bits1,demodulate(demodulator{log2(M_without_zeros1(l))},qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+l))'];
        end
    end
    
    % Using the demodulated data to esitmated the SNR since it is dependent on the cross-talk.
    signal_energy1=zeros(1,block_length);
    noise_energy1=zeros(1,block_length);
    for k=1:frame_eq_mult
        signal_energy1 = signal_energy1 + qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+1:k*block_length).*conj(qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+1:k*block_length));
        noise_energy1 = noise_energy1 + (qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+1:k*block_length) - qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+1:k*block_length)).*...
            conj(qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+1:k*block_length) - qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+1:k*block_length));
    end
    polynomial_degree=5;
    SNR1(counter,:) = polyval(polyfit([1:length(signal_energy1)],signal_energy1./noise_energy1,polynomial_degree),[1:length(signal_energy1)]);
    figure, plot(10*log10(SNR1(counter,:))), hold on, plot(10*log10(signal_energy1./noise_energy1),'r');
    title('Channel 1 Achievable SNR');
    
    block_length = length(qam_recovered_diode_no_zeros_equalized_ch2)/frame_eq_mult;
    for k=1:frame_eq_mult
        for l=1:block_length
            qam_recovered_diode_no_zeros_rescaled_ch2((k-1)*block_length+l) = qam_recovered_diode_no_zeros_ch2((k-1)*block_length+l)*power_rescale(log2(M_without_zeros2(l)));
            
            points_of_same_size_received{log2(M_without_zeros2(l))} = [points_of_same_size_received{log2(M_without_zeros2(l))},qam_recovered_diode_no_zeros_rescaled_ch2((k-1)*block_length+l)];
            
            qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+l) = qam_recovered_diode_no_zeros_equalized_ch2((k-1)*block_length+l)*power_rescale(log2(M_without_zeros2(l)));
            
            points_of_same_size_received_equalized{log2(M_without_zeros2(l))} = [points_of_same_size_received_equalized{log2(M_without_zeros2(l))},qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+l)];
            
            qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+l) = qam_dco_no_zeros_ch2((k-1)*block_length+l)*power_rescale(log2(M_without_zeros2(l)));
            
            points_of_same_size_original{log2(M_without_zeros2(l))} = [points_of_same_size_original{log2(M_without_zeros2(l))},qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+l)];
            
            received_QAM_bits2 = [received_QAM_bits2,demodulate(demodulator{log2(M_without_zeros2(l))}, qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+l)).'];
 
            original_QAM_bits2 = [original_QAM_bits2,demodulate(demodulator{log2(M_without_zeros2(l))},qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+l))'];
        end
    end
    
    % Using the demodulated data to esitmated the SNR since it is dependent on the cross-talk.
    signal_energy2=zeros(1,block_length);
    noise_energy2=zeros(1,block_length);
    for k=1:frame_eq_mult
        signal_energy2 = signal_energy2 + qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+1:k*block_length).*conj(qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+1:k*block_length));
        noise_energy2 = noise_energy2 + (qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+1:k*block_length) - qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+1:k*block_length)).*...
            conj(qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+1:k*block_length) - qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+1:k*block_length));
    end
    polynomial_degree=5;
    SNR2(counter,:) = polyval(polyfit([1:length(signal_energy2)],signal_energy2./noise_energy2,polynomial_degree),[1:length(signal_energy2)]);
    figure, plot(10*log10(SNR2(counter,:))), hold on, plot(10*log10(signal_energy2./noise_energy2),'r');
    title('Channel 2 Achievable SNR');
    
    for k=1:log2(Max_Constellation_Size)
        if length(points_of_same_size_received{k})>0 && length(points_of_same_size_received_equalized{k})>0 && length(points_of_same_size_original{k})>0
            scatterplot(points_of_same_size_received{k});
            scatterplot(points_of_same_size_received_equalized{k});
            scatterplot(points_of_same_size_original{k});
        end
    end
    
    
    
    BER_QAM1(counter) = sum(sum(xor(original_QAM_bits1, received_QAM_bits1)))/length(original_QAM_bits1)
    BER_QAM2(counter) = sum(sum(xor(original_QAM_bits2, received_QAM_bits2)))/length(original_QAM_bits2)
    BER(counter) = (BER_QAM1*length(original_QAM_bits1) + BER_QAM2*length(original_QAM_bits2))/(length(original_QAM_bits1) + length(original_QAM_bits2))
end

