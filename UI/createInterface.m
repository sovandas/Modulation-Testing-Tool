function [gui, h] = createInterface()
% Generates the GUI and returns a structure of handles of it

gui.Window = figure( ...
    'Name','Modulation Testing Tool', ...
    'NumberTitle','off', ...
    'MenuBar','none',...
    'Toolbar','none',...
    'HandleVisibility','off', ...
    'Position', [1 1 1000 500], ...
    'CloseRequestFcn', @onMTTGUIClose);
movegui(gui.Window,'center');
% Warn user to wait
h = figure('windowstyle','modal', ...
    'NumberTitle','off', ...
    'MenuBar','none',...
    'Toolbar','none',...
    'HandleVisibility','off', ...
    'Position', [1 1 200 50], ...
    'Name','Warning', ...
    'CloseRequestFcn','');
%uiextras.set(h, 'DefaultBoxPanelTitleColor', [0.7 1.0 0.7]);
hLayout = uiextras.VBox('Parent',h,'Padding',15,'Spacing',10);
uicontrol('Parent',hLayout,'style','text','string','Please Wait...', 'FontSize',12);
movegui(h,'center');
% Set default panel color
%uiextras.set(gui.Window, 'DefaultBoxPanelTitleColor', [0.7 1.0 0.7]);
% + File menu
gui.FileMenu = uimenu( gui.Window, 'Label', 'File' );
uimenu( gui.FileMenu, 'Label', 'Exit', 'Callback', @onMTTGUIClose );
% + Help menu
helpMenu = uimenu( gui.Window, 'Label', 'Help' );
uimenu( helpMenu, 'Label', 'Documentation', 'Callback', @onHelp );
uimenu( helpMenu, 'Label', 'About...', 'Callback', @onAbout );

%% Arrange the main interface
mainLayout = uiextras.TabPanel('Parent', gui.Window, 'Padding', 3, 'FontSize',10);
gui.GeneralSettings = uiextras.Grid('Parent',mainLayout,'Padding',5,'Spacing',10);
gui.SISOOFDM = uiextras.VBox('Parent',mainLayout,'Padding',5,'Spacing',10);
gui.SISOPAM = uiextras.VBox('Parent',mainLayout,'Spacing',10, 'Padding',5);
gui.MIMOPAM = uiextras.VBox('Parent',mainLayout,'Padding', 5, 'Spacing',10);
gui.SMPAM = uiextras.VBox('Parent',mainLayout,'Padding', 5, 'Spacing',10);
gui.frequencyResponse = uiextras.VBox('Parent',mainLayout,'Padding', 5, 'Spacing',10);
gui.SMOFDM = uiextras.VBox('Parent',mainLayout,'Padding', 5, 'Spacing',10);
gui.MIMOOFDM = uiextras.VBox('Parent',mainLayout,'Padding', 5, 'Spacing',10);
mainLayout.TabNames = {'Settings','SISO OFDM','SISO PAM', 'MIMO PAM', 'SM PAM', 'Freq. Resp.','SM OFDM','MIMO OFDM'};
mainLayout.SelectedChild = 1;
mainLayout.TabSize = 90;

%% Arrange Settings Tab
gui = arrangeSettingsTab(gui);
%% Arrange OFDM Tab
gui = arrangeSISOOFDMTab(gui);
%% Arrange PAM SISO Tab
gui = arrangeSISOPAMTab(gui);
%% Arrange OOK/PRBS SISO Tab
gui = arrangeMIMOPAMTab(gui);
%% Arrange OOK/PRBS SISO Tab
gui = arrangeSMPAMTab(gui);
%% Arrange OOK/PRBS SISO Tab
gui = arrangeFreqRespTab(gui);
%% Arrange SM OFDM Tab
gui = arrangeSMOFDMTab(gui);
%% Arrange MIMO OFDM Tab
gui = arrangeMIMOOFDMTab(gui);
end
