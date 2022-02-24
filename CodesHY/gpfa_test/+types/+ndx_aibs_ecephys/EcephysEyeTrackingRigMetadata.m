classdef EcephysEyeTrackingRigMetadata < types.core.NWBDataInterface & types.untyped.GroupClass
% ECEPHYSEYETRACKINGRIGMETADATA Metadata for ecephys experiment rig


% PROPERTIES
properties
    camera_position; % position of camera (x, y, z)
    camera_position_unit; % Unit of measurement for the data
    camera_rotation; % rotation of camera (x, y, z)
    camera_rotation_unit; % Unit of measurement for the data
    equipment; % Description of rig
    led_position; % position of LED (x, y, z)
    led_position_unit; % Unit of measurement for the data
    monitor_position; % position of monitor (x, y, z)
    monitor_position_unit; % Unit of measurement for the data
    monitor_rotation; % rotation of monitor (x, y, z)
    monitor_rotation_unit; % Unit of measurement for the data
end

methods
    function obj = EcephysEyeTrackingRigMetadata(varargin)
        % ECEPHYSEYETRACKINGRIGMETADATA Constructor for EcephysEyeTrackingRigMetadata
        %     obj = ECEPHYSEYETRACKINGRIGMETADATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % camera_position = float32
        % camera_position_unit = char
        % camera_rotation = float32
        % camera_rotation_unit = char
        % equipment = char
        % led_position = float32
        % led_position_unit = char
        % monitor_position = float32
        % monitor_position_unit = char
        % monitor_rotation = float32
        % monitor_rotation_unit = char
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'camera_position',[]);
        addParameter(p, 'camera_position_unit',[]);
        addParameter(p, 'camera_rotation',[]);
        addParameter(p, 'camera_rotation_unit',[]);
        addParameter(p, 'equipment',[]);
        addParameter(p, 'led_position',[]);
        addParameter(p, 'led_position_unit',[]);
        addParameter(p, 'monitor_position',[]);
        addParameter(p, 'monitor_position_unit',[]);
        addParameter(p, 'monitor_rotation',[]);
        addParameter(p, 'monitor_rotation_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.camera_position = p.Results.camera_position;
        obj.camera_position_unit = p.Results.camera_position_unit;
        obj.camera_rotation = p.Results.camera_rotation;
        obj.camera_rotation_unit = p.Results.camera_rotation_unit;
        obj.equipment = p.Results.equipment;
        obj.led_position = p.Results.led_position;
        obj.led_position_unit = p.Results.led_position_unit;
        obj.monitor_position = p.Results.monitor_position;
        obj.monitor_position_unit = p.Results.monitor_position_unit;
        obj.monitor_rotation = p.Results.monitor_rotation;
        obj.monitor_rotation_unit = p.Results.monitor_rotation_unit;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysEyeTrackingRigMetadata')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.camera_position(obj, val)
        obj.camera_position = obj.validate_camera_position(val);
    end
    function obj = set.camera_position_unit(obj, val)
        obj.camera_position_unit = obj.validate_camera_position_unit(val);
    end
    function obj = set.camera_rotation(obj, val)
        obj.camera_rotation = obj.validate_camera_rotation(val);
    end
    function obj = set.camera_rotation_unit(obj, val)
        obj.camera_rotation_unit = obj.validate_camera_rotation_unit(val);
    end
    function obj = set.equipment(obj, val)
        obj.equipment = obj.validate_equipment(val);
    end
    function obj = set.led_position(obj, val)
        obj.led_position = obj.validate_led_position(val);
    end
    function obj = set.led_position_unit(obj, val)
        obj.led_position_unit = obj.validate_led_position_unit(val);
    end
    function obj = set.monitor_position(obj, val)
        obj.monitor_position = obj.validate_monitor_position(val);
    end
    function obj = set.monitor_position_unit(obj, val)
        obj.monitor_position_unit = obj.validate_monitor_position_unit(val);
    end
    function obj = set.monitor_rotation(obj, val)
        obj.monitor_rotation = obj.validate_monitor_rotation(val);
    end
    function obj = set.monitor_rotation_unit(obj, val)
        obj.monitor_rotation_unit = obj.validate_monitor_rotation_unit(val);
    end
    %% VALIDATORS
    
    function val = validate_camera_position(obj, val)
        val = types.util.checkDtype('camera_position', 'float32', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_camera_position_unit(obj, val)
        val = types.util.checkDtype('camera_position_unit', 'char', val);
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
    function val = validate_camera_rotation(obj, val)
        val = types.util.checkDtype('camera_rotation', 'float32', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_camera_rotation_unit(obj, val)
        val = types.util.checkDtype('camera_rotation_unit', 'char', val);
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
    function val = validate_equipment(obj, val)
        val = types.util.checkDtype('equipment', 'char', val);
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
    function val = validate_led_position(obj, val)
        val = types.util.checkDtype('led_position', 'float32', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_led_position_unit(obj, val)
        val = types.util.checkDtype('led_position_unit', 'char', val);
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
    function val = validate_monitor_position(obj, val)
        val = types.util.checkDtype('monitor_position', 'float32', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_monitor_position_unit(obj, val)
        val = types.util.checkDtype('monitor_position_unit', 'char', val);
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
    function val = validate_monitor_rotation(obj, val)
        val = types.util.checkDtype('monitor_rotation', 'float32', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_monitor_rotation_unit(obj, val)
        val = types.util.checkDtype('monitor_rotation_unit', 'char', val);
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
        if ~isempty(obj.camera_position)
            if startsWith(class(obj.camera_position), 'types.untyped.')
                refs = obj.camera_position.export(fid, [fullpath '/camera_position'], refs);
            elseif ~isempty(obj.camera_position)
                io.writeDataset(fid, [fullpath '/camera_position'], obj.camera_position, 'forceArray');
            end
        else
            error('Property `camera_position` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.camera_position_unit) && ~isempty(obj.camera_position)
            io.writeAttribute(fid, [fullpath '/camera_position/unit'], obj.camera_position_unit);
        elseif ~isempty(obj.camera_position)
            error('Property `camera_position_unit` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.camera_rotation)
            if startsWith(class(obj.camera_rotation), 'types.untyped.')
                refs = obj.camera_rotation.export(fid, [fullpath '/camera_rotation'], refs);
            elseif ~isempty(obj.camera_rotation)
                io.writeDataset(fid, [fullpath '/camera_rotation'], obj.camera_rotation, 'forceArray');
            end
        else
            error('Property `camera_rotation` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.camera_rotation_unit) && ~isempty(obj.camera_rotation)
            io.writeAttribute(fid, [fullpath '/camera_rotation/unit'], obj.camera_rotation_unit);
        elseif ~isempty(obj.camera_rotation)
            error('Property `camera_rotation_unit` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.equipment)
            io.writeAttribute(fid, [fullpath '/equipment'], obj.equipment);
        else
            error('Property `equipment` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.led_position)
            if startsWith(class(obj.led_position), 'types.untyped.')
                refs = obj.led_position.export(fid, [fullpath '/led_position'], refs);
            elseif ~isempty(obj.led_position)
                io.writeDataset(fid, [fullpath '/led_position'], obj.led_position, 'forceArray');
            end
        else
            error('Property `led_position` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.led_position_unit) && ~isempty(obj.led_position)
            io.writeAttribute(fid, [fullpath '/led_position/unit'], obj.led_position_unit);
        elseif ~isempty(obj.led_position)
            error('Property `led_position_unit` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.monitor_position)
            if startsWith(class(obj.monitor_position), 'types.untyped.')
                refs = obj.monitor_position.export(fid, [fullpath '/monitor_position'], refs);
            elseif ~isempty(obj.monitor_position)
                io.writeDataset(fid, [fullpath '/monitor_position'], obj.monitor_position, 'forceArray');
            end
        else
            error('Property `monitor_position` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.monitor_position_unit) && ~isempty(obj.monitor_position)
            io.writeAttribute(fid, [fullpath '/monitor_position/unit'], obj.monitor_position_unit);
        elseif ~isempty(obj.monitor_position)
            error('Property `monitor_position_unit` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.monitor_rotation)
            if startsWith(class(obj.monitor_rotation), 'types.untyped.')
                refs = obj.monitor_rotation.export(fid, [fullpath '/monitor_rotation'], refs);
            elseif ~isempty(obj.monitor_rotation)
                io.writeDataset(fid, [fullpath '/monitor_rotation'], obj.monitor_rotation, 'forceArray');
            end
        else
            error('Property `monitor_rotation` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.monitor_rotation_unit) && ~isempty(obj.monitor_rotation)
            io.writeAttribute(fid, [fullpath '/monitor_rotation/unit'], obj.monitor_rotation_unit);
        elseif ~isempty(obj.monitor_rotation)
            error('Property `monitor_rotation_unit` is required in `%s`.', fullpath);
        end
    end
end

end