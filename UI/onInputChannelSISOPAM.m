function onInputChannelSISOPAM(~,~)

global gui;
global SISOPAM;

SISOPAM.inputCH = get(gui.inputChannelSISOPAM, 'Value');