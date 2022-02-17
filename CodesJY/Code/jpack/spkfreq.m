function [twin, f, spkpower]=spkfreq(tvm,spk)

tvm=tvm/1000;

if size(vm, 2)>size(vm, 1);
    vm=vm';
end;

vm=removeAP(vm, 10000, 4, 5);

vm=detrend(vm, 'constant');

vm=medfilt1(vm, 10);

% take whisking angle data, sliding window 500 ms, plot the frequency
% content. 

params.Fs=10000;% 1000 Hz, frame rate
params.fpass=[2 80];
params.tapers=[3 5];
params.trialave=1;
params.err=[2 0.05];
movingwin=[0.25 0.05];% moving window, 0.5 s long, 0.05 s steps


[S0, f0, Serr]=mtspectrumc(vm, params)

[S, t, f]=mtspecgramc(vm, movingwin, params);

figure(315);clf(315)

subplot(3, 1, 1)
plot(tvm, vm);
set(gca, 'xlim', [tvm(1) tvm(end)]);

subplot(3, 1, 2)
plot(f0, S0)

subplot(3, 1, 3)
imagesc(t, f, log(S'))
set(gca, 'ydir', 'normal', 'xlim', [tvm(1) tvm(end)])
twin=t;
f=f;
vmpower=S;
