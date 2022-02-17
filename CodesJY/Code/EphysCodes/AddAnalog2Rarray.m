function r = AddAnalog2Rarray(r)

x1 = dir('Force*.mat');
if ~isempty(x1)
    fdata = load(x1.name);
    tnew = [1:length(fdata.index)]*1000/30000;
    r.Analog.Force = [tnew; fdata.data]';
end;

x2 = dir('Opto*.mat');
if ~isempty(x2)
    odata = load(x2.name);
    tnew = [1:length(odata.index)]*1000/30000;
    r.Analog.OptoStim = [tnew; odata.data]';
end;

tic
save ('RTarrayAll.mat','r', '-v7.3');
toc
