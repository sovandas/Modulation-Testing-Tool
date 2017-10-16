function onPlotDataSISOPAM(~,~)

global SISOPAM;

try
    figure;
    plot(SISOPAM.waveformData.YData);
    xlabel('Sample Number');
    ylabel('Voltage [V]');

    msgbox({['The achieved BER is ' num2str(SISOPAM.BER) '.'],['The achieved data rate is ' num2str(SISOPAM.dataRate) '.']},'Results', 'help', 'modal');
catch ME,
    warndlg(ME.message, 'Error','modal');
end