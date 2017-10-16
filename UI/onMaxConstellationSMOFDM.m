function onMaxConstellationSMOFDM(~,~)
global gui;
global SMOFDM;

SMOFDM.maxModulationOrder = 2^get(gui.maxConstellationSizeSMOFDM,'Value');