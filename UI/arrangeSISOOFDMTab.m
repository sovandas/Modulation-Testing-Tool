function gui = arrangeSISOOFDMTab(gui)

gui.SISOOFDMU = uiextras.Grid('Parent',gui.SISOOFDM,'Spacing',5);
gui.SISOOFDMD = uiextras.Grid('Parent',gui.SISOOFDM,'Spacing',5);

handle = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Input CH:');
javaHandle = findjobj(handle);
align(handle, 'None', 'Middle'); 
%javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Output CH+:');
javaHandle = findjobj(handle);
align(handle, 'None', 'Middle'); 
%javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Output CH-:');
javaHandle = findjobj(handle);
align(handle, 'None', 'Middle'); 
%javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
uiextras.Empty('Parent', gui.SISOOFDMU);
handle = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Parameters File:');
javaHandle = findjobj(handle);
align(handle, 'None', 'Middle'); 
%javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handle = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','text', ...
    'FontSize',10,...
    'String','Max. Modulation Order:');
javaHandle = findjobj(handle);
align(handle, 'None', 'Middle'); 
%javaHandle.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
uiextras.Empty('Parent', gui.SISOOFDMU);
gui.inputChannelSISOOFDM = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','popupmenu', ...
    'String',{'CH1','CH2', 'CH1+CH2'},...
    'FontSize',10, ...
    'Callback',@onInputChannelSISOOFDM);
gui.outputChannelPSISOOFDM = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','popupmenu', ...
    'String',{'CH1','CH2','CH3','CH4','FN1'},...
    'FontSize',10, ...
    'Callback',@onOutputChannelPSISOOFDM);
gui.outputChannelNSISOOFDM = uicontrol('Parent',gui.SISOOFDMU, ...
    'Style','popupmenu', ...
    'String',{'CH1','CH2','CH3','CH4'},...
    'FontSize',10, ...
    'Value', 2, ...
    'Enable', 'off',...
    'Callback',@onOutputChannelNSISOOFDM);
uiextras.Empty('Parent', gui.SISOOFDMU);
fileSpaceHandle = uiextras.HBox('Parent',gui.SISOOFDMU);
gui.fileLocationSISOOFDM = uicontrol('Parent', fileSpaceHandle, ...
    'Style', 'edit', ...
    'String', pwd, ...
    'FontSize', 10, ...
    'Enable','off');
gui.fileBrowseSISOOFDM = uicontrol('Parent', fileSpaceHandle, ...
    'Style', 'pushbutton', ...
    'String', 'Browse...', ...
    'FontSize', 10, ...
    'Callback', @onBrowseParametersSISOOFDM);
set(fileSpaceHandle,'Sizes',[-2 -1]);
gui.maxConstellationSizeSISOOFDM = uicontrol('Parent', gui.SISOOFDMU, ...
    'Style', 'popupmenu', ...
    'FontSize', 10, ...
    'String',{'2','4','8','16','32','64','128','256','512','1024'}, ... 
    'Callback',@onMaxConstellationSISOOFDM);

uicontrol('Parent',gui.SISOOFDMD, ...
    'Style','pushbutton',...
    'String','Edit Parameters',...
    'FontSize',10,...
    'Callback',@onEditParametersSISOOFDM);
uiextras.Empty('Parent', gui.SISOOFDMD);
uicontrol('Parent',gui.SISOOFDMD, ...
    'Style','pushbutton',...
    'String','Estimate Channel',...
    'FontSize',10,...
    'Callback',@onEstimateChannelSISOOFDM);
uicontrol('Parent',gui.SISOOFDMD, ...
    'Style','pushbutton',...
    'String','Adaptive Modulation',...
    'FontSize',10,...
    'Callback',@onAdaptiveModulationSISOOFDM);
uicontrol('Parent',gui.SISOOFDMD, ...
    'Style','pushbutton',...
    'String','Plot Data',...
    'FontSize',10,...
    'Callback',@onPlotDataSISOOFDM);
uicontrol('Parent',gui.SISOOFDMD, ...
    'Style','pushbutton',...
    'String','Save Data',...
    'FontSize',10,...
    'Callback',@onSaveDataSISOOFDM);

set(gui.SISOOFDM, 'Sizes', [32*7+10 -1]);
set(gui.SISOOFDMU, 'ColumnSizes', [-1 -1], 'RowSizes', [32 32 32 32 32 32 32]);
set(gui.SISOOFDMD, 'ColumnSizes', [-1 -1 -1], 'RowSizes', [-1 -1]);