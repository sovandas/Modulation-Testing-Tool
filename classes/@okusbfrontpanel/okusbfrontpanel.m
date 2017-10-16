classdef okusbfrontpanel < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ptr;
    end
    
    methods
        function obj = okusbfrontpanel()
            
            if ~libisloaded('okFrontPanel')
                loadlibrary('okFrontPanel', 'okFrontPanelDLL.h');
            end
            
            obj.ptr = calllib('okFrontPanel', 'okFrontPanel_Construct');
            
           
            
        end
    end
    
end

