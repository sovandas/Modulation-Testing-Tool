function onVpp(~,~)

global gui;
global systemParameters;

systemParameters.Vpp = str2double(get(gui.Vpp,'String'));