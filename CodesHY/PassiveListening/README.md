# PassiveListening trigger response workflow

This folder stores reusable MATLAB code for passive tone/flash cue response analysis.

## Files

- `compareToneAndFlashResponses.m`: Match Bpod cue timestamps to ephys trigger timestamps, save cue times into `r.Behavior`, compute per-unit response latency, and plot response latency and responsive unit locations.
- `computeResponseTime.m`: Helper function used by `compareToneAndFlashResponses.m` to estimate each unit's cue response latency.

## Analysis workflow

1. Create a new session-specific analysis folder, for example:
   `K:\<Subject>\<YYYYMMDD>\TriggerResponse`

2. Put the required data in that folder structure:
   - Copy the passive-listening Bpod `SessionData` `.mat` file into the `TriggerResponse` folder.
   - Keep `EventOut.mat` in the parent session folder.
   - Build and keep the session `RTarray_*.mat` file in the parent session folder.

3. Copy the reusable analysis code into the `TriggerResponse` folder:
   - `compareToneAndFlashResponses.m`
   - `computeResponseTime.m`

4. Build the spike table and build `r` first.
   - Run the session's `BuildSpikeTableNeuropixels.m` workflow.
   - Confirm that it creates exactly one `RTarray_*.mat` file in the parent session folder.
   - Confirm that `EventOut.mat` exists in the same parent session folder.

5. Run `compareToneAndFlashResponses.m` from inside the `TriggerResponse` folder.
   - The script expects exactly one Bpod `SessionData` `.mat` file in the current folder.
   - The script loads `../RTarray_*.mat` and `../EventOut.mat`.
   - Cue indices are read from `SessionData.TriggerTypeLabels`.
   - `Both` cue times can be saved in `r.Behavior.BothTimes`; later passive PSTH/raster plotting can draw them when the field exists and is non-empty.

6. Review the trigger-response outputs.
   - `ResponseLatency.png`: response latency histogram for analyzed cue types.
   - `ResponsiveUnitLocations.png`: depth distribution of all units and responsive units by cue type.
   - Updated `RTarray_*.mat`: includes cue timing fields such as `r.Behavior.ToneTimes`, `r.Behavior.SmallToneTimes`, `r.Behavior.FlashTimes`, and `r.Behavior.BothTimes` when those labels exist.

7. Continue with unit-level and population-level analysis.
   - Plot per-unit cue responses using the updated cue time fields in `r.Behavior`.
   - Plot population activity after per-unit results are checked.

## Standard r output

The input `r` should keep the standard `RTarray_*.mat` structure built before passive-listening analysis. At minimum, downstream code expects:

- `r.Meta`
- `r.Behavior`
- `r.Units.SpikeTimes`
- `r.Units.SpikeNotes`
- `r.Units.ChanMap`

After `compareToneAndFlashResponses.m` runs, the same parent-session `RTarray_*.mat` file is written back with passive cue timing fields added under `r.Behavior`. Depending on the cue labels in `SessionData.TriggerTypeLabels`, these fields may include:

- `r.Behavior.ToneTimes`
- `r.Behavior.SmallToneTimes`
- `r.Behavior.FlashTimes`
- `r.Behavior.BothTimes`

Each cue timing field is a vector of ephys-aligned cue onset times. The values are in milliseconds, on the same time base as `r.Units.SpikeTimes(unit).timings` and the ephys event timing. Each vector contains only trials whose Bpod cue onset was successfully matched to an ephys `Trigger` event. If a cue type is absent from the session or has no valid matched trials, its field may be absent or empty.

If `Both` is present in the Bpod labels, `compareToneAndFlashResponses.m` can save it as `r.Behavior.BothTimes`. Later passive PSTH/raster plotting code checks `ToneTimes`, `SmallToneTimes`, `FlashTimes`, and `BothTimes`; any field that exists and is non-empty is plotted as its own passive cue type.

PassiveListening does not create or modify active-task PSTH fields such as `r.PSTH`, `r.FlashPSTH`, or `r.FlashPopPSTH`. It also does not modify `r.Units`, spike timings, spike notes, or the channel map.

## Notes
- Do not place multiple Bpod `SessionData` `.mat` files in the same `TriggerResponse` folder.
- Do not place multiple `RTarray_*.mat` files in the parent session folder.
- For sessions with only one cue type, the script only analyzes and plots that cue type.
- For sessions with `Both` trials only, cue times are saved; the matching script may skip its own response summary figures, but later passive PSTH/raster plotting can still use `r.Behavior.BothTimes`.
