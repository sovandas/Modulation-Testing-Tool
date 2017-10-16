function onSamplesPerSymbol(~,~)
global gui;
global systemParameters;

systemParameters.samplesPerSymbol = floor(str2double(get(gui.SamplesPerSymbol,'String')));