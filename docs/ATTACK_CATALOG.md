# Attack CSVs and the Monsters editor

Open **Monster Editor** from the desktop main menu. The in-game map's Monsters
view also provides access to the catalogue.

## Editing

- **Attack library**: search by name, ID, or type. Common settings are grouped in
  cards; Trajectory and Advanced settings expand when needed. The selected
  attack's score is shown beside its name, with the calculation in hover help.
- **Enemy loadouts**: search enemies, inspect their preview, and review attacks
  in priority order. Range, skip chance, and ordering controls remain visible.
  Use its **Edit** button for mechanics, frames, and follow-up settings.
  Animation reference sheets expand separately.
- **Save changes** and **Reload** stay at the top right. Save validates the draft;
  saving/reloading preserves the selected enemy view. Long score explanations
  are available on hover.

Attack values are shared by every enemy that uses that attack. CSV float inputs
and displayed values use two decimals; calculations keep full precision.
The first six attack columns are name, research label, type, wind-up seconds,
execution seconds, and calculated score. Extra columns hold the scoring inputs
and parameters needed by existing attacks. CSV headers match `data/attacks.csv`.

- **Save changes** validates and stages both tables before replacing them. Only saving
  changes the shared runtime catalogue. Edits to a running attack do not change
  its captured parameters; new selections use the saved values.
- **Reload** rereads disk, refreshes the shared catalogue, and asks before
  discarding a draft. Saving refuses to overwrite files changed externally since
  they were loaded.
- **Enemy loadouts** lists every enemy. Editable (attacks in the CSV): the Ape, the enraged Ape and the six
  attacking families (Dropwing, Duskflit, Ossling, Hornback, Cragjaw, Murkspore); the others (variants, Thornmite,
  Fuzzbob, Mosstrot, the chase Ape, the Guardian) are read-only (sprite, frames, HP, where they're placed). Attacks
  are in **priority order**: the first one in range (minimum inclusive, maximum exclusive; empty / 0 = no maximum),
  eligible and not skipped starts. ▲ / ▼ reorder, ✕ removes it from the enemy, "+ Add attack" adds any catalogue
  attack or a new planned one (attacks the enemy's code can't do yet are tagged "not in game yet" and skipped in
  play). **Skip %** is the chance an attack passes its turn to the next one. Under each attack: its frames, its
  values (the same boxes for every attack of a type) and its follow-up (Then / Times / Every, or "+ Then…"). The
  score line stays pinned below the list. An invalid value shows in red.
- **Attack library** holds what defines each attack: Name, ID (renamed on Enter or leaving the box; refused when
  empty, taken, or used by the game code, including the Ape's slam, split stone and log), Type, Weight and the boxes of
  its type; **Delete attack** for attacks no code uses. Multishot is 1-64 and follow-up Times 1-10; follow-ups can't
  loop back. Esc and Back both ask before dropping unsaved edits.
- Family loadouts rule the fight: an enemy attacks only inside [minimum, maximum) and never once its attack is
  removed. Follow-ups the game can't run yet are marked "not in game yet" (today only the Ape's retreat → stone
  throw runs); an attack whose follow-up can't be scored shows its score as incomplete.

Editing is available only in the desktop source version. Exported desktop games
can inspect the catalogue; the web keeps the development editor hidden and out
of its package. Stable runtime IDs, implemented types, and derived scores cannot
be edited in the form. New behavior still requires a gameplay implementation;
adding an unknown attack binding to CSV is rejected.

Enemy families in the CSV (their behaviour code reads the values; variants share the family's attack): Dropwing
(`dropwing_dive`), Duskflit (`charge`, flying), Ossling (`ossling_bone_throw`), Hornback (`charge`), Cragjaw
(`leap`), Murkspore (`shoot`). Shared attacks: **charge** (a rush: walkers run along their floor, flyers fly
straight at the player; library monsters, Hornback, Duskflit), **leap** (library monsters, Cragjaw) and **shoot**
(library monsters, Murkspore); each enemy
keeps its own range. Thornmite, Fuzzbob and Mosstrot have no attack (they hurt on touch).
A skipped family attack waits its recovery before trying again.

**Follow-ups** (`follow_up`, `follow_up_count`, `follow_up_gap_s`; "Then / Times / Every (s)"): another attack done
right after this one, that many times, that far apart; its score is added that many times. The Ape's **retreat leap**
(`ape_retreat`, top priority, 0-5.5 tiles, only when the player is cornered: in scream range with a wall behind them,
not above or below) lands at the far end of its range, then throws `ape_throw` 3 times, 0.35 s apart. With the retreat
skipped or removed, a cornered Ape does a plain leap instead.

Attack types: body movement, melee, ranged, area and **movement** (charge, leap, the Ape's leaps and landing slam: the move
decides how long they last). Execution is read-only for ranged attacks (they spawn a projectile) and movement attacks
(the move sets the time). Movement values instead: **Max distance** (tiles) for charge, which stops sooner at a
wall, a ledge or anything they hit; **Shockwave time** (seconds) for the landing slam. Leaps end on landing.

Body and movement attacks (charge, leap, the Ape's leaps) hit with the enemy's own body: they have no area of their own
(blank `coverage_area_units2`, shown as "body"); scores use the body's size (a 10x10 px library monster or the
Ape's 3x3 tiles as the reference in the Attacks tab, each enemy's real size in Enemies).

The source tables are [attacks.csv](../data/attacks.csv) and
[enemy_attacks.csv](../data/enemy_attacks.csv). A blank means unspecified, not zero.
External spreadsheet edits take effect after Reload CSV or restarting the game.

## What currently controls gameplay

Library monsters read CSV wind-up and recovery. Charge reads speed and max distance (walkers along the floor, flyers
straight at the player); straight shots read speed and execution duration. Leaps read initial
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
to 5 at two seconds. All type weights initially equal 1.

**Multishot** (`multishot`, `aimed_shot`, `spread_deg`): an attack fires `multishot` projectiles at once;
`aimed_shot` is the one pointing at the player (0 = the lowest, numbers go upward); `spread_deg` is the angle
between neighbouring shots, and 0 spaces them evenly around the full circle. Library monsters' shoot and lob fire
the whole fan. For the score, shots within 30 degrees of the aimed one count fully and the others count 20%.

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
