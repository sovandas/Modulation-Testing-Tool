function onStepF(~,~)

global gui;
global FreqResp;

FreqResp.stepF = str2double(get(gui.stepF,'String'));