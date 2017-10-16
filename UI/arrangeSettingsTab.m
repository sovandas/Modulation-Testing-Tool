function gui = arrangeSettingsTab(gui)


handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Function Generator Type and Address:');
javaHandle = findjobj(handle);
javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Oscilloscope Type and Address:');
javaHandle = findjobj(handle);
javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Function Generator Sampling Frequency [MS/s]:');
%javaHandle = findjobj(handle);
%javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Samples/symbol:');
javaHandle = findjobj(handle);
javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Output Type:');
javaHandle = findjobj(handle);
javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Output Vpp [V]:');
gui.outputVppText = handle;
javaHandle = findjobj(handle);
javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Output Offset [V]:');
gui.outputOffsetText = handle;
javaHandle = findjobj(handle);
javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
gui.SPADChipModeText = uicontrol('Parent', gui.GeneralSettings, ...
   'Style','text', ...
    'FontSize',10,...
    'String','SPAD Chip Mode', ...
    'Enable', 'off' );
align(gui.SPADChipModeText,'None', 'Middle');
gui.SPADVoffsetText = uicontrol('Parent', gui.GeneralSettings, ...
   'Style','text', ...
    'FontSize',10,...
    'String','SPAD Offset [V]', ...
    'Enable', 'off' );
align(gui.SPADVoffsetText,'None', 'Middle');


uiextras.Empty('Parent', gui.GeneralSettings);

gui.connectAWG = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','pushbutton',...
    'String','Connect AWG',...
    'FontSize',11,...
    'BackgroundColor',[0.847 0.161 0], ...
    'Callback',@onConnectAWG);

AWGAddressSpaceHandle = uiextras.HBox('Parent',gui.GeneralSettings);
gui.AWGType = uicontrol('Parent', AWGAddressSpaceHandle,...
    'Style','popupmenu', ...
    'String',{'Agilent 81180A','Agilent 33522A','UP-VLC DAC'}, ...
    'FontSize', 10, ...
    'Callback',@onAWGType);
gui.AWGAddress = uicontrol('Parent',AWGAddressSpaceHandle, ...
    'Style','edit', ...
    'String','TCPIP0::192.168.0.223::5025::SOCKET',...
    'Callback',@onAWGAddress);
set(AWGAddressSpaceHandle,'Sizes',[-1 -3]);

ScopeAddressSpaceHandle = uiextras.HBox('Parent',gui.GeneralSettings);
gui.ScopeType = uicontrol('Parent', ScopeAddressSpaceHandle,...
    'Style','popupmenu', ...
    'String',{'Agilent MSO7104B','PHOTONTORRENT'}, ...
    'FontSize', 10, ...
    'Callback',@onScopeType);
gui.ScopeAddress = uicontrol('Parent',ScopeAddressSpaceHandle, ...
    'Style','edit', ...
    'String','USB0::0x0957::0x175D::my50340603::0::INSTR', ...
    'Callback',@onScopeAddress);
set(ScopeAddressSpaceHandle,'Sizes',[-1 -3]);

gui.SamplingFrequency = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','edit', ...
    'String','80',...
    'Callback',@onSamplingFrequency);
gui.SamplesPerSymbol = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','edit', ...
    'String','8',...
    'Callback',@onSamplesPerSymbol);
gui.outputType = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','popupmenu', ...
    'String',{'Single Sided','Differential'},...
    'FontSize',10, ...
    'Callback',@onOutputType);
gui.Vpp = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','edit', ...
    'String','0.15',...
    'Callback',@onVpp);
gui.offset = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','edit', ...
    'String','0',...
    'Callback',@onOffset);

gui.SPADChipMode = uicontrol('Parent', gui.GeneralSettings,...
    'Style','popupmenu', ...
    'String',{'25 MHz','50 MHz','100 MHz', '200 MHz, < 256 photons/5ns', '200 MHz, < 512 photons/5ns', '200 MHz, < 1024 photons/5ns', '200 MHz, < 2048 photons/5ns', '200 MHz, < 4096 photons/5ns'}, ...
    'FontSize', 10, ...
    'Enable', 'off', ... 
    'Callback',@onSPADChipMode);

gui.SPADVoffset = uicontrol('Parent', gui.GeneralSettings, ...
    'Style','edit', ...
    'String','1.0',...
    'Enable', 'off', ...
    'Callback',@onSPADVoffset);

%AWGAddressSpaceHandle = uiextras.HBox('Parent',gui.GeneralSettings);

uiextras.Empty('Parent', gui.GeneralSettings);

gui.connectScope = uicontrol('Parent',gui.GeneralSettings, ...
    'Style','pushbutton',...
    'String','Connect Scope',...
    'FontSize',10,...
    'BackgroundColor',[0.847 0.161 0], ...
    'Callback',@onConnectScope);

set(gui.GeneralSettings, 'ColumnSizes', [-1,-1], 'RowSizes', [32 32 32 32 32 32 32 32 32 -1 50]);
