function r = UpdateRFrameSignal(r, varargin)
 
% 4/20/2021
%Jianing Yu
% update/add frame signal

% Example script:
% new_sideframe_inds{1} = [1:length(ts.top(1).ts)]; 
% new_sideframe_inds{2} = [2:length(ts.top(2).ts)+1]; 
% new_sideframe_inds{3} = [1:length(ts.top(1).ts)]; 
% 
% r = UpdateRFrameSignal(r, 'time_stamps', ts, 'sidevideo_ind', new_sideframe_inds)


ts = [];
side_ind=   [];
top_ind    =    [];

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'sidevideo_ind'
                side_ind = varargin{i+1};
            case 'topvideo_ind'
                top_ind = varargin{i+1};
            case 'time_stamps'
                ts = varargin{i+1};
            case 'topvideo_ts'
                returnl
            otherwise
                errordlg('unknown argument')
        end;
    end;
end;

%% extract frame signal from original line
indframe = find(strcmp(r.Behavior.Labels, 'FrameOn'));
t_frameon = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);

ind_break = find(diff(t_frameon)>1000);
t_seg =[];
if isempty(ind_break)
    t_seg{1} = t_frameon;
else
    ind_break = [1; ind_break+1];
    for i =1:length(ind_break)
        if i<length(ind_break)
            t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
        else
            t_seg{i}=t_frameon(ind_break(i):end);
        end;
    end;
end;

%% add Video session
 
if ~isempty(ts)
    r.Video.ts = ts;
end;

r.Video.Labels                      =       {'SideFrameOn', 'TopFrameOn'};
r.Video.LabelMarkers           =       [1 2];

r.Video.EventTimings = [];
r.Video.EventMarkers = [];

if ~isempty(side_ind)
    sideframeon_new = [];
    for i=1:length(t_seg)
        frameon_org = t_seg{i};
        sideframeon_new = [sideframeon_new;  frameon_org(side_ind{i})];   % time in ms
    end;
    
    r.Video.EventTimings(r.Video.EventMarkers==1) = [];
    r.Video.EventMarkers(r.Video.EventMarkers==1) = [];
    
    r.Video.EventTimings = [r.Video.EventTimings sideframeon_new'];
    r.Video.EventMarkers = [r.Video.EventMarkers ones(1, length(sideframeon_new))];
end;

if ~isempty(top_ind)
    topframeon_new = [];
    for i=1:length(t_seg)
        frameon_org = t_seg{i};
        topframeon_new = [topframeon_new;  frameon_org(top_ind{i})];   % time in ms
    end;
    
    r.Video.EventTimings(r.Video.EventMarkers==2) = [];
    r.Video.EventMarkers(r.Video.EventMarkers==2) = [];
    
    r.Video.EventTimings = [r.Video.EventTimings topframeon_new'];
    r.Video.EventMarkers = [r.Video.EventMarkers 2*ones(1, length(topframeon_new))];

end;

tic
save RTarrayAll r
toc

