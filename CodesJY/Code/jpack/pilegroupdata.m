function pilegroupdata
cellsL4;
load('goodtrs.mat');
% Dec 2013 JY
% new version Sept 2014 JY
% pile Vm data using datawrapper for group analysis. 
% 9/4/2014 this one won't resample the data to 1khz
% 29 cells as of 9/4/2014; 5 are INs, 24 are RS cells
% if isempty(cellarray)
% 
% else
%     eval(cellarray)
% end;

wdata=struct('cellName', [], 'mainwid', [], 'allwid', [], 'varNames', [], 'trialnums', [],  'k', [], 't', [], 'tvm', [], 'Vm', [], 'Vm_noAP', [], 'Vmorg', [],  'Vth', [], 'Spk', [], 'Spkorg', [],...
    'whiskpos', [], 'whiskamp', [], 'whiskph', [], 'whisksetpt', [], 'whiskposfilt', [], 'deltaKappa', [], 'M0', [], 'Faxial', [], 'contact_onset', [], 'contact_offset', [], 'licks', [], 'Vthparams', []);

wdata2=struct('cellname', [], 'mainwid', [], 'allwid', [], 'trialnums', [], 'k', [], 't', [], 'tvm', [], 'Vth', [], 'Vthparams',[],  'S_ctk', [],'featuresName', [], 'Vm', [],'Vmorg', [], 'Spk', [], 'Spkorg', []);

redoVth={};

for i= 1:size(celllist, 1)
    cd(['C:\Work\Projects\BehavingVm\Data\Vmdata\' celllist{i, 1}]);
    load(celllist{i, 2});
    load(celllist{i, 3});
    load(celllist{i, 4});
    
    file=dir('VthJY*.mat');
    if ~isempty(file)
        load(file.name);
        if length(intersect(cell2mat(goodtrs(ismember(goodtrs(:, 1), celllist(i, 1)), 2)), Vth.trials))<length(cell2mat(goodtrs(ismember(goodtrs(:, 1), celllist(i, 1)), 2))) | ~isfield(Vth, 'Vbound')
            detectSpikeonset(T, cell2mat(goodtrs(ismember(goodtrs(:, 1), celllist(i, 1)), 2)), 0.33, [-59 -45 80 8],10000,0, 0)
            file=dir('VthJY*.mat');
            load(file.name);
            redoVth=[redoVth celllist(i, 1)];
        end;
    else
        detectSpikeonset(T, cell2mat(goodtrs(ismember(goodtrs(:, 1), celllist(i, 1)), 2)), 0.33, [-59 -45 80 8],10000,0, 0)
        file=dir('VthJY*.mat');
        load(file.name);
        redoVth=[redoVth celllist(i, 1)];
    end;

    iwdata=datawrappernew(T, cell2mat(goodtrs(ismember(goodtrs(:, 1), celllist(i, 1)), 2)), contacts, Vth, celllist{i, 5});
    iwdata2=regroupdata(iwdata);
    
    cd C:\Work\Projects\BehavingVm\Data\Groupdata\Rawdata\Rawdata
    save (['piledata' celllist{i, 1} '_form1.mat'], 'iwdata');
    save (['piledata' celllist{i, 1} '_form2.mat'], 'iwdata2');   
    
    wdata(i)=iwdata;
    wdata2(i)=iwdata2;
    
end;

cd C:\Work\Projects\BehavingVm\Data\Groupdata\Rawdata\Rawdata
save All_L4group_form1 wdata
save All_L4group_form2 wdata2
save redoVth redoVth

% assignin('base', 'wdata', wdata);
% assignin('base', 'wdata2', wdata2);
function wdataout=regroupdata(wdatain)

wdataout.cellname=wdatain.cellName;
wdataout.mainwid=wdatain.mainwid;
wdataout.allwid=wdatain.allwid;
wdataout.trialnums=wdatain.trialnums;
wdataout.k=length(wdatain.trialnums);
wdataout.t=wdatain.t;
wdataout.tvm=wdatain.tvm;
wdataout.Vth=wdatain.Vth;
wdataout.Vthparams=wdatain.Vthparams;

if length(wdataout.allwid)>1
    
    wdataout.S_ctk(1, :, :, :)=wdatain.whiskpos;
    wdataout.S_ctk(2, :, :, :)=wdatain.whiskamp;
    wdataout.S_ctk(3, :, :, :)=wdatain.whiskph;
    wdataout.S_ctk(4, :, :, :)=wdatain.whisksetpt;
    wdataout.S_ctk(5, :, :, :)=wdatain.whiskposfilt;
    wdataout.S_ctk(6, :, :, :)=wdatain.deltaKappa;
    wdataout.S_ctk(7, :, :, :)=wdatain.M0;
    wdataout.S_ctk(8, :, :, :)=wdatain.Faxial;
    
    wdataout.S_ctk(9, :, :, :)=wdatain.contact_onset;
    wdataout.S_ctk(10, :, :, :)=wdatain.contact_offset;
    
    wdataout.S_ctk(11, :, :, 1)=wdatain.licks;
    
else
    wdataout.S_ctk(1, :, :, 1)=wdatain.whiskpos;
    wdataout.S_ctk(2, :, :, 1)=wdatain.whiskamp;
    wdataout.S_ctk(3, :, :, 1)=wdatain.whiskph;
    wdataout.S_ctk(4, :, :, 1)=wdatain.whisksetpt;
    wdataout.S_ctk(5, :, :, 1)=wdatain.whiskposfilt;
    wdataout.S_ctk(6, :, :, 1)=wdatain.deltaKappa;
    wdataout.S_ctk(7, :, :, 1)=wdatain.M0;
    wdataout.S_ctk(8, :, :, 1)=wdatain.Faxial;
    wdataout.S_ctk(9, :, :, 1)=wdatain.contact_onset;
    wdataout.S_ctk(10, :, :, 1)=wdatain.contact_offset;
    wdataout.S_ctk(11, :, :, 1)=wdatain.licks;
end;

wdataout.featuresName=wdatain.varNames;

wdataout.Vm(1, :, :)=wdatain.Vm;
wdataout.Vm(2, :, :)=wdatain.Vm_noAP;
wdataout.Vmorg(:, :)=wdatain.Vmorg;
wdataout.Spk=wdatain.Spk;
wdataout.Spkorg=wdatain.Spkorg;

%               t:  (length of a trial, e.g. 5000)
%                k: (number of trials e..g. 197) 
%                u: (number of units e.g.1)
%            S_ctk: [8x5000x197 double]  - Matrix of features (in this case 8). Nro Features x Nro Time Points x Nro Trials
%     featuresName: {1x8 cell} - A String with the name of each of the features
%            R_ntk: [1x5000x197 double] - a Matrix of your Vm traces (or spikes for your cell-attached)
