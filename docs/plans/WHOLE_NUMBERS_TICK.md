# Whole-number gameplay values on a 0.2 s gameplay tick

_Status: approved by the designer on 2026-11-07, not started (waiting for the in-progress Codex work in these files to be committed). Codex: if you pick this up, finish and commit your current slice first, then follow this plan step by step._

## Context
New rule (AGENTS.md "Whole numbers only"): no floating-point numbers in the game; every division keeps only its
integer part. Scope agreed: **gameplay values** (stamina, stress, HP, costs, rates, scores, HUD/F3 text, saves).
Movement physics (speeds, gravity, positions, the Celeste port) and attack timings/speeds in the Monster Editor keep
their decimals. Today stamina is a float changed every frame by fractional amounts (regen 4–8–3/s scaled by stress
65–100%, water 40/s, heat 2/s, climbing ≈11.2/s up and ≈2.45/s still, climb jump ≈6.75), so truncating per frame
would zero every rate. Instead all continuous changes happen on one **gameplay tick of 0.2 s (12 physics frames,
5 per second)**, in whole points.

## The tick (one small module, reused everywhere)
New `scripts/progression/game_tick.gd` (static, no state of its own):
- `const FRAMES := 12` (0.2 s at the fixed 60 Hz step), `const PER_SECOND := 5`.
- `static func share(rate_per_s: int, tick: int) -> int`: `(tick + 1) * rate / PER_SECOND - tick * rate / PER_SECOND`
  (integer division). Over any 5 consecutive ticks it hands out exactly `rate` points, never a fraction
  (3/s → 1, 1, 0, 1, 0). Works for any whole rate; no accumulator to save.
- The world counts physics frames as an int (`World.frame`); a gameplay tick happens when `frame % FRAMES == 0`,
  with `tick = frame / FRAMES`. Nothing is driven by summing float `dt`.

## Changes
1. **Stamina is an int** (`scripts/adventure.gd`): `BASE_STAMINA := 27`, `STAMINA_PER_BLOCK := 17`, `stamina_max`
   int. Rates are whole points per second: `REGEN_EMPTY 4`, `REGEN_HALF 8`, `REGEN_FULL 3`, `WATER_DRAIN 40`.
   `regen_rate(run) -> int`: fill as a percentage `stamina * 100 / max`, the 4→8→3 curve with integer
   interpolation, then the stress percentage (`rate * percent / 100`). `regen_stamina(run, tick)`,
   `water_stamina(run, tick)` and `drain_stamina` add/subtract `GameTick.share(rate, tick)`; clamp with `mini/maxi`.
2. **World drives it on the tick** (`scripts/world.gd` `update_stamina`): runs only on tick frames; same priority
   as now (stunned → none, climbing → climb drain, water, heat, else regen). F3 recap tallies whole points; time in
   ticks.
3. **Climbing in the adventure** (`scripts/player.gd`): the climb code keeps its own 110-unit meter for physics,
   but in the adventure it no longer drains the bar per frame through the `stamina` setter. Instead the player
   reports `climb_drain_per_s() -> int` (11 climbing up, 2 holding still, 0 otherwise; truncated from 11.2 / 2.45)
   and the world drains it on the tick; the climb-jump cost is a whole `CLIMB_JUMP_STAMINA := 6` (from 6.75).
   The getter keeps converting the int bar to climb units for the physics checks.
4. **Stress is an int** (`scripts/progression/stress.gd`): `value()` returns int; `RECOVERY` becomes percentages
   `[100, 90, 80, 75, 70, 65]` with integer interpolation (`recovery_percent`); exhaustion threshold `max / 5`.
5. **Heat** (`scripts/progression/environment_rules.gd`): `heat_drain` an int per second (validated as a whole
   number in room data); default 2.
6. **Saves** (`Adventure.restore_run`): old float `stamina`/`stress` are truncated with `int()` on load; new saves
   store ints.
7. **Displays**: HUD bars, F3 panel (`scripts/stamina_panel.gd`: `%d`, rates as whole numbers, "x0.75" → "75%"),
   stress HUD, map/debug texts for these values: no decimals.
8. **Attack scores** (`scripts/attack_catalog.gd`): `score_attack` / `enemy_score` return `int(...)` of the
   result; the CSV score column and the editor show whole numbers. Wind-ups, speeds, gravity, flight times stay
   decimal (physics).
9. **Docs**: `docs/CODE_GUIDE.md` "Whole numbers only" gains the tick (12 frames, `GameTick.share`); README stamina
   line; `gdd.txt` line.

## Order and safety
- Codex has uncommitted work in `adventure.gd`, `stress.gd`, `world.gd`, `player.gd`, `tests/test_runner.gd`.
  Start after it commits (or work in a clean worktree at HEAD and merge only after its commit) — never commit its
  in-progress files.
- One commit per step group: tick module + stamina/world/climb; stress + heat; saves + displays; scores; docs.

## Verification
- New tests (`tests/test_runner.gd` stamina section, `tests/stamina_recovery.gd`): `GameTick.share` gives exactly
  `rate` points per 5 ticks for 0..60; regen from 0 reaches full in whole steps; water 40/s = 8 per tick; climbing
  up drains 11 per second; `Game.adv.stamina` and `stress` are `int` after every update; old float saves load as
  truncated ints; F3/HUD text contains no decimal point for these values; attack scores are ints.
- Update existing checks that expect fractions (e.g. 0.0396, base/2 = 13.5 → 13, the climb test ratio).
- `sh tools/verify.sh` → 0 failing (includes gdlint/pyflakes); screenshot of the F3 panel and HUD.
- Play check: regen and water feel the same as now, only stepped every 0.2 s.
