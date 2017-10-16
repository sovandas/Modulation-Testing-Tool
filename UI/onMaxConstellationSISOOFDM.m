function onMaxConstellationSISOOFDM(~,~)
global gui;
global SISOOFDM;

SISOOFDM.maxModulationOrder = 2^get(gui.maxConstellationSizeSISOOFDM,'Value');