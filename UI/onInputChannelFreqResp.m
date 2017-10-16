function onInputChannelFreqResp(~,~)

global FreqResp;
global gui;

FreqResp.inputCH = get(gui.inputChannelFreqResp,'Value');