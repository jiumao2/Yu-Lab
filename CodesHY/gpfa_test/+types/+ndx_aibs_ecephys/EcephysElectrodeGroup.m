classdef EcephysElectrodeGroup < types.core.ElectrodeGroup & types.untyped.GroupClass
% ECEPHYSELECTRODEGROUP A group consisting of the channels on a single neuropixels probe


% PROPERTIES
properties
    has_lfp_data; % Indicates availability of LFP data
    lfp_sampling_rate; % The sampling rate at which data were acquired on this electrode group's channels
    probe_id; % Unique ID of the neuropixels probe
end

methods
    function obj = EcephysElectrodeGroup(varargin)
        % ECEPHYSELECTRODEGROUP Constructor for EcephysElectrodeGroup
        %     obj = ECEPHYSELECTRODEGROUP(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % has_lfp_data = logical
        % lfp_sampling_rate = float64
        % probe_id = int
        obj = obj@types.core.ElectrodeGroup(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'has_lfp_data',[]);
        addParameter(p, 'lfp_sampling_rate',[]);
        addParameter(p, 'probe_id',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.has_lfp_data = p.Results.has_lfp_data;
        obj.lfp_sampling_rate = p.Results.lfp_sampling_rate;
        obj.probe_id = p.Results.probe_id;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysElectrodeGroup')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.has_lfp_data(obj, val)
        obj.has_lfp_data = obj.validate_has_lfp_data(val);
    end
    function obj = set.lfp_sampling_rate(obj, val)
        obj.lfp_sampling_rate = obj.validate_lfp_sampling_rate(val);
    end
    function obj = set.probe_id(obj, val)
        obj.probe_id = obj.validate_probe_id(val);
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
    function val = validate_has_lfp_data(obj, val)
        val = types.util.checkDtype('has_lfp_data', 'logical', val);
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
    function val = validate_lfp_sampling_rate(obj, val)
        val = types.util.checkDtype('lfp_sampling_rate', 'float64', val);
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
    function val = validate_location(obj, val)
        val = types.util.checkDtype('location', 'char', val);
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
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ElectrodeGroup(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.has_lfp_data)
            io.writeAttribute(fid, [fullpath '/has_lfp_data'], obj.has_lfp_data);
        else
            error('Property `has_lfp_data` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.lfp_sampling_rate)
            io.writeAttribute(fid, [fullpath '/lfp_sampling_rate'], obj.lfp_sampling_rate);
        else
            error('Property `lfp_sampling_rate` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.probe_id)
            io.writeAttribute(fid, [fullpath '/probe_id'], obj.probe_id);
        else
            error('Property `probe_id` is required in `%s`.', fullpath);
        end
    end
end

end