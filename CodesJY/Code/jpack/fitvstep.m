function [re, te, rin, tin]=fitvstep(v, Iinj, tmax, stepbeg, fixedRs, toplot)

% fit vm step to find out these parameters

% current injection starts from t=0
% current is shown as I

if nargin<6
    toplot=1;
end;

if isempty(fixedRs)
    fixedRs=0;
end;

if nargin<2
    Iinj=-0.1;
end;
v=v(stepbeg:end, :);
v=mean(v, 2);

t=[0:size(v, 1)-1]'/10;

v=v-v(1);

v1=v(t<=tmax);
t1=t(t<=tmax);
v2=v(t>=tmax);
t2=t(t>=tmax)-tmax;

if toplot
    figure; ha1=subplot(2, 1, 1); plot(t1, v1, 'ko')
    title('onset')
    ha2=subplot(2, 1, 2); plot(t2, v2, 'ko')
    title('offset')
end

% here is the function

if fixedRs==0
    vx=@(a, x)Iinj*a(1)*(1-exp(-x/a(2)))+Iinj*a(3)*(1-exp(-x/a(4)));
    a0=[150,1, 40, 4];
    
    [aout, r, j, cov, mse]=nlinfit(t1, v1, vx, a0);
    
    aout;
    vsim=nlpredci(vx, t1,aout, r,'Covar',cov);
    if toplot
        axes(ha1);
        hold on
        plot(t1, vsim, 'r-', 'linewidth', 2)
        
        text(10, -5, num2str(aout))
    end;
    
    re=aout(1);
    te=aout(2);
    rin=aout(3);
    tin=aout(4);
    
else
    
    vx=@(a, x)Iinj*fixedRs*(1-exp(-x/a(1)))+Iinj*a(2)*(1-exp(-x/a(3)));
    a0=[1, 50, 5];
    
    try
    
    [aout, r, j, cov, mse]=nlinfit(t1, v1, vx, a0);
    
    
    aout;
    vsim=nlpredci(vx, t1,aout, r,'Covar',cov);
    if toplot
        axes(ha1);
        hold on
        plot(t1, vsim, 'r-', 'linewidth', 2)
        text(10, -5, num2str(aout))
    end;
    
    re=fixedRs;
    te=aout(1);
    rin=aout(2);
    tin=aout(3);
    
    catch err
        re=fixedRs;
        te=NaN;
        rin=NaN;
        tin=NaN;
        
    end;
    
end;

%%
vx2=@(b, x)Iinj*b(1)*(exp(-x/b(2)))+Iinj*b(3)*(exp(-x/b(4)));
b0=[100, 0.5, 40, 10];
try
    [bout, r, j, cov, mse]=nlinfit(t2, v2, vx2, b0);
    bout;
    vsim2=nlpredci(vx2, t2,bout, r,'Covar',cov);
    if toplot
        axes(ha2);
        hold on
        plot(t2, vsim2, 'r-', 'linewidth', 2)
        text(10, -10, num2str(bout))
    end;
end;

if toplot
    
    set(gcf, 'userdata', v)
    saveas(gcf, 'vpulsefitting', 'fig')
    export_fig(gcf, 'vpulsefitting', '-tiff');
end;
