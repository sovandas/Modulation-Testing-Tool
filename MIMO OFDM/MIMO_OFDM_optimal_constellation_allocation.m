function [allocated_constellations, energy_per_active_carrier] = MIMO_OFDM_optimal_constellation_allocation(M_max, Nfft, omitted_carriers, BER_target, available_SNR)

SNR_step=0.01;

max_energy = Nfft/2;
%%%%%% Calculate the SNR requirement for a given BER for each constellation size starting from BPSK up to M_max - QAM
SNR=1;
for k=2:log2(M_max)
   
    while (MQAM_BER(2^k, SNR)>BER_target)
        SNR=SNR+SNR_step;
    end
    SNR_requirement(k)=k*SNR;
end
SNR_requirement(1) = SNR_requirement(2)/2; %BPSK requires the same amount of energy per bit as 4-QAM
SNR_requirement(log2(M_max)+1)=Inf;
SNR_requirement = [-Inf,SNR_requirement];
M_vector=[0,2.^[1:log2(M_max)]];

%%%%%% Estimate the optimal allocation of constellation size on each subcarrier for the available SNR
allocated_constellations=zeros(size(available_SNR));
size(allocated_constellations)
size(max(M_vector(SNR_requirement<available_SNR(1))))

for k=1:(Nfft-2)/2-omitted_carriers
    allocated_constellations(k+omitted_carriers) = max(M_vector(SNR_requirement<available_SNR(k)));
end
point2=1
energy_per_active_carrier = ones(size(allocated_constellations));