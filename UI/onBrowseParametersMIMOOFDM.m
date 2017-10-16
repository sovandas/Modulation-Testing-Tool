function onBrowseParametersMIMOOFDM(~,~)
global gui;
global MIMOOFDM;

[FileName, PathName] = uigetfile('*.mat', 'Select parameters file');
if ~isequal(FileName,0),
    set(gui.fileLocationMIMOOFDM,'String',fullfile(PathName, FileName));
    MIMOOFDM.parametersFile = fullfile(PathName, FileName);
end