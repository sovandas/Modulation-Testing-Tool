function onInputChannel1SMOFDM(~,~)
global gui;
global SMOFDM;

SMOFDM.inputCH1 = get(gui.inputChannel1SMOFDM, 'Value');