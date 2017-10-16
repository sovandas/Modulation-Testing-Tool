function id = getdevicelistserial(obj,idx)

[xid,id] = calllib('okFrontPanel', 'okFrontPanel_GetDeviceListSerial', obj.ptr, idx, '                                 ');

