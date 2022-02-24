classdef CompoundRefData < types.core.NWBContainer & types.untyped.GroupClass
% COMPOUNDREFDATA 


% PROPERTIES
properties
    data; % 
end

methods
    function obj = CompoundRefData(varargin)
        % COMPOUNDREFDATA Constructor for CompoundRefData
        %     obj = COMPOUNDREFDATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % data = table/struct of vectors/struct array/containers.Map of vectors with values:
        
            % a = float64
            % b = float64
            % objref = ref to RefContainer object
            % regref = ref to RefContainer region
        obj = obj@types.core.NWBContainer(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.cs.CompoundRefData')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        if isempty(val) || isa(val, 'types.untyped.DataStub')
            return;
        end
        if ~istable(val) && ~isstruct(val) && ~isa(val, 'containers.Map')
            error('Property `data` must be a table,struct, or containers.Map.');
        end
        vprops = struct();
        vprops.a = 'float64';
        vprops.b = 'float64';
        vprops.objref = 'types.untyped.ObjectView';
        vprops.regref = 'types.untyped.RegionView';
        val = types.util.checkDtype('data', vprops, val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.data)
            if startsWith(class(obj.data), 'types.untyped.')
                refs = obj.data.export(fid, [fullpath '/data'], refs);
            elseif ~isempty(obj.data)
                io.writeCompound(fid, [fullpath '/data'], obj.data);
            end
        else
            error('Property `data` is required in `%s`.', fullpath);
        end
    end
end

end