# Fix prompt: recursive Ape dependency audit

Verified against production code at `953b8ca`. Read [REVIEW.md](REVIEW.md) for
evidence, priorities, measurements, and corrections to the earlier prompt.
This is a fix prompt; the review itself has not fixed production behavior.

```text
Fix the verified Ape composition/dependency defects described below. Stay inside
/home/viridjan/Projects/videogame and read AGENTS.md, docs/ATTACK_CATALOG.md,
docs/MECHANICS_ARCHITECTURE_PLAN.md, and docs/reviews/ape-recursive/REVIEW.md first.

Context
- scripts/entities.gd contains the RefCounted Ape and CombatEnemy family helpers.
  World owns update/collision/render order; entities are not CharacterBody2D nodes.
- scripts/effects/attack_effects.gd owns detached projectiles, splitting, and areas.
- scripts/attack_catalog.gd loads/validates/scores/saves two CSVs plus
  data/enemy_profiles.json; scripts/attack_catalog_editor.gd edits a private draft.
- Both existing shipped-data suites are green. Targeted probes under
  reports/ape-recursive-review-2026-11-03 reproduce bugs they do not cover.
- The earlier docs/reviews/ape-composition/CODEX_PROMPT.md was cross-checked and
  corrected. Do not resurrect its withdrawn rollback diagnosis or scoring demand.

Constraints
- Do not modify worlds/, regenerate authored rooms, or write personal runtime data.
- Preserve the 8px tile model, pixel mover, 60 Hz physics, arena gates/rewards,
  phase-two red flash, requested log/spike consequences, and intended phase entry.
- No ECS rewrite, new physics engine, or unrelated visual redesign.
- Preserve old catalogue/room compatibility through explicit defaults/migrations.
- Retain one authoritative source per mechanic. Raw editor text, validated
  definitions, and runtime snapshots must not be interchangeable mutable objects.
- Use TDD: add a behavioral regression, observe the expected failure, then fix it.
  Do not weaken assertions or edit production data to make tests pass. One tested
  commit and one dated gdd.txt line per task. Related tasks may share helpers, but
  preserve reviewable commits and explicit validation evidence.

Blocking tasks
1. Ballistic validity: zero ape_leap gravity currently validates and leaves the
   actor in air forever. Add behavior-specific validation of effective, rounded
   leap parameters and safe execution guards. Keep intentional zero gravity legal
   for other mechanics. Test a valid normal leap, invalid zero-gravity leap, and
   boundary values after authored rounding. Invalid content must not softlock an
   encounter or overwrite the last valid catalogue.

2. Repairable editor drafts: clearing Health then switching Ape phase pages stores
   null and calls int(null), destroying the health inputs. Keep raw invalid text
   repairable across navigation, with a clear validation reason and Save disabled.
   Preserve unrelated draft edits. Test blank/non-numeric Health and phase threshold,
   navigation away/back, correction, successful save, and no engine errors. Use a
   real private editor catalogue, not the shared runtime singleton as a test double.

Major tasks
3. Shockwave defaults/geometry: present-but-empty shockwave_s becomes 0 rather
   than its 0.2s fallback; zero area creates a zero-width active wave and image
   errors. Normalize optional cells consistently and validate derived pixel sizes
   after rounding and hop scaling. Test blank duration, zero and tiny area, and
   all allowed phase-entry scales. Guard texture creation without disguising bad
   authored data as a valid complete effect. Keep profile-based effect disabling.

4. One leap snapshot: retreat launch reads ape_retreat gravity but the air state
   reads ape_leap gravity. Carry the selected leap's identity/effective values
   through its lifecycle. Test retreat gravity 25 tiles/s^2 versus ordinary 75:
   launch vy -75 must become -71.6667 after one 1/60s tick, not -65. Editing the
   other attack mid-flight must not alter the active snapshot. Verify corner escape.

5. Honest/shared effect controls: editing ape_throw area or ape_split gravity does
   not change actual geometry/physics. Establish the canonical log shape and each
   launch profile; link controls to the real source or make derived/reference-only
   fields explicitly read-only with source help. Test visible edits through the
   editor against the spawned projectile, save/reload, and relevant reference
   score inputs. Do not silently convert every scoring-only field into a new
   gameplay feature; document intentional reference-only parameters accurately.

6. Collision before consuming a split parent: splitting currently bypasses an
   overlapping player at the apex and leaves a gap between children. Define
   collision/event precedence and test it. Use the probe's parent (100,100),
   size (19,6), velocity (0,-1), gravity 200, player box (105,100,8,6), dt=1/60.
   The contact must not vanish. Preserve once-only damage, bounded child count,
   no recursive splitting, and collision-free ordinary splitting behavior.

7. Bounded projectile work: bounds rejection currently follows the full sweep.
   An already-outside object at (600,40), room 480x240, speed 983040px/s, dt=1/60
   causes 32768 terrain queries before removal, despite the CSV speed validating.
   Reject expired/outside input before costly work and constrain trajectory/work
   safely. Keep high-speed collision correct; do not cap steps then teleport the
   remaining distance. Test outside, edge-overlap, fast floor/player collision,
   split-child boundaries, invalid/non-finite data, and relevant game-speed assists.

Measured optimization and integration tasks
8. Avoid redundant work without changing collision semantics. A page build runs
   full validation nine times; reuse one operation/revision result for its score
   labels and totals, invalidating it on actual edits/reload. A vertical log makes
   duplicate solid queries for its unchanged X axis: consider initial-overlap
   detection followed by moving-axis sweeps. Preserve stationary/start-overlap
   behavior. Measure before/after on the supplied warmed probes; do not claim a
   mobile FPS improvement from headless microbenchmarks.

9. Normalize committed phase-scale display to at most two decimals. Input
   '1.234, 1.789' currently survives blur unchanged while Save correctly rounds it.
   Test blur, page navigation, and save/reload, preserving invalid text for repair
   as in task 2 rather than converting it into an unusable model.

10. Include tests/ape_composition.tscn in tools/verify.sh with its explicit
    zero-failure marker and engine-error filtering. Ensure failed exit statuses
    cannot be hidden by a previously printed success marker. Keep ordinary
    regression scenes separate from intentionally failing historical audit probes.

Previously reported issues reconfirmed in this audit
11. Effect graph/list/tooltips: triggered bindings can be removed while their
    effects still emit, and literal tooltips ignore profile changes. Derive the
    phase-aware listing/tooltips from the authoritative runtime definition or
    unify emission another compatible way. Test disabled landing effects, a
    phase-two-only splitting log, and that effects never enter AI eligibility.

12. Valid empty family loadouts: CombatEnemy interprets empty assignments as load
    failure and revives fallback attacks. Track load state independently and test
    a valid empty Hornback loadout, a removed single binding, and genuine failed
    reload with an existing last-valid catalogue.

13. Coherent backup recovery: save_all writes backups but reload does not recover
    a corrupted live set. Add validated, coherent content-set recovery for both
    CSVs and profiles. Test truncated live CSV/JSON, complete good backups, and
    bad/mixed backup generations; never silently combine incompatible files.
    Do not implement the old, impossible 'new profile before a later CSV failure'
    scenario: profiles are replaced last in the existing synchronous save order.

14. Test fixture isolation: HP=5 is valid but check_ape has two E.Ape.HP assumptions
    which fail its first-hit assertion. Use explicit controlled fixtures or
    fixture-derived expectations for HP and phase thresholds, including the new
    Ape suite. Preserve the exact one-hit/spike-removal check. Never modify the
    real data/enemy_profiles.json just to run a test.

15. Blocked split children: parent at (25,100) splits near a real boundary wall;
    the left child is born in terrain and disappears next tick with no event.
    Use bounded valid-position resolution or an explicit visible blocked/cancelled
    event if placement cannot succeed. Test full, partial, and impossible placement;
    do not force two children through solid geometry.

16. First-save rollback: save_all restores files that have backups but leaves new
    destinations behind. Test a fresh disposable directory with enemy_attacks.csv
    occupied by a directory: attacks.csv is created, assignment replacement fails,
    and the new attacks.csv currently remains despite the restoration message.
    Track prior existence, restore old files, remove newly created final files,
    and report cleanup failures honestly. Profiles are replaced last; do not use
    the old impossible profile-before-later-CSV failure scenario as this test.

Do not invent a new consequence-scoring formula. The UI deliberately labels the
subtotal 'Selected attacks' and marks consequence totals pending. Stones becoming
logs, ordinary-log floor spikes, and phase-entry hops were requested mechanics.

Verification
- Run targeted regression tests after each fix and all required gameplay/editor
  checks before completion, using disposable XDG_DATA_HOME data.
- sh tools/verify.sh -> 0 failing, with the Ape scene included after task 10.
- godot --headless --path . res://tests/ape_composition.tscn -> 0 failures.
- godot --headless --path . res://tests/attack_catalog.tscn -> ATTACK CATALOG OK.
- Reject new engine/script errors even if Godot exits 0. Report existing warning
  limitations separately. Inspect both phase pages and invalid-draft recovery in
  a rendered game; record actual measurements for optimization claims.
- git diff --check. Review the final diff to preserve all authored room edits.
```
