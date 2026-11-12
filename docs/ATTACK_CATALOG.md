# Attack CSVs and the Monsters editor

Open **Monster Editor** from the desktop main menu. The in-game map's Monsters
view also provides access to the catalogue.

## Editing

- **Attack library**: search by name, ID, or type. Common settings are grouped in
  cards; Trajectory and Advanced settings expand when needed. The selected
  attack's score is shown beside its name, with the calculation in hover help.
- **Enemy loadouts**: search enemies and review attacks
  in priority order. Range, skip chance, and ordering controls remain visible.
  Use its **Edit** button for mechanics and follow-up settings.
  The page shows no images (removed 2026-11-12 until real attack animations exist).
- **Save changes** and **Reload** stay at the top right. Save validates the draft;
  saving/reloading preserves the selected enemy view. Long score explanations
  are available on hover.

Attack values are shared by every enemy that uses that attack. CSV float inputs
and displayed values use two decimals; calculations keep full precision.
The first six attack columns are name, research label, type, wind-up seconds,
execution seconds, and calculated score. Extra columns hold the scoring inputs
and parameters needed by existing attacks. CSV headers match `data/attacks.csv`.

- **Save changes** validates and stages both tables and enemy profiles before replacing them. Only saving
  changes the shared runtime catalogue. Edits to a running attack do not change
  its captured parameters; new selections use the saved values.
  If replacement fails, it restores replaced files that existed before the attempt,
  removes newly created final files, and cleans staged temporary files. Stale backups
  are not mistaken for prior files. Incomplete rollback/cleanup is reported explicitly.
- **Reload** rereads disk, refreshes the shared catalogue, and asks before
  discarding a draft. Saving refuses to overwrite files changed externally since
  they were loaded.
- **Enemy loadouts** lists every enemy. Editable (attacks in the CSV): the Ape (both phases on one page) and the six
  attacking families (Dropwing, Duskflit, Ossling, Hornback, Cragjaw, Murkspore); the others (variants, Thornmite,
  Fuzzbob, Mosstrot, the chase Ape, the Guardian) are read-only (sprite, frames, HP, where they're placed). Attacks
  are in **priority order**: the first one in range (minimum inclusive, maximum exclusive; empty / 0 = no maximum),
  eligible and not skipped starts. ▲ / ▼ reorder, ✕ removes it from the enemy, "+ Add attack" adds any catalogue
  attack or a new planned one (attacks the enemy's code can't do yet are tagged "not in game yet" and skipped in
  play). **Skip %** is the chance an attack passes its turn to the next one. Under each attack: its frames, its
  values (the same boxes for every attack of a type) and its follow-up (Then / Times / Every, or "+ Then…"). The
  score line stays pinned below the list. An invalid value shows in red.
- **Attack library** holds what defines each attack: Name, ID (renamed on Enter or leaving the box; refused when
  empty, taken, or used by the game code, including the Ape's shockwave, splitting log, ordinary log and spikes), Type, Weight and the boxes of
  its type; **Delete attack** for attacks no code uses. Multishot is 1-64 and follow-up Times 1-10; follow-ups can't
  loop back. Esc and Back both ask before dropping unsaved edits.
- Family loadouts rule the fight: an enemy attacks only inside [minimum, maximum) and never once its attack is
  removed. Follow-ups the game can't run yet are marked "not in game yet" (today only the Ape's retreat → log
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

## Ape phases and consequences

The Monster Editor opens on **Enemy loadouts**; the attack library remains available
in its own tab. The Ape has one loadout page for both phases. Shared mechanics are
edited once; phase-labelled rows keep range, skip chance, and priority independent.
Removing a phase binding leaves the other phase intact. The Add attack selector
can assign to either phase or both; existing bindings are preserved. Effect source
tooltips describe the configured spawn chains. Compact inputs retain full labels.

The Ape's **Health & phase entry** card edits maximum health, phase-two HP threshold,
and a comma-separated list of shockwave scales. One in-place leap is performed for
each scale, once when phase two begins. Defaults: 4 HP, phase two at 2 HP, scales
1.3 and 1.7. Later screams do not repeat the phase-entry sequence. These settings
live in [enemy_profiles.json](../data/enemy_profiles.json), shared by both phase
pages. They apply to newly created encounters. Save/Reload and external-change
checks include this file, and saved wave scales use at most two decimals.

The binding CSV stores selected attacks. Older files with `activation_mode = triggered`
remain readable; saving migrates those redundant rows out of the CSV. A missing/empty
mode retains the old selected behavior. The editor derives its phase-aware
**Triggered effects** section from the profile references used by gameplay:
`landing_effects`, `throw_effect`, `phase2_throw_effect`, and `log_impact_effect`.
Changing those references changes the listing; the splitting variant appears only
when the selected phase uses it. The section is always last. Its entries have no editable
range, skip, or order controls and never perform AI eligibility/chance checks.
Their mechanics remain editable. The profile's validated effect references
describe landing → shockwave/log and log floor impact → spikes.
The effect names and section heading expose tooltips generated from those same
links. They list the current source attack/effect names and triggering events,
and refresh when a source name is edited without leaving the page.

Ordinary falling and thrown logs use the same projectile implementation and floor
impact behavior. The shared log area controls their dimensions; launch velocity,
gravity, and warning can differ. Phase-two throws spawn a splitting log: when it
hits the floor it leaves no spike itself and produces two ordinary logs that hop
outwards, cannot split again and each make a spike on valid tile ground. A child whose initial position is obstructed is
cancelled with a visible burst; it is never placed through a wall. Walls, player hits, and leaving the room do not create
floor spikes. Encounter death cancels transient effects; permanent arena aftermath
continues to use the existing boss flags and spike restoration.

The Enemy-tab total now labels **Selected attacks** separately. Triggered chains
are excluded from that total until a consequence-scoring policy is agreed;
individual reference-pending effects must not be treated as a complete encounter
score. The pixel physics and public attack IDs are preserved. Shared projectile
and area primitives live in `scripts/effects/attack_effects.gd`; arena decisions,
rewards, and gates remain in the encounter implementation.

Regression scene: `godot --headless --path . res://tests/ape_composition.tscn`.

## What currently controls gameplay

### Behavior kinds (2026-11-12)

Each attack row has a `behavior`: `charge`, `leap`, `straight_shot`, `lobbed_shot`, `dive`, or one of the Ape's four
scripted kinds. Enemy code implements kinds, never single attacks (`AttackCatalog.SUPPORTED`): a library monster
performs any bound row with one of its four kinds, and each fixed family (Dropwing, bat, Ossling, Hornback, Cragjaw,
Murkspore) uses the highest-priority bound row of its own kind, with that row's numbers. A new row therefore works in
game as soon as it has a behavior and a binding; choosing a behavior in the Attack library marks it implemented. An
empty behavior means data only. Built-in rows keep their behavior, because code, levels and tests name them.

Still scripted, not data: the Ape's choice rules and its four kinds, follow-up chains other than retreat then throw,
split/spike/slam effects, projectile size and lifetime, and the non-Ape enemies' bodies and movement.

Library monsters read CSV wind-up and recovery. Charge reads speed and max distance (walkers along the floor, flyers
straight at the player); straight shots read speed and execution duration. Leaps read initial
horizontal/vertical components and gravity, ending on landing. Lobbed shots read
flight-time, vertical velocity, gravity, and release-animation duration. Trait
modifiers remain applied as before. Body size and the 3×3 pixel small-projectile
hitbox remain defined by the entity implementation.

The Ape reads ordinary attack wind-ups, recovery, scream coverage/duration,
leap flight-time/gravity, thrown-log flight-time/gravity parameters, split-child
velocity components, shared log area/warning/gravity, and slam area/duration. Its ordinary attack choice
uses normal/enraged range rows. Random throw eligibility and scripted wake-up,
hurt, corner escape, trunk transitions, and volleys remain boss logic; phase-entry
hops use the enemy profile. Ground shockwaves remain at their landing location.

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

Moving hits (ranged shots, body and movement attacks with a speed) count the strip they sweep too:
`area = hitbox_area + √hitbox_area × 15` (`SWEEP_LENGTH`, tiles). Area attacks already count their whole area, so this
keeps types comparable. Final scores truncate to whole numbers: Ape scream 164, leap 104, log throw 28, slam 37; library charge 13, leap 26,
shot 3, lob 7. Tune `SWEEP_LENGTH` in `scripts/attack_catalog.gd`, then refresh the score column.

```
raw = base_weight × area / measured_time × weighted_projectile_count
penalty = 1 + 4 × clamp((windup - measured_time) / (2 - measured_time), 0, 1)
score = int(raw / penalty + follow_up_total)
```

Each follow-up contributes its returned integer score; enemy totals likewise truncate at their returned score boundary. Stored CSV scores and editor totals use whole numbers. Intermediate area, speed, time and penalty calculations retain precision.

This implements a neutral penalty of 1 at or below measured time, rising linearly
to 5 at two seconds. All type weights initially equal 1.

**Multishot** (`multishot`, `aimed_shot`, `spread_deg`): an attack fires `multishot` projectiles at once;
`aimed_shot` is the one pointing at the player (0 = the lowest, numbers go upward); `spread_deg` is the angle
between neighbouring shots, and 0 spaces them evenly around the full circle. Library monsters' shoot and lob fire
the whole fan. For the score, shots within 30 degrees of the aimed one count fully and the others count 20%.

Scores for measured times of two seconds or more remain unavailable because the
requested curve's anchors conflict there. Falling logs also remain unscored:
they start at rest, so initial-speed reference travel time is undefined. Neither
case is silently given a fabricated score. The inspector shows selected-attack
subtotals with body area added once; triggered effect-chain totals remain pending.
Repeated hops and enlarged shockwaves use
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

Expanded enemy attack settings use the card width in two columns of groups:
Timing, Damage & speed, Projectile pattern, and Trajectory. Numeric controls
stretch within each group; animation references and follow-up controls remain
available. This is a layout change and does not change attack parameters.

## Family health and shared foundations (2026-11-05)

Ordinary enemy families now have a **Base health** field in Enemy loadouts,
including the **Library monster** entry. Variants edit their family's base value;
swift/armored/giant/shielded modifiers are applied afterwards. Library monsters
apply their trait list once in its saved order. Clearing the field restores the
original family or movement-based default. Save changes before spawning a new
runtime enemy; already living enemies keep their health.

Health overrides live in `enemy_profiles.json` as optional `enemy_*` profiles with
`max_hp` (whole number 1–10000). The same validator is used for load and save.
Attack mechanics for code-driven families remain code-driven, so their divider is
labelled accordingly. Their health can still be edited. Ape's existing health and
phase-entry card is unchanged; Guardian still uses its vent-plug puzzle.

`actors/enemy_health.gd` owns health authoring/modifiers. `motion/surface_patrol.gd`
owns fractional floor movement and sticky crawler corner traversal, using injected
collision/support/contact adapters. `actors/death_actions.gd` builds the existing
bounded brood child definitions, consumed once on a real death through World's
spawn queue. These are shared foundations, not yet arbitrary object/path authoring,
quest-conditioned drops, configurable attached weapons, or a general phase editor.

Enemy loadout cards expose one **Range** field: the maximum center-to-center distance in tiles; **0 = any range**. Minimum distance is no longer shown in this page; shipped bindings have zero minimum. The existing CSV column remains compatible with legacy external definitions. Mechanics cards use natural widths and wrap as the pane narrows, rather than stretching into equal columns.

Ape attack bindings also have a per-phase **Trigger** selector (`trigger_condition` in the range CSV): **Normal rules**, **Player cornered**, **Player above/below**, or **Always**. Retreat leap defaults to Player cornered, using the ground-corridor coverage definition below. Above/below uses the Ape's existing vertical-alignment test. Distance is set with each binding's own Range (the old nearby/far triggers, which borrowed the scream's range, were removed on 2026-11-12).

An explicit trigger replaces that attack's normal decision heuristic. It enables a candidate rather than interrupting the current animation: priority, Range, Skip %, and skip cooldown still decide when the attack starts while the Ape is idle. Normal rules retains the old per-attack heuristic. Triggered landing/projectile effects and follow-ups remain separate. Hornback and library-monster bindings additionally expose Normal rules / Player cornered; other Ape context conditions remain Ape-only. Their default decision rules are unchanged. Old files without the column receive the same cornered-retreat default on load.


**Player cornered — coverage definition.** Enemy profiles select `cornered_coverage_attack`, separate from the attack binding that reacts to it. The Ape defaults to `ape_scream`; the enemy settings show a Cornered coverage selector. Disabled turns this condition off. Only attacks with an accurate registered coverage adapter can be selected. The Ape supplies its circular scream; Hornback families and grounded library monsters supply a floor-charge sweep. Flying charges, leaps and projectiles are not approximated as solid coverage of their travel bounds. Ordinary profiles default to Disabled.

The shared `combat/cornered_coverage.gd` detector requires a grounded player on a supported floor within one tile of the enemy's floor. It searches toward the player, starting outside the enemy body. Any solid collision in the first three tile rows above the player's floor counts as the nearest wall, including a lone low block or overhang. One-way platforms may support the floor but do not count as walls. The player body must be fully between the enemy and the wall.

Candidate search uses an attack-bounds-sized rectangle centred on the player, enlarged by two tiles total (one on each edge). Both enemy centre and wall must lie in that tracer. It does not enlarge the attack. For every clear standing position in the corridor, at pixel spacing, the chosen attack's real hit predicate must hit the player's damage rectangle. Floor gaps, a floor-level difference exceeding one tile, missing walls and any uncovered standing position make the condition false. Circle checks use the same strict circle-versus-rectangle routine as actual scream damage. Searches over 4096 pixels are conservatively rejected.

This tests covered ground-level space, not whether jumping, climbing or breaking the qualifying block could escape. The detector itself accepts real rectangular or circular providers and generic solid/support queries. Other enemies still need their own accurate footprint/context adapter before their UI can offer this trigger.


**Ordinary ground charges (2026-11-10).** The forecast uses the real floor controller, collision body, speed/assist scale, maximum distance and fractional remainder in disposable state. Existing ledge, solid, spike and acid stopping rules clip the swept damage rectangle. The candidate envelope spans potential left/right travel; only the actual current-direction clipped sweep supplies `hits()`. Actor/player state is not changed. Both AI decision paths consume the condition; library instances without grounded charge support return false. Profile/CSV Save and Reload preserve coverage, health and reaction selection. See [delivery evidence and editor captures](../reports/ordinary-cornered-2026-11-10/README.md).
