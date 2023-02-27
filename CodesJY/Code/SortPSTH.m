function [NewSort, IndSig] = SortPSTH(PSTHOut)

% Jianing Yu
%12/2/2022
% This is used in KornbumSpikesPopulation.m
% it sort channels from a session according to the peak firing times

% Will go through press, release, and reward 
N_Cell = size(PSTHOut.Units, 1);
Events = {'Press', 'Release', 'Reward'};
N_Event = length(Events);

pval_pop                =             zeros(N_Event, size(PSTHOut.Units, 1));
tpeaks_pop            =             zeros(N_Event, size(PSTHOut.Units, 1));
peakval_pop            =           zeros(N_Event, size(PSTHOut.Units, 1));

for i = 1:N_Cell
    for j =1:N_Event
        % read p value of this event      
        pval_pop(j, i)            =      eval(['PSTHOut.' Events{j}, 'MergedStat.StatOut(i).pval']);
        tpeaks_pop(j, i)        =      eval(['PSTHOut.' Events{j}, 'MergedStat.StatOut(i).tpeak']);
        [~, indpeak]              =     eval(['min(abs(PSTHOut.' Events{j} 'Merged(1, :) - PSTHOut.' Events{j} 'MergedStat.StatOut(i).tpeak));']);
        peakval_pop(j, i)      =     eval(['PSTHOut.' Events{j} 'Merged(i+1, indpeak)']);
    end;
end;

% find out for each cell, where the highest firing rate is
max_rate_epoch = NaN*ones(1, N_Cell);
max_rate = NaN*ones(1, N_Cell);

PeakTimeInEvent = NaN*ones(1, N_Cell);

for i = 1:N_Cell
    ind_sig = find(pval_pop(:, i)<0.05);
    if ~isempty(ind_sig)
        rate_sig = peakval_pop(ind_sig, i);
        [max_rate(i), ind_max] = max(rate_sig);
        max_rate_epoch(i) = ind_max;
        PeakTimeInEvent(i) = tpeaks_pop(ind_max,i);
    end;
end;

[EpochSort1, IndSort1]= sort(max_rate_epoch); % EpochSort1: 1, Press, 2, Release, 3, Reward;  
PeakTimeInEvent = PeakTimeInEvent(IndSort1);

% EpochSort1 =
%   Columns 1 through 12
%      1     1     1     1     1     1     1     1     1     2     2     2
%   Columns 13 through 15
%      3     3   NaN
% IndSort1 =
%   Columns 1 through 12
%      1     4     5     7     9    11    12    13    15     2    10    14
%   Columns 13 through 15
%      3     6     8
% PeakTimeInEvent =
%   Columns 1 through 6
%          625        -375        -625        -375       -1875         375
%   Columns 7 through 12
%        -1375         NaN         375        -125       -1125        1625
%   Columns 13 through 15
%         -125        -125        -375
% Sort cells for the second time, within each categories

NewSort = [];
for i =1:N_Event
    ind_thisEvent = find(EpochSort1 == i);

    if ~isempty(ind_thisEvent)
    ind_Cells_thisEvent = IndSort1(ind_thisEvent); % index of cells
    PeakTime_thisEvent = PeakTimeInEvent(ind_thisEvent); % peak time
    % sort rate in this Event
    [PeakTime_thisEvent, IndSort2] = sort(PeakTime_thisEvent);
    NewSort = [NewSort ind_Cells_thisEvent(IndSort2)];
    end;
end;

IndSig    = [ones(1, length(NewSort)) zeros(length( setdiff(IndSort1, NewSort)))];
NewSort = [NewSort setdiff(IndSort1, NewSort)]; % put NaN in the end

