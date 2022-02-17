function gaussFilter=gaussian_kernel(width_s, fs_s)

if nargin==0
    width_s=0.01; % 10 ms
    fs_s=0.001; % also 10 ms
end;

sigma=round(width_s*fs_s);
sz=sigma*5;

x=linspace(-sz/2, sz/2, sz);


x = linspace(-sz / 2, sz / 2, sz);
gaussFilter1 = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = fs_s*(gaussFilter1 / sum (gaussFilter1)); % normalize
 



% figure(55);
% clf
% plot(gaussFilter1, 'ko-')
% hold on
% plot(gaussFilter, 'r^-')
% 
% hold on


% y = rand(500,1);
% yfilt = conv (y, gaussFilter, 'same');
% 
