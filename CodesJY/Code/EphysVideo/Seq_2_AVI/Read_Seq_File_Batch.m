clc;
clear all;
close all;

[ image_folder_path ] = uigetdir('Select Seq_Reader_Toolbox path...');
if(image_folder_path==0)
    return;
end
% Add Seq_Reader_Toolbox path.
addpath(genpath(image_folder_path)); savepath;

% % Read Seq path.
% [ seq_file_name,seq_file_path ] = uigetfile({'*.seq'},'Pick a video seq. file...');
% if(seq_file_path == 0)
%     return;
% end
% input_seq_file = [seq_file_path,seq_file_name];
input_path_parent = '\\10.204.220.37\DataSet\Caltech\Input\Testing_Sets\Convt_AVI\Input';
outPath_parent = '\\10.204.220.37\DataSet\Caltech\Input\Testing_Sets\Convt_AVI\Output';

input_folders = dir(input_path_parent);

for folder_cnt = 1:length(input_folders)
    if(strcmp(input_folders(folder_cnt).name,'.') || strcmp(input_folders(folder_cnt).name,'..'))
        continue;
    end
    
    input_path = fullfile(input_path_parent,input_folders(folder_cnt).name);
    outPath = fullfile(outPath_parent,input_folders(folder_cnt).name);
    mkdir(outPath);
    image_files = dir(fullfile(input_path,'*.seq'));
    
    
    
    % % Read output image path.
    % [video_file_name,video_file_path] = uigetdir('Select Destination Image Folder');
    % output_image_file = [video_file_path,video_file_name];
    
    for cnt = 1:length(image_files)
        
        input_seq_file = fullfile(input_path,image_files(cnt).name);
        
        % % Read output video path.
        % [video_file_name,video_file_path] = uiputfile([seq_file_name(1:end-4),'.avi'],'Save Video Name');
        % output_video_file = [video_file_path,video_file_name];
        
        output_video_file = fullfile(outPath,[image_files(cnt).name(1:end-4),'.avi']);
        
        
        videoFWriter = VideoWriter(output_video_file);
        videoFWriter.Quality = 100;
        open(videoFWriter);
        % Read User input
        prompt = 'Start Frame Number : ';
        %     start_frame = input(prompt);
        start_frame = [];
        
        prompt = 'End Frame Number : ';
        %     end_frame = input(prompt);
        end_frame = [];
        
        skip_frame = 1;
        
        % %% Save Images from seq video.
        % Is = seqIo( input_seq_file, 'toImgs', output_image_file, skip_frame, start_frame, end_frame, 'png' );
        
        
        %% Read Seq frame and write in video file
        % if(isempty(skip)), skip=1; end
        if(isempty(start_frame)), start_frame=0; end
        if(isempty(end_frame)), end_frame=inf; end
        
        sr = seqIo( input_seq_file, 'reader' );
        % sr=reader(input_seq_file);
        info=sr.getinfo();
        end_frame=min(end_frame,info.numFrames-1);
        frames=start_frame:skip_frame:end_frame;
        
        for frame=frames
            disp(frame);
            sr.seek(frame);
            I=sr.getframe();
            writeVideo(videoFWriter, I);
            clear I;
        end;
        sr.close();
        close(videoFWriter);
 
    end
end

% Remove Seq_Reader_Toolbox path.
rmpath(genpath(image_folder_path));savepath;

disp('COMPLETE... (-_-)');