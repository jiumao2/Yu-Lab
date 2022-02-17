function testingvmvar(cellname)
varnormal=calVmvar({cellname}, 'normal', [0.25 0.25], 1, 1);
varstim=calVmvar({cellname}, 'stim', [0.25 0.25], 1, 1);

figure;

subplot(1, 2, 1)
plot(varnormal.f, mean(varnormal.SVm_nonwhisking{1}, 2), 'k');
hold on
plot(varnormal.f, mean(varstim.SVm_nonwhisking{1}, 2), 'b');
title('non-whisking')

subplot(1, 2, 2)
plot(varnormal.f, mean(varnormal.SVm_whisking{1}, 2), 'k');
hold on
if ~isempty(varstim.SVm_whisking{1})
    plot(varnormal.f, mean(varstim.SVm_whisking{1}, 2), 'b');
end;
title('whisking')