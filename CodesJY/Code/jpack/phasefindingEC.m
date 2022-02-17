
function phaseout=phasefindingEC(datain, type, tosave)

% take the product of neuralphase to determine the preferred phase of avg
% Vm

if nargin<2
    tosave=0;
end;

switch type
    case 'whiskcorr'
        % this is the product of function "neuralphase". it contains many
        % elements for futher processing
        thist=datain.thist;
        whiskspkhist_ns=datain.whiskspkhist_nostim;
        angle_avg=resample(mean(datain.whiskavg_nostim, 2), 400, 401);
        datainnew1=[angle_avg, whiskspkhist_ns'];
        datainnew2=[datain.phasebincenters' nanmean(datain.spkphase_nostim, 2)];

        phaseout_angle=phasefindingEC(datainnew1, 'angle')
        phaseout_phase=phasefindingEC(datainnew2, 'phase')
    
    case 'angle'
        x=datain(:, 1); % this is angle
        y=datain(:, 2);  % this is spike rate
        t=[-200:200]';
        ind=find(t>=-50 & t<=50);
        x=x(ind); y=y(ind); t=t(ind);
        % first, fit the angle
        dsf=@(a, x)a(1)*cos(2*pi*x/a(2))+a(3);
        a0(1)=(max(x)-min(x))/2;
        [dum, indtmin]=min(x);
        tmin=abs(t(indtmin));
        a0(2)=2*tmin;
        a0(3)=mean(x);
        trange=[-100:100]';
        [ahat, r, J, cov. mse]=nlinfit(t, x, dsf, a0);
        
        ahat
        
        figure(1); clf(1)
        plot(t, x, 'bo');
        hold on
        plot(trange, dsf(ahat, trange), 'r');
        
        hold off
        
        
        % fit spike histogram:
        
        dsf2=@(a, x)a(1)*cos(2*pi*x/ahat(2)-a(2))+a(3);
        a0=[];
        
        a0(1)=1;
        % a0(2)=ahat(3);
        a0(2)=0;
        a0(3)=mean(y);
        
        
        [ahat2, r, J, cov, mse]=nlinfit(t, y, dsf2, a0);
        
        ahat2
        
        ph=ahat2(2)*180/pi;
        
        if ahat2(1)<0
            
            if ph<0
                ph=180+ph;
            else
                ph=ph-180
            end;
            
        end;
        
        if ph>180
            ph=rem(ph, 360);
        elseif ph<-180
            ph=ph+360;
        end;
        
        ph
        
        Spkmod=abs(2*ahat2(1))
        modratio=Spkmod/ahat2(3)
        
        dsfx=@(a, x)a(1)*cos(2*pi*x/a(2))+a(3);
        
        ax(1)=ahat2(3);
        ax(2)=ahat(2);
        ax(3)=ahat2(3);
        
        hf=figure(2);clf(hf)
        set(hf, 'unit', 'centimeters', 'position', [4 4 10 10], 'paperpositionmode', 'auto');
        bar(t, y, 'b');
        hold on
        plot(trange, dsf2(ahat2, trange), 'r');
        plot(trange, dsfx(ax, trange), 'k', 'linewidth', 2);
        legend('spk', 'spk cos-fit')
        
        xlabel('Time (ms)')
        ylabel('Spike rate (spk/s)')
        hold off
        set(gca, 'xlim', [-50 50])
        
        pause
        
        phaseout.dataorg=datain;
        phaseout.prefphase=ph;
        phaseout.spkmod=Spkmod;
        phaseout.spkbase=ahat2(3);
        phaseout.spkmodratio=modratio;
        
        
        
    case 'phase'
        
        x=datain(:, 1); % this is phase
        y=datain(:, 2);  % this is spike rate
        
        dsf3=@(a, x)a(1)*cos(x-a(2))+a(3);
        a0=[];
        a0(1)=1;
        a0(2)=0;
        a0(3)=mean(y);
        
        xrange2=[-pi:0.1:pi]';
        
        [ahat3, r, J, cov, mse]=nlinfit(x, y,  dsf3, a0);
        
        ph2=ahat3(2)*180/pi;
        
        if ahat3(1)<0
            
            if ph2<0
                ph2=180+ph2;
            else
                ph2=ph2-180;
            end;
            
        end;
        
        if ph2>180
            ph2=rem(ph2, 360);
        elseif ph2<-180
            ph2=rem(ph2, 360);
            
            if ph2<-180
                ph2=ph2+360;
            end;
        end;
        
        ph2
        Spkmod=2*ahat3(1)
        Spkbase=ahat3(3)
        spkmodratio=Spkmod/Spkbase
        
        hf2=figure(3); clf(hf2)
        set(hf2, 'unit', 'centimeters', 'position', [30 4 10 10], 'paperpositionmode', 'auto');
        plot(x, y, 'bo');
        hold on
        plot(xrange2, dsf3(ahat3, xrange2), 'r');
        
        legend('Spike', 'cos-fit')
        
        xlabel('Phase')
        ylabel('Spike rate(spk/s)')
        hold off
        pause
        phaseout.dataorg=datain;
        phaseout.prefphase=ph2;
        phaseout.spkmod=Spkmod;
        phaseout.spkbase=Spkbase;
        phaseout.spkmodratio=spkmodratio;
        
    otherwise
        return;
end;

