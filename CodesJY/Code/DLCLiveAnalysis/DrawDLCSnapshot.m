clear all;
close all;

VideoNames=[
%     {'pineapple2021-06-10T16_47_42.avi'}
%     {'pineapple2021-06-11T15_27_54.avi'}
%     {'pineapple2021-06-13T14_50_05.avi'}
%     {'pineapple2021-06-14T18_42_43.avi'}
%     {'pineapple2021-06-15T20_46_22.avi'}
%     {'pineapple2021-06-16T19_40_18.avi'}
%     {'pineapple2021-06-17T14_56_45.avi'}
%     {'pineapple2021-06-18T16_04_48.avi'}
%     {'pineapple2021-06-20T14_35_30.avi'}
    {'pineapple2021-06-21T18_26_53.avi'}
    {'pineapple2021-06-22T16_42_47.avi'}
    {'pineapple2021-06-23T15_31_35.avi'}
    {'pineapple2021-06-24T16_11_01.avi'}
    {'pineapple2021-06-25T17_57_30.avi'}
    {'pineapple2021-06-27T14_30_27.avi'}
    
    ];

BpodSessionNames=[
%     {'Pineapple_MedOptoRecordingFRIAppDLC_20210610_164638.mat'     }
%     {'Pineapple_MedOptoRecordingFRIAppDLC_20210611_152703.mat'     }
%     {'Pineapple_MedOptoRecordingFRIAppDLC_20210613_144918.mat'     }
%     {'Pineapple_MedOptoRecordingFRIAppDLC_20210614_184152.mat'     }
%     {'Pineapple_MedOptoRecMix_20210615_204526.mat'                 }
%     {'Pineapple_MedOptoRecMix_20210616_193924.mat'                 }
%     {'Pineapple_MedOptoRecMix_20210617_145558.mat'                 }
%     {'Pineapple_MedOptoRecMix_20210618_160358.mat'                 }
%     {'Pineapple_MedOptoRecMix_20210620_143415.mat'                 }
    {'Pineapple_MedOptoRecMix_20210621_182552.mat'                 }
    {'Pineapple_MedOptoRecMix_20210622_164135.mat'                 }
    {'Pineapple_MedOptoRecMix_20210623_153045.mat'                 }
    {'Pineapple_MedOptoRecMix_20210624_161000.mat'                 }
    {'Pineapple_MedOptoRecMix_20210625_175630.mat'                 }
    {'Pineapple_MedOptoRecMix_20210627_142921.mat'                 }
    ];

VideoFrameNames=[
%     {'pineapple2021-06-10T16_47_42.txt'}
%     {'pineapple2021-06-11T15_27_54.txt'}
%     {'pineapple2021-06-13T14_50_05.txt'}
%     {'pineapple2021-06-14T18_42_43.txt'}
%     {'pineapple2021-06-15T20_46_22.txt'}
%     {'pineapple2021-06-16T19_40_18.txt'}
%     {'pineapple2021-06-17T14_56_45.txt'}
%     {'pineapple2021-06-18T16_04_48.txt'}
%     {'pineapple2021-06-20T14_35_30.txt'}
    {'pineapple2021-06-21T18_26_53.txt'}
    {'pineapple2021-06-22T16_42_47.txt'}
    {'pineapple2021-06-23T15_31_35.txt'}
    {'pineapple2021-06-24T16_11_01.txt'}
    {'pineapple2021-06-25T17_57_30.txt'}
    {'pineapple2021-06-27T14_30_27.txt'}
    ];

StimNames=[
%     {'pineapplestilm2021-06-10T16_47_49.txt'}
%     {'pineapplestilm2021-06-11T15_28_02.txt'}
%     {'pineapplestilm2021-06-13T14_50_08.txt'}
%     {'pineapplestilm2021-06-14T18_43_00.txt'}
%     {'pineapplestilm2021-06-15T20_46_36.txt'}
%     {'pineapplestilm2021-06-16T19_40_27.txt'}
%     {'pineapplestilm2021-06-17T14_57_13.txt'}
%     {'pineapplestilm2021-06-18T16_04_51.txt'}
%     {'pineapplestilm2021-06-20T14_35_33.txt'}
    {'pineapplestilm2021-06-21T18_27_50.txt'}
    {'pineapplestilm2021-06-22T16_42_50.txt'}
    {'pineapplestilm2021-06-23T15_31_37.txt'}
    {'pineapplestilm2021-06-24T16_11_01.txt'}
    {'pineapplestilm2021-06-25T17_57_39.txt'}
    {'pineapplestilm2021-06-27T14_30_30.txt'}
    ];

PositionNames=[
%     {'pineapple_position2021-06-10T16_47_42.txt'}
%     {'pineapple_position2021-06-11T15_27_54.txt'}
%     {'pineapple_position2021-06-13T14_50_05.txt'}
%     {'pineapple_position2021-06-14T18_42_43.txt'}
%     {'pineapple_position2021-06-15T20_46_22.txt'}
%     {'pineapple_position2021-06-16T19_40_18.txt'}
%     {'pineapple_position2021-06-17T14_56_45.txt'}
%     {'pineapple_position2021-06-18T16_04_48.txt'}
%     {'pineapple_position2021-06-20T14_35_30.txt'}
    {'pineapple_position2021-06-21T18_26_53.txt'}
    {'pineapple_position2021-06-22T16_42_47.txt'}
    {'pineapple_position2021-06-23T15_31_35.txt'}
    {'pineapple_position2021-06-24T16_11_01.txt'}
    {'pineapple_position2021-06-25T17_57_30.txt'}
    {'pineapple_position2021-06-27T14_30_27.txt'}
    ];

SessionNames=[
%     {'2021-06-10_16h43m_Subject Pineapple.txt'}
%     {'2021-06-11_15h23m_Subject Pineapple.txt'}
%     {'2021-06-13_14h45m_Subject Pineapple.txt'}
%     {'2021-06-14_18h38m_Subject Pineapple.txt'}
    {'2021-06-15_20h42m_Subject Pineapple.txt'}
    {'2021-06-16_19h36m_Subject Pineapple.txt'}
    {'2021-06-17_14h52m_Subject Pineapple.txt'}
    {'2021-06-18_16h00m_Subject Pineapple.txt'}
    {'2021-06-20_14h31m_Subject Pineapple.txt'}
    {'2021-06-21_18h22m_Subject Pineapple.txt'}
    {'2021-06-22_16h38m_Subject Pineapple.txt'}
    {'2021-06-23_15h27m_Subject Pineapple.txt'}
    {'2021-06-24_16h06m_Subject Pineapple.txt'}
    {'2021-06-25_17h53m_Subject Pineapple.txt'}
    {'2021-06-27_14h26m_Subject Pineapple.txt'}
];

FPs = [
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
    750 1500
   
    ];

x_position_sum=[];
y_position_sum=[];

for i = 1:length(VideoNames)
    load(BpodSessionNames{i});
    vf = importdata(VideoFrameNames{i}); 
    sf = importdata(StimNames{i});
    pf = importdata(PositionNames{i});
    sd = SessionData;
    
    % bpod to bonsai time difference
    j=1;
    while ~isfield(sd.RawEvents.Trial{j}.Events,'SoftCode6')
        j = j+1;
    end
    BpodStartTime = str2num(sd.Info.SessionStartTime_UTC(1:2))*3600000+str2num(sd.Info.SessionStartTime_UTC(4:5))*60000+str2num(sd.Info.SessionStartTime_UTC(7:8))*1000;
    FirstStimTime = str2num(sf{1}(12:13))*3600000+ str2num(sf{1}(15:16))*60000+str2num(sf{1}(18:19))*1000+str2num(sf{1}(22:end-1));
    Bpod2BonsaiTime = BpodStartTime+sd.TrialStartTimestamp(j)*1000+sd.RawEvents.Trial{j}.Events.SoftCode6(1)*1000-FirstStimTime;
    BpodStartTime2 = BpodStartTime - Bpod2BonsaiTime;
    StimFrameTime = cellfun(@(x)str2num(x(12:13))*3600000+ str2num(x(15:16))*60000+str2num(x(18:19))*1000+str2num(x(22:end-1)),sf,'Uniformoutput',false);
    StimFrameTime = cell2mat(StimFrameTime);
    
    
    SoftCode6 = [];
    TriggerBpodNum = [1];
    SoftCode6Num = [];
    BpodIndex = [];
    for k = 1:length(sd.RawEvents.Trial)
        if isfield(sd.RawEvents.Trial{k}.Events,'SoftCode6')
            TriggerBpodNum = [TriggerBpodNum TriggerBpodNum(end)+length(sd.RawEvents.Trial{k}.Events.SoftCode6)];
            SoftCode6Num = [SoftCode6Num length(sd.RawEvents.Trial{k}.Events.SoftCode6)];
            BpodIndex = [BpodIndex k];
            for l = 1:length(sd.RawEvents.Trial{k}.Events.SoftCode6)
                SoftCode6 = [SoftCode6 sd.RawEvents.Trial{k}.Events.SoftCode6(l)*1000+sd.TrialStartTimestamp(k)*1000+BpodStartTime2];
            end
        end
    end
    TriggerBpodNum(end) = [];
    
    Bpod_to_Bonsai = [];
    SoftCode6_2=SoftCode6 -SoftCode6(1);
    SoftCode6_2Org = SoftCode6_2;
    dt_record = [];
    StimFrameTime2 = StimFrameTime - StimFrameTime(1);
    StimFrameTime2Org = StimFrameTime2;
    TriggerFrameTime=[];
    for m = 1: length(SoftCode6)
        [dmin,ind_dmin] = min(abs(StimFrameTime2-SoftCode6_2(m)));
        if dmin < 500
            Bpod_to_Bonsai(m) = ind_dmin;
            dt_record = [dt_record dmin];
            StimFrameTime2 = StimFrameTime2 - StimFrameTime2(ind_dmin);
            SoftCode6_2=SoftCode6_2 -SoftCode6_2(m);
        end
    end
    
%     figure;
%     subplot(2, 1, 1)
%     plot([0 dt_record])
%     subplot(2, 1, 2)
%     plot(SoftCode6_2Org, 5, 'ko');
%     hold on
%     plot(StimFrameTime2Org(Bpod_to_Bonsai), 5.2, 'ro')
%     set(gca, 'ylim', [4.5 5.5])
    
    if length(Bpod_to_Bonsai) > length(SoftCode6)
        error('Mismatch')
    end
    
    BpodStimTime = StimFrameTime(Bpod_to_Bonsai);
    BonsaiTriggerTime = BpodStimTime(TriggerBpodNum);
    VideoFrameTime = cellfun(@(x)str2num(x(12:13))*3600000+ str2num(x(15:16))*60000+str2num(x(18:19))*1000+str2num(x(22:end-1)),vf,'Uniformoutput',false);
    VideoFrameTime = cell2mat(VideoFrameTime);
     
    TriggerFrameindex = [];
    dt2_record = [];
    for n = 1:length(BonsaiTriggerTime)
        [dmin2,ind_dmin2] = min(abs(VideoFrameTime-BonsaiTriggerTime(n)));
        TriggerFrameindex = [TriggerFrameindex ind_dmin2];
        dt2_record = [dt2_record dmin2];
    end
    
    x_position=[];
    y_position=[];
    for o = 1:length(TriggerFrameindex)
        xy_position = strsplit(pf{TriggerFrameindex(o)},',');
        x_position = [x_position str2num(xy_position{1}(2:end))];
        y_position = [y_position str2num(xy_position{2}(2:end))];
    end
    
    x_position_sum = [x_position_sum x_position];
    y_position_sum = [y_position_sum y_position];
    
    DLC(i).name = VideoNames{i}(1:end-4);
    DLC(i).x_position = floor(x_position);
    DLC(i).y_position = floor(y_position);
    DLC(i).BpodIndex = BpodIndex;
    
    
    %      FrameList = [ ];
    %      for p = 1:length(TriggerFrameindex)
    %      FrameList(:,:,:,p) = read(Video,TriggerFrameindex(p));
    %      end
    %      FrameList2 = squeeze(FrameList(:, :, 1, :));
    %      MaxProjection = max(FrameList2, [], 3);
    %      imagesc(MaxProjection, [0 300]);
    %      colormap('gray')
    
end

figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 20 12], 'paperpositionmode', 'auto' )
Video=VideoReader('pineapple2021-06-15T20_46_22.avi');
FirstFrame = read(Video,703);

ha1= axes('unit', 'centimeters', 'position', [1 2 8 8], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 400],'ytick', [0:100:400], 'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xlim', [0 400],'xtick', [0:100:400],'XAxisLocation','Top');
imshow(FirstFrame);
hold on;
drawpoint('Position',[204.7663 203.9839]);

%      bFrame=read(Video,834);
%      imshow(bFrame);
%      drawpoint('Position',[53.218 76.734]);

%       cFrame=read(Video,3275);
%       imshow(cFrame);
%       drawpoint('Position',[114.9938 223.8071]);


ha1= axes('unit', 'centimeters', 'position', [11 2 8 8], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 400],'ytick', [0:100:400], 'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xlim', [0 400],'xtick', [0:100:400],'XAxisLocation','Top');
ylabel('Yposition');
xlabel('Xposition');
imshow(FirstFrame);
hold on;
axis ij;
axis on;
line([295 295],[0 400],'LineStyle','-.','Color','g');
line([0 400],[225 225],'LineStyle','-.','Color','g');
plot(x_position_sum,y_position_sum,'.','Color','c');


% ROI select
sprintf('Please select region of interests')
roi_selected = drawfreehand();
pause;
maskout = createMask(roi_selected);
print (gcf,'-dpng', ['ROI_mask']);

% index filter
for p = 1:length(DLC)
    BpodIndexHit=[];
    for q = 1:length(DLC(p).x_position)        
        if maskout(DLC(p).y_position(q),DLC(p).x_position(q))==1
            BpodIndexHit=[BpodIndexHit DLC(p).BpodIndex(q)];
        end
    end
    DLC(p).BpodIndexHit = BpodIndexHit;
end
