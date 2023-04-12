function RTOut = calRT(HT, FP, varargin)
% RTOut = calRT(hold_dur, forepriod, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'CalSE', 0)
% RTOut = calRT(reaction_time, [], 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'CalSE', 0)
% JY 8.19.2022

if isempty(FP)
    RelTime = HT;
else
    RelTime = HT-FP;
end;

% computing_method = 'cdf'; % could also be mean, ecdf
remove_100ms      = 1; % remove very fast responses, which are deemed anticipatory responses
remove_outliers     = 1;
toplot = 1;
calse = 1;

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case {'Remove100ms'}
                remove_100ms = varargin{i+1}; %
            case {'RemoveOutliers'}
                remove_outliers = varargin{i+1}; %
            case {'ToPlot'}
                toplot = varargin{i+1}; %
            case {'Calse', 'CalSE'}
                calse = varargin{i+1}; %
            otherwise
                errordlg('unknown argument')
        end
    end
end

switch remove_100ms
    case 1
        RelTime = RelTime(RelTime>0.1);
    case 0
        RelTime = RelTime(RelTime>0.0);
end;

% remove outliers
if remove_outliers
    RelTimeOrg = RelTime;
%     thisMAD = mad(RelTime);
    [RelTime, indremoved] = rmoutliers_custome(RelTime);
    if toplot
        figure(10); clf
        set(10, 'Visible', 'on')
        plot(RelTimeOrg, 'ko');
        hold on
        plot(indremoved, RelTimeOrg(indremoved), 'rx', 'linewidth',2,'markersize', 8);
        set(gca, 'yscale','log')
    end;
end;

if isempty(RelTime) || length(RelTime)<5
    RTOut.median = NaN;
    RTOut.median_ksdensity = NaN;
else
    if calse
        RTOut.median = [median(RelTime) std(bootstrp(1000, @median, RelTime))];
        RTOut.median_ksdensity = [kscdf_med(RelTime) std(bootstrp(1000, @kscdf_med, RelTime))];
    else
        RTOut.median = [median(RelTime) ];
        RTOut.median_ksdensity = [kscdf_med(RelTime)];
    end;
end;
end

function rtout = kscdf_med(rt)
% use a kernel density method to estimate the median
rt_space = linspace(min(rt), max(rt), 100);
f = ksdensity(rt, rt_space, 'function', 'cdf');
% find f near 0.5
ind_med = find(f>=0.5, 1, 'first');
rtout = rt_space(ind_med);

end

function [dataout,indrmv] = rmoutliers_custome(datain);

[data2575] = prctile(datain, [25, 75]);
interq = data2575(2) - data2575(1);
c=5;
indrmv = find(datain>data2575(2)+interq*c | datain<data2575(1)-interq*c);
dataout = datain;
 
% if ~isempty(indrmv)
%     sprintf('Remove these long reaction time (ms): %2.0f, \n', dataout(indrmv))
% end;
dataout(indrmv) = [];
end


