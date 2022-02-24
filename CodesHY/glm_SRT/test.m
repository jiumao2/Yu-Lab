to_choose = 1:length(Kernels.names);
a0 = myGlmfit(Kernels,[]);
for n_kernel = 1:1:length(Kernels.names)
a = cell(nchoosek(length(Kernels.names),n_kernel),1);
ind_this = nchoosek(to_choose,n_kernel);

for k = 1:nchoosek(length(Kernels.names),n_kernel)
    a{k} = myGlmfit(Kernels,ind_this(k,:));
end

b = zeros(nchoosek(length(Kernels.names),n_kernel),1);
for k = 1:nchoosek(length(Kernels.names),n_kernel)
    b(k) = mean([a{k}]);
end
[~,min_idx] = min(b);
ind_this(min_idx,:)
figure;plot(a0,a{min_idx},'x');
axis('equal')
hold on
xlim_this = get(gca,'XLim');
plot(xlim_this,xlim_this)

signrank(a0,a{min_idx},'alpha',0.05,"tail",'left')
a0 = a{min_idx};
drawnow;
end