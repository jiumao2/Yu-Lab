function output = isIntersect(P1,P2,Q1,Q2) 


if max(P1(1),P2(1)) < min(Q1(1),Q2(1)) ...
        || max(Q1(1),Q2(1)) < min(P1(1),P2(1)) ...
        || max(P1(2),P2(2)) < min(Q1(2),Q2(2)) ...
        || max(Q1(2),Q2(2)) < min(P1(2),P2(2))
    output = false;
    return;
end
    
P1Q1 = Q1 - P1; P1P2 = P2 - P1; P1Q2 = Q2 - P1;
P1Q1(:,3) = 0; P1P2(:,3) = 0; P1Q2(:,3) = 0;
a1 = cross(P1Q1,P1P2);
a2 = cross(P1Q2,P1P2);
if sign(a1(3)*a2(3))>=0
    output = false;
    return
end

temp=P1;P1=Q1;Q1=temp;
temp=P2;P2=Q2;Q2=temp;

P1Q1 = Q1 - P1; P1P2 = P2 - P1; P1Q2 = Q2 - P1;
P1Q1(:,3) = 0; P1P2(:,3) = 0; P1Q2(:,3) = 0;
a1 = cross(P1Q1,P1P2);
a2 = cross(P1Q2,P1P2);
if sign(a1(3)*a2(3))>=0
    output = false;
    return
end

output = true;

end
