function drawTrajAll(r_path, num, bg_path, bodypart)
if nargin <= 3
    bodypart = 'right_ear';
end
figure;
bg = imread(bg_path);
imshow(bg)
for path_id = 1:length(r_path)
load(['TrackingAnalysis/',r_path{path_id}])
ind_bodypart = find(strcmp(r.VideoInfos(1).Tracking.BodyParts, bodypart));
ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));

colors = colororder;
cat = [r.VideoInfos.Trajectory];
index_cat1 = find(cat==num);

hold on
for k = 1:length(index_cat1)
        x = r.VideoInfos(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart}(r.VideoInfos(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart}>0.99);
        y = r.VideoInfos(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart}(r.VideoInfos(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart}>0.99);
        x = x(1:5:end);
        y = y(1:5:end);
        X = x(1:end-1);
        Y = y(1:end-1);
        x_diff = diff(x);
        y_diff = diff(y);
        quiver(X,Y,x_diff,y_diff,0);
end
end

saveas(gcf,['Fig/Traj',num2str(num),'.png']);
% end