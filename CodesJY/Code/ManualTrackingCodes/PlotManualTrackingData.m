TrackingResults = [
{'Will_20210214_Press.xlsx'}
{'Will_20210215_Press.xlsx'}
{'Will_20210216_Press.xlsx'}
{'Will_20210217_Press.xlsx'}
{'Will_20210218_Press.xlsx'}

{'Will_20210227_Press.xlsx'}
{'Will_20210228_Press.xlsx'}
{'Will_20210301_Press.xlsx'}
{'Will_20210302_Press.xlsx'}
{'Will_20210312_Press.xlsx'}
{'Will_20210313_Press.xlsx'}
{'Will_20210315_Press.xlsx'}
{'Will_20210316_Press.xlsx'}
% {'Will_20210317_Press.xlsx'}
% {'Will_20210325_Press.xlsx'}
% {'Will_20210326_Press.xlsx'}
% {'Will_20210327_Press.xlsx'}
% {'Will_20210329_Press.xlsx'}
% {'Will_20210330_Press.xlsx'}

];

Post = {'Will_20210227_Press.xlsx'};
IndPost =  find(strcmp(TrackingResults, Post));
IndPreLesion = [IndPost-4:IndPost-1];
IndPostLesion = [IndPost:IndPost+3];

PrefPaw = 1;  % rightM1/q.acid/ZQ/2021.2.19
piledata = 0;

if piledata
    for i = 1:length(TrackingResults)
        TrackingResults{i}
        if i == 1
            PressOut = ExtractMovementParams(TrackingResults{i})
        else
            PressOut(i) = ExtractMovementParams(TrackingResults{i})
        end;
    end;
    save PressOut PressOut
else
    load('PressOut.mat')
end;

PlotManualTrackingPressOut(PressOut, PrefPaw, IndPost, IndPreLesion, IndPostLesion)
