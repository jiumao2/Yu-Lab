function r2csv(r_path,csv_path)
    load(r_path)
    rTbl = table(); 
    su_idx = find(r.Units.SpikeNotes(:,3)==1);
    date_this = datetime(r.Meta(1).DateTime);
    VariableNames = {'ID','Animal','Date','Channel','Cluster','Path','Region','ImgPath','OtherImgPath',...
        'Lift','Press','Holding','Trigger','Release'};
    if ~exist(csv_path,'file')
        num_neurons = 0;
    else
        [~,~,csv_out] = xlsread(csv_path);
        num_neurons = csv_out{end,1};
    end
    
    for k = 1:length(su_idx)
        rTbl(k,1:length(VariableNames)) = {...
            k+num_neurons,... % ID
            r.Meta(1).Subject,... % Animal
            r.Meta(1).DateTime,...           % Date
            r.Units.SpikeNotes(su_idx(k),1),... % Channel
            r.Units.SpikeNotes(su_idx(k),2),... % Cluster
            r_path,... % Path
            'M1',...   % Region
            ['Images/',...
                r.Meta(1).Subject,'/',...
                datestr(date_this,'yyyymmdd'),...
                '/Ch',num2str(r.Units.SpikeNotes(su_idx(k),1)),'_Unit',num2str(r.Units.SpikeNotes(su_idx(k),2)),'.png'],... % ImgPath
            '', ... % OtherImgPath
            '', ... % Lift
            '', ... % Press
            '', ... % Holding
            '', ... % Trigger
            '', ... % Release
            };
    end
    
    rTbl.Properties.VariableNames = VariableNames;
    writetable(rTbl,csv_path,'WriteMode','append');
end