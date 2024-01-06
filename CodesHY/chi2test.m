function [p_value, chi2_value] = chi2test(x)

sum_row = sum(x, 2);
sum_col = sum(x, 1);
n = sum(x(:));

x_exp = zeros(size(x));
for k = 1:size(x, 1)
    for j = 1:size(x, 2)
        x_exp(k,j) = n*x(k,j)*x(k,j)./sum_row(k)./sum_col(j);
    end
end

chi2_value = sum((x-x_exp).^2./x_exp, 'all');
df = (size(x,1)-1)*(size(x,2)-1);

p_value = 1-chi2cdf(chi2_value, df);

end