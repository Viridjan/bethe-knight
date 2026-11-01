# Plan: attack catalogue, scoring, and enemy selection

Status: implementation checkpoint, 2026-10-31. The CSV catalogue, score calculator,
Monsters editor, ActionMonster integration, and ordinary Ape range selection are
implemented. See [the usage guide](ATTACK_CATALOG.md) for scope and remaining limits.
The sections below retain the original design plan; automatic melee coverage and
composite boss scoring remain future work.
Confirmed: longer wind-up lowers the score; the selector executes only the first
eligible attack. The wind-up penalty reaches 5 at two seconds and decreases
linearly toward the attack's measured time. Interpretation awaiting confirmation:
penalty is 1 at equal timing and stays 1 below it. The case where measured attack
time is already two seconds or longer still needs a rule.

## 1. Data model

Make CSV the editable source of attack parameters. Generate the runtime catalogue
and derived score column from it; do not maintain a second set of timing constants
in GDScript. Score is an estimate of threat, not measured difficulty.

`data/attacks.csv` starts with the requested six columns:

| Column | Meaning |
|---|---|
| name | Stable attack name/key used by the game |
| codex_online_name | Human-readable name from research; metadata only |
| type | `body`, `melee`, `ranged`, or `area` |
| windup_s | Warning time before the damaging action starts |
| animation_s | Execution animation duration, excluding wind-up and recovery |
| score | Generated value, never an independently edited input |

Additional inputs needed to reproduce the score: `base_weight`,
`coverage_area_units2`, `initial_speed_units_s`, `multishot`, `aimed_shot`,
`spread_deg`, and `recovery_s`. Put the source link in `notes` ("Source: ...") to
identify the research reference; researched names without a verified source
remain explicitly marked as proposed. Geometry can use a shape reference rather
than a hand-maintained area when a hitbox definition already exists.

`data/enemy_attacks.csv` binds attacks to enemies, including the Ape:

`enemy_id,phase,attack_name,min_range_units,max_range_units,priority`

Ranges belong to the assignment because the same attack can serve different enemy
sizes and phases. Include them even for a single-attack enemy for consistency.
Cooldown/phase/ground/line-of-sight restrictions also belong to eligibility, with
explicit fields added for the conditions actually required by existing attacks.

Enemy hitbox geometry stays in the enemy definition. Add its area once to the
final enemy score, never once per attack.

## 2. Units and timing

- Use seconds and tile units throughout scoring. One Summit tile is 8 pixels.
  The proposed reference room width is 20 units = 160 pixels.
- Measure damage geometry, not sprite dimensions, including scale modifiers.
- Keep wind-up, execution, damage-active interval, recovery, projectile lifetime,
  and reference travel time distinct. An animation can finish while a shot lives.
- Convert initial velocity from pixels/second to units/second before scoring.
- For ballistic shots, use the magnitude of initial velocity; intentionally
  ignore gravity, curvature, subsequent acceleration, and homing in this model.
- Do not divide by zero. Reject moving attacks with nonpositive speed and attacks
  with nonpositive measured execution time. A genuinely instantaneous hit needs
  an explicit scoring duration floor of one physics tick (1/60 second), flagged
  in validation; it must not silently produce infinity.

## 3. Proposed score equations

Let B be the configurable base weight for the attack type. Start all four types
at B = 1 until comparisons justify different weights; no type ranking is assumed.
Let A be damage coverage area in square units and t be the measurement duration.

    raw_score = B * A / t
    attack_score = raw_score / windup_penalty(w)

The division is confirmed: more warning lowers threat.

Let w be wind-up in seconds and t be the measured attack time defined below.
For t < 2 seconds, interpret the requested linear curve as:

    windup_penalty(w, t) = 1 + 4 * clamp((w - t) / (2 seconds - t), 0, 1)

This gives a neutral penalty of 1 when w <= t, increases linearly from 1 to 5
between t and two seconds, and stays at 5 for longer wind-ups. The neutral floor
is an explicit proposed interpretation, not an additional confirmed requirement.
For example, when t = 0.5 seconds:

| Wind-up | Penalty | Score relative to raw score |
|---|---|---|
| 0 seconds | 1 | 100% |
| 0.5 seconds | 1 | 100% |
| 1.25 seconds | 3 | 33.33% |
| 2 seconds or longer | 5 | 20% |

Open edge case: when t >= 2 seconds, the anchors "1 at equal timing" and "5 at
two seconds" conflict (and at t = 2 the denominator is zero). Do not evaluate
this expression for those attacks until a policy is agreed. Candidate policies:
keep a neutral factor of 1, or move the maximum to t + 2 seconds. Never silently
clamp the denominator to an epsilon, which would hide the design conflict.

The comparison uses a duration, not velocity: for moving attacks, t is the
20-unit reference travel time; for melee and area attacks, it is the execution
or coverage duration described below.

### Melee

A = union of the damaging hitbox positions over one full attack, without counting
overlapping space repeatedly. t = execution time until the attack finishes
covering that area. Wind-up is excluded here because it is already accounted for
by the warning penalty. If the intended denominator is wind-up + execution, choose
that instead and reassess the penalty to avoid charging for the same warning twice.

### Ranged and moving objects

    t = 20 / initial_speed_units_s
    A = projectile damage-hitbox area

Score each projectile with the same rule. A thrown or otherwise detached moving
item is ranged even if its emitter is performing a melee-looking animation.

Update 2026-11-01: moving objects also count their swept strip (hitbox width × 15 tiles) so their scores compare
with area attacks; see ATTACK_CATALOG.md "Scores".

### Body

Use the ranged formula with the enemy's damaging body area and its attack's
initial movement speed. The body-area baseline added to the enemy score remains
separate: it represents the size of the enemy, while the body-attack component
represents its attacking motion.

### Area

A = union of the area damaged during the attack; t = time from activation until
that area has been covered. For a static pulse or lingering zone, use its damage-
active duration. This follows the requested area/time model, but means longer-
lasting static hazards score lower; verify that outcome before treating the score
as difficulty. For an expanding ring, use time to reach the final damaging area.
Wind-up is again separate.

### Multi-shot and omnidirectional

For identical projectiles:

    volley = (shots within 30 degrees of the aimed one + 0.2 * the other shots) * single_projectile_score

(columns `multishot`, `aimed_shot`, `spread_deg`; spread 0 = evenly around the full circle)

For different projectiles, sum their individual weighted scores. Snapshot the
player direction when the volley is committed. Define "toward" as a positive dot
product between initial velocity and the emitter-to-player vector; perpendicular
shots count as other. Use the authored firing pattern for catalogue scoring, with
an explicit reference player direction. Actual encounters may have different
counts; keep the reference score stable rather than changing it every frame.

### Enemy total

Provisional aggregation, pending calibration:

    enemy_score = actual_body_hitbox_area + sum(assigned_attack_scores)

Count each distinct available attack once per phase, not repeated range bindings.
Produce separate phase scores for the Ape rather than summing mutually exclusive
phases. This sum deliberately rates variety; it does not model attack frequency.
Recovery, simultaneous attacks, and cooldowns can change encounter difficulty
without changing the requested basic score.

## 4. Range selection

Proposed deterministic selector:

1. Only consider attacks assigned to the current enemy and phase.
2. Sort by descending maximum range, then explicit priority, then stable CSV order.
3. Check distance against the attack's interval and all eligibility conditions.
4. Continue to the next row when a check fails.
5. Start the first eligible attack and stop selecting until its attack cycle ends.

Use center-to-center radial distance in tile units, matching the Ape's current
radial selection, with separate alignment/height restrictions when necessary.
Use half-open intervals `[min, max)` to make adjacent boundaries unambiguous.

Example: a throw valid for `[8, 20)` is checked before a leap valid for `[3, 8)`,
then a scream valid for `[0, 3)`. Ranges are illustrative, not proposed balance
changes. Using only maximum ranges would allow the farthest attack to win at
all shorter distances too. Overlapping ranges are allowed only as intentional
fallbacks; warn when a later row can never be selected.

Execution of only the first eligible attack is confirmed. Do not start later
eligible attacks in the same scan; reconsider selection after the current cycle.

## 5. Ape migration

Inventory scream, leap/contact, landing slam, stone throw/volley, split stones,
and phase-two hops/log hazards separately. Build composite attacks from components
so leap + slam and split-projectile volleys do not get counted twice.

Route ordinary attack choice through the common range selector. Explicitly keep
boss lifecycle and scripted safety transitions separate: wake-up scream, hurt
reaction, corner escape, trunk constraints, phase changes, and death. Decide
whether the current random throw chance survives as an eligibility rule; deterministic
range selection otherwise changes the fight. Record that choice rather than
accidentally dropping randomness or escape behavior during migration.

## 6. Implementation stages

1. Resolve the wind-up curve floor and slow-attack edge case, unit convention,
   and reference direction for radial volleys. Approve a few worked scores before bulk data entry.
2. Inventory live hitboxes, timings, speeds, and trait/phase modifiers. Mark research
   candidates separately from attacks implemented in the game.
3. Add CSV files, validation, a deterministic score generator, and a generated runtime
   catalogue. Reject duplicate keys, missing bindings, invalid types, NaN values,
   and invalid durations/ranges. Report shadowed range rules and stale scores.
4. Migrate ActionMonster parameters and selection; preserve existing saves by retaining
   charge/leap/shoot/lob/dive identifiers and provide defaults for legacy entities.
5. Migrate the Ape after ordinary-enemy selection passes. Keep authored boss sequences
   and test hooks explicit, then playtest both phases.
6. Expose names, ranges, score breakdown, and phase totals in desktop editor/debug
   tools. Include only gameplay catalogue data in web builds.

## 7. Verification

- Doubling area or speed doubles the raw score; doubling time halves it.
- Zero warning is finite. Under the proposed floor, warnings up to measured attack
  time leave the score unchanged; above it, longer warnings lower the score.
  Verify the linear midpoint and the maximum penalty of 5 at two seconds.
- Measured times equal to or greater than two seconds use the agreed explicit
  edge-case policy and never divide by zero.
- Projectile count scales normally; 2 toward + 6 away gives 3.2 projectile scores.
- The same initial speed scores equally for straight and ballistic trajectories.
- Melee coverage unions exclude overlapping samples. Scale/trait effects are applied
  to geometry and timing before calculating the effective score.
- Enemy baseline area is added once; composite attacks and phase bindings do not
  duplicate components.
- Range boundaries, stable descending order, ineligible fallback, no valid attack,
  and overlap warnings behave deterministically.
- Ape opening, corner escape, trunk interaction, phase-two changes, and death still
  work after adopting the selector.
- Run focused scoring/selection checks, then existing physics and smoke runners;
  verify the web catalogue contains no dependency on editor tooling.
