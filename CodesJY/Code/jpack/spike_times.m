function out1 = spike_times(trace,threshold)
%
%   This function detects and locates the time points of action potentials in a trace of 
%   membrane potential as a function of time in a neuron. The trace should represent
%   a current clamp recording from a neuron.
%   Input: 
%   "trace" is the membrane voltage array of the neuron
%   "threshold" is the factor times the maximum membrane potential (peak of spike)
%    This "threshold" factor should be between 0 and 1 and the default value is 0.5
%
%   Output:
%   The output array is the index location of spikes.
%
%   Rune W. Berg 2006
%   rune@berg-lab.net
%   www.berg-lab.net

gim=trace;

if nargin>1
    threshold1=threshold;  %The threshold for spike selection, amount multiplied by the peak value. Everything below is disregarded.
else 
    threshold1=0.5;  %The threshold for spike selection, amount multiplied by the peak value. Everything below is disregarded.
end    

    
 
   % gim=testtrace1-mean(testtrace1);

    clear('set_crossgi')
    set_crossgi=find(gim(1:end) > threshold1*max(gim))  ;  % setting the threshold
    clear('index_shift_neggi');clear('index_shift_pos');

if isempty(set_crossgi) < 1     % This to make sure there is a spike otherwise the code below gives problems. There is an empty else statement below.
    clear('set_cross_plusgi');clear('set_cross_minus')

    index_shift_posgi(1)=min(set_crossgi);
    index_shift_neggi(length(set_crossgi))=max(set_crossgi);

for i=1:length(set_crossgi)-1
 if set_crossgi(i+1) > set_crossgi(i)+1 ; 
     index_shift_posgi(i+1)=i;
     index_shift_neggi(i)=i;
  end
end

%These are the coords in the nerve based smooothing:
set_cross_plusgi=  set_crossgi(find(index_shift_posgi));   % find(x) returns nonzero arguments.
set_cross_minusgi=  set_crossgi(find(index_shift_neggi));   % find(x) returns nonzero arguments.
set_cross_minusgi(length(set_cross_plusgi))= set_crossgi(end);

nspikes= length(set_cross_plusgi); % Number of pulses, i.e. number of windows.

%% Getting the spike coords

for i=1: nspikes
        spikemax(i)=min(find(gim(set_cross_plusgi(i):set_cross_minusgi(i)) == max(gim(set_cross_plusgi(i):set_cross_minusgi(i))))) +set_cross_plusgi(i)-1;
end

else
    spikemax=[];
    'No spikes in trace!'
end


figure; plot(trace); hold on; plot(spikemax, trace(spikemax),'or');hold off

out1=spikemax;
