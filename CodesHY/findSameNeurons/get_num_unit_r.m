function num_unit = get_num_unit_r(r, channel, num_in_channel)
    num_unit = find(r.Units.SpikeNotes(:,1)==channel & r.Units.SpikeNotes(:,2) == num_in_channel);
end