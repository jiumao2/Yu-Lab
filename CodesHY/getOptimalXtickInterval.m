function out = getOptimalXtickInterval(interval)
    count = 0;
    x = interval;
    if x >= 10
        while x >= 10
            count = count + 1;
            x = x/10;
        end
    elseif x < 1
        while x < 1
            count = count-1;
            x = x*10;
        end
    end
    
    num_top = ceil(interval/10.^count);
    
    if num_top>6
        out = 10.^(count+1);
    elseif num_top == 4 || num_top == 6
        out = 5*10.^count;
    else
        out = num_top*10.^count;
    end
end