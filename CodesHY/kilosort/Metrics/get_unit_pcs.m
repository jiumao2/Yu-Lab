function unit_PCs = get_unit_pcs(unit_id, spike_clusters, spike_templates, pc_feature_ind, pc_features, channels_to_use, subsample)
    % Return PC features for one unit
    %
    % Inputs:
    % -------
    % unit_id : Int
    %     ID for this unit
    % spike_clusters : Array
    %     Cluster labels for each spike
    % spike_templates : Array
    %     Template labels for each spike
    % pc_feature_ind : Array
    %     Channels used for PC calculation for each unit
    % pc_features : Array
    %     Array of all PC features
    % channels_to_use : Array
    %     Channels to use for calculating metrics
    % subsample : Int
    %     Maximum number of spikes to return
    %
    % Output:
    % -------
    % unit_PCs : Array
    %     PCs for one unit (num_spikes x num_PCs x num_channels)

    % Find indices for spikes belonging to the given unit_id
    inds_for_unit = find(spike_clusters == unit_id);

    % Randomly select spikes to use (with a maximum of 'subsample')
    spikes_to_use = inds_for_unit(randperm(length(inds_for_unit), min(subsample, length(inds_for_unit))));

    % Get unique template IDs for the selected spikes
    unique_template_ids = unique(spike_templates(spikes_to_use));

    unit_PCs = [];

    % Loop through each unique template
    for j = 1:length(unique_template_ids)
        template_id = unique_template_ids(j);
        % Get the indices for spikes corresponding to the current template
        index_mask = spikes_to_use(spike_templates(spikes_to_use) == template_id);
        these_inds = pc_feature_ind(template_id+1, :);

        pc_array = [];

        % Loop through channels to use
        for k = 1:length(channels_to_use)
            i = channels_to_use(k);
            % Check if the current channel is used for the PC calculation
            if ismember(i, these_inds)
                channel_index = find(these_inds == i, 1);
                pc_array = cat(3, pc_array, pc_features(index_mask, :, channel_index));
            else
                unit_PCs = [];
                return; % Return early if the channel is not part of the PC calculation
            end
        end

        % Stack PCs for the current template
        if ~isempty(pc_array)
            unit_PCs = cat(1, unit_PCs, pc_array);
        end
    end

end
