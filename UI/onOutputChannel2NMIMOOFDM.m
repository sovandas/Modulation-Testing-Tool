function onOutputChannel2NMIMOOFDM(~,~)
global gui;
global MIMOOFDM;

MIMOOFDM.outputCH2N = get(gui.outputChannel2NMIMOOFDM, 'Value');