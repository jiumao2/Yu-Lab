function v = computeVelocity(x, y)
% compute the velocity from x and y
% do not accept NaN values

if nargin < 2
    y = zeros(size(x));
end

assert(all(~isnan(x), 'all') && all(~isnan(y), 'all'));

v_temp = sqrt((x(2:end) - x(1:end-1)).^2 + (y(2:end) - y(1:end-1)).^2);

flag_transpose = false;
if size(v_temp, 1) ~= 1
    v_temp = v_temp';
    flag_transpose = true;
end

v = mean([NaN, v_temp; v_temp, NaN], 'omitnan');

if flag_transpose
    v = v';
end

end