classdef MultiShapeWrapper < types.core.NWBDataInterface & types.untyped.GroupClass
% MULTISHAPEWRAPPER 


% READONLY
properties(SetAccess=protected)
    help; % Value is 'Arbitrary shapes'
end
% PROPERTIES
properties
    shaped_data; % 
end

methods
    function obj = MultiShapeWrapper(varargin)
        % MULTISHAPEWRAPPER Constructor for MultiShapeWrapper
        %     obj = MULTISHAPEWRAPPER(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % help = char
        % shaped_data = ShapeDataset
        varargin = [{'help' 'Arbitrary shapes'} varargin];
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'help',[]);
        addParameter(p, 'shaped_data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.help = p.Results.help;
        obj.shaped_data = p.Results.shaped_data;
        if strcmp(class(obj), 'types.mss.MultiShapeWrapper')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.shaped_data(obj, val)
        obj.shaped_data = obj.validate_shaped_data(val);
    end
    %% VALIDATORS
    
    function val = validate_shaped_data(obj, val)
        val = types.util.checkDtype('shaped_data', 'types.mss.ShapeDataset', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.help)
            io.writeAttribute(fid, [fullpath '/help'], obj.help);
        else
            error('Property `help` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.shaped_data)
            refs = obj.shaped_data.export(fid, [fullpath '/shaped_data'], refs);
        else
            error('Property `shaped_data` is required in `%s`.', fullpath);
        end
    end
end

end