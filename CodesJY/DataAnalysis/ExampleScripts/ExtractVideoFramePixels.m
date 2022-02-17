mainfolder ='C:\Users\jiani\OneDrive\Work\Physiology\Data\Subjects\Lucky\20200120';
framefile{1}='Cam_00D41933035+2020_1_20_16_57_44.5940819+.avi';
framefile{2}='Cam_00D41933035+2020_1_20_16_57_44.5940819++.avi';
frames_all =cell(1, 2);

figure;

frametime=[];
for i=1
    %read the video
    vidObj= VideoReader(fullfile(mainfolder, framefile{1}));
    
    while(hasFrame(vidObj))
        frame = readFrame(vidObj);
%         imshow(frame);
        frametime = [frametime vidObj.CurrentTime];
%         title(sprintf('Current Time = %.3f sec', vidObj.CurrentTime)); 
    end
    
end;
    
    
% 
% n=1;
% while hasFrame(v)
%     frame = readFrame(v); 
%     x=sum(sum((frame([615:660], [300:340],1))));
%     frames_all{i}(n)=x;
%      n=n+1;
%      
%      
%      
% 
%      
%      
%      
% end
% 
% figure; plot(frames_all{i})
% 
% end;
% 
% 
