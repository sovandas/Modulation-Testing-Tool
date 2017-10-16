function onPlotDataMIMOOFDM(~,~)

global MIMOOFDM;

try
% Plot SINR
figure;
plot(MIMOOFDM.SINREstimate1);
xlabel('Subcarrier');
ylabel('SNR Ch1 [dB]');

figure;
plot(MIMOOFDM.SINREstimate2);
xlabel('Subcarrier');
ylabel('SNR Ch2 [dB]');

figure;
plot(MIMOOFDM.P(1,:));
hold on;
plot(MIMOOFDM.P(2,:),'r');
xlabel('Subcarrier');
ylabel('Allocated Power');
legend('Channel 1', 'Channel 2');

figure;
plot(MIMOOFDM.M(1,:));
hold on;
plot(MIMOOFDM.M(2,:));
xlabel('Subcarrier');
ylabel('Modulation Order');
legend('Channel 1', 'Channel 2');

% Display BER & Datarate
msgbox({['The achieved BER is ' num2str(MIMOOFDM.BER) '.'],['The achieved data rate is ' num2str(MIMOOFDM.dataRate) '.']},'Results', 'help', 'modal');
catch ME,
    warndlg(ME.message, 'Error','modal');
end