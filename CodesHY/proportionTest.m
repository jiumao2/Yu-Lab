function [p_value, z_value] = proportionTest(px, nx, py, ny, tail)
if nargin<5
    tail = 'both';
end
p_hat = (px*nx + py*ny)./(nx+ny);

z_value = (px-py)./sqrt(p_hat*(1-p_hat)*(1/nx+1/ny));
if strcmpi(tail, 'both')
    p_value = 2*(1-normcdf(abs(z_value)));
elseif strcmpi(tail, 'left')
    p_value = normcdf(z_value);
elseif strcmpi(tail, 'right')
    p_value = 1-normcdf(z_value);
else
    error('Wrong tail!');
end

end