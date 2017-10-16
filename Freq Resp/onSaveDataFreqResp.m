function onSaveDataFreqResp(~,~)

global systemParameters;
global FreqResp;

try
    folder_name = uigetdir(pwd,'Select Folder to Save Data...');
    samplingFrequency = systemParameters.samplingFrequency;
    samplesPerSymbol = systemParameters.samplesPerSymbol;
    frequencyResponse = FreqResp.result;
    if ~isequal(folder_name,0),
        save(fullfile(folder_name, 'data.mat'), 'samplingFrequency', 'samplesPerSymbol', 'frequencyResponse');
    end
catch ME,
    warndlg(ME.message, 'Error','modal');
end