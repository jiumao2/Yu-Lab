function [ err, pars ] = fit_hyper_ratio(cs,resps,nn)
% FIT_HYPER_RATIO fits hyper_ratio to the data
%
% 	[ err, pars ] = fit_hyper_ratio(cs,resps)
% 	[ err, pars ] = fit_hyper_ratio(cs,resps,nn) uses nn starting points (Default:3)
%
% 1998 Matteo Carandini
% part of the Matteobox toolbox

if nargin < 3
   nn = 3;
end

cs = cs(:);
resps = resps(:);

if any(~finite(cs)) | any(~finite(resps))
   error('yoooooooo');
end

if size(cs)~=size(resps)
   error('yo');
end

% -------------- initial values

if any(cs==0)
   R0 = mean(resps(cs==0));
else 
   R0 = 0;
end
Rmax = max(resps);
n = 2.5;
sigma = mean(cs);

%--------------- hyper_ratio pars are [ Rmax, sigma, n, R0 ]
[ err pars ] = fitit('hyper_ratio',resps,...
   [ 0 eps 0 0 ], [ Rmax, sigma, n, R0 ], [ 2*Rmax max(cs) 10 Rmax ], [0 1e-4 1e-4 nn], cs );


% figure;
% plot(cs,resps,'o');
% hold on
% cc = linspace(min(cs),max(cs));
% plot(cc,hyper_ratio(pars,cc),'k-');
