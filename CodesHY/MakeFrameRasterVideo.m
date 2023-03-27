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
spike_height = 20;
spike_width = 3;
line_width = 1;
line_color = uint8([0,0,0]);
raster_space_top = 5;
raster_space_bottom = 5;
raster_space_left = 5;
raster_space_right = 5;
raster_height = spike_height*unit_num+raster_space_top+raster_space_bottom;
raster_width = frame_width;

% Notation parameters
space_note = 50;
note_height = 50 + length(notes)*space_note;
note_width = frame_width;
text_pos = [5,5];
text_size = 24;
text_color = 'yellow';

t_start = t_seq(1);
t_end = t_seq(end);

% raster_block template
blk_raster_template = uint8(255*ones(raster_height,raster_width,3));
p = raster_space_top+1;
for k = 1:unit_num
    temp = spiketime_seq{k};
    temp = temp(temp>t_start & temp<t_end);
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

% x tick block template
xtick_height = 50;
xtick_line_space_top = 10;
xtick_width = raster_width;
xtick_color = [255,255,255];
xtick_line_width = 1;
tick_height = 5;
xtick_fontsize = 18;
xtick_interval = getOptimalInterval((t_end-t_start)/10); % ms
xtick_space_left = raster_space_left;
xtick_space_right = raster_space_right;

font_space_top = 1;
font_space_left = 5;
font_space_per_num = 6;

t_now = 0;

blk_xtick_template = uint8(zeros(xtick_height,xtick_width,3));
for x = xtick_space_left:xtick_width-xtick_space_right
    for y = xtick_line_space_top-round((xtick_line_width-1)/2):xtick_line_space_top+round((xtick_line_width-1)/2)
        blk_xtick_template(y,x,:) = xtick_color;
    end
end
ticks = ceil((t_start-t_now)/xtick_interval)*xtick_interval:xtick_interval:floor((t_end-t_now)/xtick_interval)*xtick_interval;
for i_tick = 1:length(ticks)
    x_this = round((ticks(i_tick)+t_now-t_start)/(t_end-t_start)*(xtick_width-xtick_space_left-xtick_space_right)+raster_space_left);
    for y = xtick_line_space_top-tick_height:xtick_line_space_top
        blk_xtick_template(y,x_this,:) = xtick_color;
    end
    blk_xtick_template = insertText(blk_xtick_template,[x_this-font_space_left-font_space_per_num*length(num2str(ticks(i_tick))),xtick_line_space_top+font_space_top],num2str(ticks(i_tick)),'FontSize',xtick_fontsize,'TextColor','white','BoxOpacity', 0);                   
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
    for k = 1:length(notes)
        blk_note = insertText(blk_note,text_pos + [0,space_note]*k,notes{k},...
            'FontSize',text_size,'TextColor',text_color,'BoxOpacity', 0);
    end
    
    % Frame block
    blk_frame = img_seq{i_Frame};
    
    % xtick block
    blk_xtick = blk_xtick_template;   
    
    % Raster block
    blk_raster = blk_raster_template;
    blk_raster = [blk_raster;blk_xtick];
    
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

