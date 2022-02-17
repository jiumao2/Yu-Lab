function EventOut = AlignMED2BR(EventOut, bMED)

% 3/3/2021 Jianing Yu
% EventOut comes from BlackRock's digital input
% bMED is the b array coming from MED data
% Time of some critical behavioral events (e.g., Trigger stimulus) needs to be mapped to EventOut
% Alignment is performed using press onset data
% Alignment of each trigger stimulus needs to be adjusted to the preceding press
% onset

% Lever presses and releases recorded in blackrock
leverpress_ephys        =     EventOut.Onset{find(strcmp(EventOut.EventsLabels, 'LeverPress'))};
leverrelease_ephys     =     EventOut.Offset{find(strcmp(EventOut.EventsLabels, 'LeverPress'))};

% Lever presses, FP, releases, and correct index recorded in MED
leverpress_MED          =     bMED.PressTime*1000;  % turn press time to ms
leverrelease_MED       =     bMED.ReleaseTime*1000; % lever releases recorded in MED
Trigger_MED               =     bMED.TimeTone*1000; % trigger time recorded in MED

CorrectIndex_MED      =     bMED.Correct; % index of correct press-release responses
LateIndex_MED           =     bMED.Late;
PrematureIndex_MED =     bMED.Premature;
FPs_MED                    =     bMED.FPs;

figure(30); clf
subplot(2, 2, 1)
plot(leverpress_MED, 5, 'ro');
text(1, 6, 'LeverMED', 'color', 'r')
hold on
plot(leverpress_ephys, 4, 'ko')
text(1, 3, 'LeverEphys', 'color', 'k')
set(gca, 'ylim', [1 9])

n_pressMED                     =     length(leverpress_MED);  % presses in MED
n_pressEphys                   =     length(leverpress_ephys);  % blackrock recorded presses
IndexEphysMED               =     zeros(1, n_pressEphys);

% find out the corresponding index of each ephys presses in MED

IndexEphysMED               =       findseqmatch(leverpress_MED, leverpress_ephys);
leverpress_EphysMED     =       leverpress_MED(IndexEphysMED); % this is the lever press time in MED during ephys recording

figure(45); clf
set(gcf, 'units', 'centimeters', 'position', [3 10, 20, 10])

plot(leverpress_MED, 4, 'ko')
text(leverpress_ephys(1)-500, 4.2, 'MED press')
hold on
plot(leverpress_ephys, 5, 'r^');
text(leverpress_ephys(1)-500, 5.2, 'Blackrock press')
plot(leverpress_EphysMED, 4.5, 'ro');
text(leverpress_ephys(1)-500, 4.7, 'Mapped')
line([leverpress_EphysMED; leverpress_ephys'], [4.5 5], 'color', 'b')
line([leverpress_EphysMED; leverpress_EphysMED], [4.5 4], 'color', 'b')
set(gca, 'ylim', [3.5 5.5], 'xlim', [leverpress_ephys(1)-5000 leverpress_EphysMED(end)+10000])
xlabel('Time (ms)')

%  time limit correspondance in MED
time_range = [leverpress_EphysMED(1)-100  leverpress_EphysMED(end)+100];
% Now, align tone time to ephys time system
Trigger_MED2 = Trigger_MED(Trigger_MED>=time_range(1) & Trigger_MED<=time_range(end));
Tone_ephys = zeros(1, length(Trigger_MED2)); % this is to mark trigger time in the blackrock's time space

t_tonepress = [];

for k =1:length(Trigger_MED2)
    tTone = Trigger_MED2(k); % this is the time for kth tone presentation
    % the goal is to find out time of this tone in ephys time system
%     ind_pre = find(leverpress_MED<=tTone, 1, 'last'); % this is the index for last lever press preceeding this tone
    tkpressMED =  leverpress_MED(find(leverpress_MED<=tTone, 1, 'last')); % this is the time of the press
    [~, ind] = intersect(leverpress_EphysMED, tkpressMED);
    leverpress_ephys_k = leverpress_ephys(ind);
    Tone_ephys(k) = leverpress_ephys_k+tTone-tkpressMED;
    t_tonepress = [t_tonepress Tone_ephys(k)-leverpress_ephys_k];  % this is the press duration.
end

figure(46); clf
subplot(2, 1, 1)
plot(leverpress_ephys, 6,  'ko')
text(0, 6.4, 'lever press')
hold on
plot(Tone_ephys, 5, 'ro' )
text(0, 5.4, 'tone')
set(gca, 'ylim', [4 7])

subplot(2, 1, 2)
plot(t_tonepress, 'ro')
ylabel('FPs')
EventOut.EventsLabels{5}='Trigger';
EventOut.Onset{5}=Tone_ephys;

%     attach important information
%     IndexEphysMED

[~, CorrectEphysIndex]                  =       intersect(IndexEphysMED, CorrectIndex_MED);
[~, LateEphysIndex]                       =       intersect(IndexEphysMED, LateIndex_MED);
[~, PrematureEphysIndex]             =      intersect(IndexEphysMED, PrematureIndex_MED);
[~, DarkEphysIndex]                      =      intersect(IndexEphysMED, bMED.Dark);
FPsEphysIndex                             =       FPs_MED(IndexEphysMED);

EventOut.Performance                 =          {'Correct', 'Premature', 'Late', 'Dark'};
EventOut.PerfIndex                      =         {CorrectEphysIndex, PrematureEphysIndex, LateEphysIndex, DarkEphysIndex};
%     EventOut.CorrectIndex         =       CorrectEphysIndex;
%     EventOut.LateIndex              =       LateEphysIndex;
%     EventOut.PrematureIndex    =        PrematureEphysIndex;
EventOut.FPs                              =        FPsEphysIndex;