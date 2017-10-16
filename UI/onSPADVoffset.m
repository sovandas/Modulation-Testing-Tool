function onSPADVoffset(~,~)

global gui;
global systemParameters;

systemParameters.SPADVoffset = str2double(get(gui.SPADVoffset,'String'));

if(systemParameters.SPADVoffset < 0)
    systemParameters.SPADVoffset = 0;
    get(gui.SPADVoffset,'String','0.0');
end

if(systemParameters.SPADVoffset > 3.3)
    systemParameters.SPADVoffset = 3.3;
    get(gui.SPADVoffset,'String','3.3');
end

if( isfield(systemParameters, 'ScopeObj') && ~isempty(systemParameters.ScopeObj) && ( isa(systemParameters.ScopeObj, 'photontorrent_aa') || isa(systemParameters.ScopeObj, 'photontorrent_ab')) )

    systemParameters.ScopeObj.setVoffset(systemParameters.SPADVoffset*1000); 
    
end
    