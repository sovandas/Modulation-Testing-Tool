function onPlotDataSMOFDM(~,~)

global SMOFDM;

try
% Plot SINR
figure;
plot(SMOFDM.SINREstimate);
xlabel('Subcarrier');
ylabel('SNR [dB]');

figure;
plot(SMOFDM.P);
xlabel('Subcarrier');
ylabel('Allocated Power');

figure;
plot(SMOFDM.M);
xlabel('Subcarrier');
ylabel('Modulation Order');

% Display BER & Datarate
msgbox({['The achieved BER is ' num2str(SMOFDM.BER) '.'],['The achieved data rate is ' num2str(SMOFDM.dataRate) '.']},'Results', 'help', 'modal');
catch ME,
    warndlg(ME.message, 'Error','modal');
end