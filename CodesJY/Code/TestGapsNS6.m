function gaps=TestGapsNS6(ns)

% time stamps of segments
sr = ns.MetaTags.SamplingFreq;
ts = ns.MetaTags.Timestamp;

gaps = zeros(1, length(ts)-1);

for i = 1:length(gaps)
    gaps(i) = ts(i+1)-(ts(i)+ns.MetaTags.DataPoints(i));
end;


x1 = ns.Data{1}(1, :);
x2 = ns.Data{2}(1, :);


figure;

x1end = x1(end-10:end);
x2beg = x2(1:10);
figure;
plot([x1end], 'ko-');
hold on
plot(x2beg, 'ro-')