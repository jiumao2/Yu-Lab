function spkout=sdf(tspk, spkin, kernel_width)
% 2019, 2021
% Jianing Yu
% tspk is time, in sec
% spkin takes the form of spike 1 and no spike 0, spkin is a sparse matrix.
% spkout is the kernal product of spkin
% firing rate can be estimated by averaging spkout
% K(t)=exp(-t^2/(2*s^2))/(sqrt(2*pi)*s);
% s is the kernel width, e.g., 10 ms


if nargin<3
    kernel_width=1;
end;

f=round(1/(tspk(2)-tspk(1))); % sampling rate

k=gaussian_kernel(kernel_width/1000, f); % the area under the curve is 1

if size(spkin, 1)~=length(tspk)
    spkin=spkin';  % dim1 spikes, dim2 trial nums
end;

if size(k, 1)<size(k, 2)
    k=k';
end;

spkin2=[];
for ni=1:size(spkin, 2)
    spktemp=full(spkin(:, ni));
    spkin2(:, ni)=conv(spktemp, k, 'same');
end;

spkout=spkin2;

% figure;
% subplot(3, 1, 1)
% plot(tspk, spkin)
% set(gca, 'xlim', [-50 50]/1000)
% subplot(3, 1, 2)
% plot(tspk, spkout)
% set(gca, 'xlim', [-50 50]/1000)
% subplot(3, 1, 3)
% plot(tspk, mean(spkout, 2),'linewidth',  2,'color', 'k')
% set(gca, 'xlim', [-50 50]/1000)
