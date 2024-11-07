function p_value = permutationTest(x, y, n, tail)
if nargin < 3
    n = 10000;
end

if nargin < 4
    tail = 'both';
end

if size(x, 1) ~= 1
    x = x';
end

if size(y, 1) ~= 1
    y = y';
end

x = x(~isnan(x));
y = y(~isnan(y));

x_len = length(x);
y_len = length(y);
dmean = mean(x)-mean(y);

data_combined = [x, y];

randmat = zeros(n, x_len+y_len);

for k = 1:n
    randmat(k,:) = randperm(x_len+y_len);
end

data_rand = data_combined(randmat);
out = mean(data_rand(:, 1:x_len), 2) - mean(data_rand(:, x_len+1:end), 2);

if strcmpi(tail, 'both')
    p_value = sum(abs(out) >= abs(dmean))./n;
elseif strcmpi(tail, 'left')
    p_value = sum(out <= dmean)./n;
elseif strcmpi(tail, 'right')
    p_value = sum(out >= dmean)./n;
end

end