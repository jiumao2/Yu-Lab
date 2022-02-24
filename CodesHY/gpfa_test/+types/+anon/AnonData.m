classdef AnonData < types.untyped.MetaClass & types.untyped.DatasetClass
% ANONDATA 


% PROPERTIES
properties
    data; % property of type any
end

methods
    function obj = AnonData(varargin)
        % ANONDATA Constructor for AnonData
        %     obj = ANONDATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % data = any
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.anon.AnonData')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end