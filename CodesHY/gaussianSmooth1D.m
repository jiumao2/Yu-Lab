function data_out = gaussianSmooth1D(data, t, gaussianKernelWidth, varargin)
    t_out = t;
    if nargin>3
        for k = 1:2:size(varargin,2)
            switch varargin{k}
                case 'tOut'
                    t_out = varargin{k+1};
                otherwise
                    error('wrong argument!');
            end
        end
    end
    data_out = zeros(size(data));

    idx_good = find(~isnan(data));
    data_good = data(idx_good);
    t_good = t(idx_good);

    for k = 1:length(t_out)
        t_new = t_good-t_out(k);
        kernel = normpdf(t_new,0,gaussianKernelWidth);

        % omit nan values
        data_out(k) = dot(kernel,data_good)./(sum(kernel));
    end
    
    if length(t_out) == length(t) && all(t_out == t)
        data_out(isnan(data)) = NaN;
    end
end