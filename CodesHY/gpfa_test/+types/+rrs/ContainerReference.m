classdef ContainerReference < types.core.NWBDataInterface & types.untyped.GroupClass
% CONTAINERREFERENCE 


% PROPERTIES
properties
    attribute_regref; % region reference attribute
    data_regref; % 
end

methods
    function obj = ContainerReference(varargin)
        % CONTAINERREFERENCE Constructor for ContainerReference
        %     obj = CONTAINERREFERENCE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % attribute_regref = ref to RefContainer region
        % data_regref = ref to RefContainer region
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'attribute_regref',[]);
        addParameter(p, 'data_regref',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.attribute_regref = p.Results.attribute_regref;
        obj.data_regref = p.Results.data_regref;
        if strcmp(class(obj), 'types.rrs.ContainerReference')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.attribute_regref(obj, val)
        obj.attribute_regref = obj.validate_attribute_regref(val);
    end
    function obj = set.data_regref(obj, val)
        obj.data_regref = obj.validate_data_regref(val);
    end
    %% VALIDATORS
    
    function val = validate_attribute_regref(obj, val)
        % Reference to type `RefContainer`
        val = types.util.checkDtype('attribute_regref', 'types.untyped.RegionView', val);
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
    function val = validate_data_regref(obj, val)
        % Reference to type `RefContainer`
        val = types.util.checkDtype('data_regref', 'types.untyped.RegionView', val);
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
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.attribute_regref)
            io.writeAttribute(fid, [fullpath '/attribute_regref'], obj.attribute_regref);
        else
            error('Property `attribute_regref` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.data_regref)
            if startsWith(class(obj.data_regref), 'types.untyped.')
                refs = obj.data_regref.export(fid, [fullpath '/data_regref'], refs);
            elseif ~isempty(obj.data_regref)
                io.writeDataset(fid, [fullpath '/data_regref'], obj.data_regref);
            end
        else
            error('Property `data_regref` is required in `%s`.', fullpath);
        end
    end
end

end