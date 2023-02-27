function [psth1,psth2,tpsth,preference_index, difference_index] = ExtractPETH(spike_time,event_times,params)

    params_temp = params;
    params_temp.pre = 2000;
    params_temp.pose = 2000;
    [psth_temp1, ~] = jpsth(spike_time, event_times{1}', params_temp);
    [psth_temp2, ~] = jpsth(spike_time, event_times{2}', params_temp);


    [psth1, tpsth] = jpsth(spike_time, event_times{1}', params);
    [psth2, ~] = jpsth(spike_time, event_times{2}', params);

    psth1 = smoothdata(psth1,'gaussian',25*5);
    psth2 = smoothdata(psth2,'gaussian',25*5);   

%     difference_index = preferenceIndex(max(psth1),max(psth2));
    difference_index = (psth1-mean([psth_temp1,psth_temp2]))./std([psth_temp1,psth_temp2])...
        -(psth2-mean([psth_temp1,psth_temp2]))./std([psth_temp1,psth_temp2]);

    if max(psth2)>max(psth1)
        [psth1, psth2] = swap(psth1, psth2);
    end

    preference_index = preferenceIndex(max(psth1),max(psth2));

    mean_psth = mean([psth_temp1,psth_temp2]);
    std_psth = std([psth_temp1,psth_temp2]);

    psth1 = (psth1-mean_psth)./std_psth;
    psth2 = (psth2-mean_psth)./std_psth;
end