classdef imageconstruct < handle
    %IMAGECONSTRUCT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private); 
        finalimg;
        xdim = 1000;
        ydim = 1000;
    end
    
    methods
        
        function obj = imageconstruct(xdim, ydim)
            obj.finalimg = uint8(zeros(ydim, xdim, 3)); 
            obj.xdim = xdim;
            obj.ydim = ydim; 
        end
        
        function showimage(obj, axes)
            image(obj.finalimg,'Parent',axes);
            axes.Visible = 'Off';
        end
        
        function reconstruct(obj, rxdata, axes)
            
            yloc = bi2de(rxdata((16-nextpow2(obj.ydim)+1):16),'left-msb');
            xloc = bi2de(rxdata((32-nextpow2(obj.xdim)+1):32),'left-msb');
            
            if(xloc <= obj.xdim && yloc <= obj.ydim && xloc > 0 && yloc > 0)
                
                for bpos = 33:15:length(rxdata)-14
                    obj.finalimg(yloc,xloc,1) = uint8(bi2de(rxdata(bpos:bpos+4))*8 + 4);
                    obj.finalimg(yloc,xloc,2) = uint8(bi2de(rxdata(bpos+5:bpos+9))*8 + 4);
                    obj.finalimg(yloc,xloc,3) = uint8(bi2de(rxdata(bpos+10:bpos+14))*8 + 4);
                    xloc = xloc + 1;
                    if(xloc > obj.xdim)
                        xloc = 1;
                        yloc = yloc + 1;
                        if(yloc > obj.ydim)
                            yloc = 1;
                        end
                    end
                end
            else
                fprintf('xloc: %d yloc %d  - out of area!\n', xloc, yloc);
            end
            
            obj.showimage(axes); 
        end
    end
    
end

