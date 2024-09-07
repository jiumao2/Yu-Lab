function idx_out = findSeq(seqmom, seqson, type)
    % eg. seqmom = [1,2,3,5,6,7]; seqson = [2,3,6]; idx_out would be [2,3,5]
    if nargin <= 2
        type = 'normal_equal';
    end
    
    switch type
        case 'normal_equal'
            idx_out = zeros(size(seqson));
            for k = 1:length(seqson)
                idx_found = find(seqmom==seqson(k), 1);
                if ~isempty(idx_found)
                    idx_out(k) = idx_found;
                else
                    idx_out(k) = NaN;
                end
            end
        case 'normal_nearest'
            idx_out = zeros(size(seqson));
            for k = 1:length(seqson)
                [~,idx_out(k)] = min(abs(seqmom-seqson(k)));
            end            
        case 'ordered'
            idx_out = zeros(size(seqson));
            for k = 1:length(seqson)
                left = 1;
                right = length(seqmom);
                while right-left > 1
                    tmp_idx = round((left+right)/2);
                    if seqmom(tmp_idx) - seqson(k) > 0
                        right = tmp_idx;
                    else
                        left = tmp_idx;
                    end
                end
                if seqmom(right) - seqson(k) > seqson(k) - seqson(k)
                    idx_out(k) = left;
                else
                    idx_out(k) = right;
                end
            end
        otherwise
            error('Unknown argument')
    end
end