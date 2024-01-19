function [p_value, chi2_value] = chi2test(x)

sum_row = sum(x, 2);
sum_col = sum(x, 1);

if any(sum_col == 0) || any(sum_row == 0)
    chi2_value = 0;
    p_value = 1;
    return
end

n = sum(x(:));

x_exp = zeros(size(x));
for k = 1:size(x, 1)
    for j = 1:size(x, 2)
        x_exp(k,j) = sum_row(k)*sum_col(j)/n;
    end
end

for k = 1:size(x, 1)
    for j = 1:size(x, 2)
        if x_exp(k,j) == 0 && x(k,j) == 0
            x(k,j) = 1;
            x_exp(k,j) = 1;
        end
    end
end

chi2_value = sum((x-x_exp).^2./x_exp, 'all');
df = (size(x,1)-1)*(size(x,2)-1);

p_value = 1-chi2cdf(chi2_value, df);

if isnan(p_value)
    disp(chi2_value);
    disp(x);
    disp(x_exp);
    error('p_value = NaN');
end

end