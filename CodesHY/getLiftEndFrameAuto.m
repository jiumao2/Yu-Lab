function frame_num = getLiftStartFrameAuto(X,Y)
    % X: vector of length n; frame n is the frame of pressing. The x coordinate of the tracking of the left paw
    % Y: vector of length n
    thres1 = 200;
    bias = 1;
    movement_num = 4;
    
    frame_num = 1;

    [X_this, Y_this] = filter_traj(X,Y);
    s_all = zeros(1,length(X));
    for j = 1+movement_num:length(X)-movement_num
        s_all(j) = getMovement(X_this(j-movement_num:j+movement_num),Y_this(j-movement_num:j+movement_num));
    end

    flag = false;
    for j = length(X):-1:1
        if ~flag && s_all(j)>thres1
            frame_num = j+bias;
            break
        end
    end

    
    function s = getMovement(X,Y)
        s = sum((X-mean(X)).^2 + (Y-mean(Y)).^2,'all');
    end

    function [X_out,Y_out] = filter_traj(X,Y)
        for k = 2:length(X)-1
            p_mean = [X(k-1)*0.5+X(k+1)*0.5,Y(k-1)*0.5+Y(k+1)*0.5];
            if norm([X(k),Y(k)]-p_mean) >= norm(p_mean-[X(k-1),Y(k-1)])
                X(k) = p_mean(1);
                Y(k) = p_mean(2);
            end
        end
        X_out = X;
        Y_out = Y;
    end
end