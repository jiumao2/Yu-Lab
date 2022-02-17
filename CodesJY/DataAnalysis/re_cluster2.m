function re_cluster(ch, param)

if nargin<2
 param=set_parameters;
    
  param.sr = 30000;

if ~isempty(find(pos_detection==functional_channels(i)))
    param.detection = 'pos';
else
    param.detection = 'neg';
end;

param.detect_fmin = 250;               % high pass filter for detection
param.detect_fmax = 8000;              % low pass filter for detection (default 1000)
param.detect_order = 4;                % filter order for detection
param.sort_fmin = 250;                 % high pass filter for sorting
param.sort_fmax = 8000;                % low pass filter for sorting (default 3000)
param.segments_length = 0.25;            % data will be precessing in segments of 15 seconds

param.stdmin = 3.5;
param.stdmax = 20;  
    

end;


tosort_list{1} = ['chdat' ch, '.mat'];

Get_spikes(tosort_list,'parallel',false,'par',param);
Do_clustering(['chdat' ch '_spikes.mat'])
