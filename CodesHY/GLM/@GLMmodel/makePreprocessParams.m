function params = makePreprocessParams(varargin)
%MAKEPREPROCESSPARAMS Parameters for preprocessing spikes->(X,Y).

ip = inputParser;
ip.addParameter('BinWidth', 0.01, @(x)isnumeric(x)&&isscalar(x)&&x>0);

ip.addParameter('EventNames', {}, @(x)iscellstr(x) || isstring(x));
ip.addParameter('EventWindows', [], @(x)isnumeric(x) && (isempty(x) || (size(x,2)==2)));

ip.addParameter('IncludeType', 'between_events', @(s)ischar(s)||isstring(s));
ip.addParameter('StartEvent', '', @(s)ischar(s)||isstring(s));
ip.addParameter('EndEvent', '', @(s)ischar(s)||isstring(s));
ip.addParameter('StartOffset', 0, @(x)isnumeric(x)&&isscalar(x));
ip.addParameter('EndOffset', 0, @(x)isnumeric(x)&&isscalar(x));

ip.addParameter('InterpMethod', 'linear', @(s)ischar(s)||isstring(s));
ip.addParameter('DropBinsWithNaNContinuous', true, @(x)islogical(x)&&isscalar(x));

ip.addParameter('MissingEventPolicy', 'skip_trial', @(s)ischar(s)||isstring(s));

ip.parse(varargin{:});
p = ip.Results;

params = struct();
params.BinWidth = p.BinWidth;

% Event config
if isstring(p.EventNames), p.EventNames = cellstr(p.EventNames); end
params.Event = struct();
params.Event.Names = p.EventNames;

if isempty(params.Event.Names)
    params.Event.Windows = zeros(0,2);
else
    if isempty(p.EventWindows) || size(p.EventWindows,1) ~= numel(params.Event.Names)
        error('EventWindows must be [numel(EventNames) x 2] with rows [t_pre, t_post].');
    end
    if any(p.EventWindows(:) < 0)
        error('EventWindows must be >= 0.');
    end
    params.Event.Windows = p.EventWindows;
end

% Inclusion config
params.Include = struct();
params.Include.Type = lower(char(p.IncludeType));
params.Include.StartEvent = char(p.StartEvent);
params.Include.EndEvent   = char(p.EndEvent);
params.Include.StartOffset = p.StartOffset;
params.Include.EndOffset   = p.EndOffset;

if strcmp(params.Include.Type, 'between_events')
    if isempty(params.Include.StartEvent) || isempty(params.Include.EndEvent)
        error('StartEvent and EndEvent are required for IncludeType="between_events".');
    end
end

% Continuous config (NO extrapolation)
params.Continuous = struct();
params.Continuous.InterpMethod = char(p.InterpMethod);
params.Continuous.DropBinsWithNaN = p.DropBinsWithNaNContinuous;

params.MissingEventPolicy = lower(char(p.MissingEventPolicy));
end
