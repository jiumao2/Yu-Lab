function firing_rate = getFiringRate(spike_times, times, binwidth, varargin)
%GETFIRINGRATE get firing rates from spike_times
    if nargin <= 2
        binwidth = 50;
    end
    gaussian_kernel = 0;
    if nargin>=4
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'gaussian_kernel'
                    gaussian_kernel = varargin{i+1}; 
                otherwise
                    errordlg('unknown argument')
            end
        end
    end
    if gaussian_kernel == 0
        firing_rate = zeros(size(times));
        for k = 1:length(times)
            spike_num = sum(spike_times>=times(k)-binwidth/2 & spike_times<=times(k)+binwidth/2);
            firing_rate(k) = spike_num./binwidth;
        end
    else
        [spike_counts, t_spike_counts] = bin_timings(spike_times, binwidth);
        firing_rate_all = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000; % Hz
        idx_out = findSeq(t_spike_counts, times, 'ordered');
        firing_rate = firing_rate_all(idx_out);
    end
%     firing_rate = minmax(firing_rate);
% function out = minmax(x)
%     out = (x-min(x))./max(x);
% end
end