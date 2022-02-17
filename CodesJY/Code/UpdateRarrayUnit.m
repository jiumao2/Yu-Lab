function r = UpdateRarrayUnit(r, units)
% add/update units to r array
% % m: multiunits  s: single units
% units   =   {11      'ss'            [] };
% e.g., r=UpdateRarrayUnit(r, {18 'r' []})
% e.g., r=UpdateRarrayUnit(r, {18 's' []})
% e.g., r=UpdateRarrayUnit(r, {18 'm' []})
%% add spikes and plot stuff

r.Units.Definition                               = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};

ou            = r.Units.Profile;
oldchs      =   cell2mat(ou(:, 1));

for i   = 1:size(units, 1)
    
    ich = units{i, 1};
    
    toextract =0;
    
    % check if ich has already been included in oldunits
    if ~isempty(find(oldchs==ich))
        
        switch units{i, 2}
            case 'r' % simply removing an old channel
                allindx = find(r.Units.SpikeNotes(:, 1)==ich);
                r.Units.SpikeTimes(allindx)=[];
                r.Units.SpikeNotes (allindx, :) = [];
                r.Units.Profile(oldchs==ich, :) = [];
            otherwise
                allindx = find(r.Units.SpikeNotes(:, 1)==ich);
                r.Units.SpikeTimes(allindx)=[];
                r.Units.SpikeNotes (allindx, :) = [];
                r.Units.Profile(oldchs==ich, :) = units(i, :);
                toextract =1;
        end;
    else
        r.Units.Profile = [r.Units.Profile; units(i, :)];
        toextract =1;
    end;
    
    % add new units
    sorting_code                             = units{i, 2};
    for k                                              = 1:length(sorting_code)
        switch sorting_code(k)
            case 'm'
                r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 2 0];
            case 's'
                r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 1 0];
            case 'r'  % remove this channel
            otherwise
                return
        end
        
        if toextract
            
            channel_id                                        = ich;
            cluster_id                                          = k;
            
            n_new = length(r.Units.SpikeTimes)+1;
            
            r.Units.SpikeTimes(n_new)                      =   struct('timings',  [], 'wave', []);
            
            raw                  = load(['chdat' num2str(channel_id) '.mat']);
            
            tnew = [1:length(raw.index)]*1000/30000;
            
            % load spike time:
            if r.Units.SpikeNotes(i, 4)==0
                spk_id                                                 = load(['times_chdat_meansub' num2str(channel_id) '.mat']);
            else
                spk_id                                                 = load(['times_polytrode' num2str(r.Units.SpikeNotes(i, 4)) '.mat']);
            end;
            
            spk_in_ms                                           = round((spk_id.cluster_class(spk_id.cluster_class(:, 1)==cluster_id, 2))); % this is not mapped to time in recording
            [~, spkindx]                                          =     intersect(tnew, spk_in_ms);
            spk_in_ms_new                                   =    round(raw.index(spkindx));
            r.Units.SpikeTimes(n_new).timings  =       spk_in_ms_new; % in ms
            r.Units.SpikeTimes(n_new).wave    =       spk_id.spikes(spk_id.cluster_class(:, 1)==cluster_id, :);
        end;
    end;
end;

% sorting

chs = r.Units.SpikeNotes(:, 1);
[~, ind_sort] = sort(chs);
r.Units.SpikeNotes = r.Units.SpikeNotes(ind_sort, :);
r.Units.SpikeTimes = r.Units.SpikeTimes(ind_sort);

chs = cell2mat(r.Units.Profile(:, 1));
[~, ind_sort] = sort(chs);
r.Units.Profile = r.Units.Profile(ind_sort, :);

tic
save RTarrayAll r
toc
