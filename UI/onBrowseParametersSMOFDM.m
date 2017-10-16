function onBrowseParametersSMOFDM(~,~)
global gui;
global SMOFDM;

[FileName, PathName] = uigetfile('*.mat', 'Select parameters file');
if ~isequal(FileName,0),
    set(gui.fileLocationSMOFDM,'String',fullfile(PathName, FileName));
    SMOFDM.parametersFile = fullfile(PathName, FileName);
end