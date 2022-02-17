function PosOut = ExtractPosData(PosFileName, StimFileName)
    
Pos = importdata(PosFileName);

XYPos = zeros(length(Pos), 4);
IndTracked = zeros(1, length(Pos));

for iframe = 1 : length(Pos)
    iPos = strsplit(Pos{iframe}, ' ');
    if ~strcmp(iPos{1}(2:4), 'NaN') % return a real position data
        IndTracked(iframe) = 1;
        FrameTime = sum(sscanf(iPos{4}(1:end-1), '%f:%f:%f').*[3600; 60;1]) + str2num(iPos{5}(1:end-2))/1000;        
        XYPos(iframe, :) = [str2num(iPos{1}(2:end-1))  str2num(iPos{2}) FrameTime iframe];
    end;
end;
XYPosOrg = XYPos;
% XYPos = XYPos(IndTracked==1, :);

%% This is when the paw enters user-defined ROI
StimPos = importdata(StimFileName);
StimTimes = zeros(length(StimPos), 2);

for istim = 1:length(StimPos)
    iStimTime = strsplit(StimPos{istim}, ' ');
    StimTimes(istim, 1) = sum(sscanf(iStimTime{2}(1:end-1), '%f:%f:%f').*[3600; 60;1]) + str2num(iStimTime{3}(1:end-1))/1000;
    % identify the index in XYPos
    [~, StimTimes(istim, 2) ] = min(abs(XYPosOrg(:, 3) - StimTimes(istim, 1))); 
end;

PosOut.PosTime =  XYPos;
PosOut.StimTime = StimTimes;
PosOut.Latencyms = 1000*(StimTimes(:, 1) - XYPosOrg(StimTimes(:, 2), 3));

figure(40); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 24 24], 'paperpositionmode', 'auto' )
plot(XYPos(:, 1), XYPos(:, 2), 'k+', 'linewidth', 1);
set(gca, 'nextplot', 'add', 'ydir', 'reverse', 'xlim', [0 400], 'ylim', [0 400], 'unit', 'centimeters', 'position',[2 2 20 20])
hold on

plot(XYPos(StimTimes(:, 2), 1), XYPos(StimTimes(:, 2), 2), 'o', 'color', 'c', 'linewidth', 1)

xlabel('X position')
ylabel('Y position')

% making clusters

XYPosStim = [XYPos(StimTimes(:, 2), 1) XYPos(StimTimes(:, 2), 2)];

clc;
Nclus = input('Enter the number of clusters: ');

ColorClus = {'r', 'm', 'y'};

for i=1:Nclus
    
    imhappy = 0;
    
    while ~imhappy
        sprintf('Draw the perimeter of cluster #%2.0d', i)
        roi_selected = drawfreehand();
        ind_within{i} = inpolygon(XYPos(StimTimes(:, 2), 1), XYPos(StimTimes(:, 2), 2), roi_selected.Position(:, 1), roi_selected.Position(:, 2));
        plot(XYPosStim(ind_within{i}, 1), XYPosStim(ind_within{i}, 2), '*', 'color', ColorClus{i})
        
        reply = input('Are you happy? Y/N [Y]', 's');
        if isempty(reply)
            reply = 'Y';
        end;
        if strcmp(reply, 'Y')  ||  strcmp(reply, 'y')
            imhappy = 1;
        else
            imhappy =0;
        end
    end;
end;

PosOut.StimPos = XYPosStim;
PosOut.StimClus = ind_within;

xx=strsplit(PosFileName, '\');
pos_name = ['PosData_' xx{end}(1:end-4)];

save(pos_name, 'PosOut')



