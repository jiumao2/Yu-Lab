function avgdata = CommonAvg(chs)

% Jianing Yu 5/17/2021
% first, we want to have a look at all Chs and remove chs showing
% abnormally large fluctuations

% According to Ludwig et al., we need to select chns that are "good"
% We can calculate the RMS 
% chs is an array composed of all available channels, eg., [1:32];

avgdata     = [];
tic
for i =1:length(chs)
    ich = chs(i);
    load(['chdat' num2str(ich) '.mat']);
    if i==1
        avgdata = data;
    else
        avgdata=(avgdata*(i-1)+data)/i;
    end;
end;
CommonAvgData = round(avgdata);
save('CommonAvgData.mat', 'CommonAvgData', 'chs');
toc