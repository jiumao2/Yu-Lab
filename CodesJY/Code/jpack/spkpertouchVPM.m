function per_touch=spkpertouchVPM(x)
% 5.14.2016
% x = 
% 
%        all: [1x91 double]
%      thist: [1x91 double]
%     raster: [495x91 double]


post=[0 25];
pre=[-25 0];

spkmat=x.raster;
t=x.thist;

inds_post=find(t>=post(1) & t<=post(2));
inds_pre=find(t>=pre(1) & t<=pre(2));

k=length(inds_post)/length(inds_pre);

per_touch(1)=(length(find(spkmat(:, inds_post)))-k*length(find(spkmat(:, inds_pre))))/(size(spkmat, 1));

ap=@(x)(length(find(x(:, inds_post)))-length(find(x(:, inds_pre))))/(size(x, 1));
ci_per_touch=bootci(1000, ap, spkmat);

per_touch([2 3])=ci_per_touch;