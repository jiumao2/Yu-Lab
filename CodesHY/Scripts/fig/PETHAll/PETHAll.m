data_path_unit = {...
    'D:\Ephys\ANMs\Russo\Sessions\20210821\RTarrayAll.mat',     [1,2,3,5,6,7,9,10,11,13,15,17]...
    'D:\Ephys\ANMs\Russo\Sessions\r_all_20210906_20210910.mat', []...
    'D:\Ephys\ANMs\Eli\Sessions\r_all.mat',                     []...
    'D:\Ephys\ANMs\Urey\Sessions\r_all_20211123_20211128.mat',  []...
    };
t_pre = -1500;
t_post = 2400;
t_len = t_post-t_pre+1;
%%
average_spikes_long_all = [];
average_spikes_short_all = [];
for data_idx = 1:2:length(data_path_unit)
temp = load(data_path_unit{data_idx});
unit_of_interest = data_path_unit{data_idx+1};
if isfield(temp,'r')
    [average_spikes_long, average_spikes_short] = get_average_spikes(temp.r, unit_of_interest,t_pre,t_post,'gaussian_kernel',25);
    average_spikes_long_all = [average_spikes_long_all;average_spikes_short];
    average_spikes_short_all = [average_spikes_short_all;average_spikes_short];
elseif isfield(temp,'r_all')
    r_all = temp.r_all;
    trial_num = zeros(length(r_all.r),1);
    unit_of_interest_all = cell(length(r_all.r),1);
    for k = 1:length(r_all.r)
        trial_num(k) = length(r_all.r{k}.Behavior.CorrectIndex);
        unit_of_interest_all{k} = [];
    end
    for k = 1:height(r_all.UnitsCombined)
        temp = r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1};
        [~,r_idx] = max(trial_num(temp(:,1)));
        unit_of_interest_all{temp(r_idx,1)} = [unit_of_interest_all{temp(r_idx,1)}; temp(r_idx,2:3)];
    end
    for k = 1:length(r_all.r)
        [average_spikes_long, average_spikes_short] = get_average_spikes(r_all.r{k}, unit_of_interest_all{k},t_pre,t_post,'gaussian_kernel',25);
        average_spikes_long_all = [average_spikes_long_all,average_spikes_long];
        average_spikes_short_all = [average_spikes_short_all,average_spikes_short];
    end    
else
    error('Wrong r');
end
end
%% sort

% min-max normalizing
average_spikes_long_all = (average_spikes_long_all-min(average_spikes_long_all))./(max(average_spikes_long_all)-min(average_spikes_long_all));
average_spikes_short_all = (average_spikes_short_all-min(average_spikes_short_all))./(max(average_spikes_short_all)-min(average_spikes_short_all));

[~,max_idx_long] = max(smoothdata(average_spikes_long_all,'gaussian',1));
[~,sort_idx_long] = sort(max_idx_long);
average_spikes_long_all_sorted = average_spikes_long_all(:,sort_idx_long)';
average_spikes_short_all_sorted = average_spikes_short_all(:,sort_idx_long)';
%%
figure;
% for k = 1:53
%     average_spikes_short_all_sorted(k,:) = average_spikes_short_all_sorted(k,:) - min(average_spikes_short_all_sorted(k,:));
%     average_spikes_long_all_sorted(k,:) = average_spikes_long_all_sorted(k,:) - min(average_spikes_long_all_sorted(k,:));
%     
%     average_spikes_short_all_sorted(k,:) = average_spikes_short_all_sorted(k,:)/max(average_spikes_short_all_sorted(k,:));
%     average_spikes_long_all_sorted(k,:) = average_spikes_long_all_sorted(k,:)/max(average_spikes_long_all_sorted(k,:));
% end
% average_spikes_short_all_sorted(average_spikes_short_all_sorted>2)=2;
% average_spikes_long_all_sorted(average_spikes_long_all_sorted>2)=2;
imagesc(average_spikes_long_all_sorted,'xData',t_pre:t_post);
% average_spikes_long_all_sorted
colorbar;
% imagesc(average_spikes_short_all_sorted)
