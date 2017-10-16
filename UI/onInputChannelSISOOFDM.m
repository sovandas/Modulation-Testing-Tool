function onInputChannelSISOOFDM(~,~)
global gui;
global SISOOFDM;

SISOOFDM.inputCH = get(gui.inputChannelSISOOFDM, 'Value');