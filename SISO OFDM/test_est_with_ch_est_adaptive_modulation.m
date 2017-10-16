function [BER, channel, estimated_channel, SNR, estimated_SNR, fitted_SNR, fitted_SNR2, SNR3, fitted_SNR3] = test_est_with_ch_est_adaptive_modulation(...
    input_from_diode, original_ofdm, qam_dco, M, P, Frames, Nfft, cp_length, omitted_carriers, preamble_length, offset, frame_eq_mult, samples_per_symbol, ...
    filter_type, roll_off_factor, Max_Constellation_Size, number_of_pilot_frames, plotFlag)

for k=1:log2(Max_Constellation_Size),
    demodulator{k} = modem.qamdemod('M',2^k,'SymbolOrder','Gray','OutputType','Bit'); %Creates a QAM modulator object for constellation sizes up to Max_Constellation_Size
    power_rescale(k) = sqrt(demodulator{k}.Constellation()*demodulator{k}.Constellation()'/(2^k));
end

for counter=1:floor(Frames/frame_eq_mult),
    
    [estimated_channel(counter,:), channel(counter,:), SNR(counter,:), estimated_SNR(counter,:), fitted_SNR(counter,:), fitted_SNR2(counter,:), SNR3(counter,:), fitted_SNR3(counter,:)] = channel_estimation(input_from_diode, original_ofdm, qam_dco((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)*(Nfft-2)/2+1:((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2), number_of_pilot_frames, Nfft, cp_length, omitted_carriers, preamble_length, offset+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)*(Nfft+cp_length)*samples_per_symbol, samples_per_symbol, filter_type, roll_off_factor, plotFlag);
    
    qam_recovered_diode = recover_ofdm_signal(input_from_diode, preamble_length+offset+((counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft+cp_length)*samples_per_symbol, filter_type, roll_off_factor, frame_eq_mult, Nfft, cp_length, samples_per_symbol);

    qam_recovered_diode_no_zeros=[];
    for k=1:frame_eq_mult
        %qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_recovered_diode((k-1)*(Nfft-2)/2+1+omitted_carriers:k*(Nfft-2)/2)./sqrt(P);
        work_block = qam_recovered_diode((k-1)*(Nfft-2)/2+1:k*(Nfft-2)/2); %Takes a frame of symbols
        qam_recovered_diode_no_zeros = [qam_recovered_diode_no_zeros,work_block([zeros(1,omitted_carriers),M]~=0)./sqrt(P(M~=0))]; %Removes all zeros from that symbol frame and rescales by the assigned power
    end
    
    qam_dco_no_zeros=[];
    for k=1:frame_eq_mult
        %qam_dco_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_dco((k-1+(counter-1)*(frame_eq_mult+number_of_pilot_frames)+number_of_pilot_frames)*(Nfft-2)/2+1+omitted_carriers:(k+(counter-1)*(frame_eq_mult+number_of_pilot_frames)+number_of_pilot_frames)*(Nfft-2)/2)./sqrt(P);
        work_block = qam_dco((k-1+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2+1:(k+(counter-1)*(frame_eq_mult+number_of_pilot_frames*2)+number_of_pilot_frames*2)*(Nfft-2)/2);
        qam_dco_no_zeros = [qam_dco_no_zeros,work_block([zeros(1,omitted_carriers),M]~=0)./sqrt(P(M~=0))];
    end
    
    if plotFlag,
        figure, plot(10*log10(abs(qam_recovered_diode_no_zeros./qam_dco_no_zeros).^2))
        xlabel('Active Carrier Index')
        ylabel('|H|^2 [dB]')
        temp_str = ['Gain in ',num2str(frame_eq_mult),' consecutive frames'];
        legend(temp_str)

        figure, plot(phase(qam_recovered_diode_no_zeros./qam_dco_no_zeros))
        xlabel('Active Carrier Index')
        ylabel('Phase(H) [Rad]')
        temp_str = ['Phase in ',num2str(frame_eq_mult),' consecutive frames'];
        legend(temp_str)
    end

    qam_sum = zeros(1, (Nfft-2)/2 - omitted_carriers);

    qam_recovered_diode_no_zeros_equalized=[];
    current_channel = channel(counter,:);
    block_length = length(qam_recovered_diode_no_zeros)/frame_eq_mult;
    for k=1:frame_eq_mult
        %qam_recovered_diode_no_zeros_equalized((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2)./channel(counter,:);
        qam_recovered_diode_no_zeros_equalized = [qam_recovered_diode_no_zeros_equalized,qam_recovered_diode_no_zeros((k-1)*block_length+1:k*block_length)./current_channel(M~=0)];
    end
    
    
    for k=1:log2(Max_Constellation_Size)
        points_of_same_size_received{k}=[];
        points_of_same_size_received_equalized{k}=[];
        points_of_same_size_original{k}=[];
    end
    
    original_bits=[];
    received_bits=[];
    M_without_zeros = M(M~=0);
    for k=1:frame_eq_mult
        for l=1:block_length,
            qam_recovered_diode_no_zeros_rescaled((k-1)*block_length+l) = qam_recovered_diode_no_zeros((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            points_of_same_size_received{log2(M_without_zeros(l))} = [points_of_same_size_received{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_rescaled((k-1)*block_length+l)];
            qam_recovered_diode_no_zeros_equalized_rescaled((k-1)*block_length+l) = qam_recovered_diode_no_zeros_equalized((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            points_of_same_size_received_equalized{log2(M_without_zeros(l))} = [points_of_same_size_received_equalized{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_equalized_rescaled((k-1)*block_length+l)]; 
            received_bits = [received_bits,demodulate(demodulator{log2(M_without_zeros(l))},qam_recovered_diode_no_zeros_equalized_rescaled((k-1)*block_length+l))'];
            qam_dco_no_zeros_rescaled((k-1)*block_length+l) = qam_dco_no_zeros((k-1)*block_length+l)*power_rescale(log2(M_without_zeros(l)));
            points_of_same_size_original{log2(M_without_zeros(l))} = [points_of_same_size_original{log2(M_without_zeros(l))},qam_dco_no_zeros_rescaled((k-1)*block_length+l)];
            original_bits = [original_bits,demodulate(demodulator{log2(M_without_zeros(l))},qam_dco_no_zeros_rescaled((k-1)*block_length+l))'];
        end
    end
    
    if plotFlag,
        for k=1:log2(Max_Constellation_Size)
            if length(points_of_same_size_received{k})>0 && length(points_of_same_size_received_equalized{k})>0 && length(points_of_same_size_original{k})>0
                scatterplot(points_of_same_size_received{k});
                scatterplot(points_of_same_size_received_equalized{k});
                scatterplot(points_of_same_size_original{k});
            end
        end
    end
    size(original_bits);
    BER(counter) = sum(sum(xor(original_bits, received_bits)))/length(original_bits);
end


