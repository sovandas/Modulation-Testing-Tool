function [ret] = demodulate(obj, waveformdata) % filename, obj.show, generatecsv)
%SPADANALYZEOFDM Summary of this function goes here
%   Detailed explanation goes here

if(nargin ==2)
    generatecsv = 0;
end

rxdata = 0;

%load(filename);

modulator = modem.qammod('M',obj.modorder,'SymbolOrder','Gray','InputType','Bit');
demodulator = modem.qamdemod(modulator, 'OutputType', 'Bit', 'DecisionType', 'hard');

dataqamcoded = modulate(modulator, obj.data')';

%fprintf('Analyzing %s ...\n', filename);

%whos('diff')

overallidx = 1;

%if(obj.samples_per_symbol > 1)
%    lpf = designfilt('lowpassfir','PassbandFrequency',1/(obj.samples_per_symbol), 'StopbandFrequency',1/(obj.samples_per_symbol) + 1/(obj.samples_per_symbol*8), 'PassbandRipple',0.3,'StopbandAttenuation',80, 'DesignMethod','kaiserwin');

%    medfiltered = filter(lpf, waveformData.YData);
%else
medfiltered = waveformdata.YData;
%end


% filter to remove noise and prevent it from aliasing down
    
   

%% find sample rate of received data sample

sampletime = mean(diff(waveformdata.XData));

samplerate = round(1/sampletime); %% in Hz.

%% upsample pilotseq
% pilotseq has samplerate of freq * 1e6 /
pilotrate = obj.freq * 1e6;

sampleratio = samplerate / pilotrate;

upsamppilot = resample(obj.pilotsequence, samplerate, pilotrate);

upsampleadout = resample(obj.leadoutsequence, samplerate, pilotrate);

% filter the received waveform so that we don't have the silly noise alias
% down later..

cutoff = (1/sampleratio) * (1/obj.samples_per_symbol);
if(cutoff < 1)
    lpFilt = designfilt('lowpassfir','PassbandFrequency',cutoff, ...
        'StopbandFrequency',cutoff+0.01,'PassbandRipple',0.5, ...
        'StopbandAttenuation',65,'DesignMethod','kaiserwin');
    if(obj.show == 1)
        fvtool(lpFilt);
    end
    
    medfiltered = filter(lpFilt, medfiltered);
end

[corr, lag] = xcorr(medfiltered, upsamppilot);



[lcorr, llag] = xcorr(medfiltered, upsampleadout);

if obj.show >= 1
    figure;
    plot(obj.pilotsequence);
    title('pilotseq')
    figure;
    plot(corr)
    title('corr');
    line(1:length(lcorr), lcorr, 'color', 'green'); 
end

[~, peaks] = findpeaks(corr, 'MinPeakDistance', 0.9*obj.samples_per_symbol*(obj.nfft+obj.cp_length)*(obj.frames+obj.number_of_pilot_frames)*sampleratio);

[~, lpeaks] = findpeaks(lcorr, 'MinPeakDistance', 0.9*obj.samples_per_symbol*(obj.nfft+obj.cp_length)*(obj.frames+obj.number_of_pilot_frames)*sampleratio);

if(obj.show >= 1)
    for i = 2:(length(peaks-2))
        line([peaks(i), peaks(i)],[min(corr), max(corr)],'Color', 'red');
    end
    figure;
    plot(lcorr);
    title('lcorr');
    for i = 2:(length(lpeaks-2))
        line([lpeaks(i), lpeaks(i)],[min(lcorr), max(lcorr)],'Color', 'red');
    end
    
end

% xcorr offsets is one sample off. 
lag  = lag +1;
llag = llag + length(upsampleadout) + 1; 

if(obj.show >= 1)
    figure;
    plot(medfiltered)
    for i = 1:(length(peaks-2))
        line([lag(peaks(i)), lag(peaks(i))],[min(medfiltered), max(medfiltered)],'Color', 'red');
    end
    for i = 1:(length(lpeaks-2))
        line([llag(lpeaks(i)), llag(lpeaks(i))],[min(medfiltered), max(medfiltered)],'Color', 'green');
    end
    title('peaks found in correlation');
end

%singlepilotqam = pilotqam;

%pilotqam = repmat(pilotqam, 1, obj.number_of_pilot_frames);

errbits = zeros(1, length(peaks));
totalbits  = zeros(1, length(peaks));
signalsize  = zeros(1, length(peaks));
noisesize  = zeros(1, length(peaks));
flatnoisepsd  = zeros(1, length(peaks));
photontop  = zeros(1, length(peaks));
photonbot  = zeros(1, length(peaks));
meanphoton = zeros(1, length(peaks)); 
avgsignal = []; 

%length(peaks)

const = [];


for peak = 1:(length(peaks)-1)
    
    
    follow = 1;
    while( llag(lpeaks(follow)) < lag(peaks(peak)) )
        follow = follow + 1;
        if(follow > numel(lpeaks))
            follow = follow -1;
            break;
        end
    end
    
    start = lag(peaks(peak));
    finish = llag(lpeaks(follow))-1;
    
    if(start < 1 || finish < 1 || finish < start || finish > length(medfiltered))
        continue;
    end
    
    len = length(medfiltered(start:finish));
    
    
    if(obj.filter == 1)
        
        filt = RRC(obj);
        
        reallen = (obj.samples_per_symbol* ...
            ( ((obj.nfft+obj.cp_length)...
            *(obj.frames+obj.number_of_pilot_frames))...
            + obj.cp_length))+length(filt)-1;
        
        %reallen = length(encodedData) - 17*obj.samples_per_symbol-1;
    else
        
        reallen = (obj.samples_per_symbol* ...
            ( ((obj.nfft+obj.cp_length)...
            *(obj.frames+obj.number_of_pilot_frames))...
            + obj.cp_length));
        %                reallen = length(encodedData)-17*obj.samples_per_symbol-1;
    end
    % if(obj.filter_type == 1)
    %     reallen = reallen + length(RRC(obj.samples_per_symbol, obj.roll_off_factor)) - 1;
    % end
    
    if((start + reallen*sampleratio) > length(medfiltered))
        continue
    end
    if (len > 1.05*reallen*sampleratio) || (len < 0.95*reallen*sampleratio)
        continue
    end
    
    
    %    ofdmsig = medfiltered( (lag(peaks(peak)))+1: ...
    %        ( lag(peaks(peak))+(obj.samples_per_symbol* ...
    %        (obj.nfft+obj.cp_length)...
    %        *(obj.frames+obj.number_of_pilot_frames)) ) );
    
    
    %    ofdmsig = resample( medfiltered(start:finish), N, D, 1);
    
    if(obj.show > 0)
         fprintf(' --- decoding peak %s ---\n',num2str(peak));
    end
    
     
    if len ~= reallen
        
        
        
        ofdmsig = resample(medfiltered(start:finish), pilotrate, samplerate);
%         medlen = length(medfiltered(start:finish)); 
%         if(obj.show > 0)
%             fprintf('size of medlen: %s\n',num2str(medlen));
%         end
%         ofdmsig = interp1(1:medlen, medfiltered(start:finish), linspace(1,medlen, pilotrate / samplerate * medlen), 'linear'); 
        if(obj.show > 0)
            fprintf('size of ofdmsig: %s\n',num2str(size(ofdmsig)));
            fprintf('reallen: %i\n',reallen);
            
        end
        resamplen = length(ofdmsig);
        
        if(resamplen ~= reallen)
            
            %ofdmsig = resample(ofdmsig, reallen, resamplen);
            ofdmsig = interp1(1:resamplen, ofdmsig, linspace(1,resamplen,reallen), 'pchip')';
            
            if(obj.show > 0)
                fprintf('size of ofdmsig (postresample): %s\n',num2str(size(ofdmsig)));
                
                
            end
        end
        %d = linspace(1,len,reallen);
        
        %disp('RESULTSIZE')
        %size(d)
        %ofdmsig = interp1(1:len, medfiltered(start:finish), d, 'pchip')';
        
        %ofdmsig = medfiltered(start:finish);
        
        %if obj.samples_per_symbol >= 4
        %    ofdmsig = smooth(ofdmsig, obj.samples_per_symbol-3, 'lowess');
        %end
        %disp('Did spline interpolation; old size:')
        %size(medfiltered(start:finish))
       
        %disp('OFDMSIGLEN')
        %size(ofdmsig)
        %disp('** IGNORED DETECTED LENGTH **')
        %ofdmsig = medfiltered(start:start+reallen);
        
    else
        ofdmsig = medfiltered(start:finish);
    end
    
    
    %    if(numel(obj.ofdmsource) == numel(ofdmsig))
    %        %% we have the source, so use that to inform the linearizer
    %        obj.setlinear(ofdmsig)
    %    end
    
    avgsignal(peak, :) = ofdmsig; 
    
    
    noisestart = max(1, (lag(peaks(peak)) - obj.preamble_length -1));
    
    noisesig = medfiltered( noisestart : (lag(peaks(peak)) -1) );
    
    signalsize(peak) = sqrt(mean((ofdmsig - mean(ofdmsig)).^2)); % std dev of signal
    
    meanphoton(peak) = mean(ofdmsig);
    
%    meanphoton
    
    %signalsize(peak-1) = sqrt(mean(ofdmsig));
    
    ipre = obj.preamble_length / 4;
    
    offsets = [ipre/10, ipre - ipre/10];
    
    offsets = round([offsets, offsets + ipre, offsets + 2*ipre, offsets + 3*ipre]);
    
    offsets(offsets > length(noisesig)) = length(noisesig); 
    
    concatwave = [(noisesig(offsets(1):offsets(2)) - mean(noisesig(offsets(1):offsets(2)))), ...
        (noisesig(offsets(3):offsets(4)) - mean(noisesig(offsets(3):offsets(4)))), ...
        (noisesig(offsets(5):offsets(6)) - mean(noisesig(offsets(5):offsets(6)))), ...
        (noisesig(offsets(7):offsets(8)) - mean(noisesig(offsets(7):offsets(8)))) ]; 
    
    if(numel(noisesig) >= max(offsets))
        
        noisesize(peak) = geomean( [ ...
            sqrt(mean((noisesig(offsets(1):offsets(2)) - mean(noisesig(offsets(1):offsets(2)))).^2)),  ...
            sqrt(mean((noisesig(offsets(3):offsets(4)) - mean(noisesig(offsets(3):offsets(4)))).^2)),  ...
            sqrt(mean((noisesig(offsets(5):offsets(6)) - mean(noisesig(offsets(5):offsets(6)))).^2)),  ...
            sqrt(mean((noisesig(offsets(7):offsets(8)) - mean(noisesig(offsets(7):offsets(8)))).^2))  ...
            ] );
        
    else
        noisesize(peak) = NaN;
    end
    
    
    if(obj.show > 0)
        figure(45)
        plot(concatwave)
        title('concatwave for estimating PSD');
    end
    
    if(obj.getspectrum == 1)
        resp = pwelch(concatwave);
        hzperbin = samplerate / length(resp);
        flatnoisepsd(peak) = mean(resp) * (1/ hzperbin);
    else
        flatnoisepsd(peak) = NaN;
    end
    %    noisesize(peak-1) = geomean( [ ...
    %        sqrt(mean(noisesig(50:950))),  ...
    %        sqrt(mean(noisesig(1050:1950))),  ...
    %        sqrt(mean(noisesig(2050:2950))),  ...
    %        sqrt(mean(noisesig(3050:3950)))  ...
    %        ] );
    
    
    
    %ofdmpersample = reshape(ofdmsig, obj.samples_per_symbol, []);
    
    %halfrange = floor(obj.samples_per_symbol/2);
    
    %if(halfrange < 2)
    %    range = 1:obj.samples_per_symbol;
    %else
    %    range = (halfrange-1):(halfrange+1);
    %end
    
    if(obj.filter == 1)
        
        filt = RRC(obj);
        fillen = length(filt);
        
        [dummy,sample_position] = max(filt); %Find the position of the middle value of the RRC filter
        
        ofdmsigdp = ofdmsig - mean(ofdmsig); % make dual- polar
        
        dco_ofdm_filtered = conv(ofdmsigdp,filt)/obj.samples_per_symbol; %Match filter the signal with a RRC filter
        
        dco_ofdm_filtered = dco_ofdm_filtered - min(dco_ofdm_filtered); % back to unipolar
        
        
        ofdmsigresampled = dco_ofdm_filtered(fillen+1:obj.samples_per_symbol:end-fillen+2);
        %ofdmsigresampled = dco_ofdm_filtered((2*sample_position-1):obj.samples_per_symbol:(end-2*sample_position+1)); %Downsample the match-filtered signal
        if(obj.show > 0)
  
            fprintf('size of filt: %s\n',num2str(size(filt)));
            fprintf('size of dco_ofdm_filtered: %s\n',num2str(size(dco_ofdm_filtered)));
        end
        % if peak == obj.showpeak && obj.show > 0
        
        %      figure;
        %      plot(dco_ofdm_pilot_filtered(sample_position:end-sample_position))
        %      line(1:obj.samples_per_symbol:length(ofdmsigresampled)*obj.samples_per_symbol, ofdmsigresampled, 'color', 'yellow');
        %      title('filtered OFDM signsl')
        
        % end
    else
        
        if( obj.samples_per_symbol > 1)
            if(obj.samples_per_symbol < 4)
                ofdmsigresampled = mean(reshape(ofdmsig, obj.samples_per_symbol,[]))';
            else
                tpam = reshape(ofdmsig, obj.samples_per_symbol,[]);
                
                fact = normpdf(1:obj.samples_per_symbol, (obj.samples_per_symbol+1)/2, obj.samples_per_symbol/4);
                fact = fact * obj.samples_per_symbol/sum(fact);
                for j = 1:length(tpam)
                    tpam(:,j) = tpam(:,j) .* (fact');
                    %    ofdmsigresampled(j) = tpam(:,j) ./ sum(fact);
                end
                
                ofdmsigresampled = mean(tpam)';
                
            end
        else
            ofdmsigresampled = pamsig';
        end
        
    end
    
    
    
    
    
    %    ofdmsigresampled = mean(ofdmpersample)';
    if(obj.show > 0)
        fprintf('size ofdmsigresampled = %s\n', num2str(size(ofdmsigresampled)));
        %size(ofdmsigresampled)
        
        %ofdmsigresampled = resample(ofdmsig, 1, obj.samples_per_symbol, 4);
        
        %ofdmsigresampled = ofdmsig(1:obj.samples_per_symbol:end);
        
        fprintf('size obj.nonexpandedsignal = %s\n', num2str(size(obj.nonexpandedsignal)));
    end
    edata = obj.encodedData - min(obj.encodedData);
    %    sdata = signal - min(signal);
    
    if peak == obj.showpeak && obj.show > 0
        figure;
        title('comparison, pretx and rx.')
        plot(medfiltered(start:finish))
        line(1:length(ofdmsig), ofdmsig, 'color', 'green');
        line((1:obj.samples_per_symbol:(length(ofdmsigresampled)*obj.samples_per_symbol))+sample_position-1, ofdmsigresampled, 'color', 'yellow');
        line((1:obj.samples_per_symbol:(length(obj.nonexpandedsignal)*obj.samples_per_symbol))+sample_position-1, ((obj.nonexpandedsignal) / max(obj.nonexpandedsignal) * (max(ofdmsigresampled)-min(ofdmsigresampled)))+min(ofdmsigresampled) , 'color', [0.7 0 0.7]);
        line(1:length(edata), ((edata) / max(edata) * (max(ofdmsigresampled)-min(ofdmsigresampled)))+min(ofdmsigresampled), 'color', 'red')
        %        line(1:obj.samples_per_symbol:length(sdata)*obj.samples_per_symbol, (sdata / max(sdata) * (max(ofdmsigresampled)-min(ofdmsigresampled)))+min(ofdmsigresampled), 'color', [0.7 0 0] )
        if(obj.filter == 1)
            line(1:length(dco_ofdm_filtered)-2*sample_position+1, dco_ofdm_filtered(sample_position:end-sample_position), 'color', [0.7 0.7 0.7]);
        end
        drawnow;
        
        % original nonexpanded signal - purple
        % original encoded data - red

        % blue - medfiltered
        % ofdmsig - green
        % dco filtered signal - grey
        % ofdmsigresampled - yellow
        
    end
    
    
    if(peak == obj.showpeak && generatecsv > 0)
        Received = medfiltered(start:finish);
        Resampled = ofdmsigresampled;
        Signal = signal';
        Encoded = encodedData';
        
        T = table(Signal);
        writetable(T, 'signal_ofdm.csv');
        
        T = table(Encoded);
        writetable(T, 'encoded_ofdm.csv');
        
        T = table(Received);
        writetable(T, 'received_ofdm.csv');
        
        T = table(Resampled);
        writetable(T, 'resampled_ofdm.csv');
    end
    
    leaddemod = obj.ofdm_demodulate_real( ofdmsigresampled);
    
    if(obj.show > 0)
        fprintf('leaddemod size = %s\n', num2str(size(leaddemod)));
    end
    %taildemod =  ofdm_demodulate_real( ofdmsigresampled( (end-(obj.nfft+obj.cp_length)+1):end ),obj.nfft,  obj.cp_length );
    
    lipilotdemod = leaddemod(:, 1:ceil(obj.number_of_pilot_frames/2));
    datademod = leaddemod(:, ceil(obj.number_of_pilot_frames/2)+1:end-floor(obj.number_of_pilot_frames/2));
    lopilotdemod = leaddemod(:, end-floor(obj.number_of_pilot_frames/2)+1:end);
    %pilotdemod(1,1)
    
    pilotdemod = [lipilotdemod lopilotdemod]; 
    
    %pilotdemod_avg = mean(abs(pilotdemod')) .* exp((mean(angle(pilotdemod'))*sqrt(-1)));
    
    %pilotdemod_avg = mean(pilotdemod,2);
    % calculate the offsets
    
    if(obj.show > 0 && obj.showpeak == peak)
        scatterplot(reshape(pilotdemod,1,[]));
        title('pre-equalization pilots')
        scatterplot(reshape(datademod,1,[]));
        title('pre-equalization data')
    end
    
    sigcorrected = reshape(obj.equalize(pilotdemod, datademod), 1, []);
    
    if(obj.show > 0 && obj.showpeak == peak)
        scatterplot(sigcorrected);
        title('post-equalization signal')
    end
    
    if ~ ( (real(max(sigcorrected)) == Inf) || (imag(max(sigcorrected)) == Inf) )
        
        if(obj.show > 0)
            disp(['sigcorrected length = ', num2str(size(sigcorrected))]);
            size(sigcorrected);
        end
        bits = reshape(demodulate(demodulator,sigcorrected), [], 1);
        
        data = reshape(obj.data, [], 1);
        if(obj.show > 0)
            disp(['bits is size = ', num2str(size(bits))]);
            disp(['data is size = ', num2str(size(data))]);
        end
        if(length(bits) ~= length(data))
            errbits(peak) = NaN;
        else
            
            errors = symerr(bits, data) / length(data);
            %            if(peak == 1)
            %                rxdata = bits;
            %            else
            if( (numel(rxdata) < numel(bits)) || (errors < min( errbits / totalbits)))
                rxdata = bits;
            end
            %            end
            
            errbits(peak) = symerr(bits, data);
        end
        totalbits(peak) = length(data);
        
        
        
        
        photontop(peak) = min(mean(ofdmsig) +  3 * signalsize(peak), max(ofdmsig)); % 3 standard deviations away .. or actual maximum, whichever is lower.
        
        photonbot(peak) = max(mean(ofdmsig) - 3 * signalsize(peak), min(ofdmsig)); % 3 standard deviations away .. or actual minimum, whichever is lower
        
        
        
        if  obj.showpeak == peak && obj.show > 0
            figure;
            histogram(ofdmsigresampled, 1:1000);
            line([photontop(peak),photontop(peak)],[0,max(histcounts(ofdmsigresampled, 1:1000))],'color','red');
            line([photonbot(peak),photonbot(peak)],[0,max(histcounts(ofdmsigresampled, 1:1000))],'color','red');
        end
        
        if(size(const,1) == size(sigcorrected,1) || numel(const) == 0)
            const = horzcat(const, sigcorrected);
        end
        
    end
    
end

if(obj.show > 0)
    figure;
    ber = errbits ./ totalbits;
    plot(ber)
    title('BER against index of frame')
end

sig_energy = mean(meanphoton(meanphoton > 0)); 
sig_amp = mean(signalsize(signalsize > 0));
flat_noise_amp = mean(noisesize(noisesize > 0));
flat_noise_psd = mean(flatnoisepsd(flatnoisepsd > 0));

tbits = sum(totalbits);
terrors = sum(errbits);

photon_top = mean(photontop(photontop > 0));
photon_bot = mean(photonbot(photonbot > 0));

tcerr = terrors/tbits; % to be done some day.

ret.sampleratio = sampleratio; 
ret.rxdata = reshape(rxdata, 1, []);
ret.sig_amp = sig_amp;
ret.flat_noise_amp = flat_noise_amp;
ret.flat_noise_psd = flat_noise_psd; 
ret.photon_top = photon_top;
ret.photon_bot = photon_bot;
ret.tbits = tbits;
ret.terrors = terrors;
ret.calcterr = tcerr;
ret.const = const;
ret.energy = sig_energy;
if ~isempty(avgsignal)
    %disp(['size avgsignal = ', num2str(size(avgsignal))]);
    ret.signal = mean(avgsignal);
else
    ret.signal = 0; 
end

end

