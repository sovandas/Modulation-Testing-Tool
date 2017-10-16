function onBrowseParametersSISOOFDM(~,~)
global gui;
global SISOOFDM;

[FileName, PathName] = uigetfile('*.mat', 'Select parameters file');
if ~isequal(FileName,0),
    set(gui.fileLocationSISOOFDM,'String',fullfile(PathName, FileName));
    SISOOFDM.parametersFile = fullfile(PathName, FileName);
end