function onSaveDataMIMOOFDM(~,~)

global MIMOOFDM;
global systemParameters;

try
    folder_name = uigetdir(pwd,'Select Folder to Save Data...');
    P = MIMOOFDM.P;
    M = MIMOOFDM.M;
    SINREstimate1 = MIMOOFDM.SINREstimate1;
    SINREstimate2 = MIMOOFDM.SINREstimate2;
    BER = MIMOOFDM.BER;
    waveformData = MIMOOFDM.waveformData;
    OFDM1 = MIMOOFDM.OFDM1;
    OFDM2 = MIMOOFDM.OFDM2;
    QAM1 = MIMOOFDM.QAM1;
    QAM2 = MIMOOFDM.QAM2;
    if ~isequal(folder_name,0),
        save(fullfile(folder_name, 'data.mat'), 'P', 'M', 'SINREstimate1', 'SINREstimate2', 'BER', 'waveformData', 'OFDM1', 'OFDM2', 'QAM1', 'QAM2');
        fileID = fopen([folder_name '\BER.txt'],'w');
        fprintf(fileID, 'BER is %1.9f.\n\r', MIMOOFDM.BER);
        fprintf(fileID, 'Data Rate is %4.2f Mbit/s.\n\r', MIMOOFDM.dataRate);
        fprintf(fileID, 'Sampling frequency is %d MS/s.\n\r', systemParameters.samplingFrequency);
        fprintf(fileID, 'Samples per symbol is set to %d.\n\r', systemParameters.samplesPerSymbol);
        fclose(fileID);
        h = figure;
        plot(MIMOOFDM.SINREstimate1);
        hold on;
        plot(MIMOOFDM.SINREstimate2);
        xlabel('Carrier Number');
        ylabel('Estimated SINR');
        legend('Channel 1', 'Channel 2');
        saveas(h, fullfile(folder_name, 'EstimatedChannel.fig'));
        close(h);
    end
catch ME,
    warndlg(ME.message, 'Error','modal');
end