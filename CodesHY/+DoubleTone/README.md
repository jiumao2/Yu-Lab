# DoubleTone analysis workflow

This package contains analysis code for the active DoubleTone task. The
learning sessions are MED-driven Neuropixels sessions: MED defines lever
presses, foreperiods, target tone timing, rewards, and behavioral outcomes;
Bpod listens to MED TTLs and supplies the extra-tone learning schedule.

## Standard input r

The input `r` should be the session `RTarray_*.mat` structure built before
DoubleTone spike analysis. At minimum, the DoubleTone code expects:

- `r.Meta`: subject and session date/time metadata.
- `r.Behavior`: trial and event data on the Neuropixels time base.
- `r.BehaviorClass`: subject/date/protocol metadata from MED behavior parsing.
- `r.Units.SpikeTimes`: per-unit spike timing arrays, in ms on the same time
  base as behavior events.
- `r.Units.SpikeNotes`: unit channel/unit identifiers.
- `r.Units.ChanMap`: channel map metadata used by downstream summaries.

The required active-task behavior fields are:

- `r.Behavior.Labels`
- `r.Behavior.LabelMarkers`
- `r.Behavior.EventMarkers`
- `r.Behavior.EventTimings`
- `r.Behavior.Outcome`
- `r.Behavior.CorrectIndex`
- `r.Behavior.PrematureIndex`
- `r.Behavior.LateIndex`
- `r.Behavior.DarkIndex`
- `r.Behavior.Foreperiods`
- `r.Behavior.CueIndex`
- `r.Behavior.TriggerTypes`
- `r.Behavior.TriggerTypeLabels`

`r.Behavior.Outcome` is MED-derived and aligned to Neuropixels press events by
`AlignBehaviorClassToBR`. Bpod outcomes are not used for `Correct`,
`Premature`, `Late`, or `Dark` classification.

## Learning fields

DoubleTone learning sessions add only the minimal trial-level fields needed for
condition analysis:

- `r.Behavior.ExtraToneVolumes`
- `r.Behavior.IsTestTrials`
- `r.Behavior.PostLearningPhaseTrials`

Each field has one value per Neuropixels-aligned press trial, matching the
length of `r.Behavior.Outcome`.

`ExtraToneVolumes` is the effective audible extra/first-tone volume. A value of
`0` means no audible extra tone, `1` means full-volume extra tone, and values
between `0` and `1` are learning-stage volumes. In post-learning no-extra
trials, the saved value is `0` even if Bpod had a full-volume waveform loaded,
because the no-output state did not play the extra tone.

`IsTestTrials` marks Bpod full-volume test trials. `PostLearningPhaseTrials`
marks trials after the learning stage has locked at full volume.

## Trigger types

DoubleTone analysis uses the same trigger-type interface expected by the
existing DoubleTone plotting and PSTH code:

- `None`
- `Tone500`
- `Tone750`
- `Tone1000`

Learning sessions primarily use `None` and `Tone750`. `TriggerTypes` is derived
from `ExtraToneVolumes`: trials with `ExtraToneVolumes > 0` are coded as
`Tone750`, and trials with `ExtraToneVolumes <= 0` or unmatched Bpod metadata
are coded as `None`.

The target/second tone is represented by the standard `Trigger` event timing.
`TriggerTypes` describes the extra/first-tone condition, not the target tone.

## Learning behavior summary

`DoubleTone.behaviorSummaryLearning(r)` plots a session-level summary for DoubleTone
learning sessions. The function uses MED-derived outcomes and the learning
fields above, and it excludes `Dark` trials and trials with hold duration under
`750 ms` from all panels and summary statistics.

The top row contains two timeline panels. The first panel combines learning and
post-learning non-test trials across the full recording time. Trial color is
the effective `ExtraToneVolumes` value on a fixed `[0 1]` color scale, and the
post-learning phase is marked with a light shaded time block. The second panel
shows `IsTestTrials` separately so test trials are not mixed into the learning
phase timeline. Both timeline panels show the foreperiod reference line and, if
audible extra-tone trials are present, a `750 ms` reference line for the extra
tone.

The distribution, reaction-time, and count panels are grouped by foreperiod and
condition. Conditions are `Learning`, `Test`, `Post on`, and `Post off`.
`Learning` is not subdivided by intermediate volume; the continuous volume
trajectory is shown in the top timeline. Reaction time is computed per trial as
hold duration minus `r.Behavior.Foreperiods`, so sessions with one or two
foreperiods are supported.

## Building learning r files

Use `DoubleTone.buildRLearning` from a single session folder that contains
`EventOut.mat`, the MED text file, the DoubleTone Bpod file, and
`KilosortOutput.mat`:

```matlab
load KilosortOutput.mat
r = DoubleTone.buildRLearning(KilosortOutput, ...
    'Subject', 'Lamine', ...
    'Experimenter', 'HY');
```

The function saves `RTarray_<subject>_<session>.mat` in the session folder and
also returns `r` for immediate inspection.

## Building standard r files

Use `DoubleTone.buildRStandard` for DoubleTone standard sessions, including the
standard 2FP task with MED-side probe trials:

```matlab
load KilosortOutput.mat
r = DoubleTone.buildRStandard(KilosortOutput, ...
    'Subject', 'Lamine', ...
    'Experimenter', 'HY');
```

The function follows the same build style as `buildRLearning`, but saves only
the minimal standard-task additions to `r.Behavior`:

- `ExtraTonePlayed`: Bpod-derived extra-tone on/off condition aligned to the
  Neuropixels press trial.
- `IsProbeTrials`: MED-derived probe marker, defined by
  `r.Behavior.Outcome == 'NAN'`.
- `ProbeIndex`: `find(r.Behavior.IsProbeTrials)`.

Standard sessions do not save learning fields such as `ExtraToneVolumes`,
`IsTestTrials`, or `PostLearningPhaseTrials`, and they do not save Bpod
diagnostic fields such as `TargetToneDetected` or `NoToneTrials`.

`Outcome`, `CorrectIndex`, `PrematureIndex`, `LateIndex`, `DarkIndex`, and
`IsProbeTrials` are MED-derived. `Foreperiods` are filled from the MED `W:`
array when `BehaviorClass.FP` is missing. `TriggerTypes` is a compatibility
field derived from `ExtraTonePlayed`: `Tone750` for extra-tone trials and
`None` for no-extra or unmatched trials.

Event timing fields remain on the Neuropixels/EventOut time base. In
particular, `LeverPress`, `LeverRelease`, `Trigger`, `Valve`, and `Frame`
timings come from `EventOut.mat`. `Poke` timings are updated from Bpod through
the existing `UpdatePokeFromBpodEvents` workflow. `buildRStandard` asserts that
the `LeverPress` onset/offset counts match and that no release precedes its
corresponding press; it does not rewrite release, trigger, or valve times from
MED.

For 2026-05-20 standard data, the current debug result is that
`findseqmatch(PressBehavior, PressEphys)` in `AlignBehaviorClassToBR` does not
produce a clean one-to-one press alignment: both sequences have length `266`,
but only `207` unique MED indices are matched and `59` matched steps are
duplicates. This can make MED outcomes and EventOut hold durations disagree
even when the EventOut press/release counts and ordering pass the assertions.
Use `plotMatchingResults(PressBehavior, PressEphys, IndMatched)` to inspect this
case before relying on the built `r`.

## Standard output r after DoubleToneSpikes

Running `DoubleTone.DoubleToneSpikes(r, [])` computes all-unit active-task
PSTHs and writes the updated `r` back to the original `RTarray_*.mat` file.

The updated `r` gains:

- `r.PSTH.Events`: active-task event metadata used by population analysis.
- `r.PSTH.PSTHs`: per-unit PSTH structs from `DoubleTone.ComputePlotPSTH`.

For DoubleTone learning sessions, use `DoubleTone.DoubleToneLearningSpikes`.
This entry point keeps the standard `DoubleToneSpikes` behavior untouched and
adds learning-specific trial sorting, extra-tone volume metadata, test-trial
handling, and post-learning condition display through
`DoubleTone.ComputePlotPSTHLearning`.

Learning population activity uses the same `DoubleTone.PopulationActivity(r)`
entry point after `r.PSTH` has been built by `DoubleTone.DoubleToneLearningSpikes`.
Reward-aligned learning PSTHs are assigned by first matching each reward to its
own immediately preceding correct MED release, then keeping only regular
vol=0/vol=1 conditions. Test trials and intermediate-volume learning trials are
not folded into the regular vol=1 reward condition. If an older `r.PSTH` was
computed before this rule, rerun `DoubleTone.DoubleToneLearningSpikes(r, [])`
before calling `DoubleTone.PopulationActivity(r)`.

In the learning per-unit figure, panel A is the trial-time sorted press raster.
It uses the same press-aligned x-axis range and physical panel width as the
performance-sorted press panel B, shades the foreperiod and audible extra-tone
window, and marks release times on each trial. The small PETH directly below
panel A is computed from the same non-test trials shown in that raster and
overlays `Vol < 1` and `Vol = 1` responses. Full-volume extra-tone spikes use a
distinct purple tone so they do not visually conflict with the release-time
marker color.

## Output locations

- `RTarray_*.mat` files are saved in the session data folder.
- Behavior summary figures are saved in the session data folder, the parent of
  `Fig`.
- Per-unit and population figures are saved directly in the session `Fig`
  folder.
