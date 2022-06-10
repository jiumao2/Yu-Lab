function idx_out = findSeq(seqmom,seqson,type)
    % eg. seqmom = [1,2,3,5,6,7]; seqson = [2,3,6]; idx_out would be [2,3,5]
    if nargin <= 2
        type = 'normal';
    end
    
    switch type
        case 'normal'
            idx_out = zeros(size(seqson));
            for k = 1:length(seqson)
                idx_out(k) = find(seqmom==seqson(k));
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
                idx_out(k) = left;
            end
        otherwise
            error('Unknown argument')
    end
end