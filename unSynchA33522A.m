function unSynchA33522A(AWGObj, channel)

if(isa(AWGObj,'visa'))
    
    AWGModel = regexp(query(AWGObj,'*IDN?'),',','split');
    AWGModel = AWGModel{2};
    Agilent33522A = isequal(AWGModel,'33522A');
    
    if Agilent33522A,
        % Turn off synch mode for input channel
        fprintf(AWGObj, ['SOURce' int2str(channel) ':BURSt:STATe OFF']);
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
    
end