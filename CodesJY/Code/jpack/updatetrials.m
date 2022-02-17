function [nogo, nogo_correct, go, go_correct]=updatetrials(nogo, nogo_correct, go, go_correct, x)

gomin=median(x.poletag);

nogo(1)=nogo(1)+sum(x.trialcount_nostim(x.poletag<gomin)); 
nogo(2)=nogo(2)+sum(x.trialcount_stim(x.poletag<gomin));

nogo_correct(1)=nogo_correct(1)+sum(x.trialcorrect_nostim(x.poletag<gomin));
nogo_correct(2)=nogo_correct(2)+sum(x.trialcorrect_stim(x.poletag<gomin));

go=[go(1)+sum(x.trialcount_nostim(x.poletag>=gomin)) go(2)+sum(x.trialcount_stim(x.poletag>=gomin))];
go_correct=[go_correct(1)+sum(x.trialcorrect_nostim(x.poletag>=gomin)) go_correct(2)+sum(x.trialcorrect_stim(x.poletag>=gomin))];
    
