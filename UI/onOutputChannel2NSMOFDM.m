function onOutputChannel2NSMOFDM(~,~)
global gui;
global SMOFDM;

SMOFDM.outputCH2N = get(gui.outputChannel2NSMOFDM, 'Value');