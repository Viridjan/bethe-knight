# Whole-number gameplay values on a 0.2 s gameplay tick

_Status: approved plan, not implemented. Scope and stress-rule conflicts resolved by the designer on 2026-11-07; see [decision record](../DOCUMENT_CONFLICTS.md). Preserve unrelated work when implementing._

## Context
Whole numbers apply to **gameplay resources and scores**: stamina, stress, HP, costs, resource rates, attack
scores and their saved/editor/displayed values. Divisions for those values truncate the fractional part.
**Physics and inputs keep normal precision and cadence**: movement, gravity, positions/remainders, collision,
input sampling/buffering and attack timings/speeds remain responsive at the existing 60 Hz physics step.
They must not be quantized or run on the slower resource tick.

The current resource implementation stores stamina as a float and applies fractional changes per frame:
regen 4–8–3/s scaled by the newer completed-block stress rule (70–100% recovery), water 40/s, heat 2/s,
climbing approximately 11.2/s up and 2.45/s still, climb jump approximately 6.75. Truncating each frame's
resource change would erase small rates. Instead continuous **resource accounting only** runs on a
0.2-second tick (12 physics frames, 5 ticks per second), handing out whole points. One-off costs/events remain
immediate; input handling and attacks must not wait for the resource tick.

## The tick (one small module, reused everywhere)
New `scripts/progression/game_tick.gd` (static, no state of its own):
- `const FRAMES := 12` (0.2 s at the fixed 60 Hz step), `const PER_SECOND := 5`.
- `static func share(rate_per_s: int, tick: int) -> int`: `(tick + 1) * rate / PER_SECOND - tick * rate / PER_SECOND`
  (integer division). Over any 5 consecutive ticks it hands out exactly `rate` points, never a fraction
  (ticks 0–4 at 3/s → 0, 1, 0, 1, 1). Works for any whole rate; no accumulator to save.
- The world counts physics frames as an int (`World.frame`); a gameplay tick happens when `frame % FRAMES == 0`,
  with `tick = frame / FRAMES`. The resource tick is not driven by summing float `dt`; ordinary physics/input timing remains unchanged.

## Changes
1. **Stamina is an int** (`scripts/adventure.gd`): `BASE_STAMINA := 27`, `STAMINA_PER_BLOCK := 17`, `stamina_max`
   int. Rates are whole points per second: `REGEN_EMPTY 4`, `REGEN_HALF 8`, `REGEN_FULL 3`, `WATER_DRAIN 40`.
   `regen_rate(run) -> int`: fill as a percentage `stamina * 100 / max`, the 4→8→3 curve with integer
   interpolation, then the stress percentage (`rate * percent / 100`). `regen_stamina(run, tick)`,
   `water_stamina(run, tick)` and `drain_stamina` add/subtract `GameTick.share(rate, tick)`; clamp with `mini/maxi`.
2. **World drives resource accounting on the tick** (`scripts/world.gd` `update_stamina`): continuous resource
   changes run only on tick frames; keep all player/entity physics and input processing at their normal cadence.
   Preserve existing drain rules: stun/climbing suppress natural regeneration; climbing drains as appropriate;
   water drains; heat adds its drain even while stunned, climbing or in water and suppresses natural regeneration.
   Outside these exclusions, stamina regenerates. F3 resource tallies use whole points; ordinary gameplay time
   and input/attack timers keep their normal precision. One-off jumps, hits, pickups and other costs remain immediate.
3. **Climbing in the adventure** (`scripts/player.gd`): the climb code keeps its own 110-unit meter for physics,
   but in the adventure it no longer drains the bar per frame through the `stamina` setter. Instead the player
   reports `climb_drain_per_s() -> int` (11 climbing up, 2 holding still, 0 otherwise; truncated from 11.2 / 2.45)
   and the world drains it on the tick; the climb-jump cost is a whole `CLIMB_JUMP_STAMINA := 6` (from 6.75).
   The getter keeps converting the int bar to climb units for the physics checks.
4. **Stress is an int** (`scripts/progression/stress.gd`): `value()` returns int. Keep owned capacity and
   upgrades, and apply only the **newer completed-block penalty, capped at 30%**. With integer division:
   `completed = clamp(stress / BAR_CAPACITY, 0, owned_blocks)`;
   `penalty_percent = 30 * completed / owned_blocks`; `recovery_percent = 100 - penalty_percent`.
   Calculate the cumulative penalty before truncating; do not truncate each block's share and then add it.
   Four owned blocks therefore give whole penalties 0/7/15/22/30% as 0–4 blocks complete; partial blocks add
   no penalty. Keep the exhaustion threshold `max / 5`. Do not restore the old interpolated recovery table.
5. **Heat** (`scripts/progression/environment_rules.gd`): `heat_drain` an int per second (validated as a whole
   number in room data); default 2.
6. **Saves** (`Adventure.restore_run`): old float `stamina`/`stress` are truncated with `int()` on load; new saves
   store ints.
7. **Displays**: HUD bars, F3 panel (`scripts/stamina_panel.gd`: `%d`, rates as whole numbers, "x0.75" → "75%"),
   stress HUD, map/debug texts for these values: no decimals.
8. **Attack scores** (`scripts/attack_catalog.gd`): `score_attack` / `enemy_score` return `int(...)` of the
   result; the CSV score column and the editor show whole numbers. Wind-ups, speeds, gravity, flight times stay
   decimal (physics).
9. **Docs**: update resource implementation details in `docs/NONMAP_SYSTEMS.md` and the implementation ledger
   once the migration ships. Keep TODO and README linked to those details; do not append current rules to the
   historical design/development-log archive.

## Order and safety
- Inspect the current working tree before implementation. Preserve unrelated edits and historical evidence;
  do not rely on the old snapshot's list of in-progress files or commit another contributor's work.
- One commit per step group: tick module + stamina/world/climb; stress + heat; saves + displays; scores; docs.

## Verification
- New tests (`tests/test_runner.gd` stamina section, `tests/stamina_recovery.gd`): `GameTick.share` gives exactly
  `rate` points per 5 ticks for 0..60; regen from 0 reaches full in whole steps; water 40/s = 8 per tick; climbing
  up drains 11 per second; `Game.adv.stamina` and `stress` are `int` after every update; old float saves load as
  truncated ints; F3/HUD text contains no decimal point for these values; attack scores are ints.
- Update existing checks that expect fractions (e.g. 0.0396, base/2 = 13.5 → 13, the climb test ratio).
- `sh tools/verify.sh` → 0 failing (includes gdlint/pyflakes); screenshot of the F3 panel and HUD.
- Stress checks: completed-block penalties for one/four/five/upgraded capacities, 30% maximum, no partial-block
  interpolation, and cumulative integer truncation (four blocks: 0/7/15/22/30%).
- Play check: physics, collision, input sampling/buffering and attacks remain at their normal cadence and precision;
  only continuous resource accounting steps every 0.2 seconds. Test immediate jump/attack costs between ticks.
- Integer truncation may alter small regeneration rates; verify actual integer rates and time-to-refill rather
  than claiming the resource balance is identical to the old fractional implementation.
