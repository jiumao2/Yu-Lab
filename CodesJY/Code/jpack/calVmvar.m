function vmvar=calVmvar(celllist, type, Len, ampth, tosave)

% calculate Vm variance for whisking and non-whisking segments that are
% larger than a threshold, e.g., 0.25 ms
% non-whisking and whisking states not necessarily conenct
% also calculate mean Vm and spk level. 


Ncell=length(celllist);
Fs=10000;

vmvar_whisking=cell(1, Ncell);
vmvar_nonwhisking=cell(1, Ncell);

vmdc_whisking=cell(1, Ncell);
vmdc_nonwhisking=cell(1, Ncell);

spkdc_whisking=cell(1, Ncell);
spkdc_nonwhisking=cell(1, Ncell);

vmepoch_whisking=cell(1, Ncell);
vmepoch_nonwhisking=cell(1, Ncell);

vmepoch_whisking_tag=cell(1, Ncell);
vmepoch_nonwhisking_tag=cell(1, Ncell);

vmepoch_whisking_S=cell(1, Ncell);
vmepoch_nonwhisking_S=cell(1, Ncell);

for i=1:Ncell
    clear whiskmod
    cd(['C:\Work\Projects\BehavingVm\Data\Vmdata\' celllist{i}]);
    load('whiskingvmout_contacts.mat');
    wvo=whiskingvmout;
    file=dir('trial_array*.mat');
    if length(file)>1
        error(celllist{i})
    end;
    load(file.name)
    
    switch type
        case 'normal'
            nstrinums=wvo.nostimtrialnums;
            whiskampall=wvo.whiskamp.nostim;
        case 'stim'
            nstrinums=wvo.stimtrialnums;
            whiskampall=wvo.whiskamp.stim;
        otherwise
            error('check type');
    end;
    
    whiskingstamp=wvo.whiskingstamp;
    nonwhiskingstamp=wvo.nonwhiskingstamp;
    vmvar_all{i}=[];
    vmvar_allshort{i}=[];
    for j=1:length(nstrinums)
        tri=nstrinums(j);
        [vm_tri, aom, tvm, fp_tri]=findvmtrials(T, tri);
        
        fp_tri=sgolayfilt(fp_tri, 3, 41);
        spk_tri=spikespy(vm_tri, Fs, wvo.spkth, 4);
        vm_tri=sgolayfilt(removeAP(vm_tri, Fs, wvo.spkth, 6, 100, 8), 3, 41);
       
        vmvar_all{i}=[vmvar_all{i} var(reshape(vm_tri(5000+1:4500*10), 10000, []), 0, 1)];
        vmvar_allshort{i}=[vmvar_all{i} var(reshape(vm_tri(5000+1:4500*10), Len(1)*10000, []), 0, 1)];
        
        whiskamptri=whiskampall(:, j);
        twhisk=wvo.twhisk;
        
        if any(find(tri==whiskingstamp(:, 1)))
            epochs=whiskingstamp(tri==whiskingstamp(:, 1), [2 3]);
            nepochs=size(epochs, 1);
            for k=1:nepochs
                if  epochs(k, 2)-epochs(k, 1)>Len(1)
                    ind=[round(epochs(k, 1)*Fs):round(epochs(k, 2)*Fs)];
                    if mean(whiskamptri(twhisk>=epochs(k, 1) & twhisk<=epochs(k, 2)))>=ampth
                          vmepoch_whisking{i}(end+1)={vm_tri(ind)};
                          if prctile(vm_tri(ind), 90)<-25
                          vmvar_whisking{i}=[vmvar_whisking{i}, var(vm_tri(ind))];
                          vmdc_whisking{i}=[vmdc_whisking{i} mean(vm_tri(ind))];
                          spkdc_whisking{i}=[spkdc_whisking{i}; spk_tri(ind)];
                          vmepoch_whisking_tag{i}=[vmepoch_whisking_tag{i}; tri, epochs(k, 1) epochs(k, 2)];
                          specout=spectralsingleVm(vm_tri(ind), [0 100]);
                          vmepoch_whisking_S{i}=[vmepoch_whisking_S{i} specout.S];
                          end;
                    end;
                end;
            end;
        end;
        
        if any(find(tri==nonwhiskingstamp(:, 1)))
            epochs=nonwhiskingstamp(tri==nonwhiskingstamp(:, 1), [2 3]);
            nepochs=size(epochs, 1);
            for k=1:nepochs
                if  epochs(k, 2)-epochs(k, 1)>Len(2)
                    ind=[round(epochs(k, 1)*Fs):round(epochs(k, 2)*Fs)];
                    if prctile(vm_tri(ind), 90)<-25
                        vmepoch_nonwhisking{i}(end+1)={vm_tri(ind)};
                        vmvar_nonwhisking{i}=[vmvar_nonwhisking{i}, var(vm_tri(ind))];
                        vmdc_nonwhisking{i}=[vmdc_nonwhisking{i} mean(vm_tri(ind))];
                        spkdc_nonwhisking{i}=[spkdc_nonwhisking{i}; spk_tri(ind)];
                        vmepoch_nonwhisking_tag{i}=[ vmepoch_nonwhisking_tag{i}; tri, epochs(k, 1) epochs(k, 2)];
                        specout=spectralsingleVm(vm_tri(ind), [0 100]);
                        vmepoch_nonwhisking_S{i}=[vmepoch_nonwhisking_S{i} specout.S];
                    end;
                end;
            end;
        end;
    end;
    
    figure(88); set(gcf, 'units', 'centimeters', 'position', [4 4 6 6], 'paperpositionmode', 'auto', 'color', 'w')
    clf(88)
    plot(specout.f, mean(vmepoch_nonwhisking_S{i}, 2), 'k');
    hold on
    if ~isempty(vmepoch_whisking_S{i})
    plot(specout.f, mean(vmepoch_whisking_S{i}, 2), 'r');
    end;
    hold off
    
    xlabel('Freq (Hz)')
    ylabel('Vm power')
    
    legend('nonwhisking', 'whisking')
    title(type)
end;

vmvar.celllist=celllist;
vmvar.vmlen=Len;
vmvar.varall= vmvar_all;
vmvar.varallshort=vmvar_allshort;
vmvar.varwhisking=vmvar_whisking;
vmvar.varnonwhisking=vmvar_nonwhisking;
vmvar.whiskingepochs=vmepoch_whisking;
vmvar.nonwhiskingepochs=vmepoch_nonwhisking;
vmvar.vmdc_whisking=vmdc_whisking;
vmvar.vmdc_nonwhisking=vmdc_nonwhisking;
vmvar.spkdc_whisking=spkdc_whisking;
vmvar.spkdc_nonwhisking=spkdc_nonwhisking;
vmvar.f=specout.f;
vmvar.SVm_whisking= vmepoch_whisking_S;
vmvar.SVm_nonwhisking= vmepoch_nonwhisking_S;
vmvar.vmwhisking_tag=vmepoch_whisking_tag;
vmvar.vmnonwhisking_tag=vmepoch_nonwhisking_tag;

['var whisking/' 'var_nonwhisking/var_all/var_allshort' ' ' num2str(median(vmvar_whisking{1})) '/' num2str(median(vmvar_nonwhisking{1})) '/' num2str(median(vmvar_all{1})) '/' num2str(median(vmvar_allshort{1}))]
save(['vmvar' '_' vmvar.celllist{1} type '.mat'], 'vmvar')
export_fig(88, ['Vmpower' '_' type], '-tiff', '-pdf', '-eps')
% cd ('C:\Work\Projects\BehavingVm\Data\Groupdata')
% save vmvar vmvar