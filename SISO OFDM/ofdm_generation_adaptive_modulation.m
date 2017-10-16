function [dco_ofdm, dco_qam] = ofdm_generation_adaptive_modulation(M, P, OFDMParameters)

%% Generate signal
[dco_ofdm, dco_qam] = generate_ofdm_signal_adaptive_modulation(M, P, OFDMParameters.frames, OFDMParameters.Nfft, OFDMParameters.cp_length, ...
    OFDMParameters.omitted_carriers, OFDMParameters.filter_type, OFDMParameters.samples_per_symbol, OFDMParameters.upper_clipping, ...
    OFDMParameters.lower_clipping, OFDMParameters.roll_off_factor, max(M), OFDMParameters.number_of_pilot_frames, OFDMParameters.frame_eq_mult);
                            
