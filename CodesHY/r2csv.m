function r2csv(r_path,csv_path)
    load(r_path)
    rTbl = table(); 
    su_idx = find(r.Units.SpikeNotes(:,3)==1);
    
    for k = 1:length(su_idx)
        rTbl(k,1:5) = {r.Meta(1).Subject,...
            r.Meta(1).DateTime,...
            r.Units.SpikeNotes(su_idx(k),1),...
            r.Units.SpikeNotes(su_idx(k),2),...
            r_path};
    end
    rTbl.Properties.VariableNames = {'Animal','Date','Channel','Cluster','Path'};
    writetable(rTbl,csv_path,'WriteMode','append');
end