function ExtractVideoFramesR(r, ts, varargin)

% 4.15.2021
% this function extract a video clip defined by time in varargin
% r is the neural data array and it must include frame signal
% ts is the frame timestamp data. 

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 't'
                tonset = floor(varargin{i+1}*1000);
            case 'tpre'
                tpre = varargin{i+1}*1000;
            case 'tpost'
                tpost = varargin{i+1}*1000;
            otherwise
                errordlg('unknown argument')
        end
    end
end

% determine which segment
indframe = find(strcmp(r.Behavior.Labels, 'FrameOn'));
t_frameon = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);

ind_break = find(diff(t_frameon)>1000);

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
 
% check frames

 % check  trigger frames 
 
 [ica, headerInfo] = ReadJpegSEQ(ts.sideviews{1},[1 10]); % ica is image cell array
 
 %
 
 imageavg = [];
 
 for i=1:size(ica, 1)
    if i ==1
     imageavg = ica{i, 1};
    else
        imageavg = imageavg + ica{i, 1};
    end;
     
 end;
 
 imageall = 
 
 figure;
 
 

 

 
 































