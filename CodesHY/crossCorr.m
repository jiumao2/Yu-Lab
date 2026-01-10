function [ccg, lag] = crossCorr(st1, st2, window, binwidth)
% CROSSCORR  Compute the cross‐correlogram between two spike trains without normalization.
%
% computeCrossCorr calculates unnormalized cross‐correlation counts by computing
% time differences between each spike in the reference train (st1) and the target
% train (st2), binning them within ±window milliseconds at a resolution of binwidth.
% The lag vector spans from –window to +window in steps of binwidth.
%
% Inputs:
%   st1              double (1 × n1)  
%       Spike times of the reference neuron in milliseconds.
%
%   st2              double (1 × n2)  
%       Spike times of the target neuron in milliseconds.
%
%   window           double (1 × 1)  
%       Half‐width of the correlogram window in ms (default: 50).
%
%   binwidth         double (1 × 1)  
%       Bin width for time differences in ms (default: 1).
%
% Outputs:
%   ccg              double (1 × (2*window+1))  
%       Cross‐correlation counts for each lag bin.
%
%   lag              double (1 × (2*window+1))  
%       Time lag values in ms corresponding to each bin.
%
% Reference:
%   Adapted from the cross‐correlation implementation in extended-GLM-for-synapse-detection:
%   https://github.com/NaixinRen/extended-GLM-for-synapse-detection/blob/master/extended%20GLM/corr_fast_v3.m
%
%   Ren, N., Ito, S., Hafizi, H., Beggs, J. M. & Stevenson, I. H.
%   Model-based detection of putative synaptic connections from spike
%   recordings with latency and type constraints. Journal of
%   Neurophysiology 124, 1588–1604 (2020).
%
% Date:    20250827  
% Author:  Yue Huang

if nargin < 3
    window = 50;
end

if nargin < 4
    binwidth = 1;
end

n1 = length(st1);
n2 = length(st2);

if n1 == 0 || n2 == 0
    ccg = [];
    lag = [];
    return;
end

% rough estimate of # of time difference required (assuming independence)
maxTTT = 2*window;
eN = ceil((max(n1, n2))^2 * maxTTT * 2 / min(st1(end), st2(end)));
deltaT = zeros(10 * eN, 1);

% Compute all the time differences
window_left = -window-binwidth/2;
window_right = window+binwidth/2;

lastStartIdx = 1;
k = 1;
for n = 1:n1
    incIdx = 0;
    for m = lastStartIdx:n2
        timeDiff = st2(m) - st1(n);
        if timeDiff >= window_left
            if incIdx==0
                incIdx = m;
            end
            if timeDiff <= window_right
                deltaT(k) = timeDiff;
                k = k + 1;
            else % this is the ending point
                break;
            end
        end
    end
    if incIdx>0
        lastStartIdx = incIdx;
    end
end
deltaT = deltaT(1:(k-1));

% map deltaT to bins
deltaT = int32(deltaT/binwidth) + window/binwidth + 1;

lag = -window:binwidth:window;
deltaT = deltaT(deltaT > 0 & deltaT <= length(lag));

ccg = zeros(1, 2*window/binwidth + 1);
ccg_this = accumarray(deltaT, ones(length(deltaT),1))';
ccg(1:length(ccg_this)) = ccg_this;

assert(length(ccg) == length(lag));

end