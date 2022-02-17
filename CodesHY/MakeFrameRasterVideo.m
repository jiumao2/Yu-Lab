function MakeFrameRasterVideo(img_seq,spiketime_seq,t_seq,moviename,notes)
%UNTITLED2 Summary of this function goes here
%   img_seq: 1 x frame_num cell with each frame inside
%   spiketime_seq: 1 x unit_num cell with each spiketime inside
%   t_seq: 1 x frame_num vector. Time in ms

% Frame parameters
frame_num = length(img_seq);
frame_height = size(img_seq{1},1);
frame_width = size(img_seq{1},2);

% Raster parameters
unit_num = length(spiketime_seq);
colors = uint8(varycolor(unit_num+1)*255);
spike_height = 10;
spike_width = 1;
line_width = 1;
line_color = uint8([0,0,0]);
raster_space_top = 5;
raster_space_bottom = 5;
raster_space_left = 5;
raster_space_right = 5;
raster_height = spike_height*unit_num+raster_space_top+raster_space_bottom;
raster_width = frame_width;

% Notation parameters
note_height = 100;
note_width = frame_width;
text_pos = [5,5];
text_pos_notes = [5,55];
text_size = 24;
text_color = 'yellow';

t_start = t_seq(1);
t_end = t_seq(end);

% raster_block template
blk_raster_template = uint8(255*ones(raster_height,raster_width,3));
p = raster_space_top+1;
for k = 1:unit_num
    temp = spiketime_seq{k};
    if ~isempty(temp)
        temp = round((temp-t_start)/(t_end-t_start)*(raster_width-raster_space_left-raster_space_right)+raster_space_left);
        for spk = 1:length(temp)
            for y = round(temp(spk)-(spike_width-1)/2):round(temp(spk)+(spike_width-1)/2)
                for x = p:p+spike_height-1
                    blk_raster_template(x,y,:) = colors(k,:);
                end
            end
        end
    end
    p = p+spike_height;
end
        
% write video
writerObj = VideoWriter(moviename);
writerObj.FrameRate = 20;
open(writerObj);
for i_Frame=1:length(img_seq)
    % Notation block
    blk_note = uint8(zeros(note_height,note_width,3));
    blk_note = insertText(blk_note,text_pos,['Time: ',num2str(round(t_seq(i_Frame))),'ms'],...
        'FontSize',text_size,'TextColor',text_color,'BoxOpacity', 0);
    blk_note = insertText(blk_note,text_pos_notes,notes,...
        'FontSize',text_size,'TextColor',text_color,'BoxOpacity', 0);
    
    % Frame block
    blk_frame = img_seq{i_Frame};
    
    % Raster block
    blk_raster = blk_raster_template;
    line_pos = round(i_Frame/length(img_seq)*(raster_width-raster_space_left-raster_space_right)+raster_space_left);
    for y = round(line_pos-(line_width-1)/2):round(line_pos+(line_width-1)/2)
        for x = 1:size(blk_raster,1)
            blk_raster(x,y,:) = line_color;
        end
    end
    
    % Combining
    frame = [blk_note;blk_frame;blk_raster];
    
    writeVideo(writerObj, frame);
end
close(writerObj);


end

