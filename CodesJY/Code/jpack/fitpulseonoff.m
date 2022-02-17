function [aout, ypred1, ypred2, delta1, delta2]=fitpulseonoff(t1, v1, t2, v2, Iinj, a0, fixedRs)

if isempty(fixedRs)
mdf1=@(a, x)Iinj*a(1)*(1-exp(-x/a(2)))+Iinj*a(3)*(1-exp(-x/a(4)));
mdf2=@(a, x)Iinj*a(1)*(exp(-x/a(2)))+Iinj*a(3)*(exp(-x/a(4)));

x_cell={t1, t2};
y_cell={v1, v2};
mdf_cell={mdf1, mdf2};

[aout,r,J,Sigma] = ...
    nlinmultifit(x_cell, y_cell, mdf_cell, a0);

% Calculate model predictions and confidence intervals
[ypred1,delta1] = nlpredci(mdf1,t1,aout,r,'covar',Sigma);
[ypred2,delta2] = nlpredci(mdf2,t2,aout,r,'covar',Sigma);

% Calculate parameter confidence intervals
ci = nlparci(aout,r,'Jacobian',J);

else
mdf1=@(a, x)Iinj*fixedRs*(1-exp(-x/a(1)))+Iinj*a(2)*(1-exp(-x/a(3)));
mdf2=@(a, x)Iinj*fixedRs*(exp(-x/a(1)))+Iinj*a(2)*(exp(-x/a(3)));

x_cell={t1, t2};
y_cell={v1, v2};
mdf_cell={mdf1, mdf2};

[aout,r,J,Sigma] = ...
    nlinmultifit(x_cell, y_cell, mdf_cell, a0);

% Calculate model predictions and confidence intervals
[ypred1,delta1] = nlpredci(mdf1,t1,aout,r,'covar',Sigma);
[ypred2,delta2] = nlpredci(mdf2,t2,aout,r,'covar',Sigma);

% Calculate parameter confidence intervals
ci = nlparci(aout,r,'Jacobian',J);    
end;

% Plot results
ha3=subplot(2, 2, [2 4]);
hold all;
box on;
scatter(t1,v1, 'k');
scatter(t2,v2, 'k');

plot(t1,ypred1,'Color','blue', 'linewidth', 2);
plot(t1,ypred1+delta1,'Color','blue','LineStyle',':');
plot(t1,ypred1-delta1,'Color','blue','LineStyle',':');
plot(t2,ypred2,'Color',[0 0.5 0], 'linewidth', 2);
plot(t2,ypred2+delta2,'Color',[0 0.5 0],'LineStyle',':');
plot(t2,ypred2-delta2,'Color',[0 0.5 0],'LineStyle',':');

if ~isempty(fixedRs)
    aout=[fixedRs aout];
end;
text(20, -5, num2str(round(10*aout(1:2))/10))
text(20, -10, num2str(round(10*aout(3:4))/10))