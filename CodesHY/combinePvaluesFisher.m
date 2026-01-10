function p_combined = combinePvaluesFisher(p_vals)
% combinePvaluesFisher  Combine p-values via Fisher’s method
%   p_combined = combinePvaluesFisher(p_vals) returns the overall p-value
%   testing the joint null that all individual hypotheses are true.
%
%   Input:
%     p_vals    – vector of session-level p-values (size S×1 or 1×S)
%
%   Output:
%     p_combined  – Fisher’s combined p-value

    % Guard against zeros or ones
    p_vals(p_vals < eps) = eps;
    p_vals(p_vals > 1 - eps) = 1 - eps;

    % Fisher statistic
    chi2stat = -2 * sum(log(p_vals));
    
    % Degrees of freedom
    df = 2 * numel(p_vals);
    
    % Combined p-value (upper tail of chi2)
    p_combined = 1 - chi2cdf(chi2stat, df);
end