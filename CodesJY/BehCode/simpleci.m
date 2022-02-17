function ciout = simpleci(RTi)
CIFcn = @(x,p)prctile(x,abs([0,100]-(100-p)/2));  % confidence interval function


    RTi_log = (RTi);
    bootstrp_log = bootstrp(1000, @mean, RTi_log);
    RTi_logci = CIFcn (bootstrp_log, 95);
    ciout= RTi_logci;