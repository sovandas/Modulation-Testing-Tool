function onOutputChannelPSISOOFDM(~,~)
global gui;
global SISOOFDM;

SISOOFDM.outputCHP = get(gui.outputChannelPSISOOFDM, 'Value');