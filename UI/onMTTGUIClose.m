function onMTTGUIClose(~,~)

global gui;
global systemParameters;

try
    matlabVersion = sscanf(version('-release'),'%d');
    if matlabVersion <= 2013,
        matlabpool('close');
    else
        delete(gcp('nocreate'));
    end
    
    if ~isempty(systemParameters.AWGObj),
        if( isa(systemParameters.AWGObj, 'upvlcdac') )
            systemParameters.AWGObj.close()
        else
            fclose(systemParameters.AWGObj);
        end
    end
    if ~isempty(systemParameters.ScopeObj),
        if( isa(systemParameters.ScopeObj, 'photontorrent_aa') || isa(systemParameters.AWGObj, 'photontorrent_ab'))
            systemParameters.AWGObj.close()
        else
            fclose(systemParameters.ScopeObj);
        end
    end
    delete(gui.Window);
catch ME,
    delete(gui.Window);
    if ~isempty(systemParameters.AWGObj),
        if( isa(systemParameters.AWGObj, 'upvlcdac') )
            systemParameters.AWGObj.close()
        else
            fclose(systemParameters.AWGObj);
        end
    end
    if ~isempty(systemParameters.ScopeObj),
        if( isa(systemParameters.ScopeObj, 'photontorrent_aa') || isa(systemParameters.AWGObj, 'photontorrent_ab'))
            systemParameters.ScopeObj.close()
        else
            fclose(systemParameters.ScopeObj);
        end
    end
end