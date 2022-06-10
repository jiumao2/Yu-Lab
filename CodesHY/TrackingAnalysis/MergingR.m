function r_new = MergingR(r_path, r_all, varargin)
    isMeta = true;
    isBehavior = true;
    isUnits = true;
    isWave = true;
    isAnalog = false;
    isVideo = false;
    isVideoInfos_top = true;
    isVideoInfos_side = true;
    MergeIndex = 1:length(r_path);

    if nargin>=2
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'Meta'
                    isMeta = varargin{i+1};
                case 'Behavior'
                    isBehavior = varargin{i+1};
                case 'Units'
                    isUnits =  varargin{i+1};
                case 'Wave'
                    isWave = varargin{i+1};
                case 'Analog'
                    isAnalog =  varargin{i+1};    
                case 'Video'
                    isVideo =  varargin{i+1};  
                case 'VideoInfos_top'
                    isVideoInfos_top =  varargin{i+1};  
                case 'VideoInfos_side'
                    isVideoInfos_side =  varargin{i+1};
                case 'MergeIndex'
                    MergeIndex =  varargin{i+1};  
                otherwise
                    errordlg('unknown argument')
            end
        end
    end

    for path_id = 1:length(MergeIndex)
        load(r_path{MergeIndex(path_id)});
        if path_id == 1
            t0 = getReferenceTime(r);
            if isMeta
                r_new.Meta = r.Meta;
            end
            if isBehavior
                r.Behavior.EventTimings = r.Behavior.EventTimings + getReferenceTime(r, t0);
                r_new.Behavior = r.Behavior;
            end
            if isUnits
                r_new.Units.Definition = r.Units.Definition;
                r_new.Units.UnitsCombined = r_all.UnitsCombined;
                for k = 1:height(r_all.UnitsCombined)
                    r_new.SpikeNotes(k,:) = [r_all.UnitsCombined(1,:).Channel,r_all.UnitsCombined(1,:).Number,1,0];
                end
                for k = 1:height(r_all.UnitsCombined)
                    for j = 1:size(r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1},1)
                        if r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1}(j,1) == MergeIndex(path_id)
                            unit_num_this = find(r.Units.SpikeNotes(:,1)==r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1}(j,2) ...
                                & r.Units.SpikeNotes(:,2)==r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1}(j,3));
                            r_new.Units.SpikeTimes(k).timings = r.Units.SpikeTimes(unit_num_this).timings + getReferenceTime(r, t0);
                            if isWave
                                r_new.Units.SpikeTimes(k).wave = r.Units.SpikeTimes(unit_num_this).wave;
                            end
                        end
                    end
                end
            end
            if isVideoInfos_top
                for k = 1:length(r.VideoInfos_top)
                    r.VideoInfos_top(k).Time = r.VideoInfos_top(k).Time+getReferenceTime(r, t0);
                    r.VideoInfos_top(k).VideoFrameTime = r.VideoInfos_top(k).VideoFrameTime+getReferenceTime(r, t0);
                end
                r_new.VideoInfos_top = r.VideoInfos_top;
            end
            if isVideoInfos_side
                for k = 1:length(r.VideoInfos_side)
                    r.VideoInfos_side(k).Time = r.VideoInfos_side(k).Time+getReferenceTime(r, t0);
                    r.VideoInfos_side(k).VideoFrameTime = r.VideoInfos_side(k).VideoFrameTime+getReferenceTime(r, t0);
                end
                r_new.VideoInfos_side = r.VideoInfos_side;
            end
        else
            if isMeta
                r_new.Meta = [r_new.Meta, r.Meta];
            end
            if isBehavior
                r_new.Behavior.CorrectIndex = [r_new.Behavior.CorrectIndex;r.Behavior.CorrectIndex+sum(r_new.Behavior.EventMarkers==3)];
                r_new.Behavior.PrematureIndex = [r_new.Behavior.PrematureIndex;r.Behavior.PrematureIndex+sum(r_new.Behavior.EventMarkers==3)];
                r_new.Behavior.LateIndex = [r_new.Behavior.LateIndex;r.Behavior.LateIndex+sum(r_new.Behavior.EventMarkers==3)];
                r_new.Behavior.DarkIndex = [r_new.Behavior.DarkIndex;r.Behavior.DarkIndex+sum(r_new.Behavior.EventMarkers==3)];
                r_new.Behavior.Foreperiods = [r_new.Behavior.Foreperiods;r.Behavior.Foreperiods];
                r_new.Behavior.EventTimings = [r_new.Behavior.EventTimings;r.Behavior.EventTimings+getReferenceTime(r, t0)];
                r_new.Behavior.EventMarkers = [r_new.Behavior.EventMarkers;r.Behavior.EventMarkers];
            end                        
            if isUnits
                for k = 1:height(r_all.UnitsCombined)
                    for j = 1:size(r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1},1)
                        if r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1}(j,1) == MergeIndex(path_id)
                            unit_num_this = find(r.Units.SpikeNotes(:,1)==r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1}(j,2) ...
                                & r.Units.SpikeNotes(:,2)==r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1}(j,3));
                            if k <= length(r_new.Units.SpikeTimes)
                                r_new.Units.SpikeTimes(k).timings = [r_new.Units.SpikeTimes(k).timings,r.Units.SpikeTimes(unit_num_this).timings + getReferenceTime(r, t0)];
                            else
                                r_new.Units.SpikeTimes(k).timings = r.Units.SpikeTimes(unit_num_this).timings + getReferenceTime(r, t0); 
                            end
                            if isWave
                                r_new.Units.SpikeTimes(k).wave = [r_new.Units.SpikeTimes(k).wave;r.Units.SpikeTimes(unit_num_this).wave];
                            end
                        end
                    end
                end
            end
            if isVideoInfos_top
                for k = 1:length(r.VideoInfos_top)
                    r.VideoInfos_top(k).Time = r.VideoInfos_top(k).Time+getReferenceTime(r, t0);
                    r.VideoInfos_top(k).VideoFrameTime = r.VideoInfos_top(k).VideoFrameTime+getReferenceTime(r, t0);
                end
                r_new.VideoInfos_top = [r_new.VideoInfos_top,r.VideoInfos_top];
            end      
            if isVideoInfos_side
                for k = 1:length(r.VideoInfos_side)
                    r.VideoInfos_side(k).Time = r.VideoInfos_side(k).Time+getReferenceTime(r, t0);
                    r.VideoInfos_side(k).VideoFrameTime = r.VideoInfos_side(k).VideoFrameTime+getReferenceTime(r, t0);
                end
                r_new.VideoInfos_side = [r_new.VideoInfos_side,r.VideoInfos_side];
            end
        end
    end
    % save r_new r_new
end