function onPlotDataSISOOFDM(~,~)

global SISOOFDM;

try
% Plot SINR
figure;
plot(SISOOFDM.SINREstimate);
xlabel('Subcarrier');
ylabel('SNR [dB]');

figure;
plot(SISOOFDM.P);
xlabel('Subcarrier');
ylabel('Allocated Power');

figure;
plot(SISOOFDM.M);
xlabel('Subcarrier');
ylabel('Modulation Order');

% Display BER & Datarate
msgbox({['The achieved BER is ' num2str(SISOOFDM.BER) '.'],['The achieved data rate is ' num2str(SISOOFDM.dataRate) '.']},'Results', 'help', 'modal');
catch ME,
    warndlg(ME.message, 'Error','modal');
end