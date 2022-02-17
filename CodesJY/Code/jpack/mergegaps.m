function runout=mergegaps(runin, gapsize, type)

if nargin<3
    type=1; % here the input is begs and ends
    if nargin<2
        gapsize=25;
    end;
end;

% go through "run" epochs
% link the runs if the gap is less than a defined amount, default, 50 ms

switch type
    
    case 1
        
        gaps=runin(2:end, 1)-runin(1:end-1, 2);
        ind_small_gaps=find(gaps<=gapsize);
        runin(ind_small_gaps, 2)=NaN;
        runin(ind_small_gaps+1, 1)=NaN;
        runout(:, 1)=runin(~isnan(runin(:, 1)), 1);
        runout(:, 2)=runin(~isnan(runin(:, 2)), 2);
        if find(isnan(runout))
            pause
        end;
        
    case 2
        newrunout=zeros(size(runin));
        eps=dissectmat(runin, 1);
        if ~isempty(eps)
            neweps=mergegaps(eps, gapsize, 1);
        else
            neweps=[];
        end;
        
        if ~isempty(neweps)
            for k=1:size(neweps, 1)
                newrunout(neweps(k, 1):neweps(k, 2))=1;
            end;
        end;
        runout=newrunout;
end;
