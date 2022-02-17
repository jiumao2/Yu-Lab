load('t1t2.mat')
figure;
plot(event_time,ones(length(event_time),1),'x')
hold on
plot(react_time,ones(length(react_time),1),'.')
hold on

index = matching_time(react_time,event_time);
index
plot(event_time(index),ones(length(event_time(index)),1),'o')