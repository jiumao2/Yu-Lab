function st_out = getCoincidentSpikeTimes(st1, st2, coincident_range)
% GETCOINCIDENTSPIKETIMES  Extract pre‐synaptic spike times that have a
%   corresponding post‐synaptic spike within a specified time window.
%
% getCoincidentSpikeTimes identifies spikes in the pre‐synaptic train (st1)
% that are followed by spikes in the post‐synaptic train (st2) with
% latencies falling within coincident_range milliseconds. The output st_out
% is a subset of st1 containing only those spikes that meet this criterion.
%
% Inputs:
%   st1              double (1 × n1)  
%       Spike times of the pre‐synaptic neuron in milliseconds.
%
%   st2              double (1 × n2)  
%       Spike times of the post‐synaptic neuron in milliseconds.
%
%   coincident_range double (1 × 2)  
%       Time window for coincidence in ms, specified as [minDelay, maxDelay]
%       (default: [1, 4]).
%
% Outputs:
%   st_out           double (1 × m)  
%       Subset of st1 containing spikes that have at least one st2 spike
%       within the specified delay window.
%
% Date:    20250827  
% Author:  Yue Huang

if nargin < 3
    coincident_range = [1, 4]; % ms
end

% st1 should be from the pre-synapse neuron
% st2 should be from the post-synapse neuron

idx1 = 1;
idx2 = 1;
is_coincident = false(1, length(st1));
while idx1 <= length(st1) && idx2 <= length(st2)
    dt = st2(idx2) - st1(idx1);
    if dt >= coincident_range(1) && dt <= coincident_range(2)
        is_coincident(idx1) = true;
        idx1 = idx1 + 1;
    elseif dt > coincident_range(2)
        idx1 = idx1+1;
    elseif dt < coincident_range(1)
        idx2 = idx2+1;
    else
        error('Wrong situation!');
    end
end

st_out = st1(is_coincident);

end