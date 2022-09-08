function r_all2csv(r_all_path,csv_path)
    load(r_all_path)
    rTbl = table();
    VariableNames = {'ID','Animal','Date','Channel','Cluster','Path','Region','ImgPath','OtherImgPath',...
        'Lift','Press','Holding','Trigger','Release'};
    if ~exist(csv_path,'file')
        num_neurons = 0;
    else
        [~,~,csv_out] = xlsread(csv_path);
        num_neurons = csv_out{end,1};
    end
    
    trial_num = zeros(length(r_all.r),1);
    for k = 1:length(r_all.r)
        trial_num(k) = length(r_all.r{k}.Behavior.CorrectIndex);
    end    
    
    for k = 1:height(r_all.UnitsCombined)
        temp = r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1};
        [~,r_idx] = max(trial_num(temp(:,1)));
        
        date_this = datetime(r_all.r{temp(r_idx,1)}.Meta(1).DateTime);
        rTbl(k,1:length(VariableNames)) = {...
            k+num_neurons,... % ID
            r_all.r{temp(r_idx,1)}.Meta(1).Subject,... % Animal
            r_all.r{temp(r_idx,1)}.Meta(1).DateTime,...           % Date
            temp(r_idx,2),... % Channel
            temp(r_idx,3),... % Cluster
            [r_all.r{temp(r_idx,1)}.path,r_all.r{temp(r_idx,1)}.filename],... % Path
            'M1',...   % Region
            ['Images/',...
                r_all.r{temp(r_idx,1)}.Meta(1).Subject,'/',...
                datestr(date_this,'yyyymmdd'),...
                '/Ch',num2str(temp(r_idx,2)),'_Unit',num2str(temp(r_idx,3)),'.png'],... % ImgPath
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