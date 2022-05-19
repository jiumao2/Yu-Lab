clear;
% data_path_unit = {...
%     'D:\Ephys\ANMs\Russo\Sessions\20210821\RTarrayAll.mat',     [1,2,3,5,6,9,10,11,13,17]...
%     'D:\Ephys\ANMs\Russo\Sessions\r_all_20210906_20210910.mat', [1,2,3,6,7,8,9,10,11,12,13]...
%     'D:\Ephys\ANMs\Eli\Sessions\r_all.mat',                     [1,2,3,4,5,6,9,10,11,12,13]...
%     'D:\Ephys\ANMs\Urey\Sessions\r_all_20211123_20211128.mat',  [1,2,3,4,6,7,9,10,11]...
%     };
data_path_unit = {...
    'D:\Ephys\ANMs\Russo\Sessions\20210821\RTarrayAll.mat',     [1,2,3,5,6,7,9,10,11,13,15,17]...
    'D:\Ephys\ANMs\Russo\Sessions\r_all_20210906_20210910.mat', []...
    'D:\Ephys\ANMs\Eli\Sessions\r_all.mat',                     []...
    'D:\Ephys\ANMs\Urey\Sessions\r_all_20211123_20211128.mat',  []...
    };
t_pre = -1000;
t_post = 2000;
t_len = t_post-t_pre+1;

save_filename_pdf = './PrincipleAnalysis_v2.pdf';
save_filename_png = './PrincipleAnalysis_v2.png';
save_resolution = 1200;
%%
average_spikes_long_all = [];
average_spikes_short_all = [];
for data_idx = 1:2:length(data_path_unit)
temp = load(data_path_unit{data_idx});
unit_of_interest = data_path_unit{data_idx+1};
if isfield(temp,'r')
    [average_spikes_long, average_spikes_short] = get_average_spikes(temp.r, unit_of_interest,t_pre,t_post,'normalized','zscore');
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
    if isempty(unit_of_interest)
        unit_of_interest = 1:height(r_all.UnitsCombined);
    end
    for k = unit_of_interest
        temp = r_all.UnitsCombined(k,:).rIndex_RawChannel_Number{1};
        [~,r_idx] = max(trial_num(temp(:,1)));
        unit_of_interest_all{temp(r_idx,1)} = [unit_of_interest_all{temp(r_idx,1)}; temp(r_idx,2:3)];
    end
    for k = 1:length(r_all.r)
        [average_spikes_long, average_spikes_short] = get_average_spikes(r_all.r{k}, unit_of_interest_all{k},t_pre,t_post,'normalized','zscore');
        average_spikes_long_all = [average_spikes_long_all,average_spikes_long];
        average_spikes_short_all = [average_spikes_short_all,average_spikes_short];
    end    
else
    error('Wrong r');
end
end
%%
% min-max normalizing
% average_spikes_long_all = (average_spikes_long_all-min(average_spikes_long_all))./(max(average_spikes_long_all)-min(average_spikes_long_all));
% average_spikes_short_all = (average_spikes_short_all-min(average_spikes_short_all))./(max(average_spikes_short_all)-min(average_spikes_short_all));
% average_spikes_long_all = average_spikes_long_all./max(average_spikes_long_all);
% average_spikes_short_all = average_spikes_short_all./max(average_spikes_short_all);

data_all = [average_spikes_long_all;average_spikes_short_all];
[coeff, score, ~, ~, explained] = pca(data_all);

% h_explained = figure;
% bar(h_explained,explained,'b')
% title('explained')
% saveas(h_explained,'explained.png')

FP_long_index = 1:t_len;
FP_short_index = t_len+1:2*t_len;

%% Figure Configuration
num_PC = 2;

margin_left = 1;
margin_right = 0.5;
margin_up = 0.5;
margin_bottom = 1;
space_row = 0.7;
space_col = 1;

width_PC = 4;
height_PC = 4;
width_traj = 6;
height_traj = 6;
width_loading = 4;
height_loading = 4;

h = figure('Units','centimeters','Renderer','opengl');
figure_width = margin_left + margin_right + width_PC + space_col*2 + width_traj + width_loading;
figure_height = margin_up + margin_bottom + height_PC*num_PC + space_row*(num_PC-1);
h.Position = [10,10,figure_width,figure_height];

line_width_PC = 2;
line_width_traj = 2;



% ax_PC = zeros(num_PC,1);
% ax_PC = [];
for k = 1:num_PC
    ax_PC(k) = axes(h,'Units','centimeters','NextPlot','add',...
        'Position',[margin_left,margin_bottom+(space_row+height_PC)*(num_PC-k),width_PC,height_PC]);
    if k ~= num_PC
        ax_PC(k).XTick = [];
    else
        xlabel(ax_PC(k),'Time from press (ms)');
    end
    ylabel(ax_PC(k),'Coefficient');
    title(ax_PC(k),['PC',num2str(k)],'Position',[-700,8-(k-1)*3.6],'FontSize',10);
end

for k = 1:num_PC
    ax_loading(k) = axes(h,'Units','centimeters','NextPlot','add',...
        'Position',[margin_left+space_col+width_PC,margin_bottom+(space_row+height_PC)*(num_PC-k),width_loading,height_loading]);
%     ax_PC(k).Xaxis.Visible = 'off';
    if k ~= num_PC
        ax_loading(k).XTick = [];
    end
    xlabel(ax_loading(k),['Loading on PC',num2str(k)]);
    ylabel(ax_loading(k),'Neurons');
end

ax_traj = axes(h,'Units','centimeters','NextPlot','add',...
        'Position',[margin_left+width_PC+space_col*2+width_loading,margin_bottom,width_traj,height_traj]);
%         'Position',[margin_left+width_PC+space_col*2+width_loading,margin_bottom+0.5*(space_row*(num_PC-1)+height_PC*num_PC-height_traj),width_traj,height_traj]);

ax_traj.XTick = [];
ax_traj.YTick = [];
ax_traj.ZTick = [];
title(ax_traj,'Neural trajectory','FontSize',10);
xlabel(ax_traj,'PC1');
ylabel(ax_traj,'PC2');
zlabel(ax_traj,'PC3');

% Plotting
for k = 1:num_PC
    plot(ax_PC(k),t_pre:t_post,score(FP_long_index,k),'b-','lineWidth',line_width_PC)
    hold on
    plot(ax_PC(k),t_pre:t_post,score(FP_short_index,k),'r-','lineWidth',line_width_PC)
%     legend('FP=1500ms','FP=750ms')
    hold on
    xline(ax_PC(k),0,'k--','HandleVisibility','off')
    xline(ax_PC(k),1500,'b--','HandleVisibility','off')
    xline(ax_PC(k),750,'r--','HandleVisibility','off')
end

for k = 1:num_PC
    histogram(ax_loading(k),coeff(:,k),'BinWidth',0.1);
    xlim(ax_loading(k),[-0.45,0.45]);
    ylim(ax_loading(k),[0,20]);
end

interval = 80;
plot3(ax_traj,score(1:t_len,1),score(1:t_len,2),score(1:t_len,3),'b-','lineWidth',line_width_traj)
plot3(ax_traj,score(1:interval:t_len,1),score(1:interval:t_len,2),score(1:interval:t_len,3),'b.','MarkerSize',10)

plot3(ax_traj,score(1-t_pre,1),score(1-t_pre,2),score(1-t_pre,3),'bx','MarkerSize',15,'LineWidth',2)
plot3(ax_traj,score(1501-t_pre,1),score(1501-t_pre,2),score(1501-t_pre,3),'b+','MarkerSize',15,'LineWidth',2)

plot3(ax_traj,score(t_len+1:end-750,1),score(t_len+1:end-750,2),score(t_len+1:end-750,3),'r-','lineWidth',line_width_traj)
plot3(ax_traj,score(t_len+1:interval:end-750,1),score(t_len+1:interval:end-750,2),score(t_len+1:interval:end-750,3),'r.','MarkerSize',10)

plot3(ax_traj,score(t_len+1-t_pre,1),score(t_len+1-t_pre,2),score(t_len+1-t_pre,3),'rx','MarkerSize',15,'LineWidth',2)
plot3(ax_traj,score(t_len+751-t_pre,1),score(t_len+751-t_pre,2),score(t_len+751-t_pre,3),'r+','MarkerSize',15,'LineWidth',2)
xlim(ax_traj,[-7,9]);
ylim(ax_traj,[-8,7]);

%%
space_annotation = 0.5;
h_annotation_fp1 = annotation(h,'line',[0.5,1],[0.5,1],'units','centimeters','linewidth',3,'Color','red');
set(h_annotation_fp1,'X',[11,11.5],'Y',[9.5,9.5]);

h_annotation_fp2 = annotation(h,'line',[0.5,0.5],[0.5,0.5],'units','centimeters','linewidth',3,'Color','blue');
set(h_annotation_fp2,'X',[11,11.5],'Y',[9.5-space_annotation,9.5-space_annotation]);

h_annotation_fp1_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'FP = 750 ms'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_fp1_text,'Position',[11.5,8.97,3,1]);

h_annotation_fp2_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'FP = 1500 ms'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_fp2_text,'Position',[11.5,8.97-space_annotation,3,1]);

h_annotation_A = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'A'},...
    'FontWeight','bold',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_A,'Position',[0,9.5,0.5,0.5]);
h_annotation_B = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'B'},...
    'FontWeight','bold',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_B,'Position',[5,9.5,0.5,0.5]);
h_annotation_C = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'C'},...
    'FontWeight','bold',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_C,'Position',[10.4,7,0.5,0.5]);
% Create textbox
annotation(h,'textbox',...
    [0.76953252647504 0.483116883116884 0.0534629349470499 0.0727272727272727],...
    'Units','centimeters',...
    'String','Press',...
    'FontWeight','bold',...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create textbox
annotation(h,'textbox',...
    [0.636400907715583 0.207792207792208 0.0534629349470498 0.0727272727272728],...
    'Units','centimeters',...
    'String','Trigger',...
    'FontWeight','bold',...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create arrow
annotation(h,'arrow',[0.804841149773073 0.815431164901664],...
    [0.53925974025974 0.633766233766234],'Units','centimeters','LineWidth',1,...
    'HeadWidth',8,...
    'HeadLength',6);

% Create arrow
annotation(h,'arrow',[0.804841149773072 0.800302571860817],...
    [0.53925974025974 0.625974025974026],'Units','centimeters','LineWidth',1,...
    'HeadWidth',8,...
    'HeadLength',6);

% Create arrow
annotation(h,'arrow',[0.680786686838124 0.67624810892587],...
    [0.266532467532468 0.4],'Units','centimeters','LineWidth',1,'HeadWidth',8,...
    'HeadLength',6);

% Create arrow
annotation(h,'arrow',[0.680786686838125 0.714069591527988],...
    [0.266532467532468 0.301298701298701],'Units','centimeters','LineWidth',1,...
    'HeadWidth',8,...
    'HeadLength',6);
%% Save Figure
% print(h,save_filename_bmp,'-dbmp',['-r',num2str(save_resolution)])
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])