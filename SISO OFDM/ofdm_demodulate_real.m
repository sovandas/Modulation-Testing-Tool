function [result] = ofdm_demodulate_real (input,Nfft,cp)

%input - a vector with the incoming stream of symbols to be modulated on
%the carriers
%Nfft - the number of carriers including the negative frequencies. Nfft/2
%effective carriers will be used to transfer information.

if (cp<0)
    error('Prefix length can only be positive or zero')
end

input=input/sqrt(Nfft);

result=[];
for k=0:length(input)/(Nfft+cp)-1
    
    
    %The input stream is divided into blocks whose length is equal to the
    %number of OFDM carriers.
    
    if (length(input(k*(Nfft+cp)+1:end))<Nfft+cp)
       error('Dimensions of input vector and number of FFT carriers are not in agreement');
      
    else
       working_vector=input(k*(Nfft+cp)+1:(k+1)*(Nfft+cp));
    end
    temp_result=fft(working_vector(cp+1:end),Nfft);
    result=[result,temp_result(2:Nfft/2)];

end
