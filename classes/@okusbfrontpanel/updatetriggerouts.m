function updatetriggerouts(obj)

%UPDATETRIGGEROUTS  Update all TriggerOut endpoints on the device.
%
%  Copyright (c) 2005 Opal Kelly Incorporated
%  $Rev: 971 $ $Date: 2011-05-27 08:59:56 -0500 (Fri, 27 May 2011) $

calllib('okFrontPanel', 'okFrontPanel_UpdateTriggerOuts', obj.ptr);
