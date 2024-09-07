function [h, p] = checkModulationSignificance(spike_times, event_times, t_pre, t_post, binwidth, alpha)
    if nargin<6
        alpha = 0.01;
    end
    if nargin<5
        binwidth = 200;
    end
    if nargin<4
        t_post = 400;
    end
    if nargin<3
        t_pre = -400;
    end
    t_edges = t_pre:binwidth:t_post;
    spk_mat = zeros(length(event_times), length(t_edges)-1);
    for k = 1:length(event_times)
        for j = 1:length(t_edges)-1
            spk_mat(k,j) = sum(spike_times>event_times(k)+t_edges(j) & spike_times<=event_times(k)+t_edges(j+1));
        end
    end

    p = anova1(spk_mat, [], 'off');
    if p <= alpha
        h = true;
    else
        h = false;
    end

end