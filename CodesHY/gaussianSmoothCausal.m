function [smoothedData] = gaussianSmoothCausal(data, sigma, truncation)
% gaussianSmoothCausal applies a causal approximation of a Gaussian filter to smooth the input data.
%
% Args:
%   data: The input data to be smoothed (1D vector).
%   sigma: The standard deviation of the Gaussian kernel, controlling the degree of smoothing.
%   truncation: The number of standard deviations to truncate the Gaussian kernel.
%               A typical value is around 3 or 4.  The higher the value, the more
%               accurate the approximation, but the longer the filter.
%
% Returns:
%   smoothedData: The smoothed output data (1D vector).  Has the same length
%                 as the input data.

    if nargin < 3
        truncation = 4; % Default truncation value
    end

    % 1. Determine the filter length based on sigma and truncation
    filterLength = ceil(truncation * sigma) + 1; % Changed to only include non-negative t

    % 2. Create the causal Gaussian kernel
    t = 0:(filterLength - 1); % t starts at 0
    gaussianKernel = exp(-(t.^2) / (2 * sigma^2));

    % 3. Normalize the Gaussian kernel so it sums to 1
    gaussianKernel = gaussianKernel / sum(gaussianKernel);

    % 4. Pad the input data to handle the filter length
    paddedData = [zeros(1, filterLength - 1), data]; % Pad only at the end

    % 5. Perform convolution
    smoothedData = conv(paddedData, gaussianKernel, 'valid');
end
