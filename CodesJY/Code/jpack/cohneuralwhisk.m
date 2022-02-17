function [fvw, Cvw, fpw, Cpw]=cohneuralwhisk(tvm, vm, spktime, t_whisk, whiskangle)

% first, get the fitlered whisking data:

 whisk=whiskdecomposej(whiskangle, t_whisk, [0.001:0.001:5]);
 
 whisk=whisk.filtsignal;
 twhisk= [0.001:0.001:5];
 
spks=zeros(1, length(whisk));
 
if ~isempty(spktime) && ~isempty(find(spktime>0))
spks(round(spktime*1000))=1;
end;
spks=spks(1:length(whisk))';

 % downsampling
 vm=detrend(removeAP(vm', 10000, 4, 5));
 vm=resample(vm, 1, 10);
 tvm=resample(tvm, 1, 10);
 
params.Fs=1000;% 1000 Hz, frame rate
params.pad=2;
params.fpass=[2 40];
params.tapers=[2 length(whisk)/1000 1];
params.trialave=1;
params.err=[2 0.05];
movingwin=[0.5 0.05];% moving window, 0.5 s long, 0.05 s steps

vm=vm(1:length(whisk));

[Cvw, phivw, S12, S1, S2, fvw]=coherencyc(vm, whisk, params);

 [Cpw,phipw,S12,S1,S2,fpw,zerosp,confC,phistd,Cerr]=coherencycpt(spks,whisk,params)
 