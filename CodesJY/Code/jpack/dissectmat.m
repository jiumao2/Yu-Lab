function [eps, newdatamat]=dissectmat(datamat, mindur)

toreverse=0;

if size(datamat, 1)<size(datamat, 2)
    datamat=datamat';
    toreverse=1;
end;

newdatamat=sparse(size(datamat, 1), size(datamat, 2));

eps=cell(1, size(datamat, 2));

for i=1:size(datamat, 2)
    inds=find(datamat(:, i));
    if ~isempty(inds)
        diff_inds=diff(inds);
        starts=inds([1; 1+find(diff_inds>1)]);
        ends=[inds(find(diff_inds>1)); inds(end)];
        
        ep_dur=ends-starts;
        
        inds_real=find(ep_dur>=mindur);
        
        starts=starts(inds_real);
        ends=ends(inds_real);
        
        if ~isempty(starts)
            eps{i}=[starts ends];
            
            for k=1:length(starts)
                newdatamat(starts(k):ends(k), i)=1;
            end;
        end;
    end;
end;

if size(datamat, 2)==1
    eps=cell2mat(eps);
end;

if toreverse
    newdatamat=newdatamat';
end;