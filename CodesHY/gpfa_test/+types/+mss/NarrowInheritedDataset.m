classdef NarrowInheritedDataset < types.mss.NullShapeDataset & types.untyped.DatasetClass
% NARROWINHERITEDDATASET 



methods
    function obj = NarrowInheritedDataset(varargin)
        % NARROWINHERITEDDATASET Constructor for NarrowInheritedDataset
        %     obj = NARROWINHERITEDDATASET(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.mss.NullShapeDataset(varargin{:});
        if strcmp(class(obj), 'types.mss.NarrowInheritedDataset')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'char', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.mss.NullShapeDataset(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end