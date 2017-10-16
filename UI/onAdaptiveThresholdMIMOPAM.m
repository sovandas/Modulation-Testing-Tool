function onAdaptiveThresholdMIMOPAM(~,~)

global gui;
global MIMOPAM;

MIMOPAM.adaptiveThreshold = get(gui.adaptiveThresholdMIMOPAM,'Value');