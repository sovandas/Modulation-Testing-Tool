function onAdaptiveThresholdSISOPAM(~,~)

global gui;
global SISOPAM;

SISOPAM.adaptiveThreshold = get(gui.adaptiveThresholdSISOPAM, 'Value');