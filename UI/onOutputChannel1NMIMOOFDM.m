function onOutputChannel1NMIMOOFDM(~,~)
global gui;
global MIMOOFDM;

MIMOOFDM.outputCH1N = get(gui.outputChannel1NMIMOOFDM, 'Value');