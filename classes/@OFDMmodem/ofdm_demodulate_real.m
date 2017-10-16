function [result] = ofdm_demodulate_real (obj, input)

%input - a vector with the incoming stream of symbols to be modulated on
%the carriers
%obj.nfft - the number of carriers including the negative frequencies. obj.nfft/2
%effective carriers will be used to transfer information.

if (obj.cp_length<0)
    error('Prefix length can only be positive or zero')
end

input=input/sqrt(obj.nfft); 

%result=zeros(1, (((length(input)-obj.cp_length)/(obj.nfft+obj.cp_length)))*(obj.nfft/2-1));

m = mod(length(input), obj.nfft+obj.cp_length);

input = reshape(input(1:(end-m)), obj.nfft+obj.cp_length, []);

result = fft(input((obj.cp_length+1):end,:), [], 1);

result = conj(result(2:obj.nfft/2, :));

%result = reshape(result, 1, []); 

% 
% for k=0:(length(input)-16)/(obj.nfft+obj.cp_length)-1
%     
%     
%     %The input stream is divided into blocks whose length is equal to the
%     %number of OFDM carriers.
%     
%     if (length(input(k*(obj.nfft+obj.cp_length)+1:end))<obj.nfft+obj.cp_length)
%        error('Dimensions of input vector and number of FFT carriers are not in agreement');
%       
%     else
%        working_vector=input(k*(obj.nfft+obj.cp_length)+1:(k+1)*(obj.nfft+obj.cp_length));
%     end
%     temp_result=fft(working_vector(obj.cp_length+1:end),obj.nfft);
%     result(k*(obj.nfft/2-1):(k+1)*(obj.nfft/2-1)-1) = temp_result(2:obj.nfft/2)';
% 
% end
