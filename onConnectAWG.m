function onConnectAWG(~,~)
global gui;
global systemParameters;

try
    if isempty(systemParameters.AWGObj),
        % If scope has not been connected
		props = regexp(systemParameters.AWGAddress,'::','split');
        if systemParameters.AWGType == 1,
            % 81180A
            systemParameters.AWGObj = instrfind('Type', 'tcpip', 'RemoteHost', props{2}, 'RemotePort', str2num(props{3}));
            % Create the VISA object if it does not exist
            % otherwise use the object that was found.
            if isempty(systemParameters.AWGObj),
                systemParameters.AWGObj = tcpip(props{2},str2num(props{3}));
            else
                fclose(systemParameters.AWGObj);
                systemParameters.AWGObj = systemParameters.AWGObj(1);
            end
            % Set the buffer size
            systemParameters.AWGObj.OutputBufferSize = 80000000;
            fopen(systemParameters.AWGObj);
            % Update button appearance and text
            set(gui.connectAWG,'BackgroundColor',[0 0.498 0]);
            set(gui.connectAWG,'String','Disconnect AWG');
            set(gui.AWGType, 'Enable', 'off');
            set(gui.AWGAddress, 'Enable', 'off');
            % Run setup commands
            fprintf(systemParameters.AWGObj, '*RST'); % Reset instrument
            operationComplete = str2double(query(systemParameters.AWGObj,'*OPC?'));
            while ~operationComplete
                operationComplete = str2double(query(systemParameters.AWGObj,'*OPC?'));
            end
            fprintf(systemParameters.AWGObj, ':SOUR:ROSC:SOUR EXT'); % Set oscillator clock to EXT
            fprintf(systemParameters.AWGObj, ':SOUR:ROSC:EXT:FREQ 10e6'); % Set frequency to 10MHz
            fprintf(systemParameters.AWGObj, ':INST:COUP:STAT ON'); % Couple sampling clock on channels
            % Update swing and offset so no confusions happen
            set(gui.outputVppText,'String','Output Vpp [V]:');
            set(gui.outputOffsetText,'String','Output Offset [V]:');
            set(gui.Vpp,'String','0.15');
            set(gui.offset,'String','0');
            systemParameters.Vpp = 0.15;
            systemParameters.offset = 0;
        elseif systemParameters.AWGType == 2,
            % 33522A
            vAddress = ['TCPIP0::' props{2} '::inst0::INSTR']; %build visa address string to connect
            systemParameters.AWGObj = instrfind('Type', 'visa-tcpip', 'RemoteHost', props{2});
            % Create the VISA object if it does not exist
            % otherwise use the object that was found.
            if isempty(systemParameters.AWGObj),
                systemParameters.AWGObj = visa('AGILENT',vAddress); %build IO object
            else
                fclose(systemParameters.AWGObj);
                systemParameters.AWGObj = systemParameters.AWGObj(1);
            end
            %systemParameters.AWGObj.Timeout = 30; %set IO time out
            %calculate output buffer size
            set(systemParameters.AWGObj,'OutputBufferSize',80000000);
            % open connection to 33500A/B waveform generator
            fopen(systemParameters.AWGObj);
            fprintf (systemParameters.AWGObj, '*RST');
            operationComplete = str2double(query(systemParameters.AWGObj,'*OPC?'));
            while ~operationComplete
                operationComplete = str2double(query(systemParameters.AWGObj,'*OPC?'));
            end
            % Update button appearance and text
            set(gui.connectAWG,'BackgroundColor',[0 0.498 0]);
            set(gui.connectAWG,'String','Disconnect AWG');
            set(gui.AWGType, 'Enable', 'off');
            set(gui.AWGAddress, 'Enable', 'off');
            % Update swing and offset so no confusions happen
            set(gui.outputVppText,'String','Output Vpp [V]:');
            set(gui.outputOffsetText,'String','Output Offset [V]:');
            set(gui.Vpp,'String','0.15');
            set(gui.offset,'String','0');
            systemParameters.Vpp = 0.15;
            systemParameters.offset = 0;
        elseif systemParameters.AWGType == 3,
            %UP-VLC DAC
            
            if isempty(systemParameters.AWGAddress),
                systemParameters.AWGObj = upvlcdac;
            else
                systemParameters.AWGObj = upvlcdac(systemParameters.AWGAddress);
            end
            systemParameters.samplingFrequency = systemParameters.AWGObj.setsamplefreq(systemParameters.samplingFrequency);
            set(gui.SamplingFrequency, 'String', num2str( systemParameters.samplingFrequency) )
            % Update button appearance and text
            set(gui.connectAWG,'BackgroundColor',[0 0.498 0]);
            set(gui.connectAWG,'String','Disconnect AWG');
            set(gui.AWGType, 'Enable', 'off');
            set(gui.AWGAddress, 'Enable', 'off');
            % Update swing and offset so no confusions happen
            set(gui.outputVppText,'String','Output Swing [mA]:');
            set(gui.outputOffsetText,'String','Output Offset [mA]:');
            set(gui.Vpp,'String','40');
            set(gui.offset,'String','20');
            systemParameters.Vpp = 40;
            systemParameters.offset = 20;
             
        end
    elseif ~isempty(systemParameters.AWGObj),
        % If AWG is already connected, disconnect
        if(isa(systemParameters.AWGObj,'upvlcdac'))
            systemParameters.AWGObj.close();
        else
            fclose(systemParameters.AWGObj);
        end
        systemParameters.AWGObj = [];
        % Update button appearance and text
        set(gui.connectAWG,'BackgroundColor',[0.847 0.161 0]);
        set(gui.connectAWG,'String','Connect AWG');
        set(gui.AWGType, 'Enable', 'on');
        set(gui.AWGAddress, 'Enable', 'on');
    end
catch ME,
    systemParameters.AWGObj = [];
    set(gui.connectAWG,'BackgroundColor',[0.847 0.161 0]);
    set(gui.connectAWG,'String','Connect AWG');
    set(gui.AWGType, 'Enable', 'on');
    set(gui.AWGAddress, 'Enable', 'on');
    errordlg(ME.message,'Error');
end