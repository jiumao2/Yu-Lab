function tab = unit_table(r)

% Produce a table showing the units. you can copy and paste this into your
% population excel sheet. 
% Jianing Yu
% 4/9/2023


% number of sorted units in this experiment-this is also the number of
% rows
n_unit = size(r.Units.SpikeTimes, 2);

% anm name
Name = repmat(r.Meta(1).Subject, n_unit, 1);

% session
x=r.Meta(1).DateTimeRaw(1:4);
Session =  repmat( [num2str(x(1), '%2.f') num2str(x(2),'%02.f') num2str(x(4),'%02.f')], n_unit, 1);

% polytrode
if isfield(r.Units, 'Tetrodes') || isfield(r.Units.SpikeTimes, 'wave_mean')
    polytrode = 1;
else
    polytrode = 0;
end;
Polytrode = repmat(polytrode, n_unit, 1);

% channel_or_trode
Channel_or_trode = r.Units.SpikeNotes(:, 1);

% units
Units = r.Units.SpikeNotes(:, 2);

% quality
ind_quality =  r.Units.SpikeNotes(:, 3);
Quality = repmat('s', n_unit, 1);
Quality(ind_quality==2) = 'm';

% putative INs
% for now, just list it as 0. one should manually correct it to 1 if it is
% a putative interneuron
PutIN = repmat(0, n_unit, 1);

% unit table
tab = table(Name, Session, Polytrode, Channel_or_trode, Units, Quality, PutIN);
aGoodName = ['UnitTable_', r.Meta(1).Subject, '_',  [num2str(x(1), '%2.f') num2str(x(2),'%02.f') num2str(x(4),'%02.f')], '.csv'];
writetable(tab, aGoodName)
% open this table
winopen(aGoodName)
% also throw it to a data folder

try
    target_folder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'UnitTables', r.Meta(1).Subject);
    if ~exist(target_folder, 'dir')
        mkdir(target_folder);
    end;
    copyfile(aGoodName, target_folder)
end;

% display units
clc
disp('~~~~~~~~~~~ all units in this session ~~~~~~~~~~')
for i =1:n_unit
    disp(['Unit ' num2str(i) ': ' 'Ch ' num2str( tab.Channel_or_trode(i)) ' | Unit ' num2str( tab.Units(i))])
    disp(' ')
end;
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')