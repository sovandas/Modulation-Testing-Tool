function onMaxConstellationSISOPAM(~,~)

global gui;
global SISOPAM;

SISOPAM.maxModulationOrder = 2^get(gui.maxConstellationSizeSISOPAM,'Value');