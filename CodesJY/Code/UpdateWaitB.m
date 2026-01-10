function b = UpdateWaitB(b);
 
FP2              =        zeros(1, length(b.TimeTone));
IndFP2        =        zeros(1, length(b.TimeTone));

for i =1:length(b.TimeTone)
    itone = b.TimeTone(i); % in sec
    i_press = find(itone - b.PressTime>0, 1, 'last');
    t_trigger = (itone - b.PressTime(i_press))*1000; % in msec
    FP2(i) = t_trigger;
    IndFP2(i) = i_press;
end;

% note that only correct press will lead to an increaase of FP.
% thus incorrect presses have the same FP as the next press

for i =1:length(b.PressTime)
    
    if isempty(find(IndFP2==i)) % premature trials or other trials
        
        ind_fp =  find(IndFP2>i, 1, 'first');
        if ~isempty(ind_fp)
            b.FPs(i) =FP2(ind_fp);
        else
            b.FPs(i) = FP2(end);
        end;
    else
        b.FPs(i) = FP2(IndFP2==i);
    end;
    
end; 