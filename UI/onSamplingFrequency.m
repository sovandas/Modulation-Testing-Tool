function onSamplingFrequency(~,~)
global gui;
global systemParameters;

systemParameters.samplingFrequency = str2double(get(gui.SamplingFrequency, 'String'));


if( isfield(systemParameters, 'AWGObj') && ~isempty(systemParameters.AWGObj) && isa(systemParameters.AWGObj, 'upvlcdac') ) 

    systemParameters.samplingFrequency = systemParameters.AWGObj.setsamplefreq(systemParameters.samplingFrequency);
    set(gui.SamplingFrequency, 'String', num2str( systemParameters.samplingFrequency) )
end
    
end
    