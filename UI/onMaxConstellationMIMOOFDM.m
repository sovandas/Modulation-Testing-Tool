function onMaxConstellationMIMOOFDM(~,~)
global gui;
global MIMOOFDM;

MIMOOFDM.maxModulationOrder = 2^get(gui.maxConstellationSizeMIMOOFDM,'Value');