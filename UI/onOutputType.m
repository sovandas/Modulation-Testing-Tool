function onOutputType(~,~)
global gui;
global systemParameters;

systemParameters.outputType = get(gui.outputType,'Value');

if systemParameters.outputType == 1,
    % Single Sided
    set(gui.outputChannelNSISOOFDM,'Enable','off');
    set(gui.outputChannelNSISOPAM,'Enable','off');
    set(gui.outputChannel1NSMPAM,'Enable','off');
    set(gui.outputChannel2NSMPAM,'Enable','off');
    set(gui.outputChannel1NMIMOPAM,'Enable','off');
    set(gui.outputChannel2NMIMOPAM,'Enable','off');
    set(gui.outputChannel1NSMOFDM,'Enable','off');
    set(gui.outputChannel2NSMOFDM,'Enable','off');
    set(gui.outputChannel1NMIMOOFDM,'Enable','off');
    set(gui.outputChannel2NMIMOOFDM,'Enable','off');
elseif systemParameters.outputType == 2,
    % Differential
    set(gui.outputChannelNSISOOFDM,'Enable','on');
    set(gui.outputChannelNSISOPAM,'Enable','on');
    set(gui.outputChannel1NSMPAM,'Enable','on');
    set(gui.outputChannel2NSMPAM,'Enable','on');
    set(gui.outputChannel1NMIMOPAM,'Enable','on');
    set(gui.outputChannel2NMIMOPAM,'Enable','on');
    set(gui.outputChannel1NSMOFDM,'Enable','on');
    set(gui.outputChannel2NSMOFDM,'Enable','on');
    set(gui.outputChannel1NMIMOOFDM,'Enable','on');
    set(gui.outputChannel2NMIMOOFDM,'Enable','on');
end