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

save_filename_pdf = './PrincipleAnalysis.pdf';
save_filename_png = './PrincipleAnalysis.png';
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

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_PC + space_col + width_traj;
figure_height = margin_up + margin_bottom + height_PC*num_PC + space_row*(num_PC-1);
h.Position = [10,10,figure_width,figure_height];


% ax_PC = zeros(num_PC,1);
% ax_PC = [];
for k = 1:num_PC
    ax_PC(k) = axes(h,'Units','centimeters','NextPlot','add',...
        'Position',[margin_left,margin_bottom+(space_row+height_PC)*(num_PC-k),width_PC,height_PC]);
%     ax_PC(k).Xaxis.Visible = 'off';
    ax_PC(k).XTick
    if k ~= num_PC
        ax_PC(k).XTick = [];
    else
        xlabel(ax_PC(k),'Time from Press (ms)');
    end
    ylabel(ax_PC(k),'Coefficient');
    title(ax_PC(k),['PC',num2str(k)]);
end

ax_traj = axes(h,'Units','centimeters','NextPlot','add',...
        'Position',[margin_left+width_PC+space_col,margin_bottom+0.5*(space_row*(num_PC-1)+height_PC*num_PC-height_traj),width_traj,height_traj]);
ax_traj.XTick = [];
ax_traj.YTick = [];
ax_traj.ZTick = [];
title(ax_traj,'Neural Trajectory');
xlabel(ax_traj,'PC1');
ylabel(ax_traj,'PC2');
zlabel(ax_traj,'PC3');
% Plotting
for k = 1:num_PC
    plot(ax_PC(k),t_pre:t_post,score(FP_long_index,k),'b-','lineWidth',3)
    hold on
    plot(ax_PC(k),t_pre:t_post,score(FP_short_index,k),'r-','lineWidth',3)
%     legend('FP=1500ms','FP=750ms')
    hold on
    xline(ax_PC(k),0,'k--','HandleVisibility','off')
    xline(ax_PC(k),1500,'b--','HandleVisibility','off')
    xline(ax_PC(k),750,'r--','HandleVisibility','off')
end

interval = 80;
plot3(ax_traj,score(1:t_len,1),score(1:t_len,2),score(1:t_len,3),'b-','lineWidth',1)
plot3(ax_traj,score(1:interval:t_len,1),score(1:interval:t_len,2),score(1:interval:t_len,3),'b.','MarkerSize',8)
plot3(ax_traj,score(1-t_pre,1),score(1-t_pre,2),score(1-t_pre,3),'b+','MarkerSize',10)

plot3(ax_traj,score(1501-t_pre,1),score(1501-t_pre,2),score(1501-t_pre,3),'bo','MarkerSize',10)
plot3(ax_traj,score(t_len+1:end-750,1),score(t_len+1:end-750,2),score(t_len+1:end-750,3),'r-','lineWidth',1)
plot3(ax_traj,score(t_len+1:interval:end-750,1),score(t_len+1:interval:end-750,2),score(t_len+1:interval:end-750,3),'r.','MarkerSize',8)

plot3(ax_traj,score(t_len+1-t_pre,1),score(t_len+1-t_pre,2),score(t_len+1-t_pre,3),'r+','MarkerSize',10)
plot3(ax_traj,score(t_len+751-t_pre,1),score(t_len+751-t_pre,2),score(t_len+751-t_pre,3),'ro','MarkerSize',10)

%%
% figure();
% for k = 1:4
%     subplot(2,2,k)
%     plot(t_pre:t_post,score(FP_long_index,k),'b-','lineWidth',3)
%     hold on
%     plot(t_pre:t_post,score(FP_short_index,k),'r-','lineWidth',3)
%     legend('FP=1500ms','FP=750ms')
%     hold on
%     xline(0,'k--','HandleVisibility','off')
%     xline(1500,'b--','HandleVisibility','off')
%     xline(750,'r--','HandleVisibility','off')
%     xlabel('time (ms)')
%     ylabel(['PC',num2str(k)])
% end
% saveas(gcf,'PC.png');
% 
% %%
% h_traj = figure('Units','centimeters','NextPlot','add');
% h_traj.Position = [10,10,6,6];
% interval = 80;
% axes1 = axes(h_traj);
% hold(axes1,'on');
% plot3(axes1,score(1:t_len,1),score(1:t_len,2),score(1:t_len,3),'b-','lineWidth',1)
% plot3(axes1,score(1:interval:t_len,1),score(1:interval:t_len,2),score(1:interval:t_len,3),'b.','MarkerSize',8)
% hold on
% plot3(axes1,score(1-t_pre,1),score(1-t_pre,2),score(1-t_pre,3),'b+','MarkerSize',10)
% plot3(axes1,score(1501-t_pre,1),score(1501-t_pre,2),score(1501-t_pre,3),'bo','MarkerSize',10)
% xlabel('PC1')
% ylabel('PC2')
% zlabel('PC3')
% 
% plot3(axes1,score(t_len+1:end-750,1),score(t_len+1:end-750,2),score(t_len+1:end-750,3),'r-','lineWidth',1)
% plot3(axes1,score(t_len+1:interval:end-750,1),score(t_len+1:interval:end-750,2),score(t_len+1:interval:end-750,3),'r.','MarkerSize',8)
% 
% plot3(axes1,score(t_len+1-t_pre,1),score(t_len+1-t_pre,2),score(t_len+1-t_pre,3),'r+','MarkerSize',10)
% plot3(axes1,score(t_len+751-t_pre,1),score(t_len+751-t_pre,2),score(t_len+751-t_pre,3),'ro','MarkerSize',10)
% 
% hold(axes1,'off');
% axes1.XAxis.Visible = 'off';
% axes1.YAxis.Visible = 'off';
% 
% % Create textbox
% annotation(h_traj,'textbox',...
%     [0.400656631701956 0.00200328315850978 0.200328315850978 0.100164157925489],...
%     'EdgeColor','none',...
%     'Units','centimeters',...
%     'VerticalAlignment','middle',...
%     'String',{'PC1'},...
%     'HorizontalAlignment','center',...
%     'FitBoxToText','off');
% 
% % Create textbox
% annotation(h_traj,'textbox',...
%     [0.0100164157925489 0.400656631701956 0.100164157925489 0.200328315850978],...
%     'EdgeColor','none',...
%     'Units','centimeters',...
%     'VerticalAlignment','middle',...
%     'String',{'PC2'},...
%     'HorizontalAlignment','center',...
%     'FitBoxToText','off');
% print(h_traj,'PC_traj.png','-dpng','-r1200')
%%
% figure(3);
% for k = 1:3
%     subplot(3,1,k)
%     histogram(coeff(:,k),'BinWidth',0.1)
%     xlim([-0.45,0.45]);
%     ylim([0,20]);
% end
% xlabel('Loadings')
% saveas(gcf,'Loadings.png');
%% Save Figure
% print(h,save_filename_bmp,'-dbmp',['-r',num2str(save_resolution)])
% print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
% print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])