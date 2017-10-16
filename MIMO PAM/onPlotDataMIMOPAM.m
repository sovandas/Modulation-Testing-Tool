function onPlotDataMIMOPAM(~,~)

global MIMOPAM;

try
    figure;
    subplot(2,1,1), plot(MIMOPAM.waveformData1.YData);
    ylabel('Voltage [V]');
    subplot(2,1,2), plot(MIMOPAM.waveformData2.YData);
    xlabel('Sample Number');
    ylabel('Voltage [V]');
    
    msgbox({['The achieved BER is ' num2str(MIMOPAM.BER) '.'],['The achieved data rate is ' num2str(MIMOPAM.dataRate) 'Mbit/s.']},'Results', 'help', 'modal');
catch ME,
    warndlg(ME.message, 'Error','modal');
end