function onSaveDataSISOPAM(~,~)

global SISOPAM;
global systemParameters;

try
    folder_name = uigetdir(pwd,'Select Folder to Save Data...');
    BER = SISOPAM.BER;
    waveformData = SISOPAM.waveformData;
    data = SISOPAM.data;
    dataRate = SISOPAM.dataRate;
    if ~isequal(folder_name,0),
        save(fullfile(folder_name, 'data.mat'), 'BER', 'waveformData', 'data', 'dataRate');
        fileID = fopen([folder_name '\BER.txt'],'w');
        fprintf(fileID, 'BER is %1.9f.\n\r', SISOPAM.BER);
        fprintf(fileID, 'Data Rate is %4.2f Mbit/s.\n\r', SISOPAM.dataRate);
        fprintf(fileID, 'Sampling frequency is %d MS/s.\n\r', systemParameters.samplingFrequency);
        fprintf(fileID, 'Samples per symbol is set to %d.\n\r', systemParameters.samplesPerSymbol);
        fclose(fileID);
        h = figure;
        plot(SISOPAM.waveformData.YData);
        xlabel('Sample Number');
        ylabel('Voltage [V]');
        saveas(h, fullfile(folder_name, 'acquiredSignal.fig'));
        close(h);
    end
catch ME,
    warndlg(ME.message, 'Error','modal');
end