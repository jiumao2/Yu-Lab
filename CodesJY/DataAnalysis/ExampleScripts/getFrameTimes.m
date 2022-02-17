mainfolder ='C:\Users\jiani\OneDrive\Work\Physiology\Data\Subjects\Lucky\20200120';
file1='Cam_00D41933035+2020_1_20_16_57_44.5940819+.txt';
file2='Cam_00D41933035+2020_1_20_16_57_44.5940819++.txt';
 

fileID = fopen(fullfile(mainfolder, file1));

formatSpec = '%f';
sizeA = [1 inf];
 A = fscanf(fileID,formatSpec,sizeA);
 
 % extract time of each frame
 indframebeg = find(A==0);
 frame_times = A(1:indframebeg-1);
 frame_index = A(indframebeg:end-1);
 
 first_frame_time = frame_times(1);
 
 
 
fileID = fopen(fullfile(mainfolder, file2));

formatSpec = '%f'; 
A2 = fscanf(fileID,formatSpec,sizeA);
 
 % extract time of each frame
 indframebeg = find(A2==0);
 frame_times2 = A2(1:indframebeg-1);
 frame_index2 = A2(indframebeg:end-1);
 
 %% total
 frame_times_all =[frame_times  frame_times2]-first_frame_time;
 frame_index_all = [frame_index frame_index2+frame_index(end)];
  
 
 figure; plot(frame_index_all, frame_times_all/1000, 'ko');
 
 
 
 
 