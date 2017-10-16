function [ data ] = getData( obj, samples )
%GETDATA Summary of this function goes here
%   Detailed explanation goes here

start = clock;
timeout = 5;

data = -1;


if(obj.mode ~= 15)
    
ready = wireoutdata(obj , 'STATUS_BITS');
disp(['status_bits = ' num2str(ready)]);
while(ready ~= 29)
    ready = wireoutdata(obj , 'STATUS_BITS');
    disp(['status_bits = ' num2str(ready)]);
    if(etime(clock, start) > timeout)
        return;
    end
    pause on
    pause(0.5)
    pause off
end
end

if (obj.mode == 3 ) || (obj.mode == 5) || (obj.mode == 6) || (obj.mode == 10)
    
    % in these modes, two bytes = 1 sample.
    wireindata(obj , 'NUMELEMENTS', samples/2) % the sample counter countr 4 bytes = 2 samples at a time
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock;
    ready = wireoutdata(obj , 'STATUS_BITS'); 
    while( bitget(ready,2) == 1 )
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples*2); % ok takes byte counts, not sample counts
    
    %pipevalue(1:20)'
 
    pipevalue_adj = double(convertbinary([], pipevalue')); 
%    pipevalue_adj = zeros((samples),1);
%    i = 1;
%    for x=1:2:length(pipevalue)
%        pipevalue_adj(i) = typecast( (bitshift(uint32(pipevalue(x+1)),8) + uint32(pipevalue(x))), 'uint32');
%        i = i + 1;

%    end   
%     for x = 2:2:length(pipevalue_adj) 
%         pipevalue_adj(x) = pipevalue_adj(x-1);
%     end
    data = pipevalue_adj;
    return;
end
if  (obj.mode == 4)
    
    % in these modes, two bytes = 1 sample.
    wireindata(obj , 'NUMELEMENTS', samples) % the sample counter countr 4 bytes = 1 samples at a time
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock;
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj.okComms,obj.bank,'HISTOGRAM_FIFO_OUT',samples*4); % ok takes byte counts, not sample counts
    
    %pipevalue(1:20)'
    
    pipevalue_adj = zeros((samples),1);
    i = 1;
    for x=1:4:length(pipevalue)
        pipevalue_adj(i) = sum(uint32(pipevalue(i:i+3))); 
        i = i + 1;
    end   
    
    
    return;
end
if obj.mode == 7
    
    wireindata(obj , 'NUMELEMENTS', samples/4) % the sample counter counts 4bytes at a time..
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock;
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples); % opal kelly takes byte counts, not sample counts
    
    %    for x = 1:4:length(pipevalue)
    %        t = pipevalue(x);
    %        pipevalue(x) = pipevalue(x+3);
    %        pipevalue(x+3) = t;
    %        t = pipevalue(x+1);
    %        pipevalue(x+1) = pipevalue(x+2);
    %        pipevalue(x+2) = t;
    %    %end
    
    data = uint32(pipevalue); % upcast so the multiply doesnt saturate
    
    data = data * 16;
    
end


if obj.mode == 8
    
    % in these modes, 1 byte = 2 samples.
    
    wireindata(obj , 'NUMELEMENTS', samples/8) % the sample counter counts 4bytes at a time..
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock; 
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples/2); % opal kelly takes byte counts, not sample counts
    
    pipevalue_adj = zeros(samples,1);
    
    i = 1;
    for x=1:length(pipevalue)
        pipevalue_adj(i) = bitand(pipevalue(x),15);
        pipevalue_adj(i+1) = bitshift(pipevalue(x), -4);
        i = i + 2;
    end
    
    
    %    for x = 1:4:length(pipevalue)
    %        t = pipevalue(x);
    %        pipevalue(x) = pipevalue(x+3);
    %        pipevalue(x+3) = t;
    %        t = pipevalue(x+1);
    %        pipevalue(x+1) = pipevalue(x+2);
    %        pipevalue(x+2) = t;
    %    %end
    
    data = uint16(pipevalue_adj); % upcast so the multiply doesnt saturate
    
    data = data * 32;
    
end

if obj.mode == 9
    
    % in these modes, 1 byte = 2 samples.
    
    wireindata(obj , 'NUMELEMENTS', samples/8) % the sample counter counts 4bytes at a time..
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock; 
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples/2); % opal kelly takes byte counts, not sample counts
    
    pipevalue_adj = zeros(samples,1);
    
    i = 1;
    for x=1:length(pipevalue)
        pipevalue_adj(i) = bitand(pipevalue(x),15);
        pipevalue_adj(i+1) = bitshift(pipevalue(x), -4);
        i = i + 2;
    end
    
    
    %    for x = 1:4:length(pipevalue)
    %        t = pipevalue(x);
    %        pipevalue(x) = pipevalue(x+3);
    %        pipevalue(x+3) = t;
    %        t = pipevalue(x+1);
    %        pipevalue(x+1) = pipevalue(x+2);
    %        pipevalue(x+2) = t;
    %    %end
    
    data = uint16(pipevalue_adj); % upcast so the multiply doesnt saturate
    
    data = data * 16;
    
end
if obj.mode == 2
    
    % in these modes, 1 byte = 2 samples.
    
    wireindata(obj , 'NUMELEMENTS', samples/8) % the sample counter counts 4bytes at a time..
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock; 
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples/2); % opal kelly takes byte counts, not sample counts
    
    pipevalue_adj = zeros(samples,1);
    
    i = 1;
    for x=1:length(pipevalue)
        pipevalue_adj(i) = bitand(pipevalue(x),15);
        pipevalue_adj(i+1) = bitshift(pipevalue(x), -4);
        i = i + 2;
    end
    
    
    %    for x = 1:4:length(pipevalue)
    %        t = pipevalue(x);
    %        pipevalue(x) = pipevalue(x+3);
    %        pipevalue(x+3) = t;
    %        t = pipevalue(x+1);
    %        pipevalue(x+1) = pipevalue(x+2);
    %        pipevalue(x+2) = t;
    %    %end
    
    data = uint16(pipevalue_adj); % upcast so the multiply doesnt saturate
    
    data = data * 8;
    
end

if obj.mode == 16 || obj.mode == 17 || obj.mode == 18 || obj.mode == 19 || obj.mode == 20 || obj.mode == 21 || obj.mode == 22 || obj.mode == 23 
    
    % in these modes, 1 byte = 1 sample
    
    wireindata(obj , 'NUMELEMENTS', samples/4) % the sample counter counts 4bytes at a time..
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock; 
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = double(blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples)); % opal kelly takes byte counts, not sample counts

    %i = 1;
    %for x=1:length(pipevalue)
    %    pipevalue_adj(i) = bitand(pipevalue(x),15);
    %    pipevalue_adj(i+1) = bitshift(pipevalue(x), -4);
    %    i = i + 2;
    %end
    
    %pipevalue_adj = double(convertbinary([], pipevalue')); 
            
    mult = 2^(obj.mode - 15) ;
    
    data = pipevalue * mult;
    
    data = reshape(data, 1, []); 
    
end

if obj.mode == 24 || obj.mode == 25 || obj.mode == 26 || obj.mode == 27 || obj.mode == 28 || obj.mode == 29 || obj.mode == 30 || obj.mode == 31 
    
    % in these modes, 4 bits = 1 sample
    
    wireindata(obj , 'NUMELEMENTS', samples/8) % the sample counter counts 4bytes at a time..
    
    trigger(obj , 'CAPTURE');
    
    %wait for the capture to finish
    start = clock; 
    ready = wireoutdata(obj , 'STATUS_BITS');
    while(bitget(ready,2) == 1)
        ready = wireoutdata(obj , 'STATUS_BITS');
        if(etime(clock, start) > timeout)
            return;
        end
    end
    
    pipevalue = blockpipeoutdata(obj,'HISTOGRAM_FIFO_OUT',samples/2); % opal kelly takes byte counts, not sample counts
    
    pipevalue_adj = zeros(1,samples); 
    
    i = 1;
    for x=1:length(pipevalue)
        pipevalue_adj(i) = bitand(pipevalue(x),15);
        pipevalue_adj(i+1) = bitshift(pipevalue(x), -4);
        i = i + 2;
    end
    
    %pipevalue_adj = double(convertbinary([], pipevalue')); 
            
    mult = 2^(obj.mode - 23) ;
    
    data = double(pipevalue_adj) * mult;
    
    data = reshape(data, 1, []); 
    
end


end

