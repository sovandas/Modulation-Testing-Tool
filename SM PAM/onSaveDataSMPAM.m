function onSaveDataSMPAM(~,~)

global SMPAM;
global systemParameters;

try
    folder_name = uigetdir(pwd,'Select Folder to Save Data...');
    BER = SMPAM.BER;
    waveformData1 = SMPAM.waveformData1;
    waveformData2 = SMPAM.waveformData2;
    PAMData = SMPAM.PAMData;
    SMData = SMPAM.SMData;
    dataRate = SMPAM.dataRate;
    if ~isequal(folder_name,0),
        save(fullfile(folder_name, 'data.mat'), 'BER', 'waveformData1', 'waveformData2', 'data1', 'data2', 'dataRate');
        fileID = fopen([folder_name '\BER.txt'],'w');
        fprintf(fileID, 'BER is %1.9f.\n\r', MIMOPAM.BER);
        fprintf(fileID, 'Data Rate is %4.2f Mbit/s.\n\r', MIMOPAM.dataRate);
        fprintf(fileID, 'Sampling frequency is %d MS/s.\n\r', systemParameters.samplingFrequency);
        fprintf(fileID, 'Samples per symbol is set to %d.\n\r', systemParameters.samplesPerSymbol);
        fclose(fileID);
        h = figure;
        subplot(2,1,1), plot(MIMOPAM.waveformData1.YData);
        ylabel('Voltage [V]');
        subplot(2,1,2), plot(MIMOPAM.waveformData2.YData);
        xlabel('Sample Number');
        ylabel('Voltage [V]');
        saveas(h, fullfile(folder_name, 'acquiredSignal.fig'));
        close(h);
    end
catch ME,
    warndlg(ME.message, 'Error','modal');
end