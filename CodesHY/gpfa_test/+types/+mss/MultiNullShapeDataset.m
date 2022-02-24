classdef MultiNullShapeDataset < types.mss.ShapeDataset & types.untyped.DatasetClass
% MULTINULLSHAPEDATASET 



methods
    function obj = MultiNullShapeDataset(varargin)
        % MULTINULLSHAPEDATASET Constructor for MultiNullShapeDataset
        %     obj = MULTINULLSHAPEDATASET(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.mss.ShapeDataset(varargin{:});
        if strcmp(class(obj), 'types.mss.MultiNullShapeDataset')
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