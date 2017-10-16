function onScopeType(~,~)
global gui;
global systemParameters;

systemParameters.ScopeType = get(gui.ScopeType,'Value');

if systemParameters.ScopeType == 2,
    % UP-VLC SPAD
    set(gui.ScopeAddress,'Enable','on');
    set(gui.ScopeAddress,'String','photontorrent_aa::1447000A9T')
    systemParameters.ScopeAddress = get(gui.ScopeAddress,'String');
    systemParameters.SPADChipMode = 6; % default to 25MHz
    systemParameters.SPADVoffset = 1.0;
        set(gui.SPADChipMode, 'Enable', 'on');
    set(gui.SPADChipMode, 'Value', 1); 
    set(gui.SPADChipModeText, 'Enable', 'on');
    set(gui.SPADVoffset, 'Enable', 'on');
    set(gui.SPADVoffset, 'String', '1.0');
    set(gui.SPADVoffsetText, 'Enable', 'on');
else
    % Need address space
    set(gui.ScopeAddress,'Enable','on');
    set(gui.ScopeAddress,'String','USB0::0x0957::0x175D::my50340603::0::INSTR'); 
    set(gui.SPADChipMode, 'Enable', 'off');
    set(gui.SPADChipModeText, 'Enable', 'off');
    set(gui.SPADVoffset, 'Enable', 'off');
    set(gui.SPADVoffsetText, 'Enable', 'off');
end