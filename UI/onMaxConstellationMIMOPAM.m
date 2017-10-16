function onMaxConstellationMIMOPAM(~,~)

global gui;
global MIMOPAM;

MIMOPAM.maxModulationOrder = 2^get(gui.maxConstellationSizeMIMOPAM, 'Value');