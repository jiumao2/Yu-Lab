t=[0:0.01:10];

yt=exp(-t/1.5);

figure;



t2=t(find(t>0.6));
yt2 = yt(find(t>0.6));



ratio = sum(yt2(t2>2))/(sum(yt2(t2<2)))