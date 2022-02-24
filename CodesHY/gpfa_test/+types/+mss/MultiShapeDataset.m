classdef MultiShapeDataset < types.mss.ShapeDataset & types.untyped.DatasetClass
% MULTISHAPEDATASET 



methods
    function obj = MultiShapeDataset(varargin)
        % MULTISHAPEDATASET Constructor for MultiShapeDataset
        %     obj = MULTISHAPEDATASET(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.mss.ShapeDataset(varargin{:});
        if strcmp(class(obj), 'types.mss.MultiShapeDataset')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.mss.ShapeDataset(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end