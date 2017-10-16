function onSaveDataSMOFDM(~,~)

global SMOFDM;
global systemParameters;

try
    folder_name = uigetdir(pwd,'Select Folder to Save Data...');
    P = SMOFDM.P;
    M = SMOFDM.M;
    SINREstimate = SMOFDM.SINREstimate;
    BER = SMOFDM.BER;
    waveformData = SMOFDM.waveformData;
    OFDM = SMOFDM.OFDM;
    QAM = SMOFDM.QAM;
    if ~isequal(folder_name,0),
        save(fullfile(folder_name, 'data.mat'), 'P', 'M', 'SINREstimate', 'BER', 'waveformData', 'OFDM', 'QAM');
        fileID = fopen([folder_name '\BER.txt'],'w');
        fprintf(fileID, 'BER is %1.9f.\n\r', SMOFDM.BER);
        fprintf(fileID, 'Data Rate is %4.2f Mbit/s.\n\r', SMOFDM.dataRate);
        fprintf(fileID, 'Sampling frequency is %d MS/s.\n\r', systemParameters.samplingFrequency);
        fprintf(fileID, 'Samples per symbol is set to %d.\n\r', systemParameters.samplesPerSymbol);
        fclose(fileID);
        h = figure;
        plot(SMOFDM.SINREstimate);
        xlabel('Carrier Number');
        ylabel('Estimated SINR');
        saveas(h, fullfile(folder_name, 'EstimatedChannel.fig'));
        close(h);
    end
catch ME,
    warndlg(ME.message, 'Error','modal');
end