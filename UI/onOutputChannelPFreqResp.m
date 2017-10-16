function onOutputChannelPFreqResp(~,~)

global gui;
global FreqResp;

FreqResp.outputCHP = get(gui.outputChannelPFreqResp,'Value');