function onOutputChannelNFreqResp(~,~)

global gui;
global FreqResp;

FreqResp.outputCHN = get(gui.outputChannelNFreqResp,'Value');