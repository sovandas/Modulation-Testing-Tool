function onSPADChipMode(~,~)
global gui;
global systemParameters;

mode= get(gui.SPADChipMode,'Value');

if(mode == 1)
    systemParameters.SPADChipMode = 6;
elseif(mode == 2)
    systemParameters.SPADChipMode = 5;
elseif(mode == 3)
    systemParameters.SPADChipMode = 3;
    %elseif(mode == 4)
    %    systemParameters.SPADChipMode = 7;
elseif(mode == 4)
    systemParameters.SPADChipMode = 16;
elseif(mode == 5)
    systemParameters.SPADChipMode = 17;
elseif(mode == 6)
    systemParameters.SPADChipMode = 18;
elseif(mode == 7)
    systemParameters.SPADChipMode = 19;
elseif(mode == 8)
    systemParameters.SPADChipMode = 20;
elseif(mode == 9)
    systemParameters.SPADChipMode = 21;
elseif(mode == 10)
    systemParameters.SPADChipMode = 22;
elseif(mode == 11)
    systemParameters.SPADChipMode = 23;
end

if( isfield(systemParameters, 'ScopeObj') && ~isempty(systemParameters.ScopeObj) && ( isa(systemParameters.ScopeObj, 'photontorrent_aa') || isa(systemParameters.ScopeObj, 'photontorrent_ab')) )
    
    systemParameters.ScopeObj.setChipMode(systemParameters.SPADChipMode);
    
end

end