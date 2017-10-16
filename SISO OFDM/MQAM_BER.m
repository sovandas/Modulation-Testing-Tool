function [result] = MQAM_BER (M,SNR)

sum=zeros(size(SNR));
%range=floor(sqrt(M)/2);
if (M>=8)
    range=2;
else
    range=1;
end
for j=1:range
    sum = sum + 1-normcdf((2*j-1)*sqrt(3*log2(M)*SNR/(M-1)),0,1);
end

result=4/log2(M)*(1-1/sqrt(M))*sum;