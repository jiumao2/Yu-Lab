function EventOut = AlignMED2BR(EventOut, bMED)

% 3/3/2021 Jianing Yu
% EventOut comes from BlackRock's digital input
% bMED is the b array coming from MED data
% Time of some critical behavioral events (e.g., Trigger stimulus) needs to be mapped to EventOut
% Alignment is performed using press onset data
% Alignment of each trigger stimulus needs to be adjusted to the preceding press
% onset

% Lever presses and releases recorded in blackrock
leverpress_ephys        =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')};
leverrelease_ephys     =     EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')};

% Lever presses, FP, releases, and correct index recorded in MED
leverpress_MED          =     bMED.PressTime*1000;  % turn press time to ms
leverrelease_MED       =     bMED.ReleaseTime*1000; % lever releases recorded in MED
Trigger_MED               =     bMED.TimeTone*1000; % trigger time recorded in MED

CorrectIndex_MED      =     bMED.Correct; % index of correct press-release responses
LateIndex_MED           =     bMED.Late;
PrematureIndex_MED =     bMED.Premature;
DarkIndex_MED          =     bMED.Dark;
FPs_MED                    =     bMED.FPs;
IndexMED                   =      [1:length(bMED.FPs)];

if isfield(bMED, 'Cue')
    CueMED      =    bMED.Cue;
else
    CueMED      =     ones(1, length(bMED.FPs));
end

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
leverpress_EphysMED     =     [];
leverrelease_EphysMED  =     [];

% find out the corresponding index of each ephys presses in MED
%  findseqmatchrev(seqmom, seqson, man, toprint, toprintname)
IndexEphysMED               =       findseqmatch(leverpress_MED, leverpress_ephys);
leverpress_EphysMED   =       leverpress_MED(IndexEphysMED(~isnan(IndexEphysMED))); % this is the lever press time in MED during ephys recording
IndMatched = find(~isnan(IndexEphysMED));

leverpress_ephys            =           leverpress_ephys(IndMatched);
leverrelease_ephys         =            leverrelease_ephys(IndMatched);


figure(45); clf

set(gcf, 'units', 'centimeters', 'position', [3 10, 20, 10])
subplot(3, 1, [1 2])
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

% examine release signal
leverrelease_EphysMED      =       leverrelease_MED(IndexEphysMED(~isnan(IndexEphysMED))); % this is the lever press time in MED during ephys recording
% subtract 5
plot(leverrelease_MED, -1+3, 'ko')
text(leverrelease_ephys(1)-500, -0.8+3, 'MED release')
hold on
plot(leverrelease_ephys, 0+3, 'r^');
text(leverrelease_ephys(1)-500, 0.2+3, 'Blackrock release')
plot(leverrelease_EphysMED, -0.5+3, 'ro');
text(leverrelease_ephys(1)-500, -0.3+3, 'Mapped')
line([leverrelease_EphysMED; leverrelease_ephys'], [4.5 5]-5+3, 'color', 'b')
line([leverrelease_EphysMED; leverrelease_EphysMED], [4.5 4]-5+3, 'color', 'b')
set(gca, 'ylim', [1 6])


subplot(3, 1, 3)

dt_onset = leverpress_EphysMED-leverpress_ephys';
dt_onset = dt_onset-dt_onset(1);

dt_onset2 = leverrelease_EphysMED-leverrelease_ephys';
dt_onset2 = dt_onset2-dt_onset2(1);

plot(leverpress_ephys, dt_onset, 'r*-'); hold on
plot(leverrelease_ephys, dt_onset2, 'ko-', 'linewidth', 2)
xlabel('Time (ms)')
ylabel('Difference (ms)')

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
plot(leverrelease_ephys, 5.5,  'co')
text(0, 5.8, 'lever release')
plot(Tone_ephys, 5, 'ro' )
text(0, 5.4, 'tone')
set(gca, 'ylim', [4 7])

subplot(2, 1, 2)
plot(t_tonepress, 'ro')
ylabel('FPs')

if isempty(find(strcmp(EventOut.EventsLabels, 'Trigger')));
    EventOut.EventsLabels{end+1}='Trigger';
    EventOut.Onset{end+1}=Tone_ephys;
end;

%     attach important information
%     IndexEphysMED
[~, CorrectEphysIndex]                  =      intersect(IndexEphysMED(~isnan(IndexEphysMED)), CorrectIndex_MED);
[~, LateEphysIndex]                       =      intersect(IndexEphysMED(~isnan(IndexEphysMED)), LateIndex_MED);
[~, PrematureEphysIndex]             =      intersect(IndexEphysMED(~isnan(IndexEphysMED)), PrematureIndex_MED);
[~, DarkEphysIndex]                      =      intersect(IndexEphysMED(~isnan(IndexEphysMED)), DarkIndex_MED);

CueOut = [];
if isfield(bMED, 'Cue')
    CueOut = [IndexMED(IndexEphysMED(~isnan(IndexEphysMED))); CueMED(IndexEphysMED(~isnan(IndexEphysMED)))]; % this includes both index and cue label
end;

FPsEphysIndex                             =       FPs_MED(IndexEphysMED(~isnan(IndexEphysMED)));
EventOut.Performance                 =       {'Correct', 'Premature', 'Late', 'Dark', 'Cue'};
EventOut.PerfIndex                      =       {CorrectEphysIndex, PrematureEphysIndex, LateEphysIndex, DarkEphysIndex, CueOut};
EventOut.FPs                               =        FPsEphysIndex;