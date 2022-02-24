classdef ExternalResources < types.hdmf_common.Container & types.untyped.GroupClass
% EXTERNALRESOURCES A set of four tables for tracking external resource references in a file. NOTE: this data type is in beta testing and is subject to change in a later version.


% PROPERTIES
properties
    entities; % A table for mapping user terms (i.e., keys) to resource entities.
    keys; % A table for storing user terms that are used to refer to external resources.
    object_keys; % A table for identifying which objects use which keys.
    objects; % A table for identifying which objects in a file contain references to external resources.
    resources; % A table for mapping user terms (i.e., keys) to resource entities.
end

methods
    function obj = ExternalResources(varargin)
        % EXTERNALRESOURCES Constructor for ExternalResources
        %     obj = EXTERNALRESOURCES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % entities = Data
        % keys = Data
        % object_keys = Data
        % objects = Data
        % resources = Data
        obj = obj@types.hdmf_common.Container(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'entities',[]);
        addParameter(p, 'keys',[]);
        addParameter(p, 'object_keys',[]);
        addParameter(p, 'objects',[]);
        addParameter(p, 'resources',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.entities = p.Results.entities;
        obj.keys = p.Results.keys;
        obj.object_keys = p.Results.object_keys;
        obj.objects = p.Results.objects;
        obj.resources = p.Results.resources;
        if strcmp(class(obj), 'types.hdmf_experimental.ExternalResources')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.entities(obj, val)
        obj.entities = obj.validate_entities(val);
    end
    function obj = set.keys(obj, val)
        obj.keys = obj.validate_keys(val);
    end
    function obj = set.object_keys(obj, val)
        obj.object_keys = obj.validate_object_keys(val);
    end
    function obj = set.objects(obj, val)
        obj.objects = obj.validate_objects(val);
    end
    function obj = set.resources(obj, val)
        obj.resources = obj.validate_resources(val);
    end
    %% VALIDATORS
    
    function val = validate_entities(obj, val)
        val = types.util.checkDtype('entities', 'types.hdmf_common.Data', val);
    end
    function val = validate_keys(obj, val)
        val = types.util.checkDtype('keys', 'types.hdmf_common.Data', val);
    end
    function val = validate_object_keys(obj, val)
        val = types.util.checkDtype('object_keys', 'types.hdmf_common.Data', val);
    end
    function val = validate_objects(obj, val)
        val = types.util.checkDtype('objects', 'types.hdmf_common.Data', val);
    end
    function val = validate_resources(obj, val)
        val = types.util.checkDtype('resources', 'types.hdmf_common.Data', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Container(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.entities)
            refs = obj.entities.export(fid, [fullpath '/entities'], refs);
        else
            error('Property `entities` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.keys)
            refs = obj.keys.export(fid, [fullpath '/keys'], refs);
        else
            error('Property `keys` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.object_keys)
            refs = obj.object_keys.export(fid, [fullpath '/object_keys'], refs);
        else
            error('Property `object_keys` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.objects)
            refs = obj.objects.export(fid, [fullpath '/objects'], refs);
        else
            error('Property `objects` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.resources)
            refs = obj.resources.export(fid, [fullpath '/resources'], refs);
        else
            error('Property `resources` is required in `%s`.', fullpath);
        end
    end
end

end