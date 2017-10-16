function onPlotDataSMPAM(~,~)

global SMPAM;

try
    figure;
    subplot(2,1,1), plot(SMPAM.waveformData1.YData);
    ylabel('Voltage [V]');
    subplot(2,1,2), plot(SMPAM.waveformData2.YData);
    xlabel('Sample Number');
    ylabel('Voltage [V]');
    
    msgbox({['The achieved BER is ' num2str(SMPAM.BER) '.'],['The achieved data rate is ' num2str(SMPAM.dataRate) 'Mbit/s.']},'Results', 'help', 'modal');
catch ME,
    warndlg(ME.message, 'Error','modal');
end