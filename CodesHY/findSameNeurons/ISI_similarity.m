function out = ISI_similarity(x1,x2)
    cc = corrcoef(x1, x2);
    out = atanh(cc(1, 2));    
end