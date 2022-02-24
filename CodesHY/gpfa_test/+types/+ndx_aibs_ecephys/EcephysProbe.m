classdef EcephysProbe < types.core.Device & types.untyped.GroupClass
% ECEPHYSPROBE A neuropixels probe device


% PROPERTIES
properties
    probe_id; % Unique ID of the neuropixels probe
    sampling_rate; % The sampling rate for the device
end

methods
    function obj = EcephysProbe(varargin)
        % ECEPHYSPROBE Constructor for EcephysProbe
        %     obj = ECEPHYSPROBE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % probe_id = int
        % sampling_rate = float64
        obj = obj@types.core.Device(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'probe_id',[]);
        addParameter(p, 'sampling_rate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.probe_id = p.Results.probe_id;
        obj.sampling_rate = p.Results.sampling_rate;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysProbe')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.probe_id(obj, val)
        obj.probe_id = obj.validate_probe_id(val);
    end
    function obj = set.sampling_rate(obj, val)
        obj.sampling_rate = obj.validate_sampling_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
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
    function val = validate_manufacturer(obj, val)
        val = types.util.checkDtype('manufacturer', 'char', val);
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
    function val = validate_probe_id(obj, val)
        val = types.util.checkDtype('probe_id', 'int', val);
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
    function val = validate_sampling_rate(obj, val)
        val = types.util.checkDtype('sampling_rate', 'float64', val);
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
        refs = export@types.core.Device(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.probe_id)
            io.writeAttribute(fid, [fullpath '/probe_id'], obj.probe_id);
        else
            error('Property `probe_id` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.sampling_rate)
            io.writeAttribute(fid, [fullpath '/sampling_rate'], obj.sampling_rate);
        else
            error('Property `sampling_rate` is required in `%s`.', fullpath);
        end
    end
end

end