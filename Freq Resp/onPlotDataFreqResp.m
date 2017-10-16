function onPlotDataFreqResp(~,~)

global FreqResp;

%% Display result
figure, plot(frequency, FreqResp.result);
xlabel('Frequency [Hz]');
ylabel('Normalised response [dB]');