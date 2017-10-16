function [result] = SM_ofdm_modulate_real (input,Nfft,cp)

%input - a vector with the incoming stream of symbols to be modulated on
%the carriers
%Nfft - the number of carriers including the negative frequencies. Nfft/2
%effective carriers will be used to transfer information.

if (cp<0)
    error('Prefix length can only be positive or zero')
end

result=[];
result1=[];
result2=[];
for i=0:floor(length(input)/((Nfft-2)/2))
    
    if mod(i,1000)==0
        i
    end
    %The input stream is divided into blocks whose length is equal to the
    %number of OFDM carriers.
    if (i*(Nfft-2)/2~=length(input))
        if (length(input(i*(Nfft-2)/2+1:end))<(Nfft-2)/2)
            working_vector=[input(i*(Nfft-2)/2+1:end),zeros(1,(Nfft-2)/2-length(input(i*(Nfft-2)/2+1:end)))]; 
        else
            working_vector=input(i*(Nfft-2)/2+1:(i+1)*(Nfft-2)/2);
        end
        working_vector2=[0,working_vector,0,conj(working_vector(end:-1:1))];
        
        temp_result = sqrt(Nfft)*ifft(working_vector2,Nfft);
        result=[result,temp_result(end-cp+1:end),temp_result];
        
    end

end
