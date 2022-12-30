% automatic find out the manually modified images and make them in the new
% training sets

path = {'D:\Ephys\ANMs\Chen\Video'
    'D:\Ephys\ANMs\Davis\Video'
    'D:\Ephys\ANMs\Eli\Sessions'
    'D:\Ephys\ANMs\Russo\Sessions'
    'D:\Ephys\ANMs\Urey\Videos'};
for idx_path = 1:length(path)
    video_path = dir(path{idx_path});
    video_path = {video_path.name};
    for idx_video = 1:length(video_path)
        if length(video_path{idx_video})>6 && strcmp(video_path{idx_video}(end-5:end),'_video')
            count = 0;
            if ~exist(fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/'))
                break
            end
            
            mat_path = dir(fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/MatFile/*.mat'));
            mat_path = {mat_path.name};
            mat_path = sort(mat_path);
            
            csv_path = dir(fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/RawVideo/*.csv'));
            csv_path = {csv_path.name};
            csv_path = sort(csv_path);
            
            if isempty(csv_path) || isempty(mat_path)
                break
            end
            
            dir_name = fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/ModifiedFrames/');
            if ~exist(dir_name,'dir')
                mkdir(dir_name);
            else
                rmdir(dir_name,'s');
                mkdir(dir_name);
            end 
            
            for idx_mat = 1:length(mat_path)
                load(fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/MatFile/',mat_path{idx_mat}))
                if ~isfield(VideoInfo,'Tracking')
                    break
                end
                
                [data,txt,~] = xlsread(fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/RawVideo/',csv_path{idx_mat}));
                bodyParts = cell(round((size(txt,2)-1)/3),1);
                coordinates_x = cell(length(bodyParts),1);
                coordinates_y = cell(length(bodyParts),1);
                coordinates_p = cell(length(bodyParts),1);
                for k = 1:length(bodyParts)
                    bodyParts{k} = txt{2,3*k-1};
                    coordinates_x{k} = data(:,3*k-1);
                    coordinates_y{k} = data(:,3*k);
                    coordinates_p{k} = data(:,3*k+1);
                end
                
                idx_left_paw = find(strcmp(bodyParts,'left_paw'));
                               
                for k = 1:length(coordinates_x{idx_left_paw})
                    if coordinates_x{idx_left_paw}(k) ~= VideoInfo.Tracking.Coordinates_x{idx_left_paw}(k) || ...
                            coordinates_y{idx_left_paw}(k) ~= VideoInfo.Tracking.Coordinates_y{idx_left_paw}(k)
                        
                        vid_filename = fullfile(path{idx_path},video_path{idx_video},'VideoFrames_side/RawVideo/',...
                            [mat_path{idx_mat}(1:end-3),'avi']);
                        vid_obj = VideoReader(vid_filename);
                        img = vid_obj.read(k);
                        imwrite(img,fullfile(dir_name,[num2str(count,'%03d'),'.png']));

                        temp = zeros(1,length(bodyParts)*3);
                        for j = 1:length(bodyParts)
                            temp(3*j-2) = VideoInfo.Tracking.Coordinates_x{j}(k);
                            temp(3*j-1) = VideoInfo.Tracking.Coordinates_y{j}(k);
                            temp(3*j-0) = VideoInfo.Tracking.Coordinates_p{j}(k);
                        end
                        dlmwrite(fullfile(dir_name,'out.csv'),temp,'-append');
                        
                        count = count + 1;
                    end
                end

                
            end
        end
    end
end
    
    