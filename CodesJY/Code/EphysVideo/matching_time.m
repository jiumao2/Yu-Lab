function indout = matching_time(t1,t2)
% 方法1： 
% m = length(t1);
% n = length(t2);
% indout = zeros(1,m);
% t = 0:0.1:2500;
% 
% for k = 1:1
%     
% 
%     for j = 1:n-m+1
%         t1_bin = zeros(length(t),1);
%         t2_bin = zeros(length(t),1);
%         t_corr = zeros(n-m+1,1);    
%           
%         t1_tmp = t1-t1(1)+1e-8;
%         t1_tmp(end);
%         t2_tmp = t2(j:j+m-1)-t2(j)+1e-8;
%         t2_tmp(end);
%         for i = 1:m
%             idx1 = ceil(t1_tmp(i)*0.1);
%             t1_bin(idx1) = t1_bin(idx1) + 1;
%             idx2 = ceil(t2_tmp(i)*0.1);
%             t2_bin(idx2) = t2_bin(idx2) + 1;
%         end
%         tcorr(j) = t1_bin'*t2_bin;
%     end
% end
% figure
% plot(1:n-m+1,tcorr)

% 方法2：
tic
indout = zeros(1,length(t1));
start = 10;

min_frame_rate = 0;
min_error = 1e8;
min_k = 0;
for frame_rate = 95:0.01:105 % 得到相机真实平均每秒帧数
    for k = 1:length(t2)-length(t1)+1
        tmp_t1 = t1(start:end)/(frame_rate/100);
        tmp_sum = 0;
        tmp_t1 = tmp_t1-tmp_t1(1)+t2(k);
        for j = 1:length(tmp_t1)
            tmp_sum = tmp_sum + min(abs(t2-tmp_t1(j)));
        end

        % disp([num2str(k),': ',num2str(tmp_sum)])

        if tmp_sum < min_error
            min_error = tmp_sum;
            min_k = k;
            min_frame_rate = frame_rate;
        end
    end
end

t1 = t1/(min_frame_rate/100); % 使用真实每秒帧数更正t1

% 为每个t1中的点寻找t2中匹配点
for j = 1:length(t1)
    min_error = 1e8;
    min_k = 0;
    for k = 1:length(t2)-length(t1)+1
        tmp_t1 = t1;
        tmp_sum = 0;
        tmp_t1 = tmp_t1-tmp_t1(j)+t2(k);
        for i = 1:length(tmp_t1)
            tmp_sum = tmp_sum + min(abs(t2-tmp_t1(i))); % t2中与t1距离最小的点，加上该距离
        end

        %disp([num2str(k),': ',num2str(tmp_sum)])

        if tmp_sum < min_error 
            min_error = tmp_sum;
            min_k = k;
            min_frame_rate = frame_rate;
        end
    end
    indout(j) = min_k;
end
toc
% 若出现相同的index则设为nan
% for k = 1:length(t1)
%     if sum(indout == indout(k))>1
%         indout(indout == indout(k)) = nan;
%     end
% end



    

end