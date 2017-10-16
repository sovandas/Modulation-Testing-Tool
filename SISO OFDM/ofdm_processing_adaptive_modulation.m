function [BER, channel, estimated_channel, SNR, estimated_SNR, fitted_SNR, fitted_SNR2, SNR3, fitted_SNR3] = ...
    ofdm_processing_adaptive_modulation(input, original_ofdm, qam_dco, sampleNumber, M, P, OFDMParameters)

%% Initial Clarifications
%input is the signal that you would like to process, i.e., the output from the AWG or the output from the photoreceiver

%qam_dco is the M-QAM input to the OFDM modulator. It includes the zeros on omitted subcarriers. It does not include the zero on the DC
%and 180-degree subcarriers since they are defaultly set by the OFDM modulator. 

%% Update parameters
OFDMParameters.offset = sampleNumber;

%% Calling the function that does the processing
iterator = -3*OFDMParameters.oversampling_factor:1:3*OFDMParameters.oversampling_factor;
achievedBER = ones(1,length(iterator));
optimalK = zeros(1,length(iterator));
applied_offset = 0;
parfor i=1:length(iterator),
    k = iterator(i);
    if OFDMParameters.offset+k>0
        input_downsampled = input(OFDMParameters.offset+k:OFDMParameters.oversampling_factor:end);    
        [BER, channel, estimated_channel, SNR, estimated_SNR, fitted_SNR, fitted_SNR2,  SNR3, fitted_SNR3] = test_est_with_ch_est_adaptive_modulation(input_downsampled, original_ofdm, qam_dco, M, P, OFDMParameters.frames, OFDMParameters.Nfft, ...
            OFDMParameters.cp_length, OFDMParameters.omitted_carriers, OFDMParameters.preamble_length, applied_offset, OFDMParameters.frame_eq_mult, ...
            OFDMParameters.samples_per_symbol, OFDMParameters.filter_type, OFDMParameters.roll_off_factor, max(M), OFDMParameters.number_of_pilot_frames, 0);
        achievedBER(i) = sum(BER)/length(BER);
        optimalK(i) = k;
    end
end
[minBER, indexBER] = min(achievedBER);
optimalK = optimalK(indexBER);

input_downsampled = input(OFDMParameters.offset+optimalK:OFDMParameters.oversampling_factor:end);    
[BER, channel, estimated_channel, SNR, estimated_SNR, fitted_SNR, fitted_SNR2,  SNR3, fitted_SNR3] = test_est_with_ch_est_adaptive_modulation(input_downsampled, original_ofdm, ...
    qam_dco, M, P, OFDMParameters.frames, OFDMParameters.Nfft, OFDMParameters.cp_length, OFDMParameters.omitted_carriers, OFDMParameters.preamble_length, ...
    applied_offset, OFDMParameters.frame_eq_mult, OFDMParameters.samples_per_symbol, OFDMParameters.filter_type, OFDMParameters.roll_off_factor, max(M), ...
    OFDMParameters.number_of_pilot_frames, 1);

