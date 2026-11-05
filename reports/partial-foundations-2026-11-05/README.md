# First partial-system batch — 2026-11-05

Delivered:

- Ordinary enemy family base-health overrides, including the library monster.
  A compact Base health field is available in Enemy loadouts. Saving persists an
  optional max_hp profile, variants apply their modifiers afterwards, and clearing
  the override restores the original default. Invalid zero/fractional/out-of-range
  values are rejected. Existing living actors keep their HP.
- Shared fractional floor motion and surface-crawler corner traversal in
  scripts/motion/surface_patrol.gd, called by the existing enemy adapters. Support,
  collision, hazard avoidance and per-pixel player contact remain actor/World rules.
- Shared bounded brood child definitions in scripts/actors/death_actions.gd,
  consumed once on death through World's spawn queue. Library children preserve
  their authored movement/attacks and lose the brood trait.
- Health authoring/modifier rules in scripts/actors/enemy_health.gd. Library monster
  loadouts are now reachable in the editor; code-driven attack families still have
  editable family health. Ape phases and Guardian vent-puzzle behaviour are retained.

Verification:

- partial_foundations.tscn: 16 checks, 0 failures. Exercises actual enemy spawns,
  real editor controls, catalogue round-trip, movement and duplicate-hit death cases.
- attack_catalog.tscn: ATTACK CATALOG OK; known renderer shutdown leak diagnostics.
- stress.tscn and ape_composition.tscn: 0 failures.
- smoke.tscn: SMOKE OK.
- test.tscn: one existing Jungle Falls story-bot traversal failure; no new failures.
  Existing corner traversal, variant movement and brood tests pass.
- GDScript lint and git diff --check pass. family-health.png was visually inspected;
  the capture changes only an unsaved draft under disposable user storage.

Boundaries: arbitrary-object/path authoring, sticky-placement controls, generic
conditioned death/drop lists, shared attached weapons and general phase editing
remain pending. This is a completed foundation batch, not completion of every row
in docs/IMPLEMENTATION_STATUS.md. No world room files were edited for this batch.
