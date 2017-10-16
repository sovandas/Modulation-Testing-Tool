function [SM_bit, QAM_bits] = SM_demodulate_2channels_with_crosstalk(symbol1, symbol2, M, demodulator, ch11, ch12, ch21, ch22)

symbol1_difference_to_constellation = abs(symbol1 - demodulator.Constellation().*ch11).^2 + abs(symbol2 - demodulator.Constellation().*ch21).^2;
[min_d1, index_d1] = min(symbol1_difference_to_constellation);

symbol2_difference_to_constellation = abs(symbol2 - demodulator.Constellation().*ch22).^2 + abs(symbol1 - demodulator.Constellation().*ch12).^2;
[min_d2, index_d2] = min(symbol2_difference_to_constellation);

if min_d1<min_d2
    SM_bit=1;
    QAM_bits_string = dec2bin(demodulator.SymbolMapping(index_d1));
else
    SM_bit=0;
    QAM_bits_string = dec2bin(demodulator.SymbolMapping(index_d2));
end

for k=1:length(QAM_bits_string)
    QAM_bits(k) = str2num(QAM_bits_string(k));
end

QAM_bits = [zeros(1,log2(M)-length(QAM_bits)),QAM_bits];