function aomonset=findaomonset(aom, th)

if nargin<2
    th=3;
end;

n=size(aom, 2);

aomonset=zeros(1, n);

for i=1:n
    aomonset(i)=find(aom(:, i)>th, 1, 'first')/10000;
end;

