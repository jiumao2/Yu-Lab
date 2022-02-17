function per_touch=spkpertouch(touch, type, post, pre)

% based on PSTH, derive spikes evoked per touch. 
% psthdata

if nargin<3
    post=[0 50]/1000;
    pre=[-25 0]/1000;
end;
    

if nargin<2
    type='traditional';
end;

switch type
    
    case 'traditional'

if ~isfield(touch, 'ind_stim') 
    touch.ind_stim=[];
end;

if length(touch.ind_stim)>5
    inds_post=find(touch.t>=0.004 & touch.t<=0.054);
    inds_pre=find(touch.t>=-0.025 & touch.t<=0);
    
    ind_nostim=touch.ind_nostim;
    ind_stim=touch.ind_stim;
    
    per_touch.nostim=(length(find(touch.Spk(inds_post, ind_nostim)))-2*length(find(touch.Spk(inds_pre, ind_nostim))))/length(ind_nostim);
    per_touch.stim=(length(find(touch.Spk(inds_post, ind_stim)))-2*length(find(touch.Spk(inds_pre, ind_stim))))/length(ind_stim);
    
    per_touch.nostimspkall=touch.Spk(inds_post, ind_nostim);
    per_touch.nostimspkpre=touch.Spk(inds_pre, ind_nostim);
    
    per_touch.stimspkall=touch.Spk(inds_post, ind_stim);
    per_touch.stimspkpre=touch.Spk(inds_pre, ind_stim);
    
    ap=@(x)(length(find(x(:, inds_post)))-length(find(x(:, inds_pre))))/(size(x, 1));
    
    ci_nostim=bootci(1000, ap, transpose(touch.Spk(:, ind_nostim)));
    ci_stim=bootci(1000, ap, transpose(touch.Spk(:, ind_stim)));
    
    per_touch.nostim([2 3])=ci_nostim';
    per_touch.stim([2 3])=ci_stim';
    
    per_touch.nostimraw=(length(find(touch.Spk(inds_post, ind_nostim))))/length(ind_nostim);
    per_touch.stimraw=(length(find(touch.Spk(inds_post, ind_stim))))/length(ind_stim);
    
    % add FF calculation
    nostim_spks= full(sum(touch.Spk(inds_post, ind_nostim), 1));
    stim_spks=   full(sum(touch.Spk(inds_post, ind_stim), 1));
    if mean(nostim_spks)>0
        per_touch.nostimFF= var(nostim_spks)/mean(nostim_spks);
    else
        per_touch.nostimFF=1;
    end;
    
    if mean(stim_spks)>0
        per_touch.stimFF= var(stim_spks)/mean(stim_spks);
    else
        per_touch.stimFF=1;
    end;
    
    ffcal=@(x)var(x)/mean(x);
    
    bs_nostimFF=bootstrp(2000, ffcal, nostim_spks); bs_nostimFF(isnan(bs_nostimFF))=1;
    bs_stimFF=bootstrp(2000, ffcal, stim_spks); bs_stimFF(isnan(bs_stimFF))=1;
    
    per_touch.nostimFF([2 3])=prctile(bs_nostimFF, [2.5 97.5]);
    per_touch.stimFF([2 3])=prctile(bs_stimFF, [2.5 97.5]);
    
    
else
    inds_post=find(touch.t>=post(1) & touch.t<=post(2));
    inds_pre=find(touch.t>=pre(1) & touch.t<=pre(2));
    
    ind_nostim=[touch.ind_ret touch.ind_prot];
    
    per_touch.nostim=(length(find(touch.Spk(inds_post, ind_nostim)))-2*length(find(touch.Spk(inds_pre, ind_nostim))))/length(ind_nostim);
    per_touch.stim=[];
    
    per_touch.nostimspkall=touch.Spk(inds_post, ind_nostim);
    per_touch.nostimspkpre=touch.Spk(inds_pre, ind_nostim);
    
    per_touch.stimspkall=[];
    per_touch.stimspkpre=[];
    
    ap=@(x)(length(find(x(:, inds_post)))-length(find(x(:, inds_pre))))/(size(x, 1));
    
    ci_nostim=bootci(1000, ap, transpose(touch.Spk(:, ind_nostim)));
    ci_stim=[];
    
    per_touch.nostim([2 3])=ci_nostim';
    
    per_touch.nostimraw=(length(find(touch.Spk(inds_post, ind_nostim))))/length(ind_nostim);
    per_touch.stimraw=[];
    
    % add FF calculation
    nostim_spks= full(sum(touch.Spk(inds_post, ind_nostim), 1));
    stim_spks=   [];
    if mean(nostim_spks)>0
        per_touch.nostimFF= var(nostim_spks)/mean(nostim_spks);
    else
        per_touch.nostimFF=1;
    end;
    
    per_touch.stimFF=[];
    
    ffcal=@(x)var(x)/mean(x);
    
    bs_nostimFF=bootstrp(2000, ffcal, nostim_spks); bs_nostimFF(isnan(bs_nostimFF))=1;
    bs_stimFF=[];
    
    per_touch.nostimFF([2 3])=prctile(bs_nostimFF, [2.5 97.5]);
    
    
end;

    case 'new'
        
    inds_post=find(touch.t>=post(1) & touch.t<=post(2));
    inds_pre=find(touch.t>=pre(1) & touch.t<=pre(2));
    
    k=length(inds_post)/length(inds_pre);
    
    ind_nostim=[touch.ind_all];
    
    per_touch.nostim=(length(find(touch.Spk(inds_post, ind_nostim)))-k*length(find(touch.Spk(inds_pre, ind_nostim))))/length(ind_nostim);
    
    per_touch.nostimspkall=touch.Spk(inds_post, ind_nostim);
    
    for i=1:length(ind_nostim)
        per_touch.nostimspkpost_trialbytrial(i)=length(find(touch.Spk(inds_post, ind_nostim(i))));
    end;
    per_touch.nostimspkpre=touch.Spk(inds_pre, ind_nostim);
    
  
    ap=@(x)(length(find(x(:, inds_post)))-k*length(find(x(:, inds_pre))))/(size(x, 1));
    
    ci_nostim=bootci(1000, ap, transpose(touch.Spk(:, ind_nostim)));
    
    per_touch.nostim([2 3])=ci_nostim';
    
    per_touch.nostimraw=(length(find(touch.Spk(inds_post, ind_nostim))))/length(ind_nostim);
    
    % add FF calculation
    nostim_spks= full(sum(touch.Spk(inds_post, ind_nostim), 1));
    if mean(nostim_spks)>0
        per_touch.nostimFF= var(nostim_spks)/mean(nostim_spks);
    else
        per_touch.nostimFF=1;
    end;
        
    ffcal=@(x)var(x)/mean(x);
    
    bs_nostimFF=bootstrp(2000, ffcal, nostim_spks); bs_nostimFF(isnan(bs_nostimFF))=1;
    
    per_touch.nostimFF([2 3])=prctile(bs_nostimFF, [2.5 97.5]);
    
end;

