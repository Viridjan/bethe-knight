# Integer resources and scores — 2026-11-10

Point 2 of the [sequential delivery plan](../../docs/plans/REMAINING_WORK.md).
Implemented behavior is described in [Non-map systems](../../docs/NONMAP_SYSTEMS.md#integer-resources-and-resource-tick--2026-11-10).

## Delivered

- Integer stamina, stress, capacities, rates and costs; legacy fractional saves truncate on restore.
- Stateless resource shares distribute whole per-second rates over five ticks. World counts twelve active physics frames per resource tick. Movement, collision, input buffers, attack timings/speeds and standalone climb physics retain precision and their existing cadence.
- Regeneration uses integer interpolation and integer stress adjustment; completed stress blocks yield cumulative truncated penalties capped at 30%. Four owned blocks give 0/7/15/22/30% penalties.
- Water drains 40/second; adventure upward climbing drains 11/second and wall holding 2/second after the existing grace. Heat remains additive and suppresses regeneration. Climb jumps immediately pay the truncated extra six points plus the ordinary five-point jump cost.
- Jump/attack costs, pickups and hard landing/exhaustion remain immediate between ticks. Exhaustion/grey hair use truncated `max / 5`.
- Heat authoring steps by one and stores integers; level validation rejects fractional heat rates. F3 values/rates/totals and stress percentages show whole numbers. HUD geometry retains fractional fill precision.
- Attack/enemy scores truncate at returned score boundaries, including follow-ups. CSV score cells were refreshed; movement, timing and geometry columns were preserved. Editor totals display integers. Existing HP validation/runtime already used whole numbers.

## Final result

**Full verifier: 0 failing, exit 0.** All 42 Godot invocations, Python unittest discovery, GDScript lint, Pyflakes and diff checks passed after the hard-landing fix. The final direct integer-resource rerun also passed after strengthening the F3 assertion. Point 2 is complete; point 3 remains a separate design task.

## Evidence

The initial [regression run](red.txt) failed eight checks for the missing tick service, float resources/save restoration, fractional heat/stress calculations and float scores. A separate [hard-landing regression](hard-landing-red.txt) reproduced delayed exhaustion before its fix; the updated [integer regression suite](integer_resources-latest.txt) passes.

Intermediate targeted logs retain superseded failures from the former fractional expectations; `test-latest.txt`, `stress-latest.txt` and the final aggregate output record the corrected expectations.

The suite covers rates 0–60 over five consecutive ticks at different phase offsets, integer interpolation, old saves, integer score boundaries, real physics advancement between resource ticks, paused/frozen/inactive clocks, immediate costs, combined water/heat and climbing/heat drain, heat during stun and F3 percentage text.

[Full verifier output](verification.txt) and [exit status](verification-exit.txt) record the final aggregate run. An earlier full pass is retained in [verification-before-hard-landing-fix.txt](verification-before-hard-landing-fix.txt). The verifier includes gameplay, smoke, layer/checkpoint/quest/editor/encounter suites, Python tests, GDScript lint, Pyflakes and diff whitespace checks. Lint uses approved access to the uv cache, resolving the sandbox issue established in point 1.

[HUD and F3 screenshot](hud-f3.png) was rendered in the running game and visually inspected: whole resource values/rates, 85% stress recovery, attached segmented bars and an integer-step history graph are visible. Reproduce with `godot --path . res://reports/integer-resources-2026-11-10/capture.tscn`; it uses disposable run state and does not write personal saves. The capture is a scripted running-game inspection, not a complete manual chapter playthrough.

## Measured recovery and limits

[Refill measurements](refill-times.txt) use four stamina blocks (78 capacity), one stress block and ticks beginning at phase zero. From empty, recovery takes **79 ticks / 15.8 seconds** starting at zero stress, or **133 ticks / 26.6 seconds** at full stress (50). The normal immediate exhaustion event still applies to the empty run. From 44 stamina, the corresponding measurements are 37 ticks / 7.4 seconds and 63 ticks / 12.6 seconds. Tick phase and discrete rate changes affect exact arrival times.

This intentionally changes effective recovery relative to fractional accounting. Rates truncate before distribution, so a calculated fractional rate is not carried into later ticks. Continuous accounting uses active frame count, independent of assist-scaled `dt`; movement and timers still use the existing assist speed. Broader resource/reward policy decisions belong to point 3.

Shutdown leak warnings are reported by the verifier separately; this work does not claim to resolve them. No story rooms were changed, no deployment was performed, and no existing changes were staged or committed.

The optional editor import completed asset processing but reported sandbox editor-settings/socket errors ([log](import.txt)); gameplay/test loading and the approved graphical capture succeeded. The generated unrelated untracked UID files were removed; [cleanup inventory](generated-uids-removed.txt) records them. New tick/test UIDs remain with their sources.
