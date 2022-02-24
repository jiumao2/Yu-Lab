classdef AnonGroup < types.core.NWBDataInterface & types.untyped.GroupClass
% ANONGROUP 


% PROPERTIES
properties
    anondata; % 
    anongroup; % 
end

methods
    function obj = AnonGroup(varargin)
        % ANONGROUP Constructor for AnonGroup
        %     obj = ANONGROUP(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % anondata = AnonData
        % anongroup = AnonGroup
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        [obj.anondata,ivarargin] = types.util.parseAnon('types.anon.AnonData', varargin{:});
        varargin(ivarargin) = [];
        [obj.anongroup,ivarargin] = types.util.parseAnon('types.anon.AnonGroup', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.anon.AnonGroup')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.anondata(obj, val)
        obj.anondata = obj.validate_anondata(val);
    end
    function obj = set.anongroup(obj, val)
        obj.anongroup = obj.validate_anongroup(val);
    end
    %% VALIDATORS
    
    function val = validate_anondata(obj, val)
        val = types.util.checkDtype('anondata', 'types.anon.AnonData', val);
    end
    function val = validate_anongroup(obj, val)
        val = types.util.checkDtype('anongroup', 'types.anon.AnonGroup', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.anondata)
            refs = obj.anondata.export(fid, [fullpath '/'], refs);
        end
        if ~isempty(obj.anongroup)
            refs = obj.anongroup.export(fid, [fullpath '/'], refs);
        end
    end
end

end