function ci = computeCI_PETH(spxtimes, trigtimes, params, gaussian_kernel, n_boot)
if nargin<5
    n_boot = 1000;
end

pre = params.pre;
post = params.post;
trigtimes = round(trigtimes);

binwidth = params.binwidth; % also in msec

n_events = length(trigtimes); % time of events

if size(spxtimes,1)~=1
    spxtimes = spxtimes';
end

if size(trigtimes,2)~=1
    trigtimes = trigtimes';
end

spxtimes = round(spxtimes(spxtimes>0.5)); 
tspkall = 1:max([spxtimes trigtimes'])+5000;
spkall = zeros(1, length(tspkall));
spkall(spxtimes) = 1; 
trialspxmat = zeros(pre+post+1, n_events);

for i = 1:n_events 
    if trigtimes(i)-pre>0 && trigtimes(i)+post < max(tspkall)
        trialspxmat(:, i) = spkall (trigtimes(i)-pre : trigtimes(i)+post);
    else
       trialspxmat(:, i) = NaN*ones(pre+post+1, 1);
    end
end

[~, inan]=find(isnan(trialspxmat));

spkmat = trialspxmat;
spkmat(:, inan)=[];
trialspxmat = spkmat;
trigtimes(inan) = [];

% [spkhistos, ts] = spikehisto(spkmat, 1000, (pre+post)/binwidth);
% ts = ts*1000 - pre;
%  
% psth = spkhistos;
% tpsth = ts; 

ci = bootci(n_boot,...
    @(x)smoothdata(spikehisto(x', 1000, (pre+post)/binwidth), 'gaussian', gaussian_kernel/params.binwidth*5),...
    spkmat');
end
