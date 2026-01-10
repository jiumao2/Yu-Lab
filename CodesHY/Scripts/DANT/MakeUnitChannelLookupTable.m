load('D:\Dara\DANT_Output_Striatum\Output.mat');
folder_task = {'1_AutoShaping', '2_LeverPress', '3_LeverRelease', '4_Wait', '5_SRT_2FPProbeWin1000', '6_SRT_2FPProbe'};

folder_data = fullfile('D:\Dropbox\13_EphysProcessed\Dara\');
session_names = unique(Output.SessionNames);

SessionNames = {};
SessionIDs = [];
Unit = [];
Ch = [];
UnitInCh = [];
for k = 1:length(session_names)
    for j = 1:length(folder_task)
        dir_output = dir(fullfile(folder_data, folder_task{j}, session_names{k}, 'RTarray*.mat'));
        if ~isempty(dir_output)
            load(fullfile(folder_data, folder_task{j}, session_names{k}, dir_output.name));
            break
        end
    end

    for j = 1:length(r.Units.SpikeTimes)
        SessionNames{end+1} = session_names{k};
        SessionIDs(end+1) = k;
        Unit(end+1) = j;
        Ch(end+1) = r.Units.SpikeNotes(j,1);
        UnitInCh(end+1) = r.Units.SpikeNotes(j,2);
    end

    fprintf('%d / %d done!\n', k, length(session_names));
end

tbl = table();
tbl.SessionNames = SessionNames';
tbl.Sessions = SessionIDs';
tbl.Unit = Unit';
tbl.Ch = Ch';
tbl.UnitInCh = UnitInCh';

writetable(tbl, './UnitChannelLookupTable_Dara.csv');


