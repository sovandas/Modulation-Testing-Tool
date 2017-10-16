function onOutputChannelPSISOPAM(~,~)

global gui;
global SISOPAM;

SISOPAM.outputCHP = get(gui.outputChannelPSISOPAM, 'Value');