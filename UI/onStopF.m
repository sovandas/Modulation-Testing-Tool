function onStopF(~,~)

global gui;
global FreqResp;

FreqResp.stopF = str2double(get(gui.stopF,'String'));