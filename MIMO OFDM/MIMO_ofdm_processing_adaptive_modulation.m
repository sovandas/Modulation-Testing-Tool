function [BER, BER_QAM1, BER_QAM2, channel, estimated_channel, SNR1, SNR2] = MIMO_ofdm_processing_adaptive_modulation(input_ch1, input_ch2, qam_dco_ch1, qam_dco_ch2, offset_ch1, offset_ch2, M, P, OFDMParameters)

%%%%% Initial Clarifications

%input is the signal that you would like to process, i.e., the output from the AWG or the output from the photoreceiver

%qam_dco is the M-QAM input to the OFDM modulator. It includes the zeros on omitted subcarriers. It does not include the zero on the DC
%and 180-degree subcarriers since they are defaultly set by the OFDM modulator. 


%%%%% Setting the parameters

%%%%% Equalizing the offset

offset = offset_ch1;

if offset_ch1>offset_ch2
    input_ch1 = input_ch1(offset_ch1-offset_ch2:end);
    offset = offset_ch2;
end

if offset_ch2>offset_ch1
    input_ch2 = input_ch2(offset_ch2-offset_ch1:end);
    offset = offset_ch1;
end

oversampling_factor = OFDMParameters.oversampling_factor;
%%%%% Calling the function that does the processing
lowest_BER=1;
optimal_k=0;
applied_offset = 0;
for k=1:1:1
    if offset+k>0
        for l=1:1:1
            if offset+l>0
                input_downsampled_ch1 = input_ch1(offset+k:oversampling_factor:end);
                input_downsampled_ch2 = input_ch2(offset+l:oversampling_factor:end);
                [BER, BER_QAM1, BER_QAM2, channel, estimated_channel, SNR1, SNR2] = MIMO_test_est_with_ch_est_adaptive_modulation(input_downsampled_ch1, input_downsampled_ch2, qam_dco_ch1, qam_dco_ch2, M, P, OFDMParameters.frames, OFDMParameters.Nfft, ...
            OFDMParameters.cp_length, OFDMParameters.omitted_carriers, OFDMParameters.preamble_length, applied_offset, OFDMParameters.frame_eq_mult, ...
            OFDMParameters.samples_per_symbol, OFDMParameters.filter_type, OFDMParameters.roll_off_factor, max(max(M)), OFDMParameters.number_of_pilot_frames);
                close all;
                sum(BER)/length(BER)
                if sum(BER)/length(BER) < lowest_BER
                    optimal_k = k;
                    optimal_l = l;
                    lowest_BER = sum(BER)/length(BER)
                end
            end
        end
    end
end
input_downsampled_ch1 = input_ch1(offset+optimal_k:oversampling_factor:end);
input_downsampled_ch2 = input_ch2(offset+optimal_l:oversampling_factor:end);
[BER, BER_QAM1, BER_QAM2, channel, estimated_channel, SNR1, SNR2] = MIMO_test_est_with_ch_est_adaptive_modulation(input_downsampled_ch1, input_downsampled_ch2, qam_dco_ch1, qam_dco_ch2, M, P, OFDMParameters.frames, OFDMParameters.Nfft, ...
            OFDMParameters.cp_length, OFDMParameters.omitted_carriers, OFDMParameters.preamble_length, applied_offset, OFDMParameters.frame_eq_mult, ...
            OFDMParameters.samples_per_symbol, OFDMParameters.filter_type, OFDMParameters.roll_off_factor, max(max(M)), OFDMParameters.number_of_pilot_frames);