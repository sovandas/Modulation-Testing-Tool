function onAdaptiveThresholdSMPAM(~,~)

global gui;
global SMPAM;

SMPAM.adaptiveThreshold = get(gui.maxConstellationSizeSMPAM, 'Value');