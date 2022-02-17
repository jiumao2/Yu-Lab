function PressOut = ExtractMovementParams(filename)
% filename = 'Denny_20210430_Press.xlsx';

[num,txt,raw] = xlsread(filename) ;
 
inddash = strfind(filename, '_');

Press.RatName          =   filename(1:inddash(1)-1);
Press.SessionName   =   raw{2, 2};
Press.PressIndex        =   cell2mat(raw(2:end, 3));
Press.PressTime         =   cell2mat(raw(2:end, 4));

Outcome =  raw(2:end, 5);
Press.Outcome = 10*ones(1, length(Outcome));
Press.OutcomeLabels = {'Correct: 1', 'Premature: -1', 'Late: 0'};

for i =1:length(Outcome)
    switch Outcome{i}
        case 'Correct'
           Press.Outcome(i) = 1;
        case 'Premature'
            Press.Outcome(i) = -1;
        case 'Late'
            Press.Outcome(i) = 0;
    end;
end;
Press.FPs                   =   cell2mat(raw(2:end, 6));

RTs =  raw(2:end, 7);
for i =1:length(RTs)
    if isnumeric(RTs{i})
        Press.RTs(i) = RTs{i};
    else
        Press.RTs(i) = NaN;
    end;
end;

FlexOnset =  raw(2:end, 8);
for i =1:length(FlexOnset)
    if isnumeric(FlexOnset{i})
        Press.FlexOnset(i) = FlexOnset{i};
    else
        Press.FlexOnset(i) = NaN;
    end;
end;

TouchOnset =  raw(2:end, 9);
for i =1:length(TouchOnset)
    if isnumeric(TouchOnset{i})
        Press.TouchOnset(i) = TouchOnset{i};
    else
        Press.TouchOnset(i) = NaN;
    end;
end;

ReleaseOnset =  raw(2:end, 10);
for i =1:length(ReleaseOnset)
    if isnumeric(ReleaseOnset{i})
        Press.ReleaseOnset(i) = ReleaseOnset{i} - Press.FPs(i);
    else
        Press.ReleaseOnset(i) = NaN;
    end;
end;

PressPaw =  raw(2:end, 11);
Press.PawUsage = {'Left: 1', 'Right: 2', 'Both: 3'};
Press.PressPaw =  NaN*ones(1, length(PressPaw));

for i =1:length(PressPaw)
    switch PressPaw{i}
        case 'L'
            Press.PressPaw(i) = 1;
        case 'R'
            Press.PressPaw(i) = 2;
        case 'B'
            Press.PressPaw(i) = 3;
    end;
end;

HoldPaw =  raw(2:end, 12);
Press.HoldPaw =  NaN*ones(1, length(HoldPaw));
for i =1:length(HoldPaw)
    switch HoldPaw{i}
        case 'L'
            Press.HoldPaw(i) = 1;
        case 'R'
            Press.HoldPaw(i) = 2;
        case 'B'
            Press.HoldPaw(i) = 3;
    end;
end;

ReleasePaw =  raw(2:end, 13);
Press.ReleasePaw =  NaN*ones(1, length(ReleasePaw));
for i =1:length(ReleasePaw)
    switch ReleasePaw{i}
        case 'L'
            Press.ReleasePaw(i) = 1;
        case 'R'
            Press.ReleasePaw(i) = 2;
        case 'B'
            Press.ReleasePaw(i) = 3;
    end;
end;

PressOut = Press;

hf = figure(22); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 14 7], 'paperpositionmode', 'auto','renderer','Painters' )

ha1 =  axes('unit', 'centimeters', 'position', [1.5 2 6 4], 'nextplot', 'add', 'xlim', [0.5 4.5], 'ylim', [-800 800],...
    'ytick', [-2000:200:800], 'xtick', [1 2 3 4], 'xticklabel', {'Flex', 'Touch', 'Release1', 'Release2'});
ylabel('Time from press onset (ms)')

line([0 5], [0 0], 'color', 'k', 'linestyle', '--')

tFlex = PressOut.FlexOnset(~isnan(PressOut.FlexOnset));
plot(1+0.25*(rand(1, length(tFlex))-0.5), tFlex, 'ko', 'markersize', 4, 'markerfacecolor','k', 'markeredgecolor', 'w')
line([-0.2 0.2]+1, [median(tFlex) median(tFlex)], 'color', 'c', 'linewidth', 2)

tTouch = PressOut.TouchOnset(~isnan(PressOut.TouchOnset));
plot(2+0.25*(rand(1, length(tTouch))-0.5), tTouch, 'ko', 'markersize', 4, 'markerfacecolor','k', 'markeredgecolor', 'w')
line([-0.2 0.2]+2, [median(tTouch) median(tTouch)], 'color', 'c', 'linewidth', 2)

tReleaseOnset = PressOut.ReleaseOnset(~isnan(PressOut.ReleaseOnset) & Press.Outcome>=0);

plot(3+0.25*(rand(1, length(tReleaseOnset))-0.5), tReleaseOnset, 'ko', 'markersize', 4, 'markerfacecolor','k', 'markeredgecolor', 'w')
line([-0.2 0.2]+3, [median(tReleaseOnset) median(tReleaseOnset)], 'color', 'c', 'linewidth', 2)
 
% correct release
tReleaseOnsetCorrect = PressOut.ReleaseOnset;
tReleaseOnsetCorrect = tReleaseOnsetCorrect(Press.Outcome==1);
tReleaseOnsetCorrect = tReleaseOnsetCorrect(~isnan(tReleaseOnsetCorrect));

plot(4+0.25*(rand(1, length(tReleaseOnsetCorrect))-0.5), tReleaseOnsetCorrect, 'ko', 'markersize', 4, 'markerfacecolor','k', 'markeredgecolor', 'w')
line([-0.2 0.2]+4, [median(tReleaseOnsetCorrect) median(tReleaseOnsetCorrect)], 'color', 'c', 'linewidth', 2)
 
% paw preference
ha2 =  axes('unit', 'centimeters', 'position', [9.5 2 4 3], 'nextplot', 'add', 'xlim', [0 12], 'ylim', [0 100],...
    'ytick', [0:50:100], 'xtick', [1 2 3 5 6 7 9 10 11], 'xticklabel', {'L', 'R', 'B'});

ylabel('Percentage (%)')

PressPaw_L = 100*length(find(Press.PressPaw ==1))/length(Press.PressPaw);
PressPaw_R = 100*length(find(Press.PressPaw ==2))/length(Press.PressPaw);
PressPaw_B = 100*length(find(Press.PressPaw ==3))/length(Press.PressPaw);

hbar11 = bar([1], [PressPaw_L ]);
set(hbar11, 'Facecolor', 'c')
hbar12 = bar([2], [ PressPaw_R ]);
set(hbar12, 'Facecolor', 'b')
hbar13 = bar([3], [ PressPaw_B]);
set(hbar13, 'Facecolor', 'y')


HoldPaw_L = 100*length(find(Press.HoldPaw ==1))/length(Press.HoldPaw);
HoldPaw_R = 100*length(find(Press.HoldPaw ==2))/length(Press.HoldPaw);
HoldPaw_B = 100*length(find(Press.HoldPaw ==3))/length(Press.HoldPaw);

hbar21 = bar([5], [HoldPaw_L ]);
set(hbar21, 'Facecolor', 'c')
hbar22 = bar([6], [ HoldPaw_R ]);
set(hbar22, 'Facecolor', 'b')
hbar23 = bar([7], [ HoldPaw_B]);
set(hbar23, 'Facecolor', 'y')


ReleasePaw_L = 100*length(find(Press.ReleasePaw ==1))/length(Press.ReleasePaw);
ReleasePaw_R = 100*length(find(Press.ReleasePaw ==2))/length(Press.ReleasePaw);
ReleasePaw_B = 100*length(find(Press.ReleasePaw ==3))/length(Press.ReleasePaw);

hbar31 = bar([9], [HoldPaw_L ]);
set(hbar31, 'Facecolor', 'c')
hbar32 = bar([10], [ HoldPaw_R ]);
set(hbar32, 'Facecolor', 'b')
hbar33 = bar([11], [ HoldPaw_B]);
set(hbar33, 'Facecolor', 'y')

ha3 =  axes('unit', 'centimeters', 'position', [9.5 5.5 4 1], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10]);
axis off
text(1, 5, PressOut.RatName)
text(1, 1, num2str(PressOut.SessionName))

tosavename=  ['ManualTracking' '_' num2str(PressOut.SessionName)];

print (hf,'-dpng', tosavename);
print (hf,'-depsc2', tosavename);
