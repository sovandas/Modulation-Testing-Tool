function [res] = derivelinearity(obj, wf, do_ppc, do_linearity)
%demodulates AND uses the data to derive a linearization compensation

if(nargin < 3)
    do_ppc = 1;
    do_linearity = 1;
end
if(nargin < 4)
    do_linearity = 1;
end

res = obj.demodulate(wf);

if(numel(res.signal) > 10) % if we did indeed decode correctly.
    
    if(do_linearity)
        
        [sorted_nomap, order] = sort(obj.ofdmsig_nomapping);
        
        %  figure(37)
        %  toplot = res.signal - min(res.signal);
        %  toplot = toplot * (max(obj.ofdmsig_nomapping) - min(obj.ofdmsig_nomapping)) / max(toplot);
        %  toplot = toplot + min(obj.ofdmsig_nomapping);
        
        %   plot(obj.ofdmsig_nomapping);
        %   line(1:length(toplot), toplot, 'color', 'green');
        %   title('Comparison sent and received')
        
        sorted = obj.ofdmsig(order);
        
        if(length(res.signal) > length(sorted_nomap))
            disp('concatenating res.signal')
            res.signal = res.signal(1:length(sorted_nomap));
        end
        if(length(res.signal) < length(sorted_nomap))
            disp('resorting signal')
            [sorted_nomap, order] = sort(obj.ofdmsig_nomapping(1:length(res.signal)));
        end
        
        %  figure(38);
        %  plot(sorted)
        
        %  figure(39);
        %  plot(res.signal(order));
        
        %  figure(40)
        %  plot(sort(res.signal))
        
        smoothed = smooth(res.signal(order), 1000, 'lowess');
        
        % scale to the same size as modem.ofdmsig (or 'sorted')
        
        smoothed = smoothed - min(smoothed);
        smoothed = smoothed';
        smoothed = smoothed * (max(sorted_nomap) - min(sorted_nomap)) / max(smoothed);
        
        sorted = sorted - min(sorted);
        sorted_nomap = sorted_nomap - min(sorted_nomap);
        
        original = interp1(1:length(obj.mapping), obj.mapping, linspace(1,length(obj.mapping),length(unique(sorted_nomap))));
        
        corr = original;
        for code = unique(sorted_nomap)
            % sorted_nomap is the level that we _should_ be at
            actuallevel = mean(smoothed(sorted_nomap == code)); % find what level we received at
            %    txlevel = mean(sorted(sorted_nomap == code)); % and what level we transmitted at
            targetlevel = code; % the level we want to receive at
            
            if(actuallevel > targetlevel)
                
                % fraction of distance to ceiling
                frac(code + 1) = -((actuallevel - code) / (max(sorted_nomap) - code));
                
                corr(code+1) = original(code+1) + (original(code+1) - min(original)) * frac(code+1)*2/3;
                
                
            else
                
                % fraction of distance to floor
                frac(code+1) = (code - actuallevel) / ( code - min(sorted_nomap));
                
                corr(code+1) = original(code+1) + (original(code+1) - min(original)) * frac(code+1)*2/3;
                
                
            end
            
            
        end
        
        corr = smooth(corr, length(corr)/4, 'lowess');
        
        if(obj.show == 1)
            figure(10)
            line(1:length(sorted_nomap), sorted_nomap, 'color', 'blue');
            %line(1:length(sorted), sorted, 'color', 'red');
            line(1:length(smoothed), smoothed, 'color', 'green');
            title('linearizer gap to perfect')
            
            figure(11);
            line(1:length(original), original, 'color', 'blue');
            line(1:length(corr), corr, 'color', 'green');
            
            figure(13)
            line(1:length(frac), frac);
        end
        
        minidx = find(corr == min(corr));
        
        corr(1:minidx) = min(corr);
        
        maxidx = find(corr == max(corr));
        
        corr(maxidx:end) = max(corr);
        
        
        corr(corr < obj.minlevel) = obj.minlevel;
        
        corr(corr > obj.minlevel + obj.levels) = obj.minlevel + obj.levels;
        
        corr = interp1(1:length(corr), corr, linspace(1, length(corr), obj.minlevel + obj.levels+1));
        
        obj.mapping = corr;
        
    end
    
    if(do_ppc)
        
        %%%% and do the power per subcarrier thing as well..
        powerpercarrier = mean(abs(reshape(res.const, obj.nfft/2-1, [])),2);
        ppc = 1./powerpercarrier;
        ppc = ppc - mean(ppc) + 1;
        %if(obj.show > 0)
        f = figure(12);
        
        line(1:length(powerpercarrier), powerpercarrier,'color', [0 0 0])
        title('Received power per carrier')
        
        lines = 1;
        while lines <= length(f.CurrentAxes.Children)
            if(all(f.CurrentAxes.Children(lines).Color == [1 1 1]))
                delete(f.CurrentAxes.Children(lines))
                continue;
            end
            f.CurrentAxes.Children(lines).Color = max(0.1, min(1, ((f.CurrentAxes.Children(lines).Color) +0.2)));
            lines = lines + 1;
        end
        
        drawnow;
        %end
        obj.set_powerloading(ppc);
        
    end
end


end