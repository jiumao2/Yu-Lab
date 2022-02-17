function indout = matching_time(t1,t2)
%t2 = (t2-300)*0.987+300;
% t1=t1(10:end);
% figure;
% plot(t2,ones(length(t2),1),'x')
% hold on
% plot(t1,ones(length(t1),1),'.')
% 
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

indout = zeros(1,length(t1));
start = 10;
%tmp_react_time1 = react_time(start:end);

min_frame_rate = 0;
min_error = 1e8;
min_k = 0;
for frame_rate = 95:0.01:105
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

t1 = t1/(min_frame_rate/100);

for j = 1:length(t1)
    min_error = 1e8;
    min_k = 0;
    for k = 1:length(t2)-length(t1)+1
        tmp_t1 = t1;
        tmp_sum = 0;
        tmp_t1 = tmp_t1-tmp_t1(j)+t2(k);
        for i = 1:length(tmp_t1)
            tmp_sum = tmp_sum + min(abs(t2-tmp_t1(i)));
        end

        disp([num2str(k),': ',num2str(tmp_sum)])

        if tmp_sum < min_error
            min_error = tmp_sum;
            min_k = k;
            min_frame_rate = frame_rate;
        end
    end
    indout(j) = min_k;
end

for k = 1:length(t1)
    if sum(indout == indout(k))>1
        indout(k) = nan;
    end
end



    

end