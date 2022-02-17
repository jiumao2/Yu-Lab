function per_touch=spkpertouchnormal(touch)

% based on PSTH, derive spikes evoked per touch. 
% psthdata
inds_post=find(touch.t>=0.005 & touch.t<=0.025);
inds_pre=find(touch.t>=-0.02 & touch.t<=0);

% ind_nostim=[touch.ind_prot touch.ind_ret];

ind_nostim1=touch.ind_prot;
ind_nostim2=touch.ind_ret;

per_touch.nostim_prot=  (length(find(touch.Spk(inds_post, ind_nostim1)))-length(find(touch.Spk(inds_pre, ind_nostim1))))/length(ind_nostim1);
per_touch.nostim_ret=   (length(find(touch.Spk(inds_post, ind_nostim2)))-length(find(touch.Spk(inds_pre, ind_nostim2))))/length(ind_nostim2);

per_touch.nostimspkall_prot=touch.Spk(inds_post, ind_nostim1);
per_touch.nostimspkpre_prot=touch.Spk(inds_pre, ind_nostim1);

per_touch.nostimspkall_ret=touch.Spk(inds_post, ind_nostim2);
per_touch.nostimspkpre_ret=touch.Spk(inds_pre, ind_nostim2);

ap=@(x)(length(find(x(:, inds_post)))-length(find(x(:, inds_pre))))/(size(x, 1));

ci_nostim_prot=bootci(1000, ap, transpose(touch.Spk(:, ind_nostim1)));
ci_nostim_ret=bootci(1000, ap, transpose(touch.Spk(:, ind_nostim2)));

per_touch.nostim_prot([2 3])=ci_nostim_prot';
per_touch.nostim_ret([2 3])=ci_nostim_ret';

per_touch.nostimraw_prot=(length(find(touch.Spk(inds_post, ind_nostim1))))/length(ind_nostim1);
per_touch.nostimraw_ret=(length(find(touch.Spk(inds_post, ind_nostim2))))/length(ind_nostim2);
