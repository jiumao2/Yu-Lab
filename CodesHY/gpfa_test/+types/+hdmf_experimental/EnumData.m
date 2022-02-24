classdef EnumData < types.hdmf_common.VectorData & types.untyped.DatasetClass
% ENUMDATA Data that come from a fixed set of values. A data value of i corresponds to the i-th value in the VectorData referenced by the 'elements' attribute.


% PROPERTIES
properties
    elements; % Reference to the VectorData object that contains the enumerable elements
end

methods
    function obj = EnumData(varargin)
        % ENUMDATA Constructor for EnumData
        %     obj = ENUMDATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % elements = ref to VectorData object
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'elements',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.elements = p.Results.elements;
        if strcmp(class(obj), 'types.hdmf_experimental.EnumData')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.elements(obj, val)
        obj.elements = obj.validate_elements(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'uint8', val);
    end
    function val = validate_elements(obj, val)
        % Reference to type `VectorData`
        val = types.util.checkDtype('elements', 'types.untyped.ObjectView', val);
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
        refs = export@types.hdmf_common.VectorData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.elements)
            io.writeAttribute(fid, [fullpath '/elements'], obj.elements);
        else
            error('Property `elements` is required in `%s`.', fullpath);
        end
    end
end

end