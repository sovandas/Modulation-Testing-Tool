function xid = getdevicelistmodel(obj,idx)

[xid,id] = calllib('okFrontPanel', 'okFrontPanel_GetDeviceListModel', obj.ptr, idx);

