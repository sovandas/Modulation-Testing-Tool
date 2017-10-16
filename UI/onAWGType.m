function onAWGType(~,~)
global gui;
global systemParameters;

systemParameters.AWGType = get(gui.AWGType,'Value');

if systemParameters.AWGType == 3,
    % UP-VLC DAC
    set(gui.AWGAddress,'String','1447000A98');
    systemParameters.AWGAddress = '1447000A98';
else
    % Standard Address
    set(gui.AWGAddress,'String','TCPIP0::192.168.0.223::5025::SOCKET');
    systemParameters.AWGAddress = 'TCPIP0::192.168.0.223::5025::SOCKET';
end