function id = getdevicecount(obj)

[id,id2] = calllib('okFrontPanel', 'okFrontPanel_GetDeviceCount', obj.ptr);

