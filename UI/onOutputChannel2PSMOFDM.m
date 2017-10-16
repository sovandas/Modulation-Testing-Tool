function onOutputChannel2PSMOFDM(~,~)
global gui;
global SMOFDM;

SMOFDM.outputCH2P = get(gui.outputChannel2PSMOFDM, 'Value');