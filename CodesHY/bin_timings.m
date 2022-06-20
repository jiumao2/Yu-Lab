function [spike_train, t_spike_train] = bin_timings(spike_times, binwidth, varargin)
    StartFromZero = 'on';
    if nargin>=3
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'StartFromZero'
                    StartFromZero = varargin{i+1}; 
                otherwise
                    errordlg('unknown argument')
            end
        end
    end
    switch StartFromZero
        case 'on'
            t_edges = 0:binwidth:spike_times(end)+binwidth;
        case 'off'
            t_edges = spike_times(1):binwidth:spike_times(end)+binwidth; 
        otherwise
            errordlg('unknown argument')   
    end
    t_spike_train = (t_edges(1:end-1)+t_edges(2:end))/2;
    
    spike_train = zeros(1,length(t_edges)-1);
    
    k = 1; j = 1;
    while j <= length(spike_times)
        if spike_times(j) < t_edges(k+1)
            spike_train(k) = spike_train(k)+1;
            j = j+1;
        else
            k = k+1;
        end
    end
        
end