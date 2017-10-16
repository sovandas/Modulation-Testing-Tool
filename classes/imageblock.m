classdef imageblock < handle
    %IMAGEBLOCK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties %(SetAccess = private)
        images = {};
        loc = [1, 1, 1];
        
    end
    
    methods
        function obj = imageblock(obj)
        end
        
        function addimage(obj, path)
            obj.images{length(obj.images)+1} = round(imread(path)/8)*8 + 4; % reduce to 15-bit color
        end
        
        function showimage(obj,axes)
            image(obj.images{obj.loc(1)},'Parent',axes);
            axes.Visible = 'Off';
        end
        
        function data = getData(obj, length, axes) % maximum length in bits, returns BINARY data. imshow where to draw the current image
            pixelcount = 0;
            numpixels = floor((((length - 32) / 5) ) / 3);
            data = zeros(1,( (numpixels * 3 ) * 5) + 32 );
            data(1:32) = [ de2bi(uint16(obj.loc(2)),16,'left-msb'), de2bi(uint16(obj.loc(3)),16,'left-msb') ];
            while(pixelcount < numpixels)
                
                bitstart = (33+pixelcount*15);
                bitend = (33+pixelcount*15+14);
                
                bitdata = de2bi(obj.images{obj.loc(1)}(obj.loc(2),obj.loc(3),:),8);
                bitcutdata = bitdata(:,4:end); %% only send upper 5 bits
                data(bitstart:bitend) = reshape(bitcutdata',1,[]);
                
                %                 [...
                %                     de2bi(obj.images{obj.loc(1)}(obj.loc(2),obj.loc(3),1),8), ...
                 %                     de2bi(obj.images{obj.loc(1)}(obj.loc(2),obj.loc(3),2),8), ...
                %                     de2bi(obj.images{obj.loc(1)}(obj.loc(2),obj.loc(3),3),8)];
                
                obj.loc(3) = obj.loc(3) + 1;
                if(obj.loc(3) > size(obj.images{obj.loc(1)},2))
                    obj.loc(3) = 1;
                    obj.loc(2) = obj.loc(2) + 1;
                    if(obj.loc(2) > size(obj.images{obj.loc(1)},1))
                        obj.loc(2) = 1;
                        obj.loc(1) = obj.loc(1) + 1;
                        if(obj.loc(1) > numel(obj.images))
                            obj.loc(1) = 1;
                        end
                        % update display if changed image
                        showimage(obj,axes);
                        
                    end
                end
                pixelcount = pixelcount + 1;
            end
            
        end
        
        
        
        
    end
    
end

