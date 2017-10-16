function onOutputChannel1PSMOFDM(~,~)
global gui;
global SMOFDM;

SMOFDM.outputCH1P = get(gui.outputChannel1PSMOFDM, 'Value');