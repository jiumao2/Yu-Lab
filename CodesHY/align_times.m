function t_out = align_times(t, map)
%ALIGN_TIMES Map event times between synchronized clocks.
% t: real numeric row/column vector, in any order; NaN stays NaN.
% map: finite 2-by-N paired anchors, [target times; source times].
% Anchor columns may be unordered, but each clock must be strictly
% increasing after sorting by source time. Duplicate anchors are rejected.
% Interpolate linearly between anchors. Outside the anchor range (or with
% one anchor), preserve the original unit-slope time-shift convention.
% Output is double, with the same shape and order as t. No files are written.

if ~isnumeric(t) || ~isreal(t) || ...
        ~(isvector(t) || isequal(size(t), [0 0])) || any(isinf(t(:)))
    error('align_times:InvalidTimes', ...
        't must be a real numeric vector with finite values or NaN.');
end
if ~isnumeric(map) || ~isreal(map) || ~ismatrix(map) || ...
        size(map,1) ~= 2 || size(map,2) == 0 || ...
        any(isnan(map(:)) | isinf(map(:)))
    error('align_times:InvalidMap', ...
        'map must be a finite real 2-by-N numeric matrix, with N >= 1.');
end

t = double(t);
map = double(map);
[~, order] = sort(map(2,:));
map = map(:,order); % Keep corresponding source/target anchors paired.
steps = diff(map,1,2);
if any(steps(:) <= 0) || any(isinf(steps(:)))
    error('align_times:InvalidAnchors', ...
        'Source and target anchors must both be strictly increasing.');
end

t_out = NaN(size(t));
valid = ~isnan(t);
if size(map,2) == 1
    t_out(valid) = map(1,1) + (t(valid) - map(2,1));
else
    left = valid & t < map(2,1);
    right = valid & t > map(2,end);
    inside = valid & ~left & ~right;
    if any(inside(:))
        t_out(inside) = interp1(map(2,:), map(1,:), t(inside), 'linear');
    end
    t_out(left) = map(1,1) + (t(left) - map(2,1));
    t_out(right) = map(1,end) + (t(right) - map(2,end));
end
if any(isnan(t_out(valid)) | isinf(t_out(valid)))
    error('align_times:NumericOverflow', ...
        'Alignment produced nonfinite values for finite input times.');
end
end
