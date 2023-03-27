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
    for k = 1:length(t_out)
        t_new = t-t_out(k);
        kernel = normpdf(t_new,0,gaussianKernelWidth);
        data_out(k) = dot(kernel,data)./(sum(kernel));
    end
    data_out(isnan(data_out)) = 0;
end