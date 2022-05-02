clear
data_path_unit = {...
    'D:\Ephys\ANMs\Russo\Sessions\20210821\RTarrayAll.mat',     [1,2,3,5,6,7,9,10,11,13,15,17]...
    'D:\Ephys\ANMs\Russo\Sessions\r_all_20210906_20210910.mat', []...
    'D:\Ephys\ANMs\Eli\Sessions\r_all.mat',                     []...
    'D:\Ephys\ANMs\Urey\Sessions\r_all_20211123_20211128.mat',  []...
    };
t_pre_press = -1000;
t_post_press = 3500;

% t_pre_release = -500;
% t_post_release = 1000;
% 
% t_pre_reward = -1000;
% t_post_reward = 1000;

save_filename_pdf = './PSTHAll_v2.pdf';
save_filename_png = './PSTHAll_v2.png';
save_resolution = 1200;
%% Figure Configuration
margin_left = 1;
margin_right = 1.5;
margin_up = 0.5;
margin_bottom = 1;
space_col = 1;
space_row = 0.5;

line_width_press = 1;

width_PSTH = 15;
height_PSTH = 3;
width_colorbar = 0.5;
height_colorbar = 2*height_PSTH+space_row;

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_PSTH + width_colorbar;
figure_height = margin_up + margin_bottom + height_PSTH*2 + space_row;
h.Position = [15,15,figure_width,figure_height];

% PSTH press
ax_press_1 = axes(h,'Units','centimeters','NextPlot','add');
ax_press_1.Position = [margin_left,margin_bottom+space_row+height_PSTH,width_PSTH,height_PSTH];
ax_press_1.XAxis.Visible = 'off';
title(ax_press_1,'Sorted by Maximum Activity')
ylabel(ax_press_1,'Neurons')

ax_press_2 = axes(h,'Units','centimeters','NextPlot','add');
ax_press_2.Position = [margin_left,margin_bottom,width_PSTH,height_PSTH];
title(ax_press_2,'Sorted by Minimum Activity')
xlabel(ax_press_2,'Time from Press (ms)')
ylabel(ax_press_2,'Neurons')


%% Plotting
[average_spikes_long_all,average_spikes_short_all] = load_data(data_path_unit,t_pre_press,t_post_press,'press');
average_spikes_long_all = 1./(exp(-average_spikes_long_all)+1);
%% sort by max
[~,max_idx_long] = max(smoothdata(average_spikes_long_all,'gaussian',1));
[~,sort_idx_long] = sort(max_idx_long,'descend');
% [~,max_idx_short] = max(smoothdata(average_spikes_short_all,'gaussian',1));
% [~,sort_idx_short] = sort(max_idx_short);
average_spikes_long_all_sorted = average_spikes_long_all(:,sort_idx_long)';
% average_spikes_short_all_sorted = average_spikes_short_all(:,sort_idx_short)';
imagesc(ax_press_1,average_spikes_long_all_sorted,'xData',t_pre_press:t_post_press,'YData',1:size(average_spikes_long_all_sorted,1));
plot(ax_press_1,[0,0],[0.5,size(average_spikes_long_all_sorted,1)+0.5],'k-','LineWidth',line_width_press)
plot(ax_press_1,[1500,1500],[0.5,size(average_spikes_long_all_sorted,1)+0.5],'m-','LineWidth',line_width_press)
ylim(ax_press_1,[0.5,size(average_spikes_long_all_sorted,1)+0.5]);
xlim(ax_press_1,[t_pre_press,t_post_press]);
%% sort by min
[~,min_idx_long] = min(smoothdata(average_spikes_long_all,'gaussian',1));
[~,sort_idx_long] = sort(min_idx_long,'descend');
% [~,max_idx_short] = min(smoothdata(average_spikes_short_all,'gaussian',1));
% [~,sort_idx_short] = sort(max_idx_short);
average_spikes_long_all_sorted = average_spikes_long_all(:,sort_idx_long)';
% average_spikes_short_all_sorted = average_spikes_short_all(:,sort_idx_short)';
imagesc(ax_press_2,average_spikes_long_all_sorted,'xData',t_pre_press:t_post_press,'YData',1:size(average_spikes_long_all_sorted,1));
plot(ax_press_2,[0,0],[0.5,size(average_spikes_long_all_sorted,1)+0.5],'k-','LineWidth',line_width_press)
plot(ax_press_2,[1500,1500],[0.5,size(average_spikes_long_all_sorted,1)+0.5],'m-','LineWidth',line_width_press)
ylim(ax_press_2,[0.5,size(average_spikes_long_all_sorted,1)+0.5]);
xlim(ax_press_2,[t_pre_press,t_post_press]);

%% colorbar
colorbar('Units','centimeters','Position',[margin_left+width_PSTH+0.5,margin_bottom,width_colorbar,height_colorbar]);
h_annotation = annotation(h,'textarrow',...
    [0.5,0.5],...
    [0.5,0.5],...
    'String','Firing Rate (Z-scored)',...
    'HeadStyle', 'none',...
    'LineStyle', 'none',...
    'Units','centimeters',...
    'FontSize',8.25,...
    'color','k',...
    'TextRotation',270);
set(h_annotation,'X',[margin_left+width_PSTH+width_colorbar+1.2,margin_left+width_PSTH+width_colorbar+1.2],'Y',[2.75, 2.75])

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'A'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[-0.1,7.5,0.5,0.5]);

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'B'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[-0.1,4,0.5,0.5]);
%% Save Figure
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])
%%
function [average_spikes_long_all,average_spikes_short_all] = load_data(data_path_unit,t_pre,t_post,event)
average_spikes_long_all = [];
average_spikes_short_all = [];
for data_idx = 1:2:length(data_path_unit)
temp = load(data_path_unit{data_idx});
unit_of_interest = data_path_unit{data_idx+1};
if isfield(temp,'r')
    [average_spikes_long, average_spikes_short] = get_average_spikes(temp.r, unit_of_interest,t_pre,t_post,'gaussian_kernel',25,'event',event,'normalized','zscore');
    average_spikes_long_all = [average_spikes_long_all;average_spikes_long];
    average_spikes_short_all = [average_spikes_short_all;average_spikes_short];
elseif isfield(temp,'r_all')
    r_all = temp.r_all;
    trial_num = zeros(length(r_all.r),1);
    unit_of_interest_all = cell(length(r_all.r),1);
    for k = 1:length(r_all.r)
        trial_num(k) = length(r_all.r{k}.Behavior.CorrectIndex);
        unit_of_interest_all{k} = [];
    end
    if isempty(unit_of_interest)
        unit_of_interest = 1:height(r_all.UnitsCombined);
    end
    for k = unit_of_interest
        temp = r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1};
        [~,r_idx] = max(trial_num(temp(:,1)));
        unit_of_interest_all{temp(r_idx,1)} = [unit_of_interest_all{temp(r_idx,1)}; temp(r_idx,2:3)];
    end
    for k = 1:length(r_all.r)
        [average_spikes_long, average_spikes_short] = get_average_spikes(r_all.r{k}, unit_of_interest_all{k},t_pre,t_post,'gaussian_kernel',25,'event',event,'normalized','zscore');
        average_spikes_long_all = [average_spikes_long_all,average_spikes_long];
        average_spikes_short_all = [average_spikes_short_all,average_spikes_short];
    end    
else
    error('Wrong r');
end
end

% min-max normalizing
% average_spikes_long_all = (average_spikes_long_all-min(average_spikes_long_all))./(max(average_spikes_long_all)-min(average_spikes_long_all));
% average_spikes_short_all = (average_spikes_short_all-min(average_spikes_short_all))./(max(average_spikes_short_all)-min(average_spikes_short_all));
end