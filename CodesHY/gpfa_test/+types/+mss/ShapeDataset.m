classdef ShapeDataset < types.core.NWBData & types.untyped.DatasetClass
% SHAPEDATASET 


% READONLY
properties(SetAccess=protected)
    help; % Value is 'Shape Data'
end

methods
    function obj = ShapeDataset(varargin)
        % SHAPEDATASET Constructor for ShapeDataset
        %     obj = SHAPEDATASET(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % help = char
        varargin = [{'help' 'Shape Data'} varargin];
        obj = obj@types.core.NWBData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'help',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.help = p.Results.help;
        if strcmp(class(obj), 'types.mss.ShapeDataset')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.help)
            io.writeAttribute(fid, [fullpath '/help'], obj.help);
        else
            error('Property `help` is required in `%s`.', fullpath);
        end
    end
end

end