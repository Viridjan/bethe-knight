# Ape composition: first implementation slice

The Enemy tab now edits health, phase-two threshold, and the phase-entry wave-scale
sequence. Trigger-only effects appear after selected attacks and bypass AI
eligibility/chance checks. Falling/thrown logs share projectile collision and floor
impact; phase-two parents split at the apex into two ordinary logs. Each valid
child floor impact makes a spike. Collision with another object can end a log
before floor impact.

Transient effects are cancelled on the lethal hit. Ground waves are anchored at
the landing point. A regression also covers the old infinite corner-search loop
when the player is exactly vertically aligned with the Ape.

Authoring: `data/attacks.csv`, `data/enemy_attacks.csv`, and
`data/enemy_profiles.json`. The existing Save stages the full content set and
includes profiles in external-edit checks. This extends its synchronous rollback;
it does not implement the future crash-recovery manifest described in the plan.

## Verification

All four scenes exited 0 after the final gameplay/editor changes:

```sh
godot --headless --path . res://tests/test.tscn
godot --headless --path . res://tests/smoke.tscn
godot --headless --path . res://tests/attack_catalog.tscn
godot --headless --path . res://tests/ape_composition.tscn
```

Physics: 0 failures. Smoke: SMOKE OK. Catalogue: ATTACK CATALOG OK.
Ape composition: 0 failures. The smoke scene still emits its pre-existing
`ApeChase: no path found to x 496` warning for its synthetic fixture, also observed
before these changes. No new runtime/script errors appeared in these runs.

The editor import completed successfully using disposable settings. Rendered
captures were inspected: [health/phase controls](editor.png),
[attack controls](attacks.png), [triggered effects](effects.png), and
[arena/log appearance](arena.png). `capture.tscn` reproduces these fixtures without
saving an adventure or modifying a room.

Tests were first observed failing for missing authored health/trigger bindings,
then for rounded profile persistence, death cleanup, shared dimensions, anchored
waves, and pending scores. The vertical-alignment regression timed out before the
wall-search guard and completed afterward.

## Remaining scope

This is the first Ape slice of the [mechanics plan](../../docs/MECHANICS_ARCHITECTURE_PLAN.md).
General event-graph authoring/attack runners, traps, patrol authoring, inventory,
player-state extraction, hidden-terrain mechanics, and the level pass remain
planned. Encounter decision/choreography code still lives in `entities.gd` while
projectile and area mechanics have moved to `scripts/effects/attack_effects.gd`.
Consequence-chain scoring and final encounter tuning remain separate decisions.
