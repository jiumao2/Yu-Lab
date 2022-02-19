ind_left_ear = find(strcmp(r.VideoInfos(1).Tracking.BodyParts,'left_ear'));
ind_right_ear = find(strcmp(r.VideoInfos(1).Tracking.BodyParts,'right_ear'));
ind_head = find(strcmp(r.VideoInfos(1).Tracking.BodyParts,'head_center'));
ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
bg = ReadJpegSEQ2('20211124-17-37-43.000.seq',1);
colors = varycolor(r.VideoInfos(1).total_frames);
index_cat1 = find(cat==1 | cat==2);
figure;
imshow(bg)
hold on
for k = 1:length(index_cat1)
    for i = 1:r.VideoInfos(1).total_frames
        plot(r.VideoInfos(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_right_ear}(i),...
            r.VideoInfos(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_right_ear}(i),...
            '.','Color',colors(i,:))
    end
end