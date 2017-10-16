function synchA33522A(AWGObj)

AWGModel = regexp(query(AWGObj,'*IDN?'),',','split');
AWGModel = AWGModel{2};
Agilent33522A = isequal(AWGModel,'33522A');

if Agilent33522A,
    % Synchronize output channels
    % Set Burst Mode for CH1
    fprintf(AWGObj, 'SOURce1:BURSt:MODE TRIG');
    fprintf(AWGObj, 'SOURce1:BURSt:NCYCles INF');
    fprintf(AWGObj, 'TRIGger1:SOURce BUS');
    fprintf(AWGObj, 'SOURce1:BURSt:STATe ON');
    % Set Burst Mode for CH2
    fprintf(AWGObj, 'SOURce2:BURSt:MODE TRIG');
    fprintf(AWGObj, 'SOURce2:BURSt:NCYCles INF');
    fprintf(AWGObj, 'TRIGger2:SOURce BUS');
    fprintf(AWGObj, 'SOURce2:BURSt:STATe ON');
    % Send Trigger
    fprintf(AWGObj, '*TRG');
end

%Read Error
fprintf(AWGObj, 'SYST:ERR?');
errorstr = fscanf (AWGObj);

% error checking
if strncmp (errorstr, '+0,"No error"',13)
    errorcheck = 'Arbitrary waveforms synched without any error\n';
    fprintf (errorcheck)
else
    errorcheck = ['Error reported: ', errorstr];
    fprintf (errorcheck)
end