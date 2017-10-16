function MTTGUI()
%MTTGUI: also know as Modulation Testing Tool GUI
%
%   MTTGUI() generates a GUI that allows for the rapid testing of
%   communication systems by being able to automate signal generation and
%   processing within a relatively simple GUI. Currently the following
%   modulation schemes are supported:
%   
%       SISO OFDM
%       SISO PAM (2 PAM emulates OOK)
%       2x2 MIMO PAM (2 PAM emulates OOK)
%       2x2 SM PAM (2 PAM emulates OOK)

%   Created by: Stefan Videv, UoE, 2014


%% Place any variables that need to be shared between all function here
global systemParameters; 
systemParameters = struct();
global SISOOFDM; 
SISOOFDM = struct();
global SISOPAM; 
SISOPAM = struct();
global SMPAM; 
SMPAM = struct();
global MIMOPAM; 
MIMOPAM = struct();
global FreqResp;
FreqResp = struct();
global SMOFDM;
SMOFDM = struct();
global MIMOOFDM;
MIMOOFDM = struct();
global gui;

% General Parameters
systemParameters.AWGAddress = 'TCPIP0::192.168.0.223::5025::SOCKET';
systemParameters.ScopeAddress = 'USB0::0x0957::0x175D::MY50340603::0::INSTR';
systemParameters.AWGObj = [];
systemParameters.ScopeObj = [];

systemParameters.samplingFrequency = 80;
systemParameters.samplesPerSymbol = 8;
systemParameters.outputType = 1;
systemParameters.Vpp = 0.15;
systemParameters.offset = 0;

systemParameters.AWGType = 1;
systemParameters.ScopeType = 1;

systemParameters.saveFolder = pwd;

% SISO OFDM Parameters
SISOOFDM.inputCH = 1;
SISOOFDM.outputCHP = 1;
SISOOFDM.outputCHN = 2;
SISOOFDM.parametersFile = pwd;
SISOOFDM.maxModulationOrder = 2;

SISOOFDM.P = [];
SISOOFDM.M = [];
SISOOFDM.SINREstimate = [];
SISOOFDM.BER = [];
SISOOFDM.waveformData = [];
SISOOFDM.OFDM = [];
SISOOFDM.QAM = [];

% SISO PAM Parameters
SISOPAM.inputCH = 1;
SISOPAM.outputCHP = 1;
SISOPAM.outputCHN = 2;
SISOPAM.maxModulationOrder = 2;
SISOPAM.adaptiveThreshold = 0;

% SM PAM Parameters
SMPAM.outputCH1P = 1;
SMPAM.outputCH1N = 2;
SMPAM.outputCH2P = 3;
SMPAM.outputCH2N = 4;
SMPAM.maxModulationOrder = 2;
SMPAM.adaptiveThreshold = 0;

% MIMO PAM Parameters
MIMOPAM.outputCH1P = 1;
MIMOPAM.outputCH1N = 2;
MIMOPAM.outputCH2P = 3;
MIMOPAM.outputCH2N = 4;
MIMOPAM.maxModulationOrder = 2;
MIMOPAM.adaptiveThreshold = 0;

% Frequency Response Parameters;
FreqResp.inputCH = 1;
FreqResp.outputCHP = 1;
FreqResp.outputCHN = 2;
FreqResp.startF = 10e3;
FreqResp.stopF = 10e6;
FreqResp.stepF = 10e3;

% SM OFDM Parameters
SMOFDM.inputCH1 = 1;
SMOFDM.inputCH2 = 2;
SMOFDM.outputCH1P = 1;
SMOFDM.outputCH1N = 2;
SMOFDM.outputCH2P = 3;
SMOFDM.outputCH2N = 4;
SMOFDM.parametersFile = pwd;
SMOFDM.maxModulationOrder = 256;

SMOFDM.P = [];
SMOFDM.M = [];
SMOFDM.SINREstimate = [];
SMOFDM.BER_QAM = [];
SMOFDM.BER_SM = [];
SMOFDM.BER = [];
SMOFDM.waveformData = [];
SMOFDM.OFDM1 = [];
SMOFDM.QAM1 = [];
SMOFDM.OFDM2 = [];
SMOFDM.QAM2 = [];
SMOFDM.SIM_BITS = [];

% MIMO OFDM Parameters
MIMOOFDM.inputCH1 = 1;
MIMOOFDM.inputCH2 = 2;
MIMOOFDM.outputCH1P = 1;
MIMOOFDM.outputCH1N = 2;
MIMOOFDM.outputCH2P = 3;
MIMOOFDM.outputCH2N = 4;
MIMOOFDM.parametersFile = pwd;
MIMOOFDM.maxModulationOrder = 256;

MIMOOFDM.P = [];
MIMOOFDM.M = [];
MIMOOFDM.SINREstimate1 = [];
MIMOOFDM.SINREstimate2 = [];
MIMOOFDM.BER_ch1 = [];
MIMOOFDM.BER_ch2 = [];
MIMOOFDM.BER = [];
MIMOOFDM.waveformData = [];
MIMOOFDM.OFDM1 = [];
MIMOOFDM.QAM1 = [];
MIMOOFDM.OFDM2 = [];
MIMOOFDM.QAM2 = [];

%% Include source code folders
addpath('./UI', './SISO OFDM', './SISO PAM', './SM PAM', './MIMO PAM', './Freq Resp', './SM OFDM', './MIMO OFDM', './classes');

%% Generate interface
[gui, h] = createInterface();

%% Start workers
matlabVersion = sscanf(version('-release'),'%d');

if matlabVersion <= 2013,
    isOpen = matlabpool('size') > 0;
    if isOpen,
        if matlabpool('size') < maxNumCompThreads,
            matlabpool('close');
            matlabpool(maxNumCompThreads);
        end
    else
        matlabpool(maxNumCompThreads);
    end
else
    poolobj = gcp('nocreate');
    if( isempty(poolobj) )
        poolsize = 0;
    else
        poolsize = poolobj.NumWorkers;
    end
    if ~(poolsize > 0),
        parpool(maxNumCompThreads);
    end
end

%% Remove wait bar
delete(h);

end