function [ret] = demodulate(obj, waveform)

rxdata = 0;

%SPADANALYZE Summary of this function goes here
%   Detailed explanation goes here

%load(filename);

%fprintf('Analyzing %s ...\n', filename);

overallidx = 1;

%% find sample rate of received obj.data sample

sampletime = mean(diff(waveform.XData));

samplerate = round(1/sampletime); %% in Hz.

%% upsample pilotseq
% pilotseq has samplerate of obj.freq * 1e6 /
pilotrate = obj.freq * 1e6;

sampleratio = samplerate / pilotrate;

%if( obj.samples_per_symbol*sampleratio > 1)
%    lpf = designfilt('lowpassfir','Passbandobj.frequency',2/(obj.samples_per_symbol*sampleratio), 'Stopbandobj.frequency',2/(obj.samples_per_symbol*sampleratio) + 2/(obj.samples_per_symbol*sampleratio*8), 'PassbandRipple',0.3,'StopbandAttenuation',80, 'DesignMethod','kaiserwin');

%    medfiltered = filter(lpf, waveformdata.Ydata);
%else
%    medfiltered = waveformdata.Ydata;
%end

medfiltered = waveform.YData;

%diffdata = diff(waveformdata.Rawdata);

%medfiltered = medfilt1(unfilterdata, 5)';

% lowpas the data
%d =designfilt('lowpassfir', 'Passbandobj.frequency', .15, 'Stopbandobj.frequency', .20, 'PassbandRipple', 1, 'StopbandAttenuation', 60, 'DesignMethod', 'kaiserwin');
%     d = designfilt('bandpassfir', 'FilterOrder', 40, 'Cutoffobj.frequency1', ...
%         0.05, 'Cutoffobj.frequency2', 0.15, 'StopbandAttenuation1', ...
%         60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, ...
%         'DesignMethod', 'cls');
%medfiltered = filter(d, medfiltered);

% medfiltered = medfiltered - mean(medfiltered);

%datalong = interp1( 10:obj.samples_per_symbol:(obj.samples_per_symbol*length(data)), obj.data, 10:(obj.samples_per_symbol*length(obj.data)), 'previous');
%obj.datalong = obj.datalong - mean(obj.datalong);
numberPilots = 100;
%
pilotsamples = obj.samples_per_symbol*numberPilots*2;
%
datalen = (length(obj.encodedData)) - pilotsamples;
%
% datalong = zeros(1,pilotsamples);

numberBitsSymbol = log2(obj.modorder);

for i = 1:numberPilots,
    %    figure;
    %    plot(pilotseq((i-1)*numberBitsSymbol+1:i*numberBitsSymbol))
    %    title('pilotsq')
    pilotdecimal(i) = bi2de(obj.pilotsequence((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb');
    leadoutdecimal(i) =  bi2de(obj.leadoutsequence((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb');
end


pilotcoded = real(pammod([pilotdecimal pilotdecimal],obj.modorder));
leadoutcoded = real(pammod(leadoutdecimal, obj.modorder));

pilotcoded = reshape(repmat(pilotcoded, obj.samples_per_symbol, 1), 1, []);
leadoutcoded = reshape(repmat(leadoutcoded, obj.samples_per_symbol, 1), 1, []);

if (obj.show > 1)
    figure;
    plot(pilotcoded);
    title('pilot waveform construct.');
    figure;
    plot(leadoutcoded);
    title('leadout waveform construct.');
end

%idx = 1;
%for j = 1:length(data)
%    for k = 1:10
%        datalong(idx) = data(j);
%        idx = idx + 1;
%    end
%end
% numberBitsSymbol = log2(obj.modorder);
% decimaldata = zeros(1,4000);
% for i = 1:4000
%     decimaldata(i) = bi2de(data((i-1)*numberBitsSymbol+1:i*numberBitsSymbol),'left-msb');
% end
%
%
% for i = 1:2*numberPilots,
%     datalong((i-1)*obj.samples_per_symbol+1:i*obj.samples_per_symbol) = repmat(obj.encodeddata(i),1,obj.samples_per_symbol);
% end
%
% %datalong = [zeros(1,1000*obj.samples_per_symbol) ones(1,1000*obj.samples_per_symbol) zeros(1,1000*obj.samples_per_symbol)]+1;
%
% figure;
% if obj.show >= 2
%
%     plot(datalong);
%     title('datalong');
% end
%



pilotsamples = pilotsamples * sampleratio;

pilotcoded_e = resample(pilotcoded, samplerate, pilotrate);

leadoutcoded_e = resample(leadoutcoded, samplerate, pilotrate);

[corr,lag] = xcorr(medfiltered, pilotcoded_e);

[lcorr, llag] = xcorr(medfiltered, leadoutcoded_e);

% xcorr offsets are one off for our purpose. 
lag = lag + 1;
llag = llag + 1; 

if obj.show > 1
    figure;
    plot(lcorr)
    title('leadout corr');
    figure;
    plot(corr)
    title('pilot corr');
    
    
end

[~, peaks] = findpeaks(corr, 'MinPeakDistance', length(obj.encodedData) * obj.samples_per_symbol*0.98*sampleratio);
[~, lpeaks] = findpeaks(lcorr, 'MinPeakDistance', length(obj.encodedData) * obj.samples_per_symbol*0.98*sampleratio);

if(obj.show > 1)
    for i = 2:(length(peaks-1))
        line([peaks(i), peaks(i)],[min(corr), max(corr)],'Color', 'red');
    end
end

if(obj.show >= 1)
    figure;
    plot(medfiltered)
    for i = 1:(length(peaks))
        line([lag(peaks(i)), lag(peaks(i))],[min(medfiltered), max(medfiltered)],'Color', 'red');
    end
    for i = 1:(length(lpeaks))
        line([llag(lpeaks(i)), llag(lpeaks(i))],[min(medfiltered), max(medfiltered)],'Color', 'green');
    end
    title('peaks found in correlation');
end

obj.showpeak = 1;


sigmean = zeros(1, length(peaks)-4);
signalamp = zeros(1,length(peaks)-4);
noiseamp = zeros(1,length(peaks)-4);
db = zeros(1,length(peaks)-4);
dbsnr = zeros(1,length(peaks)-4);
agwnoiseamp = zeros(1,length(peaks)-4);
dbagwn = zeros(1,length(peaks)-4);
flatnoiseamp = zeros(1,length(peaks)-4);
aphotontop = zeros(1,length(peaks) -4);

sigamp = 0;
sigvar = 0;
flatnamp = 0;
flatnvar = 0;
flatnpsd = 0;
aphotonbot = 0;
aphotontop = 0;
cerrors = 0;
cbits = 0;
cberc = 0;

datasig = [];
dataraw = [];

for peak = 1:(length(peaks)-1)
    
    if(lag(peaks(peak)) < 300*obj.samples_per_symbol*sampleratio)
        continue;
    end
    
    if(lag(peaks(peak)) > (length(medfiltered) - length(obj.encodedData) * obj.samples_per_symbol*sampleratio) )
        continue;
    end
    
    
    nextl = 1;
    
    while (llag(lpeaks(nextl)) < lag(peaks(peak)))
        nextl = nextl + 1;
        if(nextl > length(lpeaks))
            nextl = -1;
            break;
        end
    end
    if(nextl == -1)
        continue;
    end
    
    
    
    
    if (obj.show >= 1) && (obj.showpeak == peak)
        figure;
        plot(medfiltered)
        
        line([lag(peaks(peak)), lag(peaks(peak))],[min(medfiltered), max(medfiltered)],'Color', 'red');
        
        line([llag(lpeaks(nextl)), llag(lpeaks(nextl))],[min(medfiltered), max(medfiltered)],'Color', 'green');
        
        title('symbol to decode');
        
        figure
    end
    
    pamstart = lag(peaks(peak)) ;%-1
    pamend = llag(lpeaks(nextl)) -1;
    
    %pamsig = medfiltered( (lag(peaks(peak)))+1:(llag(lpeaks(nextl))) );
    
    pamsig = medfiltered(pamstart : pamend);
    
    actuallen = length(pamsig);
    reallen = (length(obj.encodedData) - numberPilots)*obj.samples_per_symbol*sampleratio;
    
    if actuallen ~= reallen
        if(abs(actuallen - reallen) < 10)
            reallen;
            d = linspace(1,actuallen,reallen);
            %disp('RESULTSIZE');
            %size(d);
            pamsig = interp1(1:actuallen, pamsig, d, 'spline')';
            %length(pamsig);
            
        else
            continue
        end
    end
    
    pamsig = pamsig((obj.samples_per_symbol*numberPilots*2)*sampleratio+1:end);
    
    pamsig = pamsig - min(pamsig);
    
    pamsig = reshape(pamsig, 1, []);
    
    if(obj.show > 0)
        disp(['size pamsig = ', num2str(size(pamsig))]);
    end
    %pamsig_raw = (diff( waveformdata.Rawdata( (lag(peaks(peak))+pilotsamples-1):(lag(peaks(peak))+datalen+pilotsamples) ) )) ;
    if(obj.show > 0) && (peak == obj.showpeak)
        figure;
        plot(pamsig)
        title('pamsig - raw');
        figure;
        fftsig = fft(pamsig);
        scatter(real(fftsig(2:floor(end/2))),imag(fftsig(2:floor(end/2))));
        title('fft of pamsig');
        figure;
        binsize = samplerate / length(fftsig);
        xax = linspace(0,samplerate,length(fftsig));
        line(xax(2:floor(end/2)),abs(fftsig(2:floor(end/2))),'color','blue');
        title('fft magnitude against obj.frequency');
        figure;
        line(xax(2:floor(end/2)), angle(fftsig(2:floor(end/2))), 'color', 'blue');
        title('fft angle against obj.frequency');
    end
    %pamsig_zeromean = pamsig - mean(pamsig);
    
    pamsig_mean = mean(pamsig);
    
    %pamsig_amplitude = sqrt(mean((pamsig_mean).^2)); % std dev calculation
    
    
    
    %% DECODE to levels
    if(obj.show > 0)
        disp(['obj.samples_per_symbol*sampleratio = ', num2str(obj.samples_per_symbol*sampleratio)]);
    end
    
    if(obj.filter == 1)
        
        filt = RRC(obj);
        fillen = length(filt);
        
        [dummy,sample_position] = max(filt); %Find the position of the middle value of the RRC filter
        
        pamsigdp = pamsig - mean(pamsig); % make dual- polar
        
        pamsig_filtered = conv(pamsigdp,filt)/obj.samples_per_symbol; %Match filter the signal with a RRC filter
        
        pamsig_filtered = pamsig_filtered - min(pamsig_filtered); % back to unipolar
       
    if(obj.show > 0)
        disp(['size(pamsig_filtered) = ', num2str(size(pamsig_filtered))]);
    end
        
        
        pamsig_decimate = pamsig_filtered(sample_position+1:obj.samples_per_symbol:end-sample_position+2);
        
        
    else
        
        if( obj.samples_per_symbol*sampleratio > 1)
            if(obj.samples_per_symbol*sampleratio < 4)
                if(obj.show > 0)
                    disp('used mean method');
                end
                pamsig_decimate = mean(reshape(pamsig, obj.samples_per_symbol*sampleratio,[]));
            else
                tpam = reshape(pamsig, obj.samples_per_symbol*sampleratio,[]);
                
                fact = normpdf(1:(obj.samples_per_symbol*sampleratio-2), (obj.samples_per_symbol*sampleratio-1)/2, (obj.samples_per_symbol*sampleratio-2)/2);
                fact = fact * (obj.samples_per_symbol*sampleratio)/sum(fact);
                fact = [0, fact,0];
                %fact = [0, ones(1,obj.samples_per_symbol*sampleratio-2), 0];
                mean(fact);
                for j = 1:length(tpam)
                    tpam(:,j) = tpam(:,j) .* (fact');
                end
                pamsig_decimate = mean(tpam);
            end
        else
            pamsig_decimate = reshape(pamsig, obj.samples_per_symbol, []);
        end
        
    end
    
    if(obj.show > 0)
        disp(['size pamsig_decimate = ', num2str(size(pamsig_decimate))]);
    end
    if(obj.show > 0)
        figure(38)
        plot(pamsig)
        start = floor(obj.samples_per_symbol/2)
        if(start < 1) start = 1; end
        line(start:obj.samples_per_symbol:length(pamsig_decimate)*obj.samples_per_symbol, pamsig_decimate, 'color', 'red')
        drawnow
    end
    
    pamsig_deci_flat = reshape(repmat(pamsig_decimate, obj.samples_per_symbol*sampleratio, 1),1,[]);
    
    if(obj.show > 0)
        disp(['size pamsig_deci_flat = ', num2str(size(pamsig_deci_flat))]);
    end
    
%    pamsig_amplitude = sqrt(mean( (pamsig_deci_flat - mean(pamsig_deci_flat)).^2));
%    pamsig_variance = var(pamsig_deci_flat);
    
    pamsig_amplitude = sqrt( mean( (pamsig - mean(pamsig)) .^2 )); 
    pamsig_variance = var(pamsig);  
    
    numvals = max(length(unique(pamsig_deci_flat))+1, obj.levels);
    
    % calculate lows and highs, taking into account pamness
    if((obj.show > 0) && (peak == obj.showpeak))
        figure(37);
        histogram(pamsig_deci_flat, linspace(min(pamsig_deci_flat),max(pamsig_deci_flat),numvals));
        title('pamsig - histogram')
    end
    [ashist,binedge] = histcounts(pamsig_deci_flat,linspace(min(pamsig_deci_flat),max(pamsig_deci_flat),numvals));
    %ashist = [zeros(1,floor(length(ashist)/4)),ashist,zeros(1,floor(length(ashist)/4))]
    [~, hidx] = findpeaks(ashist, 'SortStr', 'descend', 'NPeaks', obj.modorder, 'MinPeakProminence', 0.05*max(ashist), 'MinPeakDistance', length(ashist) / (1.6*obj.modorder));
    
    binmean = zeros(1,length(binedge)-1);
    for( t = 1:length(binedge)-1 )
        binmean(t) = (binedge(t) + binedge(t+1)) / 2;
    end
    if(obj.show > 0)
        disp(['size binmean = ', num2str(size(binmean)), ' size ashist = ', num2str(size(ashist))]);
    end
    hidx = sort((hidx));
    
    sigrange = linspace(min(pamsig_deci_flat),max(pamsig_deci_flat),length(ashist));
    
    for l =  1:length(hidx)
        hidx(l) = binmean(hidx(l));
    end
    
    if(obj.show > 0) && (peak == obj.showpeak)
        
        for( l = 1:length(hidx) )
            line([hidx(l), hidx(l)], [0, max(ashist)], 'color', 'red');
        end
    end
    
    
    
    %pamsig_amplitude = sqrt( mean( [hidx(1), hidx(end)] ) ); % std dev using 2 points only
    
    if length(hidx) == obj.modorder
        
        signalhigh =  medfiltered((lag(peaks(peak))-200*obj.samples_per_symbol*sampleratio):(lag(peaks(peak))-100*obj.samples_per_symbol*sampleratio));
        signallow =   medfiltered((lag(peaks(peak))-300*obj.samples_per_symbol*sampleratio):(lag(peaks(peak))-200*obj.samples_per_symbol*sampleratio));
        
        signal_a = mean(signalhigh);
        signal_b = mean(signallow);
        
        %    noise = [(signallow-signal_b) (signalhigh-signal_a)];
        
        noise_a = sqrt(mean((signalhigh-mean(signalhigh)).^2)); % std dev == RMS
        noise_b = sqrt(mean((signallow-mean(signallow)).^2)); % std dev == RMS
        
        
        
        if(obj.show > 3) && (peak == obj.showpeak)
            figure(46);
            plot(1:(300*obj.samples_per_symbol*sampleratio+1+datalen+pilotsamples), medfiltered( (lag(peaks(peak))-300*obj.samples_per_symbol*sampleratio):(lag(peaks(peak))+datalen+pilotsamples) ));
            
            line([1,100*obj.samples_per_symbol*sampleratio],[signal_b, signal_b],'color','red');
            line([100*obj.samples_per_symbol*sampleratio+1,200*obj.samples_per_symbol*sampleratio],[signal_a, signal_a],'color','red');
            
            line([1,100*obj.samples_per_symbol*sampleratio],[signal_b+noise_b, signal_b+noise_b],'color','black');
            line([1,100*obj.samples_per_symbol*sampleratio],[signal_b-noise_b, signal_b-noise_b],'color','black');
            line([100*obj.samples_per_symbol*sampleratio+1,200*obj.samples_per_symbol*sampleratio],[signal_a+noise_a, signal_a+noise_a],'color','black');
            line([100*obj.samples_per_symbol*sampleratio+1,200*obj.samples_per_symbol*sampleratio],[signal_a-noise_a, signal_a-noise_a],'color','black');
            
            line([300*obj.samples_per_symbol*sampleratio+1+pilotsamples,300*obj.samples_per_symbol*sampleratio+1+pilotsamples+datalen],[pamsig_mean, pamsig_mean], 'color', 'red');
            for i = 1:length(hidx)
                line([300*obj.samples_per_symbol*sampleratio+1+pilotsamples,300*obj.samples_per_symbol*sampleratio+1+pilotsamples+datalen],[hidx(i), hidx(i)],'color','black');
            end
        end
        
        ipre = obj.syncseqlen*obj.samples_per_symbol*sampleratio; 
        
        tweak = round(ipre/10);
        
        offsets = [ -3*ipre+tweak -2*ipre-tweak -2*ipre+tweak -1*ipre-tweak -1*ipre+tweak -tweak]; 
                    
        flat1 = medfiltered((lag(peaks(peak))+offsets(1)):(lag(peaks(peak))+offsets(2)));
        flat2 = medfiltered((lag(peaks(peak))+offsets(3)):(lag(peaks(peak))+offsets(4)));
        flat3 = medfiltered((lag(peaks(peak))+offsets(5)):(lag(peaks(peak))+offsets(6)));
        
        concatwave = [ (flat1 - mean(flat1)), (flat2 - mean(flat2)), (flat3 - mean(flat3))];
        
        concatwave = reshape(concatwave, 1, []);
        
        if(obj.show > 0)
            disp(['size concatwave = ', num2str(size(concatwave))]);
        end
        %flatnoiseamp = mean( [ sqrt(mean( ( (flat1 - mean(flat1)).^2 )  )),  sqrt(mean( ( (flat2 - mean(flat2)).^2 )  )),  sqrt(mean( ( (flat3 - mean(flat3)).^2 )  )) ] );
        %flatnoisevar = var([ sqrt(mean( ( (flat1 - mean(flat1)).^2 )  )),  sqrt(mean( ( (flat2 - mean(flat2)).^2 )  )),  sqrt(mean( ( (flat3 - mean(flat3)).^2 )  )) ]);
        %flatnoisepsd = mean(pwelch([ sqrt(mean( ( (flat1 - mean(flat1)).^2 )  )),  sqrt(mean( ( (flat2 - mean(flat2)).^2 )  )),  sqrt(mean( ( (flat3 - mean(flat3)).^2 )  )) ]));
        
        flatnoiseamp = sqrt(mean( concatwave .^ 2));
        flatnoisevar = var(concatwave);
        
        if(obj.show > 0)
            figure(45)
            plot(concatwave)
            title('concatwave for estimating PSD'); 
        end
        
        if(obj.getspectrum == 1)
            resp = pwelch(concatwave);
            hzperbin = samplerate / length(resp);
            flatnoisepsd = mean(resp) * (1/ hzperbin);
        else
            flatnoisepsd = NaN;
        end
        
        dbsnr = 10*log10(pamsig_amplitude/flatnoiseamp);
        
        % adj_data = zeros(1,obj.samples_per_symbol*length(data));
        
        %for j = 1:length(data)
        %    for k = 0:9
        %        adj_data(((j*10)-9)+k) = data(j);
        %    end
        %end
        
        %adj_data_nogain = (adj_data*2);
        %adj_data = (adj_data * 2) -1;
        
        
        %adj_data = (adj_data * pamsig_amplitude)  + pamsig_mean;
        %adj_data_nogain =  (adj_data_nogain * pamsig_amplitude) ;
        
        %[pam_corr,pam_lag] = xcorr(pamsig, adj_data, 100);
        
        %         figure;
        %         plot(pam_lag, pam_corr);
        %         title('Xcorr data with signal');
        
        %[~,pam_delay_index] = max(pam_corr);
        
        %pam_delay = pam_lag(pam_delay_index);
        
        %
        %         figure;
        %         plot(1:20000, pamsig, 1:20000, adj_data);
        %         title('original')
        %
        %         figure;
        %         plot(1:20000,pamsig, (1+pam_delay):(20000+pam_delay), adj_data);
        %         title(['shifted by' num2str(pam_delay)]);
        
        %if(pam_delay > 0)
        %    pamsig = pamsig((pam_delay+1):20000);
        %    adj_data_nogain = adj_data_nogain(1:(20000-pam_delay));
        %    adj_data = adj_data(1:(20000-pam_delay));
        %end
        %if(pam_delay < 0)
        %    pam_d_abs = abs(pam_delay);
        %    pamsig = pamsig(1:(20000-pam_d_abs));
        %    adj_data_nogain = adj_data_nogain( (pam_d_abs+1):20000);
        %    adj_data = adj_data( (pam_d_abs+1):20000);
        %end
        
        %        size(pamsig)
        %        size(adj_data_nogain)
        
        %        pamsig(1:10)
        %        adj_data(1:10)
        
        %[m,n] = size(adj_data_nogain);
        %[m1,n1] = size(pamsig);
        
        %if m == m1
        %    nosignal = pamsig - adj_data_nogain;
        %end
        
        %if m == n1
        %    nosignal = pamsig - adj_data_nogain';
        %end
        
        %    figure;
        %    plot(1:length(nosignal), pamsig, 1:length(nosignal), adj_data', 1:length(nosignal), nosignal);
        %    title('signal - nosignal - adjdata');
        
        
        
        
        
        pamsig_noise = pamsig_deci_flat - pamsig;
        
        pamsig_noise = sqrt(mean( (pamsig_noise - mean(pamsig_noise)).^2 ));
        if(obj.show > 0)
            disp(['pamsig noise = ', num2str(pamsig_noise)]);
            disp(['flat noise = ', num2str(flatnoiseamp)]);
        end
        if (obj.show > 0) && (peak == obj.showpeak)
            
            
            
            figure(36);
            plot(1:length(pamsig_deci_flat), pamsig_deci_flat);
            line(1:length(pamsig), pamsig, 'color', 'red');
            %        if obj.modorder == 4
            %            line( (1:obj.samples_per_symbol:datalen)+2, (decimaldata*2)-3, 'color', 'yellow');
            %        elseif obj.modorder == 2
            %            line( (1:obj.samples_per_symbol:datalen)+2, (decimaldata*2)-1, 'color', 'yellow');
            %        elseif obj.modorder == 8
            %            line( (1:obj.samples_per_symbol:datalen)+2, (decimaldata*2)-7, 'color', 'yellow');
            %        end
            
            title('Pamsig decimate');
        end
        
        lphoton_top = max(hidx);
        lphoton_bot = min(hidx);
        %pamsig_amplitude = sqrt( ((hidx(end) - hidx(1)).^2)/2); % std dev of the signal amps
        %pamsig_variance = var(
        if(obj.show > 0)
            disp(['pamsig decimate size = ', num2str(size(pamsig_decimate))]);
        end
        if obj.modorder == 2
            
            %find the threshold
            thresh(1) = (hidx(1) - hidx(2)) / (log(hidx(1)) - log(hidx(2)) );
            
            
            bits = zeros(1,length(pamsig_decimate));
            %pamsig_decimate = zeros(1, floor(length(pamsig)/samplesSumbol));
            
            for j = 1:length(pamsig_decimate)
                level = pamsig_decimate(j);
                
                if level < thresh(1)
                    bits(j) = 0;
                else
                    bits(j) = 1;
                end
            end
            
        elseif obj.modorder == 4
            
            % we do the demodulation manually as the threshholds are not uniformly spaced.
            
            thresh(1) = (hidx(1) - hidx(2)) / (log(hidx(1)) - log(hidx(2)) );
            thresh(2) = (hidx(2) - hidx(3)) / (log(hidx(2)) - log(hidx(3)) );
            thresh(3) = (hidx(3) - hidx(4)) / (log(hidx(3)) - log(hidx(4)) );
            
            bits = zeros(1,length(pamsig_decimate));
            %pamsig_decimate = zeros(1, floor(length(pamsig)/samplesSumbol));
            
            for j = 1:length(pamsig_decimate)
                level = pamsig_decimate(j);
                
                if level < thresh(1)
                    bits(j) = 0;
                elseif level < thresh(2)
                    bits(j) = 1;
                elseif level < thresh(3)
                    bits(j) = 2;
                else
                    bits(j) = 3;
                end
            end
        elseif obj.modorder == 8
            
            % we do the demodulation manually as the threshholds are not uniformly spaced.
            
            thresh(1) = (hidx(1) - hidx(2)) / (log(hidx(1)) - log(hidx(2)) );
            thresh(2) = (hidx(2) - hidx(3)) / (log(hidx(2)) - log(hidx(3)) );
            thresh(3) = (hidx(3) - hidx(4)) / (log(hidx(3)) - log(hidx(4)) );
            thresh(4) = (hidx(4) - hidx(5)) / (log(hidx(4)) - log(hidx(5)) );
            thresh(5) = (hidx(5) - hidx(6)) / (log(hidx(5)) - log(hidx(6)) );
            thresh(6) = (hidx(6) - hidx(7)) / (log(hidx(6)) - log(hidx(7)) );
            thresh(7) = (hidx(7) - hidx(8)) / (log(hidx(7)) - log(hidx(8)) );
            
            bits = zeros(1,length(pamsig_decimate));
            
            for j = 1:length(pamsig_decimate)
                level = pamsig_decimate(j);
                
                if level < thresh(1)
                    bits(j) = 0;
                elseif level < thresh(2)
                    bits(j) = 1;
                elseif level < thresh(3)
                    bits(j) = 2;
                elseif level < thresh(4)
                    bits(j) = 3;
                elseif level < thresh(5)
                    bits(j) = 4;
                elseif level < thresh(6)
                    bits(j) = 5;
                elseif level < thresh(7)
                    bits(j) = 6;
                else
                    bits(j) = 7;
                end
            end
        elseif obj.modorder == 16
            
            % we do the demodulation manually as the threshholds are not uniformly spaced.
            
            thresh(1) = (hidx(1) - hidx(2)) / (log(hidx(1)) - log(hidx(2)) );
            thresh(2) = (hidx(2) - hidx(3)) / (log(hidx(2)) - log(hidx(3)) );
            thresh(3) = (hidx(3) - hidx(4)) / (log(hidx(3)) - log(hidx(4)) );
            thresh(4) = (hidx(4) - hidx(5)) / (log(hidx(4)) - log(hidx(5)) );
            thresh(5) = (hidx(5) - hidx(6)) / (log(hidx(5)) - log(hidx(6)) );
            thresh(6) = (hidx(6) - hidx(7)) / (log(hidx(6)) - log(hidx(7)) );
            thresh(7) = (hidx(7) - hidx(8)) / (log(hidx(7)) - log(hidx(8)) );
            thresh(8) = (hidx(8) - hidx(9)) / (log(hidx(8)) - log(hidx(9)) );
            thresh(9) = (hidx(9) - hidx(10)) / (log(hidx(9)) - log(hidx(10)) );
            thresh(10) = (hidx(10) - hidx(11)) / (log(hidx(10)) - log(hidx(11)) );
            thresh(11) = (hidx(11) - hidx(12)) / (log(hidx(11)) - log(hidx(12)) );
            thresh(12) = (hidx(12) - hidx(13)) / (log(hidx(12)) - log(hidx(13)) );
            thresh(13) = (hidx(13) - hidx(14)) / (log(hidx(13)) - log(hidx(14)) );
            thresh(14) = (hidx(14) - hidx(15)) / (log(hidx(14)) - log(hidx(15)) );
            thresh(15) = (hidx(15) - hidx(16)) / (log(hidx(15)) - log(hidx(16)) );
            
            bits = zeros(1,length(pamsig_decimate));
            
            for j = 1:length(pamsig_decimate)
                level = pamsig_decimate(j);
                
                if level < thresh(1)
                    bits(j) = 0;
                elseif level < thresh(2)
                    bits(j) = 1;
                elseif level < thresh(3)
                    bits(j) = 2;
                elseif level < thresh(4)
                    bits(j) = 3;
                elseif level < thresh(5)
                    bits(j) = 4;
                elseif level < thresh(6)
                    bits(j) = 5;
                elseif level < thresh(7)
                    bits(j) = 6;
                elseif level < thresh(8)
                    bits(j) = 7;
                elseif level < thresh(9)
                    bits(j) = 8;
                elseif level < thresh(10)
                    bits(j) = 9;
                elseif level < thresh(11)
                    bits(j) = 10;
                elseif level < thresh(12)
                    bits(j) = 11;
                elseif level < thresh(13)
                    bits(j) = 12;
                elseif level < thresh(14)
                    bits(j) = 13;
                elseif level < thresh(15)
                    bits(j) = 14;
                else
                    bits(j) = 15;
                end
            end
        elseif obj.modorder == 32
            % we do the demodulation manually as the threshholds are not uniformly spaced.
            thresh = zeros(31);
            for(i = 1:31)
                j = i + 1;
                thresh(i) = (hidx(i) - hidx(j)) / (log(hidx(i)) - log(hidx(j)) );
            end
            
            bits = zeros(1,length(pamsig_decimate));
            
            for j = 1:length(pamsig_decimate)
                level = pamsig_decimate(j);
                
                bits(j) = 31;
                for(i = 1:31)
                    if(level < thresh(i))
                        bits(j) = i - 1;
                        break;
                    end
                end
                
            end
        elseif obj.modorder == 64
            % we do the demodulation manually as the threshholds are not uniformly spaced.
            thresh = zeros(63);
            for(i = 1:63)
                j = i + 1;
                thresh(i) = (hidx(i) - hidx(j)) / (log(hidx(i)) - log(hidx(j)) );
            end
            
            bits = zeros(1,length(pamsig_decimate));
            
            for j = 1:length(pamsig_decimate)
                level = pamsig_decimate(j);
                
                bits(j) = 63;
                for(i = 1:63)
                    if(level < thresh(i))
                        bits(j) = i - 1;
                        break;
                    end
                end
                
            end
        end
        
        actualbits = zeros(1, length(bits)*log2(obj.modorder));
        
        graydepth = obj.modorder;
        
        %        for k = 1:length(bits)
        %            actualbits(((k-1)*log2(obj.modorder))+1:(k*log2(obj.modorder))) = de2bi(gray2bin(bits(k),'pam',graydepth),log2(obj.modorder),'left-msb');
        %        end
        
        actualbits = reshape( de2bi(gray2bin(bits,'pam',graydepth),log2(obj.modorder),'left-msb')', 1, [] );
        
        if(obj.show > 0)
            disp(['size bits = ',num2str(size(bits))]);
            disp(['size actualbits = ',num2str(size(actualbits))]);
            disp(['size obj.data = ',num2str(size(obj.data))]);
        end
        biterror = symerr(actualbits, obj.data);
        bitlen    = length(obj.data);
        
        if(obj.show > 0)
            origdata = zeros(1,(length(obj.data)/log2(obj.modorder)));
            for(i = 1:(length(obj.data)/log2(obj.modorder)))
                origdata(i) =  bin2gray(bi2de(obj.data((i-1)*log2(obj.modorder)+1:i*log2(obj.modorder)),'left-msb'),'pam',graydepth);
            end
            if(obj.show > 0)
                disp(['size origdata = ',num2str(size(origdata))]);
            end
            origdata_m = reshape(repmat(origdata,obj.samples_per_symbol*sampleratio,1),1,[]);
            
            origdata_m = origdata_m - min(origdata_m);
            origdata_m = origdata_m / max(origdata_m);
            origdata_m = origdata_m * (max(hidx) - min(hidx));
            origdata_m = origdata_m - mean(origdata_m) + mean(hidx);
            if(obj.show > 0)
                disp(['size origdata_m = ',num2str(size(origdata_m))]);
            end
            errorindex = zeros(1,2);
            errrow = 1;
            if (obj.show > 0) && (peak == obj.showpeak)
                
                for(p = 1:length(origdata))
                    if(origdata(p) == bits(p))
                    else
                        offset = (p-1) * obj.samples_per_symbol*sampleratio + 1;
                        line([offset, offset + obj.samples_per_symbol*sampleratio], [max(pamsig), max(pamsig)], 'color', 'red')
                        
                    end
                end
                line(1:length(origdata_m),origdata_m, 'color', 'green')
                for i = 1:length(hidx)
                    line([1,length(origdata_m)],[hidx(i), hidx(i)],'color','black');
                end
                
                
            end
            
            for(p = 1:length(origdata))
                if(origdata(p) == bits(p))
                else
                    errorindex(errrow) = p;
                    errrow = errrow + 1;
                end
            end
        end
        if(obj.show > 0)
            disp(['errors at indicies: ', num2str(errorindex(1:min(10,end))), ' offsets: ', num2str( (errorindex(1:min(10,end))-1) * obj.samples_per_symbol*sampleratio + 1)]);
            
            disp(['size biterror = ',num2str(size(biterror))]);
            disp(['biterror = ',num2str(biterror)]);
        end
        %        if mean(nosignal) > 0
        sigmean(overallidx) = pamsig_mean;
        sigamp(overallidx) = pamsig_amplitude;
        sigvar(overallidx) = pamsig_variance;
        %            namp(overallidx) = noiseamp(i-2);
        %            agwnamp(overallidx) = agwnoiseamp(i-2);
        %            dbo(overallidx) = db(i-2);
        %            dbagwno(overallidx) =  dbagwn(i-2);
        dbo(overallidx) = dbsnr;
        flatnamp(overallidx) = flatnoiseamp;
        flatnvar(overallidx) = flatnoisevar;
        flatnpsd(overallidx) = flatnoisepsd;
        aphotontop(overallidx) = lphoton_top;
        aphotonbot(overallidx) = lphoton_bot;
        cerrors(overallidx) = biterror;
        cbits(overallidx) = bitlen;
        
        if(overallidx == 1)
            rxdata = actualbits;
            datasig = pamsig_deci_flat;
        else
            if(min(cberc) > (biterror/bitlen))
                rxdata = actualbits;
                datasig = pamsig_deci_flat;
            end
        end
        
        cberc(overallidx) = biterror / bitlen;
        
        overallidx = overallidx + 1;
        %        end
        
        if (obj.show > 1) && (obj.showpeak == i)
            
            figure;
            
            histogram(pamsig, min(pamsig):max(pamsig), 'Normalization','probability');
            
            for j = 1:length(hidx)
                g  = (1/(obj.modorder)) *  poisspdf(min(pamsig):max(pamsig), hidx(j));
                line(min(pamsig):max(pamsig), g, 'Color', 'red');
            end
        end
        
    else % we did NOT get the peaks - record it as n failed bits :P
        
        sigmean(overallidx) = 0;
        sigamp(overallidx) = 0;
        %            namp(overallidx) = noiseamp(i-2);
        %            agwnamp(overallidx) = agwnoiseamp(i-2);
        %            dbo(overallidx) = db(i-2);
        %            dbagwno(overallidx) =  dbagwn(i-2);
        dbo(overallidx) = 0;
        flatnamp(overallidx) = 0;
        aphotontop(overallidx) = 0;
        aphotonbot(overallidx) = 0;
        cerrors(overallidx) = length(obj.data)/2;
        cbits(overallidx) = length(obj.data);
        cberc(overallidx) = 0;
        overallidx = overallidx + 1;
        
        
        
    end
    
    pamsig_disp = (( pamsig - mean(pamsig) ) * (obj.modorder -1)) / (max(abs(pamsig - mean(pamsig))));
    
    
end


if obj.show > 2
    
    figure;
    
    for i = 2:(length(peaks)-1)
        
        pamsig = medfiltered( (lag(peaks(i)))+pilotsamples:(lag(peaks(i))+datalen+pilotsamples-1) );
        
        if dbsnr(i-1) == min(dbsnr)
            histogram(pamsig, max(pamsig)-min(pamsig), 'FaceColor', 'red', 'Normalization','probability');
            mu = sigmean(i-1) + sigamp(i-1)/2;
            glx = min(pamsig):max(pamsig);
            gl  = normpdf(glx, mu, sqrt(mu));
            
            hold on
        end
        
        if dbsnr(i-1) == max(dbsnr)
            histogram(pamsig, max(pamsig)-min(pamsig), 'FaceColor', 'blue', 'Normalization','probability');
            mu = sigmean(i-1) + sigamp(i-1)/2;
            gux = min(pamsig):max(pamsig);
            gu  = normpdf(gux, mu, sqrt(mu));
            
            hold on
        end
        
    end
    
    line(glx, gl, 'Color', 'red');
    line(gux, gu, 'Color', 'blue');
    
end

%hold off




if obj.show > 1
    figure;
    plot(sigamp);
    title('Signal Amplitude (Photons)');
    %    figure;
    %    plot(namp);
    %    title('Bottom of signal amplitude (Photons)');
    %    figure;
    %    plot(agwnamp);
    %    title('Noise around bottom of signal (Photons)');
    %    figure;
    %    plot(dbo);
    %    title('Dynamic range in dB');
    %    figure;
    %    plot(dbagwno);
    %    title('Useless graph - ignore');
    figure;
    plot(flatnamp);
    title('AGWN Noise std dev (Photons)')
    line([1, length(flatnamp)],[geomean(flatnamp), geomean(flatnamp)], 'color', 'red');
    
    snr = 10*log10(sigamp ./ flatnamp);
    
    figure;
    plot(snr);
    title('SNR in dB');
    line([1, length(snr)], [geomean(snr), geomean(snr)], 'color', 'red');
    
    ber = cerrors ./ cbits;
    
    figure;
    plot(ber);
    title('BER');
    line([1, length(ber)], [geomean(ber), geomean(ber)], 'color', 'red');
    line(1:length(cberc), cberc, 'color', 'green');
    
end

if size(sigamp) < [1,2]
    disp(['Error analyzing file ', filename])
    sig_amp = 0;
    noise_amp= 0;
    agwn_noise_amp = 0;
    flat_noise_amp = 0;
    snr = 0;
    snr_agwn = 0;
    snr_flat = 0;
    calcterr = 1;
    pamsig_energy = 0; 
else
    pamsig_energy = mean(sigmean(sigmean > 0)); 
    sig_amp = mean(sigamp(sigamp > 0));
    sig_var = mean(sigvar(sigvar > 0));
    %    noise_amp= mean(namp);
    %    agwn_noise_amp = mean(agwnamp);
    flat_noise_amp = mean(flatnamp(flatnamp > 0));
    flat_noise_var = mean(flatnvar(flatnvar > 0));
    flat_noise_psd = mean(flatnpsd(flatnpsd > 0));
    photon_top = mean(aphotontop(aphotontop > 0));
    photon_bot = mean(aphotonbot(aphotonbot > 0));
    %    snr = 10*log10(sig_amp/noise_amp);
    %    snr_agwn = 10*log10(sig_amp/agwn_noise_amp);
    %snr_flat = 10*log10(sig_amp/flat_noise_amp);
    tbits = sum(cbits);
    terrors = sum(cerrors);
    calcterr = terrors / tbits;
end


ret.rxdata = rxdata;
ret.sig_amp = sig_amp;
ret.sig_var = sig_var;
ret.flat_noise_amp = flat_noise_amp;
ret.flat_noise_var = flat_noise_var;
ret.flat_noise_psd = flat_noise_psd;
ret.photon_top = photon_top;
ret.photon_bot = photon_bot;
ret.tbits = tbits;
ret.terrors = terrors;
ret.calcterr = calcterr;
ret.sampleratio = sampleratio;
ret.datasig = datasig;
ret.dataraw = dataraw;
ret.energy = pamsig_energy; 



end


