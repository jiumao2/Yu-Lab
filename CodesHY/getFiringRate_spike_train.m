function firing_rate = getFiringRate_spike_train(spike_counts, t_spike_counts, times, binwidth, varargin)
%GETFIRINGRATE get firing rates from spike_times
    if nargin <= 2
        binwidth = 50;
    end
    gaussian_kernel = 0;
    if nargin>=5
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
        idx_out = findSeq(t_spike_counts, times, 'ordered');
        firing_rate = spike_counts(idx_out);
    else
        firing_rate_all = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000; % Hz
        idx_out = findSeq(t_spike_counts, times, 'ordered');
        firing_rate = firing_rate_all(idx_out);
    end

end