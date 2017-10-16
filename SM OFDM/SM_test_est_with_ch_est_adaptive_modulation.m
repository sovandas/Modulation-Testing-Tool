
function [BER, BER_SM, BER_QAM, channel, estimated_channel, estimated_SNR, fitted_SNR] = SM_test_est_with_ch_est_adaptive_modulation(input_from_diode_ch1, input_from_diode_ch2, qam_dco_ch1, qam_dco_ch2, SM_bits, M, P, Frames, Nfft, cp_length, omitted_carriers, preamble_length, offset, frame_eq_mult, samples_per_symbol, filter_type, roll_off_factor, Max_Constellation_Size, number_of_pilot_frames)

for k=1:log2(Max_Constellation_Size)
    demodulator{k} = modem.qamdemod('M',2^k,'SymbolOrder','Gray','OutputType','Bit'); %Creates a QAM modulator object for constellation sizes up to Max_Constellation_Size
    power_rescale(k) = sqrt(demodulator{k}.Constellation()*demodulator{k}.Constellation()'/(2^k));
end

BER=[];
BER_SM=[];
BER_QAM=[];
channel_ch1=[];
estimated_channel_ch1=[];
estimated_SNR_ch1=[];
fitted_SNR_ch1=[];

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
    
    qam_recovered_diode_no_zeros_ch1=[];
    for k=1:frame_eq_mult
        %qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_recovered_diode((k-1)*(Nfft-2)/2+1+omitted_carriers:k*(Nfft-2)/2)./sqrt(P);
        work_block = qam_recovered_diode_ch1((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros_ch1 = [qam_recovered_diode_no_zeros_ch1,work_block([zeros(1,omitted_carriers),M]~=0)./sqrt(P(M~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
    
    qam_recovered_diode_no_zeros_ch2=[];
    for k=1:frame_eq_mult
        work_block = qam_recovered_diode_ch2((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros_ch2 = [qam_recovered_diode_no_zeros_ch2,work_block([zeros(1,omitted_carriers),M]~=0)./sqrt(P(M~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
    
    qam_dco_no_zeros_ch1=[];
    for k=1:frame_eq_mult
        work_block = qam_dco_ch1((k-1+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2+1:(k+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2);
        qam_dco_no_zeros_ch1 = [qam_dco_no_zeros_ch1,work_block([zeros(1,omitted_carriers),M]~=0)./sqrt(P(M~=0))];
    end
    
    qam_dco_no_zeros_ch2=[];
    for k=1:frame_eq_mult
        work_block = qam_dco_ch2((k-1+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2+1:(k+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2);
        qam_dco_no_zeros_ch2 = [qam_dco_no_zeros_ch2,work_block([zeros(1,omitted_carriers),M]~=0)./sqrt(P(M~=0))];
    end

%     figure, plot(10*log10(abs(qam_recovered_diode_no_zeros./qam_dco_no_zeros).^2))
%     xlabel('Active Carrier Index')
%     ylabel('|H|^2 [dB]')
%     temp_str = ['Gain in ',num2str(frame_eq_mult),' consecutive frames'];
%     legend(temp_str)
%     
%     figure, plot(phase(qam_recovered_diode_no_zeros./qam_dco_no_zeros))
%     xlabel('Active Carrier Index')
%     ylabel('Phase(H) [Rad]')
%     temp_str = ['Phase in ',num2str(frame_eq_mult),' consecutive frames'];
%     legend(temp_str)


    %qam_recovered_diode_no_zeros_equalized_ch1=qam_recovered_diode_no_zeros_ch1;
    qam_recovered_diode_no_zeros_equalized_ch1=[];
    current_channel_ch11 = channel_ch11(counter,:);
    current_channel_ch12 = channel_ch12(counter,:);
    block_length = length(qam_recovered_diode_no_zeros_ch1)/frame_eq_mult;
    for k=1:frame_eq_mult
        qam_recovered_diode_no_zeros_equalized_ch1 = [qam_recovered_diode_no_zeros_equalized_ch1,qam_recovered_diode_no_zeros_ch1((k-1)*block_length+1:k*block_length)./current_channel_ch11(M~=0)];
    end
    
    %qam_recovered_diode_no_zeros_equalized_ch2=qam_recovered_diode_no_zeros_ch2;
    qam_recovered_diode_no_zeros_equalized_ch2=[];
    current_channel_ch21 = channel_ch21(counter,:);
    current_channel_ch22 = channel_ch22(counter,:);
    block_length = length(qam_recovered_diode_no_zeros_ch2)/frame_eq_mult;
    for k=1:frame_eq_mult
        qam_recovered_diode_no_zeros_equalized_ch2 = [qam_recovered_diode_no_zeros_equalized_ch2,qam_recovered_diode_no_zeros_ch2((k-1)*block_length+1:k*block_length)./current_channel_ch22(M~=0)];
    end
    
    for k=1:log2(Max_Constellation_Size)
        points_of_same_size_received{k}=[];
        points_of_same_size_received_equalized{k}=[];
        points_of_same_size_original{k}=[];
    end
    
    original_QAM_bits=[];
    received_QAM_bits=[];
    received_SM_bits=[];
    M_without_zeros = M(M~=0);
    for k=1:frame_eq_mult
        for l=1:block_length
            qam_recovered_diode_no_zeros_rescaled_ch1((k-1)*block_length+l) = qam_recovered_diode_no_zeros_ch1((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            qam_recovered_diode_no_zeros_rescaled_ch2((k-1)*block_length+l) = qam_recovered_diode_no_zeros_ch2((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            if SM_bits((k-1)*block_length+l) == 1
                points_of_same_size_received{log2(M_without_zeros(l))} = [points_of_same_size_received{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_rescaled_ch1((k-1)*block_length+l)];
            else
                points_of_same_size_received{log2(M_without_zeros(l))} = [points_of_same_size_received{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_rescaled_ch2((k-1)*block_length+l)];
            end
            
            qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+l) = qam_recovered_diode_no_zeros_equalized_ch1((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+l) = qam_recovered_diode_no_zeros_equalized_ch2((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            
            if SM_bits((k-1)*block_length+l) == 1
                points_of_same_size_received_equalized{log2(M_without_zeros(l))} = [points_of_same_size_received_equalized{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_equalized_rescaled_ch1((k-1)*block_length+l)]; 
            else
                points_of_same_size_received_equalized{log2(M_without_zeros(l))} = [points_of_same_size_received_equalized{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_equalized_rescaled_ch2((k-1)*block_length+l)];
            end
            
           
            qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+l) = qam_dco_no_zeros_ch1((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+l) = qam_dco_no_zeros_ch2((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            
            if SM_bits((k-1)*block_length+l) == 1
                points_of_same_size_original{log2(M_without_zeros(l))} = [points_of_same_size_original{log2(M_without_zeros(l))},qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+l)];
            else
                points_of_same_size_original{log2(M_without_zeros(l))} = [points_of_same_size_original{log2(M_without_zeros(l))},qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+l)];
            end
            
            [SM_bit, QAM_bits] = SM_demodulate_2channels_with_crosstalk(qam_recovered_diode_no_zeros_rescaled_ch1((k-1)*block_length+l),qam_recovered_diode_no_zeros_rescaled_ch2((k-1)*block_length+l), M_without_zeros(l), demodulator{log2(M_without_zeros(l))}, current_channel_ch11(l), current_channel_ch12(l), current_channel_ch21(l), current_channel_ch22(l));
            received_QAM_bits = [received_QAM_bits,QAM_bits];
            received_SM_bits = [received_SM_bits,SM_bit];
            if SM_bits((k-1)*block_length+l) == 1
                original_QAM_bits = [original_QAM_bits,demodulate(demodulator{log2(M_without_zeros(l))},qam_dco_no_zeros_rescaled_ch1((k-1)*block_length+l))'];
            else
                original_QAM_bits = [original_QAM_bits,demodulate(demodulator{log2(M_without_zeros(l))},qam_dco_no_zeros_rescaled_ch2((k-1)*block_length+l))'];
            end
        end
    end
    
    for k=1:log2(Max_Constellation_Size)
        if length(points_of_same_size_received{k})>0 && length(points_of_same_size_received_equalized{k})>0 && length(points_of_same_size_original{k})>0
            scatterplot(points_of_same_size_received{k});
            scatterplot(points_of_same_size_received_equalized{k});
            scatterplot(points_of_same_size_original{k});
        end
    end
    
    
    size(original_QAM_bits) + size(SM_bits)
    BER_QAM(counter) = sum(sum(xor(original_QAM_bits, received_QAM_bits)))/length(original_QAM_bits);
    BER_SM(counter) = sum(sum(xor(SM_bits, received_SM_bits)))/length(SM_bits);
    BER(counter) = (BER_SM*length(SM_bits) + BER_QAM*length(original_QAM_bits))/(length(SM_bits) + length(original_QAM_bits));
end

