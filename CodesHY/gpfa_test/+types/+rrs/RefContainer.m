classdef RefContainer < types.core.NWBDataInterface & types.untyped.GroupClass
% REFCONTAINER 


% PROPERTIES
properties
    data; % 
end

methods
    function obj = RefContainer(varargin)
        % REFCONTAINER Constructor for RefContainer
        %     obj = REFCONTAINER(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % data = any
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.rrs.RefContainer')
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
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.data)
            if startsWith(class(obj.data), 'types.untyped.')
                refs = obj.data.export(fid, [fullpath '/data'], refs);
            elseif ~isempty(obj.data)
                io.writeDataset(fid, [fullpath '/data'], obj.data);
            end
        else
            error('Property `data` is required in `%s`.', fullpath);
        end
    end
end

end