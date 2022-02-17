function AdjustSpkTime(refname, targetname)

xref=load(refname);
xtarget = load(targetname);
% change xtarget based on xref (which may come from polytrode sorting)

spikes =xref.spikes(:, 1:size(xref.spikes, 2)/2);
cluster_class = xref.cluster_class;
par = xref.par;
forced = xref.forced;i
inspk = xref.inspk(:, [1:12]);
ipermut = xref.ipermut;
Temp = xtarget.Temp;
save targetname Temp cluster_class 




