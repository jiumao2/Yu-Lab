# Flash 2x2 analysis workflow

This package contains analysis code for the active Flash/Tone 2x2 task and optional passive cue response panels. The task conditions are defined by stimulus identity and foreperiod:

- `Tone750`
- `Flash750`
- `Tone1500`
- `Flash1500`

`Both` trials and trials outside FP 750/1500 are not part of the active 2x2 condition set.

## Standard input r

The input `r` should be the session `RTarray_*.mat` structure built before Flash analysis. At minimum, the Flash code expects:

- `r.Meta`: subject and session date/time metadata.
- `r.Behavior`: trial and event data.
- `r.BehaviorClass`: subject/date metadata used for output names.
- `r.Units.SpikeTimes`: per-unit spike timing arrays, in ms on the same time base as behavior events.
- `r.Units.SpikeNotes`: unit channel/unit identifiers.
- `r.Units.ChanMap`: channel map metadata used by some downstream summaries.

The required active-task behavior fields are:

- `r.Behavior.Labels`
- `r.Behavior.EventMarkers`
- `r.Behavior.EventTimings`
- `r.Behavior.Outcome`
- `r.Behavior.TriggerTypes`
- `r.Behavior.TriggerTypeLabels`
- `r.Behavior.Foreperiods`

`r.Behavior.TriggerTypeLabels` must include `Tone` and `Flash`. `Flash.conditionInfo(r)` maps those labels plus `Foreperiods` into the four active conditions above, in the fixed order `Tone750`, `Flash750`, `Tone1500`, `Flash1500`.

## Optional passive fields

For sessions that include passive cue times, `r.Behavior` may also include:

- `r.Behavior.ToneTimes`
- `r.Behavior.SmallToneTimes`
- `r.Behavior.FlashTimes`
- `r.Behavior.BothTimes`

Each field is a vector of cue onset times in ms, on the same time base as `r.Units.SpikeTimes(unit).timings`. `Flash.FlashSpikesWithPassive` checks these fields in the order listed above. A field is plotted only when it exists and is non-empty after the active-task end-time and optional `ComputeRange` filters.

## Standard output r after FlashSpikes

Running `Flash.FlashSpikes(r, [])` computes all-unit active-task PSTHs and writes the updated `r` back to the original `RTarray_*.mat` file. It should not create an `RTarrayFlash_*.mat` file.

The updated `r` gains:

- `r.PSTH.Events`: active-task event metadata used by population analysis.
- `r.PSTH.PSTHs`: per-unit PSTH structs from `Flash.ComputePlotPSTH`.
- `r.FlashPSTH`: a Flash-specific copy of `r.PSTH`.

`r.PSTH.Events` contains:

- `ANM_Session`
- `TaskTypes`
- `Presses`
- `Releases`
- `Pokes`
- `Triggers`
- `OptoEpochs`
- `SpikeNotes`

The function also saves `PSTHOut_Flash_<subject>_<session>.mat` as a separate analysis output.

## Standard output r after FlashSpikesWithPassive

Running `Flash.FlashSpikesWithPassive(r, [])` computes the same active-task PSTHs plus passive cue PSTH/raster panels when passive cue fields are present.

The updated `r` gains:

- `r.PSTH.Events`: active-task event metadata plus passive cue metadata.
- `r.PSTH.Events.PassiveEvents`: labels and times for passive cue types that were actually plotted.
- `r.PSTH.PSTHs`: per-unit PSTH structs from `Flash.ComputePlotPSTHWithPassive`.
- `r.FlashPSTHWithPassive`: a Flash-specific copy of this passive-inclusive `r.PSTH`.

The function also saves `PSTHOut_FlashWithPassive_<subject>_<session>.mat` as a separate analysis output.

## Standard output r after PopulationActivity

Running `Flash.PopulationActivity(r)` requires `r.PSTH.Events` and `r.PSTH.PSTHs` to already exist. It builds population-level PSTH summaries from saved per-unit PSTHs instead of recomputing spikes.

The updated `r` gains:

- `r.FlashPopPSTH`: population activity output from the Flash 2x2 task.

`Flash.PopulationActivity` writes `r` back to the original `RTarray_*.mat` file and saves `PopOut_Flash_<subject>_<session>.mat` separately. It should not create an `RTarrayFlashPop_*.mat` file.

## Output locations

- Behavior summary figures are saved in the session data folder, the parent of `Fig`.
- Per-unit and population figures are saved directly in the session `Fig` folder.
- The package should not create task-specific subfolders under `Fig` for Flash figures.