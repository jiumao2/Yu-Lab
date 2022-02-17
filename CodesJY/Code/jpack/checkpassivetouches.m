function passivetouch=checkpassivetouches(T, contacts, wid)
% 4.12.2015; give you the trialnums of passive touches of whisker wid

% the output passivetouch will be trial nums. 
passivetouch=[];

for i=1:length(T.trialNums)
    
    firsttouch_all=[];
    if ~isempty(contacts{i}) && isfield(contacts{i}, 'tid')
        if length(contacts{i}.tid)==1
            if  (any(find(contacts{i}.segmentInds{1})))
                firsttouch_all=contacts{i}.segmentInds{1}(1, 1);
            end;
        else
            for k=1:length(contacts{i}.tid)
                if  (any(find(contacts{i}.segmentInds{k})))
                    firsttouch_all=[firsttouch_all contacts{i}.segmentInds{k}(1, 1)];
                end;
            end;
        end;
        
        if ~isempty(firsttouch_all)
            if  (any(find(contacts{i}.segmentInds{contacts{i}.tid==wid}))) % whisker wid touches in this trial
                if  (any(find(contacts{i}.segmentInds{contacts{i}.tid==wid})))
                    if contacts{i}.segmentInds{contacts{i}.tid==wid}(1, 1)<=min(firsttouch_all);
                        if isfield(contacts{i}, 'passive')
                            if contacts{i}.passive==1
                                passivetouch=[passivetouch T.trialNums(i)];
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;