function onOffset(~,~)

global gui;
global systemParameters;

systemParameters.offset = str2double(get(gui.offset,'String'));