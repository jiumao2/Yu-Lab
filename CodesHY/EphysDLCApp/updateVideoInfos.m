clear
load('./RTarrayAll.mat')
camview = 'top';
mat_path = ['./VideoFrames_',camview,'/MatFile'];
%%
output_mat = dir([mat_path,'/*.mat']);
filenames_mat = sort({output_mat.name});
for n = 1:length(filenames_mat)
    load([mat_path,'/',filenames_mat{n}]);
    if strcmp(camview,'side')
        if ~isfield(VideoInfo,'Hand')
            VideoInfo.Hand = [];
        end
        if ~isfield(VideoInfo,'LiftStartFrameNum')
            VideoInfo.LiftStartFrameNum = NaN;
        end
        if ~isfield(VideoInfo,'LiftStartTime')
            VideoInfo.LiftStartTime = NaN;
        end
        if ~isfield(VideoInfo,'LiftHighestFrameNum')
            VideoInfo.LiftHighestFrameNum = NaN;
        end
        if ~isfield(VideoInfo,'LiftHighestTime')
            VideoInfo.LiftHighestTime = NaN;
        end
    end
    VideoInfos(n) = VideoInfo;
end
if strcmp(camview,'top')
    r.VideoInfos_top = VideoInfos;
elseif strcmp(camview,'side')
    r.VideoInfos_side = VideoInfos;
end
save('./RTarrayAll.mat','r')

