classdef EcephysSpecimen < types.core.Subject & types.untyped.GroupClass
% ECEPHYSSPECIMEN Metadata for ecephys specimen


% PROPERTIES
properties
    age_in_days; % Age of specimen in days
    specimen_name; % Full name of specimen
end

methods
    function obj = EcephysSpecimen(varargin)
        % ECEPHYSSPECIMEN Constructor for EcephysSpecimen
        %     obj = ECEPHYSSPECIMEN(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % age_in_days = float
        % specimen_name = char
        obj = obj@types.core.Subject(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'age_in_days',[]);
        addParameter(p, 'specimen_name',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.age_in_days = p.Results.age_in_days;
        obj.specimen_name = p.Results.specimen_name;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysSpecimen')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.age_in_days(obj, val)
        obj.age_in_days = obj.validate_age_in_days(val);
    end
    function obj = set.specimen_name(obj, val)
        obj.specimen_name = obj.validate_specimen_name(val);
    end
    %% VALIDATORS
    
    function val = validate_age_in_days(obj, val)
        val = types.util.checkDtype('age_in_days', 'float', val);
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
    function val = validate_specimen_name(obj, val)
        val = types.util.checkDtype('specimen_name', 'char', val);
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
    function val = validate_strain(obj, val)
        val = types.util.checkDtype('strain', 'char', val);
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
        refs = export@types.core.Subject(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.age_in_days)
            io.writeAttribute(fid, [fullpath '/age_in_days'], obj.age_in_days);
        else
            error('Property `age_in_days` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.specimen_name)
            io.writeAttribute(fid, [fullpath '/specimen_name'], obj.specimen_name);
        else
            error('Property `specimen_name` is required in `%s`.', fullpath);
        end
    end
end

end