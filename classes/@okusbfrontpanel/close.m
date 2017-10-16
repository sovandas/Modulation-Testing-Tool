function obj=close(obj)

%CLOSE  Close an Opal Kelly FrontPanel-enabled device.
%  Opens an attached device by serial number.
%
%  OBJ=OPENBYSERIAL(OBJ, '') opens the first device found.
%
%  OBJ=OPENBYSERIAL(OBJ, STRING) opens a device identified by serial
%  number STRING.
%
%  Copyright (c) 2005 Opal Kelly Incorporated
%  $Rev: 971 $ $Date: 2011-05-27 08:59:56 -0500 (Fri, 27 May 2011) $


calllib('okFrontPanel', 'okFrontPanel_Close', obj.ptr);
