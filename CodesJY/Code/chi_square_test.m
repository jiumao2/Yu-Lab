function chi_out = chi_square_test(pop1, pop2)
% Jianing Yu 7/12/2021
% chiout = chi_square_test([100 150], [1000 1800])
% Observed data
n1 =  pop1(1);
N1 = pop1(2);

n2= pop2(1);
N2 = pop2(2);



% Pooled estimate of proportion
p0 = (n1+n2) / (N1+N2)
% Expected counts under H0 (null hypothesis)
n10 = N1 * p0;
n20 = N2 * p0;
% Chi-square test, by hand
observed = [n1 N1-n1 n2 N2-n2];
expected = [n10 N1-n10 n20 N2-n20];
chi2stat = sum((observed-expected).^2 ./ expected)
p = 1 - chi2cdf(chi2stat,1)

chi_out.stat = chi2stat;
chi_out.p = p;