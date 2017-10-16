function onStartF(~,~)

global gui;
global FreqResp;

FreqResp.startF = str2double(get(gui.startF,'String'));