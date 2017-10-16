function onMaxConstelllationSMPAM(~,~)

global gui;
global SMPAM;

SMPAM.maxModulationOrder = 2^get(gui.maxConstellationSizeSMPAM,'Value');