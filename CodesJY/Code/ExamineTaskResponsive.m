function StatOut = ExamineTaskResponsive(t, spkmat)

% Jianing Yu
% 8/28/2021

% check spk rate 

% count spikes on 250-ms segements
% use ANOVA to test if there are significant spk rate modulation 


tdiv = 250;   % 250 ms binds

tmin = t(1);
tmax = t(end);
t_edges = linspace(tmin, tmax, (tmax-tmin)/tdiv+1);  % these are the edges of time bins
spks_bins = zeros(size(spkmat, 2), length(t_edges)-1);
t_bins = zeros(1,  length(t_edges)-1);

for i =1:size(spks_bins, 2)
    t_bins(i) = mean([t_edges(i), t_edges(i+1)]);
    inds = find(t>=t_edges(i) & t<t_edges(i+1));
    spkmat_i = spkmat(inds, :);
    spk_bins(:, i) = sum(spkmat_i, 1)';
end;

% figure;
% plot(t_bins, spk_bins, 'ko');
 
[pval, ~, stats] = anova1(spk_bins, [], "off");

[~, ind_max] = max(stats.means);

tpeak = t_bins(ind_max);

StatOut.pval            =       pval;
StatOut.tpeak          =      tpeak; 
StatOut.stats           =      stats;
StatOut.time            =      t;

close all;