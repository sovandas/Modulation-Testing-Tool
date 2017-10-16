function [result] = ofdm_modulate_real(obj, input)

%input - a vector with the incoming stream of symbols to be modulated on
%the carriers
%obj.nfft - the number of carriers including the negative frequencies. obj.nfft/2
%effective carriers will be used to transfer information.

if (obj.cp_length<0)
    error('Prefix length can only be positive or zero');
end

result=[];

bhfactors = blackmanharris(obj.cp_length*2)';

for i=0:floor(length(input)/((obj.nfft-2)/2))
    
    if mod(i,1000)==0
       % i
    end
    %The input stream is divided into blocks whose length is equal to the
    %number of OFDM carriers.
    if (i*(obj.nfft-2)/2~=length(input)),
        if (length(input((i*(obj.nfft-2)/2+1):end))<(obj.nfft-2)/2)
            error(['input length ', num2str(length(input)),' is not a multiple of ', num2str(obj.nfft/2-1)]);
            working_vector=[input(i*(obj.nfft-2)/2+1:end),zeros(1,(obj.nfft-2)/2-length(input(i*(obj.nfft-2)/2+1:end)))]; 
        else
            working_vector=input(i*(obj.nfft-2)/2+1:(i+1)*(obj.nfft-2)/2);
        end
        
        working_vector2=[0,working_vector,0,conj(working_vector(end:-1:1))];
        
        temp_result = sqrt(obj.nfft)*ifft(working_vector2,obj.nfft);
        
        
        if(length(result) ~= 0)
            if(length(prev_result) ~= 0)
                result=[result, prev_result(1:obj.cp_length).*bhfactors(obj.cp_length:-1:1) + temp_result(end-obj.cp_length+1:end).*bhfactors(1:obj.cp_length),temp_result];
            else
                result=[result, result(end-obj.cp_length+1:end).*bhfactors(obj.cp_length:-1:1) + temp_result(end-obj.cp_length+1:end).*bhfactors(1:obj.cp_length),temp_result];
            end
        else
            
            result=[result,temp_result((end-obj.cp_length+1):end) .* bhfactors(1:obj.cp_length),temp_result];
        end
        prev_result = temp_result; 
    end
end

result = [result, prev_result(1:obj.cp_length).*bhfactors(obj.cp_length:-1:1)];

