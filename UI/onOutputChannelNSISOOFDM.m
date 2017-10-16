function onOutputChannelNSISOOFDM(~,~)
global gui;
global SISOOFDM;

SISOOFDM.outputCHN = get(gui.outputChannelNSISOOFDM, 'Value');