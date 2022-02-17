function calculate_noise_population

cells

notes={'JY1045', 'JY1041', 'JY1009', 'JY0995', 'JY1139'};

tic
for i=1:size(celllist, 1)
    cd(['C:\Work\Projects\BehavingVm\Data\Vmdata\' celllist{i, 1}]);
    eval(['noise' celllist{i, 1}])
    clear T
end;

toc







