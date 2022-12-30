clear;
load testData

thres1_all = 1000:500:3000;
thres2_all = 50:50:200;
bias_all = -2:2;
movement_num_all = 1:3;
continue_num_all = 0:2;

thres1_best = 0;
thres2_best = 0;
bias_best = 0;
movement_num_best = 0;
err_out = 1e8;
err_all = zeros(length(thres1_all),length(thres2_all),length(bias_all),length(movement_num_all));

for i_thres1 = 1:length(thres1_all)
    for i_thres2 = 1:length(thres2_all)
        for i_bias = 1:length(bias_all)
            for i_movement_num = 1:length(movement_num_all)
                for i_continue_num = 1:length(continue_num_all)
                    thres1 = thres1_all(i_thres1);
                    thres2 = thres2_all(i_thres2);
                    bias = bias_all(i_bias);
                    movement_num = movement_num_all(i_movement_num);
                    continue_num = continue_num_all(i_continue_num);

                    y_predict = zeros(1,length(y));

                    for k = 1:length(y)
                        X_this = X(:,1,k);
                        Y_this = X(:,2,k);
                        [X_this, Y_this] = filter_traj(X_this,Y_this);

                        s_all = zeros(1,210);
                        for j = 1+movement_num:210-movement_num
                            s_all(j) = getMovement(X_this(j-movement_num:j+movement_num),Y_this(j-movement_num:j+movement_num));
                        end

                        flag = false;
                        for j = 210:-1:1
                            if ~flag && s_all(j)>thres1
                                flag = true;
                            end

                            if flag && all(s_all(max(j-continue_num,1):j)<thres2)
                                y_predict(k) = j+bias;
                                break
                            end
                        end
                    end

                    err = sum((y_predict-y).^2,'all');
                    err_all(i_thres1,i_thres2,i_bias,i_movement_num,i_continue_num) = err;
%                     disp(err)
                    if err<err_out
                        err_out = err;
                        thres1_best = thres1;
                        thres2_best = thres2;
                        bias_best = bias;
                        movement_num_best = movement_num;
                        continue_num_best = continue_num;
                    end
                
                end
            end
        end
    end
    i_thres1
end


disp(['error_out: ',num2str(err_out)])
disp(['thres1_best: ',num2str(thres1_best)])
disp(['thres2_best: ',num2str(thres2_best)])
disp(['bias_best: ',num2str(bias_best)])
disp(['movement_num_best: ',num2str(movement_num_best)])
disp(['continue_num_best: ',num2str(continue_num_best)])

%%
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