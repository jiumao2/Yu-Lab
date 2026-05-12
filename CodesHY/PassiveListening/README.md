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
   - `Both` cue times can be saved in `r.Behavior.BothTimes`, but `Both` is ignored for response analysis and figures.

6. Review the trigger-response outputs.
   - `ResponseLatency.png`: response latency histogram for analyzed cue types.
   - `ResponsiveUnitLocations.png`: depth distribution of all units and responsive units by cue type.
   - Updated `RTarray_*.mat`: includes cue timing fields such as `r.Behavior.ToneTimes`, `r.Behavior.FlashTimes`, and `r.Behavior.BothTimes` when those labels exist.

7. Continue with unit-level and population-level analysis.
   - Plot per-unit cue responses using the updated cue time fields in `r.Behavior`.
   - Plot population activity after per-unit results are checked.

## Notes

- Do not place multiple Bpod `SessionData` `.mat` files in the same `TriggerResponse` folder.
- Do not place multiple `RTarray_*.mat` files in the parent session folder.
- For sessions with only one cue type, the script only analyzes and plots that cue type.
- For sessions with `Both` trials only, cue times are saved but response figures are skipped.
