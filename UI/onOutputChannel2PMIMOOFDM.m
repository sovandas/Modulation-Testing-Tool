function onOutputChannel2PMIMOOFDM(~,~)
global gui;
global MIMOOFDM;

MIMOOFDM.outputCH2P = get(gui.outputChannel2PMIMOOFDM, 'Value');