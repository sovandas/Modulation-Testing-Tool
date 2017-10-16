function [allocated_constellations, energy_per_active_carrier] = MIMO_OFDM_optimal_constellation_allocation2(M_max, Nfft, omitted_carriers, BER_target, available_SNR)

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
SNR_requirement

%%%%%% Estimate the optimal allocation of constellation size on each carrier for the maximum available power

candidate_constellation_per_carrier = ones(1,(Nfft-2)/2-omitted_carriers);

energy_per_active_carrier = zeros(1,(Nfft-2)/2-omitted_carriers);

total_energy = 0;

if total_energy < max_energy
    energy_finished=0;
else
    energy_finished=1;
end

while energy_finished==0

    required_energy_for_information_increase = SNR_requirement(candidate_constellation_per_carrier)./available_SNR - energy_per_active_carrier;
    
    [min_energy_requirement, carrier_to_be_upgraded] = min(required_energy_for_information_increase);
    
    if total_energy + min_energy_requirement < max_energy
        candidate_constellation_per_carrier(carrier_to_be_upgraded) = candidate_constellation_per_carrier(carrier_to_be_upgraded)+1;
        energy_per_active_carrier(carrier_to_be_upgraded) = energy_per_active_carrier(carrier_to_be_upgraded) + min_energy_requirement;
        total_energy = total_energy + min_energy_requirement;
    else
        energy_finished=1;
    end
    
end
total_energy
allocated_constellations = 2.^(candidate_constellation_per_carrier-1);
allocated_constellations(candidate_constellation_per_carrier==1)=0;