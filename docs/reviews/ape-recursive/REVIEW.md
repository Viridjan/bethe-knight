# Recursive review: Ape composition and dependencies (2026-11-03)

Reviewed the Ape slice recursively through `scripts/entities.gd`, `scripts/effects/attack_effects.gd`, `scripts/attack_catalog.gd`, `scripts/attack_catalog_editor.gd`, their CSV/profile data, relevant World/player collision and lifetime hooks, and verification tooling. Production baseline is `953b8ca` (identical gameplay code to `41fdbd0`; the intervening commit adds only a prompt). Methods: end-to-end source tracing, isolated runtime probes, the full verification script, the separate Ape regression scene, warmed timing samples, and fresh screenshots of both phase pages and a broken draft. Skills: code-review, systematic-debugging, verification-before-completion, godot-best-practices, godot-ui-control, godot-state-machine, save-systems, performance-optimization; TDD principles guide the fix prompt. Scope/reuse and bounded-file-data checks substitute for unavailable ponytail/security helpers. **New findings: 2 blocking, 5 major, 3 minor. Six earlier issues were also reproduced, including corrected evidence for the rollback gap.** This review changes documentation and review fixtures only.

The ordinary shipped-data checks are green. These findings concern accepted edits, boundary conditions, and dependency behavior that those checks do not cover. This is a dependency-scoped audit, not a claim that the entire game has been exhaustively proven correct.

## Findings

### 1. [BLOCKING] Valid zero-gravity edits make the boss fight unwinnable

`attack_catalog.gd:124–130` accepts zero `gravity_units_s2`. Set `ape_leap.gravity_units_s2` to `0.00`: both validation and save validation succeed. The launch in `entities.gd:2687–2690` then has zero vertical speed, and the airborne update never produces a downward landing. The Ape stays in `air`; its spike-based damage and attack-selection loop cannot proceed normally.

**Evidence:** [zero_leap.json](../../../reports/ape-recursive-review-2026-11-03/zero_leap.json): after 180 ticks, state remains `air`, vertical speed is 0, and HP is unchanged. The probe uses the real actor and terrain.

**Fix direction:** impose behavior-specific validity constraints for ballistic leaps, including after authored rounding, and guard runtime execution against invalid effective parameters. Generic nonnegative-number validation is insufficient. Keep zero gravity available to mechanics which intentionally support it; do not ban it globally.

### 2. [BLOCKING] An unfinished health edit destroys the editable health controls

In the real private editor draft, clear **Health**, then select the other Ape page. The text callback stores `null` (`attack_catalog_editor.gd:721–728`). Rebuilding the page calls `int(null)` at line 717, producing `Invalid call. Nonexistent 'int' constructor`. The health input is never added, so switching back cannot repair the value. Save is disabled, while Reload discards the entire draft, including unrelated edits.

**Evidence:** [invalid_health_ui.json](../../../reports/ape-recursive-review-2026-11-03/invalid_health_ui.json), [error log](../../../reports/ape-recursive-review-2026-11-03/invalid_health_ui.log), and [screenshot](../../../reports/ape-recursive-review-2026-11-03/invalid-health.png). The final probe uses an independently loaded editor catalogue, preserving the real draft/runtime separation; it does not inject an invalid live runtime catalogue.

**Fix direction:** retain raw invalid input separately from valid parsed definitions, or make the form robust to every intermediate draft value. Changing pages must preserve a repairable input and all unsaved edits without constructor errors.

### 3. [MAJOR] Shockwave optional/default geometry is not safely interpreted

`Ape._land()` at `entities.gd:2808–2811` uses dictionary `get()` defaults, which do not apply to present-but-empty CSV cells. Clearing `shockwave_s` therefore means lifetime 0 rather than the documented unspecified/fallback value 0.2. Setting area to `0.00` also passes save validation and creates a zero-width active wave. Its real `ape_art.gd::impact_texture()` path emits invalid-image/null-texture errors. Small positive areas can also round to zero pixels; merely testing `area > 0` is insufficient.

**Evidence:** [blank_wave_time.json](../../../reports/ape-recursive-review-2026-11-03/blank_wave_time.json): lifetime 0 instead of 0.2. [zero_wave.json](../../../reports/ape-recursive-review-2026-11-03/zero_wave.json): accepted area, width 0, null texture; [renderer helper errors](../../../reports/ape-recursive-review-2026-11-03/zero_wave.log).

**Fix direction:** normalize empty optional cells through the same value/default service used elsewhere, validate final pixel dimensions across allowed hop scales, and guard texture allocation. Explicitly disabling a landing effect already has a profile representation; a malformed dimension should not be the disabling mechanism.

### 4. [MAJOR] Retreat launches and airborne motion use different gravity definitions

Launch selects `ape_retreat` when appropriate and snapshots it, but the `air` branch always requests `ape_leap` (`entities.gd:2693`). Since `_ape_param()` only uses the snapshot for a matching ID, retreat flight reads the other attack's live gravity. Different authored gravities alter airtime, landing target, and corner-escape behavior. Editing ordinary-leap gravity during a retreat can also affect that running retreat despite the snapshot contract.

**Evidence:** [retreat_gravity.json](../../../reports/ape-recursive-review-2026-11-03/retreat_gravity.json): retreat gravity 25 tiles/s² launches at -75 px/s. One tick should yield -71.67 px/s, but produces -65 px/s using ordinary-leap gravity 75 tiles/s². Validation succeeds and the snapshot ID is `ape_retreat`.

**Fix direction:** keep the active leap ID/effective gravity through launch, flight, and recovery; consume the captured parameters for the entire action.

### 5. [MAJOR] Some exposed effect controls change scores but not the actual effect

`Ape._throw()` at `entities.gd:2767–2770` takes size from `ape_log` and child gravity from `ape_log`, regardless of the visible area on `ape_throw` or gravity on `ape_split`. Those fields remain editable through the type-based editor panels, with general gameplay-oriented labels. `ape_split` gravity affects neither the parent's throw gravity nor the children's gravity. The copied size/reference fields can diverge from the actual shared hitbox and its score.

**Evidence:** [ignored_values.json](../../../reports/ape-recursive-review-2026-11-03/ignored_values.json): throw area 40 still produces a 19×6 log; split gravity 100 tiles/s² still gives child gravity 200 px/s² rather than 800. Both edits validate.

**Fix direction:** establish one authoritative source for shared log geometry and each launch profile. Bind the relevant control to that source, or display a clearly read-only linked/reference value. Preserve intentionally reference-only speed/count fields, but label their runtime limits explicitly; do not make every scoring input change gameplay without a design decision.

### 6. [MAJOR] Splitting skips player collision at the apex

`attack_effects.gd:68–73` splits and deletes the parent before checking any overlap or movement collision. If the player entered its box this tick, the expected contact is lost. The children are placed one width to either side, leaving the parent's previous box empty, so the next tick need not repair the missed hit either.

**Evidence:** [apex_collision.json](../../../reports/ape-recursive-review-2026-11-03/apex_collision.json): the real 19×6 parent overlaps an 8×6 player damage box, crosses its apex, produces two children, and reports no player-hit event on that tick or the following tick. Solid queries delegate to the real World.

**Fix direction:** define and implement collision/event precedence before consuming the parent. Add overlapping-player and terrain-at-split tests alongside ordinary mid-flight splitting; preserve once-only hit and child spawning behavior.

### 7. [MAJOR] Already-outside projectiles perform an unbounded sweep before being discarded

Bounds rejection is after the entire per-pixel loop (`attack_effects.gd:74–98`). The catalogue also accepts very large component speeds without a behavioral bound. An outside object can therefore consume tens of thousands of terrain queries although it should already have expired. Child placement already has a known edge case near arena boundaries, so the effect service should not assume all inputs begin in free interior space.

**Evidence:** [outside_sweep_cost.json](../../../reports/ape-recursive-review-2026-11-03/outside_sweep_cost.json): an accepted 122,880 tiles/s speed, applied to a projectile already beyond the supplied room bounds, makes **32,768 real terrain queries and takes 111.24 ms** before removal. This is an adversarial authoring/API case, not evidence that shipped default combat is slow. Timing is a local debug/headless measurement, not a portable device benchmark.

**Fix direction:** reject expired/outside inputs before sweeping, validate finite practical trajectory parameters, and bound work without allowing tunnelling. Do not solve this by blindly clipping the step count while still applying the full displacement.

### 8. [MINOR] Measured repeated work is avoidable without changing mechanics

The Ape editor performs **9 complete catalogue validations per page build**, including one per effect score and another for the total. Warmed samples with a process frame between builds measured median **12.95 ms** per page, of which **2.72 ms** was validation. Separately, a vertical log travelling 60 pixels made **120 solid queries**, because each substep also checks the unchanged horizontal axis.

**Evidence:** [ui_validation_cost.json](../../../reports/ape-recursive-review-2026-11-03/ui_validation_cost.json), [runtime_bounds.json](../../../reports/ape-recursive-review-2026-11-03/runtime_bounds.json). A normal single-projectile update measured about **6.65 µs** in [projectile_cost.json](../../../reports/ape-recursive-review-2026-11-03/projectile_cost.json), so ordinary projectile processing is not established as a frame bottleneck.

**Optimization direction:** validate once per draft revision/operation and share its result across score labels; preserve revalidation after edits/reload and save-time rounding checks. Consider one initial-overlap check followed by only moving-axis sweeps. Profile before introducing pools, parallel updates, or a new scheduler.

### 9. [MINOR] Phase-scale fields ignore the two-decimal display rule until Save

The new phase form uses raw `str()` conversion and has no commit/blur normalization (`attack_catalog_editor.gd:717–731`). Enter `1.234, 1.789`, leave the field: those values remain displayed and in the draft. Save correctly rounds them to 1.23 and 1.79. This is an input/display inconsistency, not a persistence rounding failure.

**Evidence:** [phase_draft_precision.json](../../../reports/ape-recursive-review-2026-11-03/phase_draft_precision.json).

**Fix direction:** normalize valid committed numbers using the common authored precision policy; preserve invalid text for correction rather than turning it into an unrenderable draft.

### 10. [MINOR] The default verification gate never runs the new Ape regression scene

`tools/verify.sh` lists the general gameplay/catalogue scenes but omits `tests/ape_composition.tscn`. Its new health/phase/effect contracts can regress while the ordinary gate prints `0 failing`.

**Evidence:** direct inspection of the script and the captured [verification output](../../../reports/ape-recursive-review-2026-11-03/verification.txt). The Ape scene was run separately and currently reports 0 failures.

**Fix direction:** add the scene with an explicit zero-failure marker and the existing engine-error rejection policy. Ensure verification also checks process exit status, not only an output marker.

## Previously reported findings independently reproduced

These are retained separately from the ten new findings above; they must not be counted as new discoveries.

| Existing issue | Fresh confirmation | Impact / priority |
| --- | --- | --- |
| Triggered-effect listing and runtime configuration can drift | Removing all triggered bindings validates; a landing still creates its log and wave: [effect_bindings.json](../../../reports/ape-recursive-review-2026-11-03/effect_bindings.json) | Major editor/data consistency issue. Derive the listing from the actual graph or make bindings authoritative. `activation_mode` does protect AI selection; it is the emission graph that does not use these rows. |
| Empty valid family loadouts revive attacks | Empty assignment array validates; Hornback still reports ready with range 160: [empty_loadout.json](../../../reports/ape-recursive-review-2026-11-03/empty_loadout.json) | Major shared runtime issue in `CombatEnemy.atk_range()/atk_ready()` (`entities.gd:751–758`). Track load failure separately from valid emptiness. |
| Backups are written but Reload does not recover them | Two successful saves create backups; a truncated live CSV then makes Reload fail: [backup_recovery.json](../../../reports/ape-recursive-review-2026-11-03/backup_recovery.json) | Major persistence gap in `AttackCatalog.reload()`. Recover a validated coherent content set; never combine arbitrary backup generations. |
| Rollback does not remove a newly created destination | First save into a disposable folder, with `enemy_attacks.csv` occupied by a directory, leaves the newly created `attacks.csv` after assignment replacement fails: [new_file_rollback.json](../../../reports/ape-recursive-review-2026-11-03/new_file_rollback.json) | General cleanup concern from the earlier prompt is valid, but the leaked destination is the earlier CSV, not the last-written profile. The error incorrectly claims the catalogue was restored. |
| Tests depend on shipped HP rather than a controlled fixture | Valid maximum HP 5 makes `check_ape()` fail its first-hit assertion: [configured_health_tests.json](../../../reports/ape-recursive-review-2026-11-03/configured_health_tests.json), [assertion output](../../../reports/ape-recursive-review-2026-11-03/configured_health_tests.log) | Test reliability issue at `tests/test_runner.gd:2082,2086`; fixture isolation should also cover hardcoded phase values in the new suite. This probe matches the original suite's non-invincible entry state. |
| A split child can disappear inside an adjacent wall without feedback | Parent at `(25,100)` splits into two; after the next real World collision update only one child remains and there are no events: [split_near_wall.json](../../../reports/ape-recursive-review-2026-11-03/split_near_wall.json) | Boundary behavior/feedback issue; keep separate from the new missed-player-contact defect. |

### Corrections to the earlier review

- The earlier concern about a **new profile file surviving a later CSV rename failure** is not reproducible in the stated order: `save_all()` replaces attacks, assignments, then the profile. There is no later CSV replacement after a newly created profile succeeds. The broader cleanup gap was reproduced for a newly created attacks CSV, so the corrected prompt retains rollback cleanup with that verified scenario.
- Replacing stones with logs, sharing floor-spike consequences, and beginning phase two with in-place leaps follow the user's requested mechanics. They are not unsolicited redesigns that require asking for approval again.
- The total is explicitly labelled **Selected attacks**, and its tooltip says consequence totals are pending. A full encounter-scoring policy remains planned; do not silently invent one or treat the labelled subtotal itself as a numerical bug.

## Verification and limits

- `sh tools/verify.sh` → **0 failing**, including gameplay, smoke, web menu, catalogue, audio, art, editor, routes, benchmark, and Python checks. It reports one existing shutdown leak warning in `tests/discoveries.gd`.
- `XDG_DATA_HOME=/tmp/summit-recursive-baseline-ape godot --headless --path . res://tests/ape_composition.tscn` → **APE COMPOSITION: 0 failure(s)**.
- Probes intentionally reproduce errors or wrong behavior; an exit code of 0 from a Godot probe does **not** mean the behavior is correct. The JSON and engine-error logs are the evidence. Normal production checks and adversarial probe logs are kept distinct.
- Visual inspection: [normal](../../../reports/ape-recursive-review-2026-11-03/normal.png), [enraged](../../../reports/ape-recursive-review-2026-11-03/enraged.png), [invalid health](../../../reports/ape-recursive-review-2026-11-03/invalid-health.png).
- No authored room, runtime script, catalogue data, or personal save was changed. No claim is made about mobile GPU performance, all possible enemy configurations, or the unimplemented architecture milestones.

## Fix prompt

Use the standalone [CODEX_PROMPT.md](CODEX_PROMPT.md). It contains a test-first task for every new finding, retained earlier defects, constraints, and verification commands.

## Suggestions for the future

- Separate raw editor text, validated definitions, and runtime snapshots. A partial number should never become a half-valid runtime-like definition.
- Compile and validate effect references once per content revision; derive previews, ownership rules, and editor listings from that definition.
- Give effects explicit start-overlap, split, impact, out-of-bounds, cancellation, and blocked-spawn outcomes; preserve once-only event semantics.
- Make the projectile's default impact reference definition-owned rather than hardcoding `ape_spikes` in a supposedly reusable primitive.
- Keep encounter-specific choreography isolated while extracting it in small tested steps; moving the entire entity registry or replacing pixel physics is unnecessary for these fixes.
- Add property/boundary tests for valid authored parameters and old-file migrations, alongside fixed shipped-data tests.
