function [channel3, estimated_channel3, SNR1, SNR2, SNR3, SNR4, SNR5, SNR6] = ...
    channel_estimation(input_from_diode, original_ofdm, qam_dco, Frames, Nfft, cp_length, omitted_carriers, preamble_length, offset, samples_per_symbol, filter_type, roll_off_factor, plotFlag)

qam_recovered_diode = recover_ofdm_signal(input_from_diode, preamble_length+offset, filter_type, roll_off_factor, Frames*2, Nfft, cp_length, samples_per_symbol);
qam_recovered_diode1 = qam_recovered_diode(1:length(qam_recovered_diode)/2);
qam_recovered_diode2 = qam_recovered_diode(length(qam_recovered_diode)/2+1:end);
qam_recovered_original_ofdm = recover_ofdm_signal(original_ofdm, 0, filter_type, roll_off_factor, Frames, Nfft, cp_length, samples_per_symbol);

for k=1:Frames,
    qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_recovered_diode1((k-1)*(Nfft-2)/2+1+omitted_carriers:k*(Nfft-2)/2);
end

for k=1:Frames,
    qam_recovered_diode_no_zeros2((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_recovered_diode2((k-1)*(Nfft-2)/2+1+omitted_carriers:k*(Nfft-2)/2);
end

for k=1:Frames,
    qam_recovered_original_ofdm_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_recovered_original_ofdm((k-1)*(Nfft-2)/2+1+omitted_carriers:k*(Nfft-2)/2);
end

for k=1:Frames*2,
    qam_dco_no_zeros_both_pilots((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2) = qam_dco((k-1)*(Nfft-2)/2+1+omitted_carriers:k*(Nfft-2)/2);
end

qam_dco_no_zeros = qam_dco_no_zeros_both_pilots(1:length(qam_dco_no_zeros_both_pilots)/2);
qam_dco_no_zeros2 = qam_dco_no_zeros_both_pilots(length(qam_dco_no_zeros_both_pilots)/2+1:end);

if plotFlag,
    figure, plot(10*log10(abs(qam_recovered_diode_no_zeros./qam_dco_no_zeros).^2));
    xlabel('Active Carrier Index');
    ylabel('|H|^2 [dB]');
    
    figure, plot(phase(qam_recovered_diode_no_zeros./qam_dco_no_zeros));
    xlabel('Active Carrier Index');
    ylabel('Phase(H) [Rad]');
end


qam_sum = zeros(1, (Nfft-2)/2 - omitted_carriers);

for k=1:Frames
    qam_sum = qam_sum + qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2);
end

qam_averaged = qam_sum/Frames;

estimated_channel = qam_averaged./qam_dco_no_zeros(1:(Nfft-2*(omitted_carriers+1))/2);
estimated_channel2 = qam_averaged./qam_recovered_original_ofdm_no_zeros(1:(Nfft-2*(omitted_carriers+1))/2);

polynomial_degree=21;
channel_polynomial = polyfit([1:length(estimated_channel)], estimated_channel, polynomial_degree);
channel = polyval(channel_polynomial, [1:length(estimated_channel)]);
channel_polynomial2 = polyfit([1:length(estimated_channel2)], estimated_channel2, polynomial_degree);
channel2 = polyval(channel_polynomial2, [1:length(estimated_channel2)]);

channel_sum = zeros(1, (Nfft-2)/2 - omitted_carriers);

for k=1:Frames
    channel_sum = channel_sum + qam_recovered_diode_no_zeros2((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2)./qam_dco_no_zeros2((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2);
end

estimated_channel3 = channel_sum/Frames;
channel_polynomial3 = polyfit([1:length(estimated_channel3)], estimated_channel3, polynomial_degree);
channel3 = polyval(channel_polynomial3, [1:length(estimated_channel3)]);

if plotFlag,
    figure, plot(10*log10(abs(estimated_channel).^2)); 
    hold on, semilogy(10*log10(abs(channel).^2), 'r');
    plot(10*log10(abs(estimated_channel2).^2),'k'); 
    plot(10*log10(abs(channel2).^2),'g'); 
    plot(10*log10(abs(estimated_channel3).^2),'m'); 
    plot(10*log10(abs(channel3).^2),'c');
    xlabel('Active Carrier Index');
    ylabel('|H|^2 [dB]');
    legend('Pilot Estimation',strcat('Polynomial of Degree ',num2str(polynomial_degree)));

    figure, plot(phase(estimated_channel)), hold on, plot(phase(channel), 'r');
    plot(phase(estimated_channel2),'k');
    plot(phase(channel2), 'g'); 
    plot(phase(estimated_channel3),'m'); 
    plot(phase(channel3), 'c');
    xlabel('Active Carrier Index');
    ylabel('Phase(H) [Rad]');
    legend('Pilot Estimation',strcat('Polynomial of Degree ',num2str(polynomial_degree)));
end;

var_sum = zeros(1, (Nfft-2)/2 - omitted_carriers);
for k=1:Frames,
    var_sum = var_sum + abs(qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2)-qam_averaged).^2;
end
noise_estimation1 = var_sum/(Frames-1);
SNR1 = abs(qam_averaged).^2./noise_estimation1;

var_sum2 = zeros(1, (Nfft-2)/2 - omitted_carriers);
for k=1:Frames,
    var_sum2 = var_sum2 + abs(qam_recovered_diode_no_zeros((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2)-channel2.*qam_recovered_original_ofdm_no_zeros(1:(Nfft-2*(omitted_carriers+1))/2)).^2;
end
noise_estimation2 = var_sum2/(Frames);
SNR2 = abs(channel.*qam_dco_no_zeros(1:(Nfft-2*(omitted_carriers+1))/2)).^2./noise_estimation2;

SNR1_polynomial = polyfit([1:length(SNR1)], 10*log10(SNR1), 3);
SNR3 = polyval(SNR1_polynomial, [1:length(SNR1)]);

SNR2_polynomial = polyfit([1:length(SNR2)], 10*log10(SNR2), 3);
SNR4 = polyval(SNR2_polynomial, [1:length(SNR2)]);

var_sum3 = zeros(1, (Nfft-2)/2 - omitted_carriers);
for k=1:Frames
    var_sum3 = var_sum3 + abs(qam_recovered_diode_no_zeros2((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2)-channel3.*qam_dco_no_zeros2((k-1)*(Nfft-2*(omitted_carriers+1))/2+1:k*(Nfft-2*(omitted_carriers+1))/2)).^2;
end
noise_estimation3 = var_sum3/Frames;
SNR5 = abs(channel3.*qam_dco_no_zeros2(1:(Nfft-2*(omitted_carriers+1))/2)).^2./noise_estimation3;
SNR5_polynomial = polyfit([1:length(SNR5)], 10*log10(SNR5), 3);
SNR6 = polyval(SNR5_polynomial, [1:length(SNR5)]);
SNR5 = 10*log10(SNR5);

if plotFlag,
    figure, plot(1:length(SNR1),10*log10(SNR1)); 
    hold on, plot(1:length(SNR2),10*log10(SNR2),'k'); 
    plot(1:length(SNR3),SNR3,'r'), plot(1:length(SNR4),SNR4,'g'); 
    plot(1:length(SNR5),SNR5,'m'), plot(1:length(SNR6),SNR6,'c');
    xlabel('Active Carrier Index');
    ylabel('SNR [dB]');
    legend('SNR estimation 1', 'SNR estimation 2');
end

