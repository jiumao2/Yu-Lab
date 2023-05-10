function out = autocorrelogram_similarity(x1,x2)
    x1 = x1./max(x1);
    x2 = x2./max(x2);
    cc = corrcoef(x1, x2);
    out = atanh(cc(1, 2));
end