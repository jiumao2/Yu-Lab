function p = checkModulationShuffling(spike_times, event_times, t_pre, t_post, binwidth)
    if nargin < 3
        t_pre = -1000;
    end
    
    if nargin < 4
        t_post = 500;
    end
    
    if nargin < 5
        binwidth = 50;
    end

    t_edges = t_pre:binwidth:t_post;

    N_shuffle = 1000;

    sc = zeros(length(event_times), length(t_edges)-1);
    for k = 1:length(event_times)
        for j = 1:size(sc, 2)
            sc(k,j) = sum(spike_times >= event_times(k)+t_edges(j) & spike_times < event_times(k)+t_edges(j+1));
        end
    end

    mean_fr = mean(sc, 'all');
    peth_data = mean(sc);
    diff_data = sum((peth_data-mean_fr).^2);
    
    squared_diff = zeros(N_shuffle, 1);
    
    for k = 1:N_shuffle
        shift_bins = randi(size(sc, 2), 1, size(sc, 1));
        sc_shuffled = sc;
        for j = 1:size(sc, 1)
            sc_shuffled(j,:) = circshift(sc(j,:), shift_bins(j));
        end
        
        peth = mean(sc_shuffled, 1);
        squared_diff(k) = sum((peth-mean_fr).^2);
    end

    p = sum(squared_diff >= diff_data) ./ N_shuffle;
end