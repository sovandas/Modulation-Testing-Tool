function [signal] = modulate(obj, data)

try
    if(nargin ==1)
        if(numel(obj.data) ~= 0 )
            
            data = obj.data;
        else
            data = [];
        end
    end
    
    %% Generate signal
    
    numberBitsSymbol = log2(obj.modorder);
        
    %signal = zeros(1,(numberSymbols+3*obj.number_of_pilots)*obj.samples_per_symbol);
    
    data = reshape(data, 1, []);
    
    if(numel(data) > obj.datalength)
        data = data(1:obj.datalength);        
    end
    if(numel(data) < obj.datalength)
        data = [data, round(rand(1, obj.datalength - numel(data)))]; 
    end
        
%    data = floor(2*rand(1,obj.numberSymbols*numberBitsSymbol));
    obj.data = data;
    
    % use a 1000110110 sequence as pilot and replicate 20 times. This
    % should hopefully be a bit better at preventing sync failures. 
    pilotSequence = repmat([ones(1,numberBitsSymbol) zeros(1,numberBitsSymbol*3) ones(1,numberBitsSymbol*2) zeros(1, numberBitsSymbol) ones(1, numberBitsSymbol*2) zeros(1,numberBitsSymbol)],1,obj.number_of_pilots/10);
    leadoutsequence = repmat([zeros(1,numberBitsSymbol) ones(1,numberBitsSymbol*3) zeros(1,numberBitsSymbol*2) ones(1, numberBitsSymbol) zeros(1, numberBitsSymbol*2) ones(1,numberBitsSymbol)],1,obj.number_of_pilots/10);
 
    data = [pilotSequence pilotSequence data leadoutsequence];
    
    obj.pilotsequence = pilotSequence;  
    obj.leadoutsequence = leadoutsequence; 
    
    decimalData = zeros(1,obj.numberSymbols+3*obj.number_of_pilots);

    graydepth = 2 ^ numberBitsSymbol;
    
%    for i = 1:obj.numberSymbols+3*(obj.number_of_pilots),
%        decimalData(i) = bin2gray(bi2de(data((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb'),'pam',graydepth);
%    end
        
    decimalData = reshape(bin2gray(bi2de(reshape(data', numberBitsSymbol, [])', 'left-msb'),'pam',graydepth),1,[]);
    
    encodedData = pammod(decimalData,obj.modorder);
    encodedData = real(encodedData);
    obj.originalScale = encodedData(1);
    encodedData = encodedData ./ (max(encodedData)-min(encodedData)) .* 2;
    % encodedData = encodedData -1 - min(encodedData);
    
    obj.encodedData = encodedData; 
    

    
    
    if(obj.filter == 1)
        
        filt = RRC(obj);
        
        [~,extradata] = max(filt);
        
        signal = zeros(1,length(encodedData) * obj.samples_per_symbol);
        signal(1:obj.samples_per_symbol:end)= encodedData;
        signal = conv(signal, filt);
        
    else
        if(obj.filter == 2)
            filt = log(1:100:100*obj.samples_per_symbol);
            filt = filt - min(filt);
            filt = (filt / max(filt)) + 10;
            signal = zeros(1,length(encodedData) * obj.samples_per_symbol);
            signal(1:obj.samples_per_symbol:end)= encodedData;
            signal = conv(signal, fliplr(filt));
            
        else
            signal = reshape(repmat(encodedData, obj.samples_per_symbol, 1),1,[]);
        end
    end

    %% Add synchronization sequence
    synchSequence = [zeros(1,obj.syncseqlen*obj.samples_per_symbol) ones(1,obj.syncseqlen*obj.samples_per_symbol) zeros(1,obj.syncseqlen*obj.samples_per_symbol)];
    signal = [synchSequence signal];
    
    %% Send to AWG
    
    
    %% apply the reverse mapping to reduce nonlinearity
    signal = signal - min(signal); 
    
    signal = (signal * (obj.levels)) / max(signal);
    
    signal = signal + obj.minlevel; 
    
    signal = round(signal);
    
    
    obj.expandedsignal = signal;
    %signal = signal + 1;
    
   
    %% Truncate data signal if needed
    %difference = length(signal) - lengthDataSent;
    %if difference > 0,
    %    numberSymbolsToRemove = ceil(difference/obj.samples_per_symbol);
    %    obj.data = obj.data(1:end-numberSymbolsToRemove*numberBitsSymbol);
    %end
    
    %% Save variables
    obj.nonexpandedsignal = signal((300 + 3*obj.number_of_pilots)*obj.samples_per_symbol+1:end);
    
    %obj.signal = reshape(repmat(obj.nonexpandedsignal, obj.downSampleTx , 1), 1, []); 

    %delete(h);

       
%% Exit gracefully if something fails
catch ME,
    %delete(h);
        ME
    for i = 1:length(ME.stack)
        ME.stack(i)
    end
    rethrow(ME)
end