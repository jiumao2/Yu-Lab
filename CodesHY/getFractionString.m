function out = getFractionString(x)
for y = 1:10000
    if abs(1/y-x) <= 1e-8 
        if y<=4
            out = num2str(1/y);
        else
            out = ['1/', num2str(y)];
        end
        return
    end
end
end