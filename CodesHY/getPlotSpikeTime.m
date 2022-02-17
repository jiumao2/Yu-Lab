function output = getPlotSpikeTime(spike_time_all,time,t_pre,t_post)
% return the processed spike time from spike_time_all in [t_pre,t_post]
output = spike_time_all(spike_time_all >= time+t_pre & spike_time_all <= time+t_post) - time;
end
