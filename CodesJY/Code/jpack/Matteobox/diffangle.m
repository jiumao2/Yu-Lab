function f = diffangle(c1,c2)
% DIFFANGLE phase difference between two complex numbers or vectors
%
% diffangle(c1,c2) gives a number between -pi and pi
%
% 1998 Matteo Carandini
% part of the Matteobox toolbox

c1 = c1(:);
c2 = c2(:);

p1 = angle(c1);
p2 = angle(c2);

f = angle(exp(i*p1)./exp(i*p2));
