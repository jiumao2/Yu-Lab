function t_in_b = Map2TimeInB(tEvent,  tRef, tRefInB, Ind);

% Jianing Yu
% 5/19/2021
% tEvent: time of events recorded in computer x 
% tRef: reference events recorded in computer x
% tRefInB: time of reference events recorded in MED 
% Ind: index of tRef in tRefInB

t_in_b = zeros(1, length(tEvent)); % this is the frame time in behavior time domain
for i =1:length(tEvent)
    % find nearest tRef
    [~, indmin] = min(abs(tEvent(i)-tRef));
    t_in_b(i) = tEvent(i) - tRef(indmin) + tRefInB(Ind(indmin));
end;

