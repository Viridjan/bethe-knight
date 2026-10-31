# Attack CSVs and the Monsters editor

Open **Monsters → Attacks CSV** from the main menu, or **Map → Monsters → Attacks
CSV** during a desktop run. The window has attack definitions, enemy range
assignments, and an inspector for reference scores of saved library-monster builds.
The original bestiary still shows appearances, discoveries, and kills.

## Editing

Select an attack or binding on the left and edit its fields on the right.
Fields are grouped into Identity, Timing, Scoring, and Movement, with two fields
per row; reference notes and links use full-width rows. CSV float inputs and
displayed values use two decimals; intermediate calculations keep full precision.
The first six attack columns are name, research label, type, wind-up seconds,
execution seconds, and calculated score. Extra columns hold the scoring inputs
and parameters needed by existing attacks. CSV headers match `data/attacks.csv`.

- **Save CSV** validates and stages both tables before replacing them. Only saving
  changes the shared runtime catalogue. Edits to a running attack do not change
  its captured parameters; new selections use the saved values.
- **Reload CSV** rereads disk, refreshes the shared catalogue, and asks before
  discarding a draft. Saving refuses to overwrite files changed externally since
  they were loaded.
- **Enemies** lists the CSV-driven enemies (library monster, Ape, Ape enraged). Pick one to see its sprite and
  its attacks **in priority order**: the first attack that is in range (minimum inclusive, maximum exclusive),
  eligible and not skipped starts. ▲ / ▼ move an attack up or down (priorities are renumbered), ✕ removes it,
  "+ Add attack" adds an implemented one at the bottom. **Skip %** (`skip_chance`, 0-100) is the chance an attack
  passes its turn when it could be used, so the next one is tried. Below the list: the scores, per saved library
  build (body area once, then its distinct attacks) or for the Ape phase's repertoire. An invalid value shows in red.

Editing is available only in the desktop source version. Exported desktop games
can inspect the catalogue; the web keeps the development editor hidden and out
of its package. Stable runtime IDs, implemented types, and derived scores cannot
be edited in the form. New behavior still requires a gameplay implementation;
adding an unknown attack binding to CSV is rejected.

The source tables are [attacks.csv](../data/attacks.csv) and
[enemy_attacks.csv](../data/enemy_attacks.csv). A blank means unspecified, not zero.
External spreadsheet edits take effect after Reload CSV or restarting the game.

## What currently controls gameplay

Library monsters read CSV wind-up and recovery. Charge/dive read speed and execution
duration; straight shots read speed and execution duration. Leaps read initial
horizontal/vertical components and gravity, ending on landing. Lobbed shots read
flight-time, vertical velocity, gravity, and release-animation duration. Trait
modifiers remain applied as before. Body size and the 3×3 pixel small-projectile
hitbox remain defined by the entity implementation.

The Ape reads ordinary attack wind-ups, recovery, scream coverage/duration,
leap flight-time/gravity, stone flight-time/gravity parameters, split-stone
components, log warning/gravity, and slam area/duration. Its ordinary attack choice
uses normal/enraged range rows. Random throw eligibility and scripted wake-up,
hurt, corner escape, trunk transitions, volleys, and follow-up hops remain boss logic.

For targeted ballistic movement, `initial_speed_units_s` is the documented scoring
reference; the launch itself is calculated from component/flight parameters and
the target. `coverage_area_units2` describes reference damage geometry. Projectile
counts describe the authored pattern for scoring; editing those counts does not
create additional projectiles. Hand-authored enemy families outside ActionMonster
and the Ape have not been migrated to this catalogue.

## Scores

Lengths use tile units (one unit = 8 pixels); durations use seconds. For body and
ranged attacks, reference time is `20 / initial_speed_units_s`. Area/melee attacks
use coverage area divided by execution duration. Authors supply measured coverage;
this version does not automatically sample a melee animation's swept union.

```
raw = base_weight × coverage_area / measured_time × weighted_projectile_count
penalty = 1 + 4 × clamp((windup - measured_time) / (2 - measured_time), 0, 1)
score = raw / penalty
```

This implements a neutral penalty of 1 at or below measured time, rising linearly
to 5 at two seconds. All type weights initially equal 1. For an omnidirectional
pattern, shots toward the reference player count fully and other shots count 20%.
For ordinary multi-shot patterns, every projectile counts fully.

Scores for measured times of two seconds or more remain unavailable because the
requested curve's anchors conflict there. Falling logs also remain unscored:
they start at rest, so initial-speed reference travel time is undefined. Neither
case is silently given a fabricated score. The inspector shows normal/enraged Ape repertoire subtotals, including slam/log
and phase-two split-stone primitives, with body area added once. Their total stays
unavailable while the log is unscored. Repeated hops and enlarged shockwaves use
the base attack reference; this is not an encounter-frequency or composite-chain
difficulty model. The score is an estimate, not a change
to damage, health, spawn budgets, or attack priority.

Refresh the persisted score column after external edits:

```sh
godot --headless --path . --script res://tools/score_attacks.gd
```

## Verification

```sh
godot --headless --path . res://tests/attack_catalog.tscn
godot --headless --path . res://tests/test.tscn
godot --headless --path . res://tests/smoke.tscn
```

Tests use disposable user data for CSV save round trips, validation, curve examples,
range order/fallback, Ape phase selection, and the edit form. Gameplay checks verify
CSV timing changes and parameter snapshots alongside existing combat regressions.
The web-package check verifies both CSVs load and the editor script is excluded.

In the desktop source version, **Monster Editor** on the main menu opens the CSV
editor directly. Restart the game after updating the source to see the new entry.
