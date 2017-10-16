function onOutputChannelNSISOPAM(~,~)

global gui;
global SISOPAM;

SISOPAM.outputCHN = get(gui.outputChannelNSISOPAM, 'Value');