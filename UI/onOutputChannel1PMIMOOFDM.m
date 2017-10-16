function onOutputChannel1PMIMOOFDM(~,~)
global gui;
global MIMOOFDM;

MIMOOFDM.outputCH1P = get(gui.outputChannel1PMIMOOFDM, 'Value');