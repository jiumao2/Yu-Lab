function [mean_traj, traj_all_resized, firing_rate_all_resized] = getMeanTrajectory(traj_all, num_points, firing_rate_all)
    if nargin <= 2
        firing_rate_all = [];
    end
    traj_all_resized = zeros(2,num_points,length(traj_all));
    firing_rate_all_resized = zeros(num_points,length(traj_all));
    for k = 1:length(traj_all)
        t_new = linspace(1,length(traj_all{k}),num_points);
        x_new = interp1(1:length(traj_all{k}),traj_all{k}(1,:),t_new);
        if ~isempty(firing_rate_all)
            firing_rate_all_resized(:,k) = interp1(1:length(firing_rate_all{k}),firing_rate_all{k},t_new);
        end
        % to remove possible same sample points
        [x_this,idx_x_this,~] = unique(traj_all{k}(1,:));
        y_this = traj_all{k}(2,idx_x_this);

        y_new = interp1(x_this,y_this,x_new);
        traj_all_resized(:,:,k) = [x_new;y_new];
    end
    mean_traj = mean(traj_all_resized,3);
end