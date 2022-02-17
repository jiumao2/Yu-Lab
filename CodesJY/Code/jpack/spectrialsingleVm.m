function specout=spectrialsingleVm(vm, frange, params)
% length of ve or vb has to be several secends. 
 
Fs=10000;
 
if nargin<3
    frange=[0 100];
end;
 
vm=removeAP(vm, Fs, 10, 4);

if size(vm, 1)>=0.5*Fs;
    vm=vm(1:0.5*Fs*floor(size(vm, 1)/(Fs/2)), :); % 0.5 sec
    vm=reshape(vm, 0.5*Fs, []);
 else
     vm(end+1:0.5*Fs)=median(vm);
end;

% clean the data
vm=clean(vm, Fs, frange);
%
% design the data tapers, etc
% spectral concentration: [-4Hz 4 Hz];. 
if nargin<3
    params=struct('tapers', [4 3], 'pad', 1, 'Fs', 4096, 'fpass', frange, 'err', [2, .05], 'trialave', 1);
end;
% get the Fourier projection
[S,f,Serr]=mtspectrumc(vm,params);

specout.f=f;
specout.S=S;
specout.Serr=Serr;
specout.params=params;

function Vout=clean(Vin, Fs, frange)
Vin=removeAP(Vin, Fs, 8, 4);
Vin=detrend(Vin, 'constant');
Vin=sgolayfilt(Vin, 3, 41);
Vin=resample(Vin, 4096, Fs);
paramsclean=struct('tapers',[3 5],'pad',1,'Fs',4096,'fpass',[0 200],'err',0,'trialave',1);
%Vin=rmlinesc(Vin, paramsclean, .05, 'n', 60);
if frange(2)>100
    Vin=rmlinesc(Vin, paramsclean, .05, 'y', 120);
    Vin=rmlinesc(Vin, paramsclean, .05, 'y', 180);
end;
Vout=Vin;

