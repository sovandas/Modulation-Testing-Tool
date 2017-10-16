function onMeasureFreqResp(~,~)

global systemParameters;
global FreqResp;

%% Setup Frequency sweep

frequency = FreqResp.startF:FreqResp.stepF:FreqResp.stopF;
FreqResp.result = zeros(1,length(frequency));

%% Sweep
% Set AWG
fprintf(systemParameters.AWGObj, [':INST:SEL ' FreqResp.inputCH]);
fprintf(systemParameters.AWGObj, ':SOUR:FUNC:MODE FIX');
fprintf(systemParameters.AWGObj, ':SOUR:FUNC:SHAP SIN');
fprintf(systemParameters.AWGObj,[':VOLT ' num2str(systemParameters.Vpp)]);
fprintf(systemParameters.AWGObj, ':OUTP ON');

% Set Scope
fprintf(systemParameters.ScopeObj, ':CHAN1:DISP 0');
fprintf(systemParameters.ScopeObj, ':CHAN2:DISP 0');
fprintf(systemParameters.ScopeObj, ':CHAN3:DISP 0');
fprintf(systemParameters.ScopeObj, ':CHAN4:DISP 0');
fprintf(systemParameters.ScopeObj, [':CHAN' num2str(FreqResp.outputCHP) ':COUP AC']);
if systemParameters.outputType == 2,
    fprintf(systemParameters.ScopeObj, [':CHAN' num2str(FreqResp.outputCHN) ':COUP AC']);
end
fprintf(systemParameters.ScopeObj, ':MEASure:STATistics MEAN');
fprintf(systemParameters.ScopeObj, ':MEASure:CLEar');

counter = 1;

for i = frequency,
   % Setup AWG
   fprintf(systemParameters.AWGObj, [':SOUR:FREQ:CW ' num2str(i)]);
   operationComplete = str2double(query(systemParameters.AWGObj,'*OPC?'));
   while ~operationComplete,
       operationComplete = str2double(query(systemParameters.AWGObj,'*OPC?'));
   end
   % Setup Scope
   fprintf(systemParameters.ScopeObj, [':VIEW CHAN' num2str(FreqResp.outputCHP)]);
   fprintf(systemParameters.ScopeObj, ':AUT');
   operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
   while ~operationComplete,
       operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
   end
   
   fprintf(systemParameters.ScopeObj, [':MEAS:VPP CHAN' num2str(FreqResp.outputCHP)]);
   operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
   while ~operationComplete,
       operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
   end
   pause(2);
   % FreqResp.result(counter) = str2double(query(systemParameters.ScopeObj, [':MEAS:VPP? CHAN' num2str(FreqResp.outputCHP)]));
   stringResult = query(systemParameters.ScopeObj, ':MEASure:RESults');
   
   if systemParameters.outputType == 2,
       fprintf(systemParameters.ScopeObj, [':VIEW CHAN' num2str(FreqResp.outputCHP)]);
       fprintf(systemParameters.ScopeObj, ':AUT');
       operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
       while ~operationComplete,
           operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
       end
       fprintf(systemParameters.ScopeObj, [':MEAS:VPP CHAN' num2str(FreqResp.outputCHP)]);
       operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
       while ~operationComplete,
           operationComplete = str2double(query(systemParameters.ScopeObj,'*OPC?'));
       end
       pause(2);
       % FreqResp.result(counter) = FreqResp.result(counter) + str2double(query(systemParameters.ScopeObj, [':MEAS:VPP? CHAN' num2str(FreqResp.outputCHP)]));
       stringResult = query(systemParameters.ScopeObj, ':MEASure:RESults');
   end
   % Increment counter
   counter = counter + 1;
end

%% Postprocess
FreqResp.result = smooth(FreqResp.result,'rloess');
FreqResp.result = FreqResp.result.^2;
FreqResp.resultdB = 10.*log10(FreqResp.result./max(FreqResp.result));


%% Display result
figure, plot(frequency, FreqResp.resultdB);
xlabel('Frequency [Hz]');
ylabel('Normalised response [dB]');

figure, plot(frequency, FreqResp.result);
xlabel('Frequency [Hz]');
ylabel('Power [V^2]');