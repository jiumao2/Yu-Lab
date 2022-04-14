function r_all2csv(r_all,csv_path)
    rTbl = table();
    
    trial_num = zeros(length(r_all.r),1);
    for k = 1:length(r_all.r)
        trial_num(k) = length(r_all.r{k}.Behavior.CorrectIndex);
    end    
    
    for k = 1:height(r_all.UnitsCombined)
        temp = r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1};
        [~,r_idx] = max(trial_num(temp(:,1)));
        
        rTbl(k,1:5) = {r_all.AnimalName,...
            r_all.r{temp(r_idx,1)}.Meta(1).DateTime,...
            temp(r_idx,2),...
            temp(r_idx,3),...
            [r_all.r{temp(r_idx,1)}.path,r_all.r{temp(r_idx,1)}.filename]};
    end
    rTbl.Properties.VariableNames = {'Animal','Date','Channel','Cluster','Path'};
    writetable(rTbl,csv_path,'WriteMode','append');
end