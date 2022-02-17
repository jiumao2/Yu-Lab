function Vth=detectSpikeonset(T, selectedtrials, ratio_dvdt, vbound, dvdtlow,  checkAP, toplot)
% vbound=[threhold_lowest_possible peak_lowest_possible peak_highest_possible size_smallest_possible]
if nargin<7
    toplot=1;
end;

% Vthlow is the lower bound
[vm, ~, t]=findvmtrials(T, selectedtrials);
Vth.threshold=cell(1, length(selectedtrials));
Vth.trials=selectedtrials;
Vth.spktime=cell(1, length(selectedtrials));
Vth.grand=[];
Vth.spks=[];
t=t';
for i=1:length(selectedtrials)
    Vth.threshold{i}=[];
    v=vm(:, i);
    dv=smooth([0; diff(v)/(median(diff(t)))], 'moving', 3);
    std_dv=std(dv);
    ddv=smooth([0; diff(dv)/(median(diff(t)))], 'moving', 3);
    
    figure(22); clf
    set(22, 'units', 'normalized', 'position',[0.05 0.1 0.3 0.75])
    
    ha1=subplot(3, 1, 1)
    set(ha1, 'nextplot', 'add', 'xlim', [min(t) max(t)], 'xgrid', 'on','ygrid', 'on')
    title([num2str(i) '/' num2str(length(selectedtrials))])
    hpv=plot(t, v, 'k');
    hold on;
    
    ha2=subplot(3, 1, 2)
    set(ha2, 'nextplot', 'add', 'xlim', [min(t) max(t)], 'xgrid', 'on')
    plot(t, dv);
    
    line([t(1) t(end)], [10*std_dv 10*std_dv], 'color', 'r');
    line([t(1) t(end)], [-10*std_dv -10*std_dv], 'color', 'r');
    line([t(1) t(end)], [0 0], 'color', 'k');
    
    ha3=subplot(3, 1, 3)
    set(ha3, 'nextplot', 'add', 'xlim', [min(t) max(t)], 'xgrid', 'on')
    plot(t, ddv)
    line([-0.05 0.1], [0 0], 'color', 'k')
    linkaxes([ha1, ha2, ha3], 'x')
    
    [dvpeaks, peaklocs]=findpeaks(dv, 'minpeakheight', dvdtlow, 'minpeakdistance', 10);
    
    if any(dvpeaks)
        
        plot(ha2, t(peaklocs), dvpeaks, '^g')
        line([t(1) t(end)], [median(dvpeaks)*ratio_dvdt median(dvpeaks)*ratio_dvdt], 'color', 'g')
        
        for j=1:length(dvpeaks)
            
            if peaklocs(j)-10>0 && peaklocs(j)+10<=length(dv)
                indpeaks=[peaklocs(j)-10:peaklocs(j)+10];
                
                % find out where the peaks are
                tfirst=find(dv(indpeaks)>=median(dvpeaks(j))*ratio_dvdt);
                
                % find the onset
                
                if find(diff(tfirst)>1)
                    tfirst_on=tfirst([1; 1+find(diff(tfirst)>1)]);
                    tfirst_on(v(indpeaks(tfirst_on))<vbound(1) | v(indpeaks(tfirst_on))>vbound(3))=[];
                else
                    tfirst_on=tfirst(1);
                    tfirst_on(v(indpeaks(tfirst_on))<vbound(1) | v(indpeaks(tfirst_on))>vbound(3))=[];
                end;
                
                if ~isempty(tfirst_on)
                    
                    thcandidate=indpeaks(tfirst_on(1));
                    
                    if thcandidate-10>0 && thcandidate+20<=length(v) && max(v(thcandidate-5: thcandidate+5))>vbound(2) && max(v(thcandidate-5: thcandidate+5))-v(thcandidate)>vbound(4)
                    
                    plot(ha1, t(thcandidate), v(thcandidate), 'rx');
                    plot(ha2, t(thcandidate), dv(thcandidate), 'rx');
                    plot(ha3, t(thcandidate), ddv(thcandidate), 'rx')
                    
                    %
                    %             % find out where the peak ddv is
                    %
                    %             thcandidate2=find(ddv==(max(ddv(thcandidate-3:thcandidate+3))));
                    %
                    %             APonset=t(thcandidate2); % this is where PSP started.
                    %
                    %             plot(ha2, t(thcandidate2), dv(thcandidate2), 'm', 'marker',  'o', 'markersize', 5)
                    %             plot(ha3, t(thcandidate2), ddv(thcandidate2), 'm', 'marker',  'o', 'markersize', 5)
                    %             plot(ha1, t(thcandidate2), v(thcandidate2), 'm', 'marker', 'o', 'markersize', 5)
                    %
                    set(ha1, 'xlim', [t(thcandidate)-0.005 t(thcandidate)+0.005]);
                    set(ha2, 'xlim', [t(thcandidate)-0.005 t(thcandidate)+0.005]);
                    set(ha3, 'xlim', [t(thcandidate)-0.005 t(thcandidate)+0.005]);
                    %
                    %             axes(ha1)
                    %             text(t(thcandidate2)+0.002, mean(get(ha1, 'ylim')), num2str(v(thcandidate2)))
                    %             text(t(thcandidate2)-0.002, mean(get(ha1, 'ylim')), [num2str(j) '/' num2str(length(tfirst_on))])
                    %
                    checkAP=0;
                    if checkAP
                        if rem(length(Vth.grand), 10)==9
                            bb2='no';
                            bb2=questdlg('Keep checking AP?', 'Accept checking' );
                            if strcmp(bb2, 'No')
                                checkAP=0
                            else
                                checkAP=1;
                            end;
                        end;
                        
                        
                        bb='no';
                        bb=questdlg('accept onset?', 'Accept onset' );
                        
                        if strcmp(bb, 'No')
                            [x, y]=ginput(1);
                            APonset=x*1000;
                            line([x x], get(ha1, 'ylim'));
                            axes(ha2);
                            line([x x], get(ha2, 'ylim'));
                            axes(ha3);
                            line([x x], get(ha3, 'ylim'));
                            [~, thcandidate]=min(abs(t-x));
                        end;
                    end;
                    if toplot
                    pause(0.01)
                    end;
                    % write down threshold and spike times
                    Vth.threshold{i}=[Vth.threshold{i} v(thcandidate)];
                    Vth.spktime{i}=[Vth.spktime{i} t(thcandidate)];
                    Vth.grand=[Vth.grand v(thcandidate)];
                    Vth.spks=[Vth.spks v(thcandidate-10: thcandidate+20)];
                end;
                end;
            end;
        end;
    end;
    plot(ha1, Vth.spktime{i}, Vth.threshold{i}, 'r.', 'markersize', 5);
    set(ha1, 'xlim', [min(t) max(t)]);
    set(ha2, 'xlim', [min(t) max(t)]);
    set(ha3, 'xlim', [min(t) max(t)]);

    drawnow
end;
Vth.tspks=[-10:20]'/10;
Vth.ratio_dvdt=ratio_dvdt;
Vth.Vbound=vbound';
Vth.Vboundtype={'threhold_lowest_possible'; 'peak_lowest_possible'; 'peak_highest_possible'; 'size_smallest_possible'};
filename=['Vth' T.cellNum T.cellCode '.mat'];
% cd (['C:\Work\Projects\BehavingVm\Data\Vmdata\' T.cellNum]);
save (filename, 'Vth')
if ~isempty(Vth.spks)
    figure;
    subplot(2, 1, 1)
    plot(Vth.grand, 'k.')
    subplot(2, 1, 2)
    plot(Vth.tspks, Vth.spks, 'color', [.75 .75 .75])
    
    print(gcf, '-dtiff',  'spike_threshold');
end;
