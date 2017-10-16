function [ data_frames ] = equalize(obj, pilot_frames, data_frames)
%EQUALIZE Summary of this function goes here
%   Detailed explanation goes here
% function to equalize the QAM signals we ahve received. inputs are 2+
% pilot frames and any number of signal frames. 

% average error fix first

pilot_frames = reshape(pilot_frames, 1, []); 

remainder = obj.pilotqam ./ pilot_frames;

%remainder = reshape(remainder, obj.number_of_pilot_frames, obj.nfft/2-1);



absoff = mean(abs(pilot_frames) ./ abs(obj.pilotqam));

angleoff = mean(abs(remainder)); 

off = absoff +exp(angleoff*sqrt(-1));

%remainder = repmat(remainder', 1, obj.frames);

data_frames = data_frames ./ off; 

end

