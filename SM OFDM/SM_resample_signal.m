function [amplitude] = resample_signal(amplitude_input,time_input,Fs)

%Fs = 4e9;  % Fs = target sampling rate
time=time_input(1):1/Fs:time_input(end); % x =  time vector,  y = amplitude vector from the scope.
amplitude=interp1(time_input,amplitude_input,time); % linear interpolation for the re-sampling
figure, plot(time_input,amplitude_input), hold on, plot(time,amplitude,'r');
figure, plot(amplitude)