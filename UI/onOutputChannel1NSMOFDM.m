function onOutputChannel1NSMOFDM(~,~)
global gui;
global SMOFDM;

SMOFDM.outputCH1N = get(gui.outputChannel1NSMOFDM, 'Value');