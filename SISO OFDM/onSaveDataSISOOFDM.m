function onSaveDataSISOOFDM(~,~)

global SISOOFDM;
global systemParameters;

try
    folder_name = uigetdir(systemParameters.saveFolder,'Select Folder to Save Data...');
    systemParameters.saveFolder = folder_name;
    P = SISOOFDM.P;
    M = SISOOFDM.M;
    SINREstimate = SISOOFDM.SINREstimate;
    BER = SISOOFDM.BER;
    waveformData = SISOOFDM.waveDataOUT;
    OFDM = SISOOFDM.OFDM;
    QAM = SISOOFDM.QAM;
    channel = SISOOFDM.channel;
    if ~isequal(folder_name,0),
        save(fullfile(folder_name, 'data.mat'), 'P', 'M', 'SINREstimate', 'BER', 'waveformData', 'OFDM', 'QAM', 'channel');
        fileID = fopen([folder_name '\BER.txt'],'w');
        fprintf(fileID, 'BER is %1.9f. \n\r', SISOOFDM.BER);
        fprintf(fileID, 'Data Rate is %4.2f Mbit/s. \n\r', SISOOFDM.dataRate);
        fprintf(fileID, 'Sampling frequency is %d MS/s. \n\r', systemParameters.samplingFrequency);
        fprintf(fileID, 'Samples per symbol is set to %d. \n\r', systemParameters.samplesPerSymbol);
        fclose(fileID);
        h = figure;
        plot(SISOOFDM.SINREstimate);
        xlabel('Carrier Number');
        ylabel('Estimated SINR');
        saveas(h, fullfile(folder_name, 'EstimatedChannel.fig'));
        close(h);
    end
catch ME
    warndlg(ME.message, 'Error','modal');
end