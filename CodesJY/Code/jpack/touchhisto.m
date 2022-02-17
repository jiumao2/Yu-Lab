function [touch_histo, t_touch]=touchhisto(T, touch, contacts, ind, wid)

% here i need to figure out the touch histogram.
touch_trials=touch.TrialNum(ind);
touch_onsets=touch.onset(ind);

t_touch=[-.1:0.001:.2];

touch_histo=zeros(length(ind), length(t_touch));


for i=1:length(ind)
    ic=contacts{T.trialNums==touch_trials(i)};
    ialltouches=ic.segmentInds{1+wid}(:, 1);
    ialltouches_off=ic.segmentInds{1+wid}(:, 2);
    itouch=touch.onset(ind(i));
    idur=touch.dur(ind(i));
    
    % fill in zeroes for primary touch
    touch_histo(i, t_touch>0 & t_touch<=idur)=1;
    
    ialltouch_times=T.trials{T.trialNums==touch_trials(i)}.whiskerTrial.time{1+wid}(ialltouches)-itouch;
    ialltouch_times_off=T.trials{T.trialNums==touch_trials(i)}.whiskerTrial.time{1+wid}(ialltouches_off)-itouch;

    if any(ialltouch_times>0 & ialltouch_times<0.2)
        secondaryinds=find(ialltouch_times>0 & ialltouch_times<0.2);
        for k=1:length(secondaryinds)
            touch_histo(i, t_touch>ialltouch_times(secondaryinds(k)) &  t_touch<=ialltouch_times_off(secondaryinds(k)))=1;
        end;
    end;
    
end;
% 
% figure; 
% plot(t_touch, mean(touch_histo, 1))
% %plot(t_touch(t_touch>=-.05&t_touch<=0.1), mean(touch_histo(:, t_touch>=-.05&t_touch<=0.1), 1))
% xlabel('time from touch (s)')
% ylabel('Probability of touch')
% set(gca, 'xlim', [-.05 .1])

