figure;
p1 = [-1,-1];
p2 = [1,1];
plot([-1,1],[-1,1],'x-')
xlim([-1.2,1.2])
ylim([-1.2,1.2])
hold on

set(gcf,'renderer','opengl')

q1 = ginput(1);
hold on
plot(q1(1),q1(2),'x')
xlim([-1.2,1.2])
ylim([-1.2,1.2])
q2 = ginput(1);
hold on
plot(q2(1),q2(2),'x')
plot([q1(1),q2(1)],[q1(2),q2(2)],'-')
xlim([-1.2,1.2])
ylim([-1.2,1.2])
p1
p2
q1
q2
disp(isIntersect(p1,p2,q1,q2))