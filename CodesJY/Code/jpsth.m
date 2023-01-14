function [psth, tpsth, trialspxmat, tspkmat, trigtimes] = jpsth(spxtimes, trigtimes, params)
% JY 8.9.2020
% spktimes in ms
% trigtimes in ms
% params.pre, params.post, params.binsize

pre = params.pre;
post = params.post;
trigtimes = round(trigtimes);

binwidth = params.binwidth; % also in msec

n_events = length(trigtimes); % time of events

spxtimes                 =      round(spxtimes); 
tspkall                     =       [1:max([spxtimes trigtimes'])+5000];
spkall                      =      zeros(1, length(tspkall));
spkall(spxtimes)      =     1; 
trialspxmat               =     zeros(pre+post+1, n_events);

to_del = []; 
for i = 1:n_events 
    if trigtimes(i)-pre>0 && trigtimes(i)+post < max(tspkall)
        trialspxmat(:, i) = spkall (trigtimes(i)-pre : trigtimes(i)+post);
    else
       trialspxmat(:, i) = NaN*ones(pre+post+1, 1);
    end;
end;


tspkmat = [-pre:post];

 [~, inan]=find(isnan(trialspxmat));

 spkmat = trialspxmat;
 spkmat(:, inan)=[];
 trialspxmat = spkmat;
 trigtimes(inan) = [];
 
[spkhistos, ts ] = spikehisto(spkmat,1000, [pre+post]/binwidth);
ts = ts*1000 - pre;
 
psth = spkhistos;
tpsth = ts; 