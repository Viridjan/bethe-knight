# Code Reviews: consolidated historical records

Merged 2026-11-07. These are dated records, **not a current task list or instructions to rerun old fix prompts**.
Current status: [implementation ledger](../../docs/IMPLEMENTATION_STATUS.md). Current tasks: [TODO](../../TODO.md).
Later delivery records can supersede earlier findings. Recorded test results describe their original run; this cleanup did not rerun gameplay.
Screenshots, logs, code probes and data remain in their original evidence directories. Original Markdown paths are compatibility redirects.

## Contents

- [docs/reviews/ape-composition/CODEX_PROMPT.md](#docs-reviews-ape-composition-codex-prompt)
- [docs/reviews/ape-composition/REVIEW.md](#docs-reviews-ape-composition-review)
- [docs/reviews/ape-recursive/CODEX_PROMPT.md](#docs-reviews-ape-recursive-codex-prompt)
- [docs/reviews/ape-recursive/REVIEW.md](#docs-reviews-ape-recursive-review)
- [docs/reviews/codebase-2026-11-03/REVIEW.md](#docs-reviews-codebase-2026-11-03-review)
- [docs/reviews/codex-2026-11-07/REVIEW.md](#docs-reviews-codex-2026-11-07-review)
- [docs/reviews/knowledge-output-2026-11-07.md](#docs-reviews-knowledge-output-2026-11-07)
- [docs/reviews/monster-editor/REVIEW.md](#docs-reviews-monster-editor-review)
- [docs/reviews/monster-editor-followup/CLAUDE_PROMPT.md](#docs-reviews-monster-editor-followup-claude-prompt)
- [docs/reviews/monster-editor-followup/REVIEW.md](#docs-reviews-monster-editor-followup-review)
- [docs/reviews/monsters/CODEX_PROMPT.md](#docs-reviews-monsters-codex-prompt)
- [reports/CLAUDE_FIX_PROMPT.md](#reports-claude-fix-prompt)

---

<a id="docs-reviews-ape-composition-codex-prompt"></a>

## Source: docs/reviews/ape-composition/CODEX_PROMPT.md

Original source: `docs/reviews/ape-composition/CODEX_PROMPT.md`. [Evidence directory](../../docs/reviews/ape-composition/).

# Codex prompt: verified Ape composition follow-up fixes

**Implementation status, 2026-11-04: all five follow-ups below are complete.**
See [implementation evidence](../ape-followups-2026-11-04/README.md).
The checked tasks remain here as the implementation record; verify current code
before reusing this prompt for any further work.

Historical diagnosis was checked against `953b8ca` on 2026-11-03. The rollback
scenario was corrected because profiles are replaced last; the verified failure
left a newly created attacks CSV instead. Original task 6 was excluded as a
numerical bug: the UI already labels its total **Selected attacks**, with
consequence totals explicitly pending.

The five tasks below replace the earlier six. Additional verified defects and
their evidence are in [the recursive review](../../docs/reviews/ape-recursive/REVIEW.md).

Follow-up fixes for the Ape composition slice. Read AGENTS.md, docs/ATTACK_CATALOG.md,
docs/MECHANICS_ARCHITECTURE_PLAN.md and docs/reviews/ape-composition/REVIEW.md first. Stay inside this repository.
Preserve intended gameplay and pixel physics. Don't edit worlds/ or personal saves.
Logs replacing stones, shared floor-spike consequences, and phase-entry in-place
leaps were requested mechanics; do not ask for their approval again or undo them.

Context: the Ape (scripts/entities.gd, class Ape) reads its health, phase-two threshold, phase-entry hop scales and
effect chain from data/enemy_profiles.json via AttackCatalog.enemy_profile("boss_ape"); projectiles and the ground
wave live in scripts/effects/attack_effects.gd. data/enemy_attacks.csv has activation_mode (selected | triggered);
triggered rows are shown in the Monster Editor (scripts/attack_catalog_editor.gd).
Their mode protects AI selection, but effect emission follows the profile rather
than those binding rows. Keep this distinction explicit.

Tasks (one commit each; write the test first and see it fail):
1. [x] Completed 2026-11-04: one source of truth for the effect chain. Derive the editor's triggered-effects list from the profile
   (landing_effects, log_impact_effect, phase2_throw_effect; split only on the enraged page) and drop the triggered
   rows from enemy_attacks.csv, or make runtime read them and drop the profile fields. Test: the list shown for each
   Ape page equals what gameplay does.
2. [x] Completed 2026-11-04: tests/test_runner.gd lines ~2082-2086 isolate configurable HP in fixtures or derive expectations from the
   fixture's max_hp instead of E.Ape.HP. Check hardcoded phase assumptions in tests/ape_composition.gd too.
   Test: valid max_hp 5 still verifies one lost HP and the intended spike removal. Do not weaken the assertion.
3. [x] Completed 2026-11-04: effect tooltips come from the profile links and refresh live when source names change.
4. [x] Completed 2026-11-04: split children emit a visible "split_blocked" cancellation when
   placement is impossible. Test: a parent at (25,100), size (19,6), speed (0,-1), gravity 200 splits against the
   real World boundary; a child must not silently vanish. Do not force children through solid terrain.
5. [x] Completed 2026-11-04: correct first-save rollback records which destinations existed before replacement. Restore old files and
   remove newly created files on failure. Reproduction: in a disposable empty directory, make enemy_attacks.csv
   a directory, then save a loaded catalogue there. Attack replacement succeeds and assignment replacement
   fails; the current code leaves the new attacks.csv while claiming restoration. Assert that no new final
   files remain. The profile is last and must not be described as replaced before that CSV failure.

Derive listing and tooltip tests from the same authoritative runtime definition, rather than requiring duplicate
CSV rows. Trigger-only effects must still bypass AI eligibility/chance work. Preserve old-file compatibility.
Do not invent a chain-scoring formula or reuse the withdrawn profile-specific rollback scenario. The recursive
review also describes a separate, reproduced backup-recovery gap; keep recovery on load distinct from save rollback.

Commit each task when its checks pass (Codex files included).

Verification: XDG_DATA_HOME=$(mktemp -d) godot --headless --path . res://tests/ape_composition.tscn → 0 failure(s);
res://tests/attack_catalog.tscn → ATTACK CATALOG OK; sh tools/verify.sh → 0 failing; a screenshot of both Ape pages.
One dated line in gdd.txt per task.


---

<a id="docs-reviews-ape-composition-review"></a>

## Source: docs/reviews/ape-composition/REVIEW.md

Original source: `docs/reviews/ape-composition/REVIEW.md`. [Evidence directory](../../docs/reviews/ape-composition/).

# Review: Codex's Ape composition slice (2026-11-03)

Reviewed Codex's uncommitted iteration: `scripts/effects/attack_effects.gd` (new), the Ape in `scripts/entities.gd`,
`scripts/attack_catalog.gd` (profiles, `activation_mode`, save), `scripts/attack_catalog_editor.gd` (Health & phase
entry, triggered-effects list), `data/enemy_profiles.json`, both CSVs, `tests/ape_composition.gd`,
`docs/MECHANICS_ARCHITECTURE_PLAN.md`. Method: read the full diff; ran `tests/ape_composition.tscn` (0 failures) and
`sh tools/verify.sh` (0 failing); grepped runtime use of the new data. Skills: code-review, systematic-debugging,
verification-before-completion, godot-best-practices, godot-state-machine, save-systems, ponytail-review (fallback).
**Headline: 0 blocking, 2 major, 5 minor, 3 questions.** The code is solid: the effects module is small, swept
collision prevents tunnelling, death and room exit clear effects, and the tests cover the new pieces.

## Findings

1. **[MAJOR] The "triggered" rows in `enemy_attacks.csv` don't drive anything.** `entities.gd` never reads
   `activation_mode` (grep: no hits); landings, log spikes and splitting come from `enemy_profiles.json`
   (`landing_effects`, `log_impact_effect`, `phase2_throw_effect`). The 8 new rows only feed the editor list. That's
   the "two representations of the same chain" the plan itself forbids (MECHANICS_ARCHITECTURE_PLAN.md §3, line 114).
   They can't be removed in the editor, so they can't drift yet, but anyone editing the CSV by hand would expect them
   to work.
2. **[MAJOR] Two tests still assume the Ape has 4 HP.** `tests/test_runner.gd:2082,2086` compare with `E.Ape.HP`; Health
   is now editable (`enemy_profiles.json` `max_hp`). Set Health to 5 and those checks fail although the game is right.
3. **[MINOR] The normal Ape page lists "Splitting log" as a triggered effect**, but splitting happens only in phase two
   (`phase2_throw_effect`). Same for its tooltip: it says "phase-two", but the row sits under the phase-one Ape.
4. **[MINOR] Effect tooltips are hard-coded in the editor** (`{"ape_slam": "Triggered by leap landing", …}`) instead of
   being built from the profile, so changing `landing_effects` leaves the text wrong.
5. **[MINOR] Restore after a failed save misses a brand-new profile file.** `save_all` restores from `.bak`, but the
   first save that creates `enemy_profiles.json` has no `.bak`, so on a later CSV failure the new profile stays while
   the CSVs roll back.
6. **[MINOR] Split children can be born inside a wall.** They spawn at the parent ± one log width; near an arena edge,
   the first step hits the wall and the child vanishes without an event (no spike, no burst).
7. **[MINOR] The Ape's total score now leaves out its effects** ("Selected attacks … triggered consequence totals
   pending"), so it's lower than before; region budgets built on it would undercount the Ape.
8. **[QUESTION] Phase two hops only once.** Before: every enraged scream was followed by 2 in-place hops (each
   dropping a log). Now: the hops happen once, on entering phase two; later screams just recover. Intended?
9. **[QUESTION] Every thrown log now leaves a floor spike** (stones became logs; floor impact is shared). A 3-log
   volley adds up to 3 spikes. Spikes hurt the player and are what hurts the Ape, so the arena fills faster and
   the fight probably gets shorter. Intended balance?
10. **[QUESTION] The stone is gone.** The throw is now "Ape log throw" (score 44 → 28) and phase two's split stones
    became splitting logs. Confirm that's the look and feel you want.

## Fix prompt

```text
Follow-up fixes for the Ape composition slice. Read AGENTS.md, docs/ATTACK_CATALOG.md,
docs/MECHANICS_ARCHITECTURE_PLAN.md and docs/reviews/ape-composition/REVIEW.md first. Stay inside this repository.
Keep gameplay identical. Leave the three [QUESTION] items to the designer. Don't edit worlds/.

Context: the Ape (scripts/entities.gd, class Ape) reads its health, phase-two threshold, phase-entry hop scales and
effect chain from data/enemy_profiles.json via AttackCatalog.enemy_profile("boss_ape"); projectiles and the ground
wave live in scripts/effects/attack_effects.gd. data/enemy_attacks.csv has activation_mode (selected | triggered);
triggered rows are shown in the Monster Editor (scripts/attack_catalog_editor.gd) but runtime ignores them.

Tasks (one commit each; write the test first and see it fail):
1. One source of truth for the effect chain: derive the editor's triggered-effects list from the profile
   (landing_effects, log_impact_effect, phase2_throw_effect; split only on the enraged page) and drop the triggered
   rows from enemy_attacks.csv, or make runtime read them and drop the profile fields. Test: the list shown for each
   Ape page equals what gameplay does.
2. tests/test_runner.gd lines ~2082-2086: use the Ape's max_hp from the profile instead of E.Ape.HP. Test: set max_hp
   to 5 in a test copy and the checks still pass.
3. Effect tooltips built from the profile (what triggers each effect), not a hard-coded dictionary.
4. save_all: when a file had no previous version, remove it on rollback. Test: first profile save + forced CSV rename
   failure leaves no enemy_profiles.json.
5. Split children: spawn at the parent's position, nudged to the nearest free spot, or emit a "split_blocked" event
   with a burst. Test: a split against a wall still produces two children or a visible event.
6. Ape total score: add the effect chain (slam and log per landing, spikes as pending) or show both numbers
   (selected / with effects). Test: the Ape total isn't lower than its selected attacks plus the scored slam.

Verification: XDG_DATA_HOME=$(mktemp -d) godot --headless --path . res://tests/ape_composition.tscn → 0 failure(s);
res://tests/attack_catalog.tscn → ATTACK CATALOG OK; sh tools/verify.sh → 0 failing; a screenshot of both Ape pages.
One dated line in gdd.txt per task.
```

## Suggestions for the future

- **Profiles for every enemy** (HP, phase threshold, effects) in `enemy_profiles.json`, editable in the same card:
  the families still have HP in code.
- **A small effects preview** in the editor (draw a log's arc, the ground-wave width at each hop scale): the numbers
  are hard to judge blind.
- **Commit Codex's slices as they land**: this one sat uncommitted with tests passing; a commit per slice makes
  reviews and rollbacks easier.
- **Keep `attack_effects.gd` free of Ape names** (`impact_effect := "ape_spikes"` default): pass it from the profile
  only, so other enemies can reuse it.


---

<a id="docs-reviews-ape-recursive-codex-prompt"></a>

## Source: docs/reviews/ape-recursive/CODEX_PROMPT.md

Original source: `docs/reviews/ape-recursive/CODEX_PROMPT.md`. [Evidence directory](../../docs/reviews/ape-recursive/).

# Fix prompt: recursive Ape dependency audit

Verified against production code at `953b8ca`. Read [REVIEW.md](../../docs/reviews/ape-recursive/REVIEW.md) for
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


---

<a id="docs-reviews-ape-recursive-review"></a>

## Source: docs/reviews/ape-recursive/REVIEW.md

Original source: `docs/reviews/ape-recursive/REVIEW.md`. [Evidence directory](../../docs/reviews/ape-recursive/).

# Recursive review: Ape composition and dependencies (2026-11-03)

Reviewed the Ape slice recursively through `scripts/entities.gd`, `scripts/effects/attack_effects.gd`, `scripts/attack_catalog.gd`, `scripts/attack_catalog_editor.gd`, their CSV/profile data, relevant World/player collision and lifetime hooks, and verification tooling. Production baseline is `953b8ca` (identical gameplay code to `41fdbd0`; the intervening commit adds only a prompt). Methods: end-to-end source tracing, isolated runtime probes, the full verification script, the separate Ape regression scene, warmed timing samples, and fresh screenshots of both phase pages and a broken draft. Skills: code-review, systematic-debugging, verification-before-completion, godot-best-practices, godot-ui-control, godot-state-machine, save-systems, performance-optimization; TDD principles guide the fix prompt. Scope/reuse and bounded-file-data checks substitute for unavailable ponytail/security helpers. **New findings: 2 blocking, 5 major, 3 minor. Six earlier issues were also reproduced, including corrected evidence for the rollback gap.** This review changes documentation and review fixtures only.

The ordinary shipped-data checks are green. These findings concern accepted edits, boundary conditions, and dependency behavior that those checks do not cover. This is a dependency-scoped audit, not a claim that the entire game has been exhaustively proven correct.

## Findings

### 1. [BLOCKING] Valid zero-gravity edits make the boss fight unwinnable

`attack_catalog.gd:124–130` accepts zero `gravity_units_s2`. Set `ape_leap.gravity_units_s2` to `0.00`: both validation and save validation succeed. The launch in `entities.gd:2687–2690` then has zero vertical speed, and the airborne update never produces a downward landing. The Ape stays in `air`; its spike-based damage and attack-selection loop cannot proceed normally.

**Evidence:** [zero_leap.json](../ape-recursive-review-2026-11-03/zero_leap.json): after 180 ticks, state remains `air`, vertical speed is 0, and HP is unchanged. The probe uses the real actor and terrain.

**Fix direction:** impose behavior-specific validity constraints for ballistic leaps, including after authored rounding, and guard runtime execution against invalid effective parameters. Generic nonnegative-number validation is insufficient. Keep zero gravity available to mechanics which intentionally support it; do not ban it globally.

### 2. [BLOCKING] An unfinished health edit destroys the editable health controls

In the real private editor draft, clear **Health**, then select the other Ape page. The text callback stores `null` (`attack_catalog_editor.gd:721–728`). Rebuilding the page calls `int(null)` at line 717, producing `Invalid call. Nonexistent 'int' constructor`. The health input is never added, so switching back cannot repair the value. Save is disabled, while Reload discards the entire draft, including unrelated edits.

**Evidence:** [invalid_health_ui.json](../ape-recursive-review-2026-11-03/invalid_health_ui.json), [error log](../ape-recursive-review-2026-11-03/invalid_health_ui.log), and [screenshot](../ape-recursive-review-2026-11-03/invalid-health.png). The final probe uses an independently loaded editor catalogue, preserving the real draft/runtime separation; it does not inject an invalid live runtime catalogue.

**Fix direction:** retain raw invalid input separately from valid parsed definitions, or make the form robust to every intermediate draft value. Changing pages must preserve a repairable input and all unsaved edits without constructor errors.

### 3. [MAJOR] Shockwave optional/default geometry is not safely interpreted

`Ape._land()` at `entities.gd:2808–2811` uses dictionary `get()` defaults, which do not apply to present-but-empty CSV cells. Clearing `shockwave_s` therefore means lifetime 0 rather than the documented unspecified/fallback value 0.2. Setting area to `0.00` also passes save validation and creates a zero-width active wave. Its real `ape_art.gd::impact_texture()` path emits invalid-image/null-texture errors. Small positive areas can also round to zero pixels; merely testing `area > 0` is insufficient.

**Evidence:** [blank_wave_time.json](../ape-recursive-review-2026-11-03/blank_wave_time.json): lifetime 0 instead of 0.2. [zero_wave.json](../ape-recursive-review-2026-11-03/zero_wave.json): accepted area, width 0, null texture; [renderer helper errors](../ape-recursive-review-2026-11-03/zero_wave.log).

**Fix direction:** normalize empty optional cells through the same value/default service used elsewhere, validate final pixel dimensions across allowed hop scales, and guard texture allocation. Explicitly disabling a landing effect already has a profile representation; a malformed dimension should not be the disabling mechanism.

### 4. [MAJOR] Retreat launches and airborne motion use different gravity definitions

Launch selects `ape_retreat` when appropriate and snapshots it, but the `air` branch always requests `ape_leap` (`entities.gd:2693`). Since `_ape_param()` only uses the snapshot for a matching ID, retreat flight reads the other attack's live gravity. Different authored gravities alter airtime, landing target, and corner-escape behavior. Editing ordinary-leap gravity during a retreat can also affect that running retreat despite the snapshot contract.

**Evidence:** [retreat_gravity.json](../ape-recursive-review-2026-11-03/retreat_gravity.json): retreat gravity 25 tiles/s² launches at -75 px/s. One tick should yield -71.67 px/s, but produces -65 px/s using ordinary-leap gravity 75 tiles/s². Validation succeeds and the snapshot ID is `ape_retreat`.

**Fix direction:** keep the active leap ID/effective gravity through launch, flight, and recovery; consume the captured parameters for the entire action.

### 5. [MAJOR] Some exposed effect controls change scores but not the actual effect

`Ape._throw()` at `entities.gd:2767–2770` takes size from `ape_log` and child gravity from `ape_log`, regardless of the visible area on `ape_throw` or gravity on `ape_split`. Those fields remain editable through the type-based editor panels, with general gameplay-oriented labels. `ape_split` gravity affects neither the parent's throw gravity nor the children's gravity. The copied size/reference fields can diverge from the actual shared hitbox and its score.

**Evidence:** [ignored_values.json](../ape-recursive-review-2026-11-03/ignored_values.json): throw area 40 still produces a 19×6 log; split gravity 100 tiles/s² still gives child gravity 200 px/s² rather than 800. Both edits validate.

**Fix direction:** establish one authoritative source for shared log geometry and each launch profile. Bind the relevant control to that source, or display a clearly read-only linked/reference value. Preserve intentionally reference-only speed/count fields, but label their runtime limits explicitly; do not make every scoring input change gameplay without a design decision.

### 6. [MAJOR] Splitting skips player collision at the apex

`attack_effects.gd:68–73` splits and deletes the parent before checking any overlap or movement collision. If the player entered its box this tick, the expected contact is lost. The children are placed one width to either side, leaving the parent's previous box empty, so the next tick need not repair the missed hit either.

**Evidence:** [apex_collision.json](../ape-recursive-review-2026-11-03/apex_collision.json): the real 19×6 parent overlaps an 8×6 player damage box, crosses its apex, produces two children, and reports no player-hit event on that tick or the following tick. Solid queries delegate to the real World.

**Fix direction:** define and implement collision/event precedence before consuming the parent. Add overlapping-player and terrain-at-split tests alongside ordinary mid-flight splitting; preserve once-only hit and child spawning behavior.

### 7. [MAJOR] Already-outside projectiles perform an unbounded sweep before being discarded

Bounds rejection is after the entire per-pixel loop (`attack_effects.gd:74–98`). The catalogue also accepts very large component speeds without a behavioral bound. An outside object can therefore consume tens of thousands of terrain queries although it should already have expired. Child placement already has a known edge case near arena boundaries, so the effect service should not assume all inputs begin in free interior space.

**Evidence:** [outside_sweep_cost.json](../ape-recursive-review-2026-11-03/outside_sweep_cost.json): an accepted 122,880 tiles/s speed, applied to a projectile already beyond the supplied room bounds, makes **32,768 real terrain queries and takes 111.24 ms** before removal. This is an adversarial authoring/API case, not evidence that shipped default combat is slow. Timing is a local debug/headless measurement, not a portable device benchmark.

**Fix direction:** reject expired/outside inputs before sweeping, validate finite practical trajectory parameters, and bound work without allowing tunnelling. Do not solve this by blindly clipping the step count while still applying the full displacement.

### 8. [MINOR] Measured repeated work is avoidable without changing mechanics

The Ape editor performs **9 complete catalogue validations per page build**, including one per effect score and another for the total. Warmed samples with a process frame between builds measured median **12.95 ms** per page, of which **2.72 ms** was validation. Separately, a vertical log travelling 60 pixels made **120 solid queries**, because each substep also checks the unchanged horizontal axis.

**Evidence:** [ui_validation_cost.json](../ape-recursive-review-2026-11-03/ui_validation_cost.json), [runtime_bounds.json](../ape-recursive-review-2026-11-03/runtime_bounds.json). A normal single-projectile update measured about **6.65 µs** in [projectile_cost.json](../ape-recursive-review-2026-11-03/projectile_cost.json), so ordinary projectile processing is not established as a frame bottleneck.

**Optimization direction:** validate once per draft revision/operation and share its result across score labels; preserve revalidation after edits/reload and save-time rounding checks. Consider one initial-overlap check followed by only moving-axis sweeps. Profile before introducing pools, parallel updates, or a new scheduler.

### 9. [MINOR] Phase-scale fields ignore the two-decimal display rule until Save

The new phase form uses raw `str()` conversion and has no commit/blur normalization (`attack_catalog_editor.gd:717–731`). Enter `1.234, 1.789`, leave the field: those values remain displayed and in the draft. Save correctly rounds them to 1.23 and 1.79. This is an input/display inconsistency, not a persistence rounding failure.

**Evidence:** [phase_draft_precision.json](../ape-recursive-review-2026-11-03/phase_draft_precision.json).

**Fix direction:** normalize valid committed numbers using the common authored precision policy; preserve invalid text for correction rather than turning it into an unrenderable draft.

### 10. [MINOR] The default verification gate never runs the new Ape regression scene

`tools/verify.sh` lists the general gameplay/catalogue scenes but omits `tests/ape_composition.tscn`. Its new health/phase/effect contracts can regress while the ordinary gate prints `0 failing`.

**Evidence:** direct inspection of the script and the captured [verification output](../ape-recursive-review-2026-11-03/verification.txt). The Ape scene was run separately and currently reports 0 failures.

**Fix direction:** add the scene with an explicit zero-failure marker and the existing engine-error rejection policy. Ensure verification also checks process exit status, not only an output marker.

## Previously reported findings independently reproduced

These are retained separately from the ten new findings above; they must not be counted as new discoveries.

| Existing issue | Fresh confirmation | Impact / priority |
| --- | --- | --- |
| Triggered-effect listing and runtime configuration can drift | Removing all triggered bindings validates; a landing still creates its log and wave: [effect_bindings.json](../ape-recursive-review-2026-11-03/effect_bindings.json) | Major editor/data consistency issue. Derive the listing from the actual graph or make bindings authoritative. `activation_mode` does protect AI selection; it is the emission graph that does not use these rows. |
| Empty valid family loadouts revive attacks | Empty assignment array validates; Hornback still reports ready with range 160: [empty_loadout.json](../ape-recursive-review-2026-11-03/empty_loadout.json) | Major shared runtime issue in `CombatEnemy.atk_range()/atk_ready()` (`entities.gd:751–758`). Track load failure separately from valid emptiness. |
| Backups are written but Reload does not recover them | Two successful saves create backups; a truncated live CSV then makes Reload fail: [backup_recovery.json](../ape-recursive-review-2026-11-03/backup_recovery.json) | Major persistence gap in `AttackCatalog.reload()`. Recover a validated coherent content set; never combine arbitrary backup generations. |
| Rollback does not remove a newly created destination | First save into a disposable folder, with `enemy_attacks.csv` occupied by a directory, leaves the newly created `attacks.csv` after assignment replacement fails: [new_file_rollback.json](../ape-recursive-review-2026-11-03/new_file_rollback.json) | General cleanup concern from the earlier prompt is valid, but the leaked destination is the earlier CSV, not the last-written profile. The error incorrectly claims the catalogue was restored. |
| Tests depend on shipped HP rather than a controlled fixture | Valid maximum HP 5 makes `check_ape()` fail its first-hit assertion: [configured_health_tests.json](../ape-recursive-review-2026-11-03/configured_health_tests.json), [assertion output](../ape-recursive-review-2026-11-03/configured_health_tests.log) | Test reliability issue at `tests/test_runner.gd:2082,2086`; fixture isolation should also cover hardcoded phase values in the new suite. This probe matches the original suite's non-invincible entry state. |
| A split child can disappear inside an adjacent wall without feedback | Parent at `(25,100)` splits into two; after the next real World collision update only one child remains and there are no events: [split_near_wall.json](../ape-recursive-review-2026-11-03/split_near_wall.json) | Boundary behavior/feedback issue; keep separate from the new missed-player-contact defect. |

### Corrections to the earlier review

- The earlier concern about a **new profile file surviving a later CSV rename failure** is not reproducible in the stated order: `save_all()` replaces attacks, assignments, then the profile. There is no later CSV replacement after a newly created profile succeeds. The broader cleanup gap was reproduced for a newly created attacks CSV, so the corrected prompt retains rollback cleanup with that verified scenario.
- Replacing stones with logs, sharing floor-spike consequences, and beginning phase two with in-place leaps follow the user's requested mechanics. They are not unsolicited redesigns that require asking for approval again.
- The total is explicitly labelled **Selected attacks**, and its tooltip says consequence totals are pending. A full encounter-scoring policy remains planned; do not silently invent one or treat the labelled subtotal itself as a numerical bug.

## Verification and limits

- `sh tools/verify.sh` → **0 failing**, including gameplay, smoke, web menu, catalogue, audio, art, editor, routes, benchmark, and Python checks. It reports one existing shutdown leak warning in `tests/discoveries.gd`.
- `XDG_DATA_HOME=/tmp/summit-recursive-baseline-ape godot --headless --path . res://tests/ape_composition.tscn` → **APE COMPOSITION: 0 failure(s)**.
- Probes intentionally reproduce errors or wrong behavior; an exit code of 0 from a Godot probe does **not** mean the behavior is correct. The JSON and engine-error logs are the evidence. Normal production checks and adversarial probe logs are kept distinct.
- Visual inspection: [normal](../ape-recursive-review-2026-11-03/normal.png), [enraged](../ape-recursive-review-2026-11-03/enraged.png), [invalid health](../ape-recursive-review-2026-11-03/invalid-health.png).
- No authored room, runtime script, catalogue data, or personal save was changed. No claim is made about mobile GPU performance, all possible enemy configurations, or the unimplemented architecture milestones.

## Fix prompt

Use the standalone [CODEX_PROMPT.md](../../docs/reviews/ape-recursive/CODEX_PROMPT.md). It contains a test-first task for every new finding, retained earlier defects, constraints, and verification commands.

## Suggestions for the future

- Separate raw editor text, validated definitions, and runtime snapshots. A partial number should never become a half-valid runtime-like definition.
- Compile and validate effect references once per content revision; derive previews, ownership rules, and editor listings from that definition.
- Give effects explicit start-overlap, split, impact, out-of-bounds, cancellation, and blocked-spawn outcomes; preserve once-only event semantics.
- Make the projectile's default impact reference definition-owned rather than hardcoding `ape_spikes` in a supposedly reusable primitive.
- Keep encounter-specific choreography isolated while extracting it in small tested steps; moving the entire entity registry or replacing pixel physics is unnecessary for these fixes.
- Add property/boundary tests for valid authored parameters and old-file migrations, alongside fixed shipped-data tests.


---

<a id="docs-reviews-codebase-2026-11-03-review"></a>

## Source: docs/reviews/codebase-2026-11-03/REVIEW.md

Original source: `docs/reviews/codebase-2026-11-03/REVIEW.md`. [Evidence directory](../../docs/reviews/codebase-2026-11-03/).

# Review: whole codebase sweep (2026-11-03)

Swept every script recursively: 16k lines of GDScript (`scripts/`, `tools/`) and 5.6k of Python. Method:
gdtoolkit `gdlint` (correctness rules only, style off) and `gdradon` (complexity) on all `.gd`; `pyflakes` on all
`.py`; greps for risky patterns (in-place file writes, unchecked loads, awaits, per-frame scans, signal connects);
`tests/bench.tscn` for performance; headless probes for each suspicion. Full suite green before the sweep
(`sh tools/verify.sh` → 0 failing). Skills: code-review, systematic-debugging, verification-before-completion,
godot-best-practices, save-systems, performance-optimization, ponytail-audit (fallback). The Ape slice is covered
separately in `docs/reviews/ape-composition/REVIEW.md`. **Headline: 1 blocking, 1 major, 4 minor; performance OK.**

**Status (2026-11-04): all fixed, suggestions done.** One crash-safe writer (`Game.write_safe`: .tmp, .bak,
rename) and reader (`Game.read_config`: falls back to .bak, refuses to save over an unreadable file) for progress,
settings, tuning presets, rooms and world.json; respawn into another room builds once; dead code removed;
`gdlint` (rules in `gdlintrc`) and `pyflakes` run in `tools/verify.sh` via uv; the benchmark has a real room
(`ape_arena`: 0.12 ms physics, 0.07 ms draw).

## Findings

1. **[BLOCKING] A save cut short wipes all progress on the next save.** `Game.save_adventure()` (and
   `submit_record`, `save_settings`) do `cf.load(save_path)` without checking the result, then `cf.save(save_path)`
   in place (`scripts/game.gd` ~454-457). If the file was left half-written (crash, power loss, full disk), the load
   fails silently, the ConfigFile is empty, and the next save writes only the current run. Probe: a save truncated
   to half, then one `save_adventure()` → `levels_kept=false other_run_kept=false keys=["adventure"]`: every level
   record and the other worlds' runs are gone.
2. **[MAJOR] World Editor files are written in place, unchecked.** `Adventure.save_world` (`scripts/adventure.gd:108`)
   and `Game.save_level` (`scripts/game.gd:312`) open the real file for writing and ignore `store_string`'s result;
   `save_level` returns the filename even when the write failed. A crash mid-save truncates `worlds/story/*.json`,
   your hand-made rooms (git can recover them, but only if committed).
3. **[MINOR] Respawning into another room builds it twice.** `World.respawn()` calls `enter_room(spawn_room, spawn)`
   (which builds the room) and then `_build()` again (`scripts/world.gd` ~956-960). About 1-2 ms wasted per such
   respawn; harmless otherwise.
4. **[MINOR] Dead code in `tools/world_fixups.py`:** the old `add_spawns` (lines 355-~420) is shadowed by
   `add_spawns = add_respawns` at line 504 and never runs.
5. **[MINOR] Unused leftovers** (pyflakes): `inward` (`tools/story/build_drafts.py:80`), `sill` (`:204`),
   `import tempfile` (`tests/test_progression.py:1`).
6. **[MINOR] The room editor is slow zoomed out on very large rooms:** 112 ms per redraw at zoom 0.5 on the
   benchmark's 400×400 room (fine at zoom 2-3: 4-7 ms). Real rooms are far smaller, so only noticeable if you build
   a huge one.

**Checked and fine:** gameplay frames in real rooms cost 0.2-0.5 ms of physics and under 0.1 ms of drawing
(`bench`: normal, moving, large_blocks); the 2,500-entity stress room draws in 30 ms with off-screen culling already
on. The linter's other hits are harmless: repeated `load()` of cached scripts, unused arguments in test stubs, one
ternary used as a statement. High complexity sits in `player.gd`'s ported Celeste movement and `World.update`
(expected; not worth splitting for its own sake).

## Fix prompt

```text
Save-safety and cleanup fixes. Read AGENTS.md and docs/reviews/codebase-2026-11-03/REVIEW.md first. Stay inside
this repository. Keep gameplay identical. Don't edit worlds/ content.

Context: player progress (adventure runs, level records, settings) is a ConfigFile at Game.save_path
(scripts/game.gd: save_adventure, submit_record, save_settings and the other cf.load/cf.save pairs). World Editor
saves: Adventure.save_world (scripts/adventure.gd) writes world.json; Game.save_level (scripts/game.gd) writes
each room JSON.

Tasks (one commit each; write the test first and see it fail):
1. Crash-safe progress saves: one helper (e.g. Game.write_config(cf, path)) that saves to path + ".tmp", keeps the
   previous file as ".bak", then renames; and one loader that tries path, then ".bak", and refuses to save
   (push_error + no write) when both fail to load, instead of starting from an empty file. Use it everywhere the
   save file is loaded then saved. Test (tests/test_runner.gd): write a save with a level record and another
   world's run, truncate it to half, call save_adventure(): the record and the other run are still there
   (from .bak) and the new run is saved.
2. Same for World Editor files: save_world and save_level write to a .tmp, check store_string / get_error, keep a
   .bak, rename; return false / "" on any failure. Test: a write into a read-only directory returns failure and
   leaves the old file intact.
3. World.respawn(): don't _build() again after enter_room() has built the target room (keep the spawn position and
   the base-stamina refill). Test: respawning into another room builds it once and puts the player on the spawn.
4. Remove the dead add_spawns body in tools/world_fixups.py (keep the alias), the unused 'inward' and 'sill'
   variables in tools/story/build_drafts.py, and the unused tempfile import in tests/test_progression.py.

Verification: sh tools/verify.sh → 0 failing; python3 -m unittest discover -s tests -p 'test_*.py' → OK.
One dated line in gdd.txt per task.
```

## Suggestions for the future

- **Add the linters to `tools/verify.sh`** (`gdlint` with the correctness rules used here, `pyflakes`): they found
  the dead code in seconds and would catch new leftovers on every run.
- **One save module** for every file the game writes (progress, rooms, world, CSVs, profiles): the Monster Editor
  already has temp + backup + rollback; the rest should share it.
- **Bench a real story room** in `tests/bench.gd` (e.g. the Ape arena with its effects) next to the synthetic ones,
  so performance numbers track what players actually see.


---

<a id="docs-reviews-codex-2026-11-07-review"></a>

## Source: docs/reviews/codex-2026-11-07/REVIEW.md

Original source: `docs/reviews/codex-2026-11-07/REVIEW.md`. [Evidence directory](../../docs/reviews/codex-2026-11-07/).

# Review: Codex's commits 2026-11-04 → 11-06 (2026-11-07)

Reviewed the 10 Codex commits after `d5d1b5f` up to `c042f5a` (64 code/data files, +4.2k lines): Ape follow-ups
and triggers, save rollback, stress, traps and trigger router, patrols, punch, room resize, world selection.
Method: full suite with linters on `c042f5a` + the stamina change (`sh tools/verify.sh` → 0 failing, gdlint and
pyflakes clean), then read the new runtime modules (`scripts/progression/stress.gd`,
`scripts/interaction/trap_cycle.gd`, `trigger_router.gd`, `trigger_settings.gd`, `scripts/motion/patrol_runtime.gd`)
and the `game.gd` / `world.gd` diffs. Codex's uncommitted, in-progress work (story progress, sea crossing, UI) was
not reviewed. **Headline: 0 blocking, 0 major, 2 minor, 1 question.** The code is careful: every loop is bounded
(64 trap iterations, 512 pending commands, 1024 patrol steps), trigger links are validated against existing targets
and supported actions before a room loads, and saves go through the crash-safe writer with failed writes changing
nothing.

## Findings

1. **[QUESTION] Stress can be farmed by killing respawned monsters.** `World.killed_enemy` removes 50 stress per kill
   (`scripts/world.gd` ~854) and enemies come back whenever the room is rebuilt, so leaving and re-entering a room
   (or dying: +20, then the kill: -50) lowers stress without limit. `docs/BETHE_KNIGHT_DESIGN.md:94` says respawned
   monsters may count, so this is by design. Options: keep it; count each placed enemy once per visit; or a
   cooldown per enemy.
2. **[MINOR] The HUD writes "/250" as a literal** (`world.gd` stress HUD) instead of `Stress.MAX_STRESS`; changing
   the bar count or capacity would leave it wrong.
3. **[MINOR] Rest relief trusts the system clock** (`Game.claim_stress_rest`, unix time): moving the clock forward
   12 hours gives -100 stress at the next Continue. Harmless for a single-player game; worth knowing.

## Fix prompt

```text
Small follow-ups to the stress system. Read AGENTS.md and docs/reviews/codex-2026-11-07/REVIEW.md. Stay inside this
repository; keep gameplay identical; leave finding 1 to the designer.
1. scripts/world.gd stress HUD: build "%d/%d" from Adventure.Stress.MAX_STRESS instead of the literal 250. Test:
   the HUD text uses MAX_STRESS.
2. Optional: document in docs/BETHE_KNIGHT_DESIGN.md that rest relief uses the system clock.
Verification: sh tools/verify.sh → 0 failing. One dated line in gdd.txt.
```

## Suggestions for the future

- Commit finished slices before starting the next one: right now 13 files of in-progress work sit uncommitted in the
  shared checkout, which makes concurrent edits (Claude and Codex) risky.


---

<a id="docs-reviews-knowledge-output-2026-11-07"></a>

## Source: docs/reviews/knowledge-output-2026-11-07.md

Original source: `docs/reviews/knowledge-output-2026-11-07.md`. [Evidence directory](../../docs/reviews/).

# Graphify and LightRAG output check — 2026-11-07

Scope: read-only inspection of generated knowledge outputs and their coverage/freshness. No graph rebuild, gameplay changes or map edits.

## Verdict

The current Graphify output is useful for navigating design documents, tools and review history. It is not a current runtime dependency graph or a playable map-connectivity audit. LightRAG could not be checked: no output was found in this project, including ignored/hidden files, and no LightRAG connector was available. Its path or URL has been requested.

## Findings

1. **Current graph omits the game implementation and room data.** `graphify-out/manifest.json` indexes 463 files, but no `.gd` files and no `worlds/` files. The current project has 58 GDScript files under `scripts/` and 51 JSON files under `worlds/`. Script-labelled nodes such as `scripts_motion_patrol_runtime` cite `docs/PATROL_AUTHORING.md`, not the script. An EXTRACTED edge therefore proves a relationship was extracted from its cited source; it does not prove that the relationship exists in current gameplay. Use source inspection and runtime/traversal checks for that.
2. **The new map plan is absent.** The indexed content hashes for `docs/STORY_DESIGN.md`, `TODO.md` and `AGENTS.md` differ from their current raw MD5 hashes; their recorded modification times also precede the current files. The graph contains no nodes for the new cluster/secret-pocket/branching-connection plan. It also predates the current Whole numbers only project instruction. Refresh these sources before asking it about current design rules.
3. **The dated subfolder is an older snapshot.** `graphify-out/2026-11-07/GRAPH_REPORT.md` actually identifies itself as 2026-10-25 and reports 257 nodes / 339 edges. The root report is dated 2026-11-07 and has 939 nodes / 1,334 edges. Their recorded commits are respectively `2f01697079fa9aad6a41744d8acf0dd9aeabb167` and `9ea578ca377da9e1865735647eb4b958283da44b`. Select snapshots by report/manifest content, not folder name alone.
4. **Historical proposals and current delivery coexist without a reliable priority layer.** The graph groups the older Kraken entry-gating proposal as well as the new lighthouse/boat flow. `docs/BETHE_KNIGHT_DESIGN.md` still describes full-base-energy / 250-stress / underwater gates; current `docs/NONMAP_SYSTEMS.md` explicitly supersedes those for the first crossing. Likewise, historical route paragraphs in `STORY_DESIGN.md` assign the sword to the sand cave, while the current plan moves it to the lighthouse. Retrieval must preserve the “superseded / planned / implemented” distinction and prefer the current-priority notes; otherwise it can confidently return obsolete requirements.

## Structural checks passed

- Root JSON: 939 unique node IDs; 1,334 links; 21 hyperedges.
- No duplicate node IDs, dangling link endpoints, self-links or missing hyperedge members.
- Link confidence counts: 1,133 EXTRACTED, 197 INFERRED, 4 AMBIGUOUS. The report's 0% ambiguous figure is rounding, not zero ambiguous links.
- All 463 indexed source paths still exist in the project.

These checks validate graph consistency, not the truth of every semantic relationship. Isolated nodes and graph centrality are navigation clues, not evidence of bugs or performance bottlenecks.

## Recommended next pass

1. Establish the LightRAG output location and inspect its ingestion manifest, latest query answers and source citations before judging its conclusions.
2. Refresh Graphify's changed design/instruction sources, including the cluster plan. Check how this extraction pipeline can include GDScript and room JSON; if unsupported, add explicit source-linked summaries rather than treating documentation references as parsed code.
3. Label historical/proposed/current material and encode supersession links. Test questions about sword location, first-crossing requirements, stress rules and cluster/shortcut topology against current authoritative sources.
4. For the map plan, build a separate room/exit graph from room definitions and progression gates. Validate reachability at each ability/quest state, physical seams, one-way transitions and shortcut travel times. A document knowledge graph alone cannot establish these properties.
5. Retain raw outputs and mark snapshot dates accurately. Do not trigger a full semantic rebuild merely to inspect the results: the root cost record reports 534,348 input tokens for the latest run.

LightRAG status remains **not inspected**, rather than inferred from Graphify's findings.


---

<a id="docs-reviews-monster-editor-review"></a>

## Source: docs/reviews/monster-editor/REVIEW.md

Original source: `docs/reviews/monster-editor/REVIEW.md`. [Evidence directory](../../docs/reviews/monster-editor/).

# Review: Monster Editor (2026-11-01)

Reviewed `scripts/attack_catalog_editor.gd` (1031 lines), `scripts/attack_catalog.gd` (load, validate, score,
select, save), the editor's exits in `scripts/menu.gd`, and the runtime consumers in `scripts/entities.gd`
(ActionMonster, families, Ape), at commit `2f64b3a`. Method: read end to end; re-ran Codex's probe scene
(`reports/monster-editor-review-2026-11-01/probes.tscn`, all 12 of its findings reproduce today); windowed screenshots
of both tabs at 1280x720; `tests/attack_catalog.tscn` passes (it misses everything below). Skills used: code-review,
systematic-debugging, verification-before-completion, godot-best-practices, ponytail-review, godot-ui-control,
save-systems, performance-optimization. **Headline: 3 blocking, 8 major, 6 minor, 2 questions.** Codex's
`reports/monster-editor-review-2026-11-01/README.md` has the raw evidence for the findings marked (C).

**Status (2026-11-01): fixed 1-17.** Speed (11): the Ape page went 57 → 8 ms. Attack details build when opened;
the world is read once; the real cost was the ▲ ▼ ✕ buttons: the UI font lacks those glyphs, and the system-font
fallback took ~2 ms per button. They are now drawn pixel icons. 18: kept as asked (same boxes per type). 19: moving hits now count their swept strip
(√area × 15 tiles), so the Ape's attacks sit within ~4x of each other.

## Findings

1. **[BLOCKING] Renaming an attack ID hijacks other attacks' bindings (C).** `_change("name")` runs on every
   keystroke (`attack_catalog_editor.gd:218`, `:344-350`) and renames every binding / follow-up equal to the previous
   text. Typing a new attack's ID through `shoot` → `shoot_variant` moves both real `shoot` bindings (library monsters,
   Murkspore) to the new planned attack; the result validates and saves. Probe: `rename_hijacked_existing_shoot_bindings: 2`.
2. **[BLOCKING] Esc leaves the editor and silently drops unsaved edits (C).** Back asks for confirmation
   (`menu.gd:91-99`) but `ui_cancel` (`menu.gd:124-126`) calls `_main()` directly; the on-screen hint even says
   "X / Esc: back". Probe: `escape_discards_dirty_editor: true`, confirmations 0.
3. **[BLOCKING] A huge Multishot / follow-up count can freeze the editor (C).** No upper bound in validation
   (`attack_catalog.gd:95-97`, `:153-155`); scoring and the game loop per shot, and the score recomputes while typing.
   `multishot = 100000000` validates. One extra zero typed by accident hangs the game.
4. **[MAJOR] Attacks the game needs can be renamed or deleted (C).** Protection only checks `EXECUTABLE`; `ape_slam`,
   `ape_split`, `ape_log` are read by the Ape (`entities.gd` ~2785, 2894, 2944) but aren't listed, so the editor offers
   Delete / rename and validation still passes; the Ape then silently uses hard-coded fallbacks.
5. **[MAJOR] Family loadouts ignore Min range and ✕ (C).** Families use `atk_range()` / `atk_ready()` (no minimum,
   fallback range when the binding is missing). Probe: an Ossling with Min 10 attacks at 5.5 tiles, and still attacks
   after its binding is removed. The editor shows controls that do nothing for 6 of the 8 editable enemies.
6. **[MAJOR] Skip % is re-rolled every frame for library monsters (verified by reading).** ActionMonster's idle branch
   calls `select_attack` each frame (`entities.gd:1320`); a skipped attack is rolled again next frame, so 50 % skip only
   delays it by ~1 frame. Same for the Ape when its only eligible attack is skipped (`:2641`). Families do it right
   (`atk_ready` waits the recovery after a skip).
7. **[MAJOR] Follow-up picker promises more than the game does (C).** Any attack can be chosen as "Then", and it's
   scored, but only `ape_retreat` runs a follow-up and always throws stones (probe: follow-up set to scream → enters
   `throw`). Follow-up cycles (A → B → A) validate; scoring stops after one level.
8. **[MAJOR] Scores can be wrong or stale (C).** (a) An unscored follow-up is dropped and the parent still says
   "valid" (retreat + log = 17.44, should be incomplete). (b) Saved scores are computed from unrounded neighbours
   (33.06 saved vs 32.98 on reload). (c) Editing a compact field updates the row score but not the enemy total
   (shows 3.16, real 2.24).
9. **[MAJOR] The Add-attack dropdown forces the page wider than the window (C).** OptionButton minimum 777 px; a
   1000 px editor becomes 1193 px. Long attack names make it worse.
10. **[MAJOR] Save isn't crash-safe for the pair of files.** `save_all` (`attack_catalog.gd:322-337`) stages `.tmp`
    files (good) but replaces the two CSVs one after the other with no backup; a crash between the renames leaves new
    attacks + old bindings, and the rollback writes `.restore` from a string read before staging. Keep a `.bak` of
    each and check reload succeeds before clearing `dirty`.
11. **[MAJOR] Selecting an enemy rebuilds the whole form (57 ms for the Ape, 210 nodes) (C).** Collapsed sections,
    frame strips and tooltips are built even when hidden; `_code_enemy_info` / `_score_text` reparse every room JSON
    via `Adventure.load_world` on each selection.
12. **[MINOR] Dead code: the library-monster branch.** `_all_enemies()` excludes `enemy_monster`, so
    `_sample_monster()` (`:464`), its uses at `:488` / `:840`, and the "Placed in the story" build table (`:650-680`)
    never run.
13. **[MINOR] Whole numbers shown with two decimals.** Min / Max / Skip % read "0.00", "40.00", "0.00" (screenshot);
    a percent and ranges in tiles are easier to read as `0`, `40`, `25`. Trim trailing zeros on display.
14. **[MINOR] "Animation reference" doesn't look clickable** (plain text in the screenshot, under a large empty
    sprite area); give it the same "+ / −" toggle look as "+ Trajectory".
15. **[MINOR] Scroll position carries over between enemies (C)** (180 px kept: the new enemy's title starts hidden).
16. **[MINOR] Help text describes the old ordering (C)** (`_help`, `:1022`, `:1029`: "max range decides, priority
    breaks ties"); the game now uses priority first.
17. **[MINOR] 28 read-only entries are mixed into the 36-row enemy list (C)**; group editable ones first or add a
    divider.
18. **[QUESTION] Should Type drive which boxes show, or the attack's own mechanics?** Every movement attack shows
    "Shockwave time" (only the landing slam uses it) and "Max distance" (only charge). You asked for the same boxes
    per type; the alternative is per-attack boxes, greyed when unused.
19. **[QUESTION] Score scale.** The scream scores 164.56 next to throws at 5.18; area dominates every total. Leave
    as is, or normalise per type? (Also asked in `docs/reviews/monsters/CODEX_PROMPT.md` #13.)

## Fix prompt

```text
Fix the Monster Editor. Read AGENTS.md, docs/ATTACK_CATALOG.md and docs/reviews/monster-editor/REVIEW.md first
(evidence: reports/monster-editor-review-2026-11-01/). Stay inside this repository. Keep gameplay identical unless a
task says so. Don't edit worlds/ (the designer edits rooms in the World Editor). Leave the two [QUESTION] items alone.

Context: scripts/attack_catalog.gd loads, validates, scores, selects and saves data/attacks.csv and
data/enemy_attacks.csv (AttackCatalog.shared(), EXECUTABLE, select_attack, score_attack, save_all).
scripts/attack_catalog_editor.gd is the Monster Editor (main menu → Monster Editor; tabs "Attack library" and
"Enemy loadouts"; opened by menu.gd _monster_editor). Runtime users are in scripts/entities.gd: ActionMonster
(library monsters, select_attack each idle frame), CombatEnemy families via attack_id()/atk()/atk_range()/atk_ready(),
and the Ape (_select_attack, plus ape_slam/ape_split/ape_log values).

Tasks (one commit each, blocking first; write the test first and see it fail):
1. ID rename commits only on Enter / focus-out, from the ID as it was when editing started; reject empty, duplicate
   and runtime-used IDs. Test: type "shoot" then "shoot_variant" into a new attack's ID → shoot's bindings unchanged.
2. Esc / ui_cancel goes through the same guarded exit as Back (Save / Discard / Cancel when dirty). Test the real
   unhandled-input path.
3. Bound multishot (e.g. 1-64) and follow_up_count (1-10) in validation; reject before scoring. Test 100000000 fails.
4. One registry of runtime-required attack IDs (EXECUTABLE + ape_slam, ape_split, ape_log and any other
   AttackCatalog.value() lookups in entities.gd); rename/delete disabled for them; validation fails if one is missing.
   Add a test that greps entities.gd for literal attack IDs and checks each is in the registry and the CSV.
5. Families select through select_attack (min/max/priority/skip like everyone); a removed binding means no attack.
   Test: Ossling with min 10 at 5.5 tiles doesn't attack; without a binding it never winds up.
6. Skip % rolls once per decision: a skipped attack waits its recovery before it can be rolled again (as atk_ready
   does) for ActionMonster and the Ape. Test: skip 100 never attacks; skip 50 over 200 decisions ≈ half.
7. Follow-ups: the Ape's retreat runs the named follow-up (any attack the Ape performs), not always throw; the picker
   only offers attacks that enemy can perform and labels the rest "not in game yet"; reject follow-up cycles.
8. Scores: an unscored follow-up makes the parent incomplete; compute saved scores from the rounded snapshot; refresh
   the enemy total on every compact-field edit. Tests for each (17.44 → incomplete, 33.06 vs 32.98, 3.16 → 2.24).
9. Add-attack dropdown: fixed width with clipped text + tooltip; the editor fits 1000 px. Test minimum width ≤ requested.
10. save_all: keep <file>.bak of both CSVs before replacing, restore both on any failure, clear dirty only after
    reload() succeeds. Test with a read-only assignments path.
11. Performance: build collapsed sections and frame strips only when opened; load the world once per editor session
    (refresh on Reload). Measure the Ape selection before/after with the probe (now ~57 ms) and report both numbers.
12. Remove the dead library-monster code (_sample_monster, the build table, its _score_text branch) and any test that
    only covers it.
13. Display numbers without trailing zeros (0, 40, 2.5); CSV keeps its format.
14. "Animation reference" uses the same "+ / −" toggle style as "+ Trajectory".
15. Reset scroll to the top when switching enemy (keep it when rebuilding the same one).
16. Update _help's ordering text: priority first, then range.
17. Enemy list: editable enemies first, then a divider, then read-only ones.

Verification:
- XDG_DATA_HOME=$(mktemp -d) godot --headless --path . res://tests/attack_catalog.tscn → ATTACK CATALOG OK
- XDG_DATA_HOME=$(mktemp -d) godot --headless --path . res://tests/test.tscn → 0 failure(s)
- XDG_DATA_HOME=$(mktemp -d) godot --headless --path . res://reports/monster-editor-review-2026-11-01/probes.tscn:
  every defect key in observations.json flips (false / within bounds)
- sh tools/verify.sh → 0 failing
- Windowed screenshots of both tabs (Ape and Ossling selected) at 1280x720 for tasks 9, 13, 14, 17.
- One dated line in gdd.txt per task; update docs/ATTACK_CATALOG.md where behaviour changes.
```

## Suggestions for the future

- **Test fight button**: open a tiny room with the selected enemy and the player, so a timing edit can be felt
  immediately instead of judged from numbers.
- **Trajectory preview**: draw the leap / lob / charge path from the current values next to the sprite (cheap, and
  catches bad gravity or speed at a glance).
- **Undo** for the last few edits (field, ▲▼, ✕) instead of only "Reload" for the whole draft.
- **"Used by" line** on each attack in the Attack library (e.g. "Ape, Murkspore, library monsters"), since one edit
  changes all of them.
- **Split the 1031-line editor** into the attack form, the loadout card and the field widget once the fixes land;
  most bugs above come from two paths doing the same thing differently (Back vs Esc, main vs compact fields).
- **Data-driven eligibility** (same height ±N tiles, line of sight, cornered) as binding columns, so new rules don't
  need code in entities.gd.
- **Budget placement** (from `docs/reviews/monsters/CODEX_PROMPT.md` task 7) will rely on these scores: fix 8 first.


---

<a id="docs-reviews-monster-editor-followup-claude-prompt"></a>

## Source: docs/reviews/monster-editor-followup/CLAUDE_PROMPT.md

Original source: `docs/reviews/monster-editor-followup/CLAUDE_PROMPT.md`. [Evidence directory](../../docs/reviews/monster-editor-followup/).

You are fixing the Monster Editor in Bethe Knight, a Godot 4 platformer. Work inside
`/home/viridjan/Projects/videogame` and follow its `AGENTS.md`.

Read first:
- `docs/reviews/monster-editor-followup/REVIEW.md` — current findings, reviewed at `450a07e`.
- `reports/monster-editor-followup-2026-11-01/observations.json` and `probes.gd` — reproducible evidence.
- `docs/ATTACK_CATALOG.md`, `docs/ATTACK_SCORING_PLAN.md`, and the relevant portions of `gdd.txt`.

Implement the fixes below, rather than writing another review. First check current
HEAD: some findings may have been fixed since this prompt was written. Reproduce
remaining issues and add a failing regression test before each fix. Keep each task
small and reviewable; one commit and one dated gdd.txt line per task. Do not commit
unrelated work or push unless the user authorizes it.

Context

`scripts/attack_catalog.gd` validates, scores, selects, and saves `data/attacks.csv`
and `data/enemy_attacks.csv`. `scripts/attack_catalog_editor.gd` implements Attack
library / Enemy loadouts, with a private editable draft and lazy detail panels.
`scripts/menu.gd` owns editor navigation and guarded exits. Runtime consumers are
in `scripts/entities.gd`: ActionMonster, fixed CombatEnemy families, and the Ape.
The family helpers are `_binding`, `atk_range`, and `atk_ready`. Existing protection
uses `EXECUTABLE`, `RUNTIME_ONLY`, `runtime_used`, `MAX_SHOTS`, `MAX_FOLLOW_UPS`, and
`FOLLOW_UPS`/`follow_up_runs`.

The original review's rename, Escape, ID-protection, count-bound, single-binding
removal, score-rounding, and layout-width bugs have already been fixed. Preserve
those fixes. The earlier 57 ms Ape rebuild was also fixed with lazy construction
and pixel icons; the latest probe is about 7 ms with 86 overview nodes. Do not
reintroduce system-font-fallback arrow glyphs or rebuild hidden settings eagerly.

Tasks (all currently confirmed; address in this order)

1. Distinguish a successfully loaded EMPTY binding table from a failed/uninitialized catalogue.
   `CombatEnemy.atk_range()` and `atk_ready()` currently use `assignments.is_empty()`
   as a load-failure signal. A valid header-only assignment CSV therefore enables
   fallback attacks, while the common selector correctly finds none.
   Expected: a valid empty loadout disables attacks for every migrated enemy; any
   intentional behavior for a genuine read failure must use an explicit load state.
   Test: load a valid empty table, run an actual SkeletonEnemy update with an eligible
   nearby player, and assert it never enters wind-up. Cover the individual removed
   binding and genuinely failed-load cases separately. Do not just test selector output.

2. Refresh dependent scores, including collapsed cards, after editing a shared attack.
   Compact fields refresh their own score and the footer but not other cards whose
   follow-ups reference that attack. With the current data, editing ape_throw wind-up
   to 1.90 leaves the retreat card at 236.72 while recomputation gives 140.89.
   Expected: one draft-change path invalidates every dependent displayed score and
   the total. Handle direct edits, follow-up changes, and shared definitions; preserve
   caret/focus and expanded-card state. Avoid rebuilding the whole form per keystroke.
   Test: open both Ape cards, edit the throw through its actual field, and compare
   the parent card, child card, and footer with fresh model calculations.

3. Separate executable loadout scores from planning scores.
   `_score_text()` currently passes every binding into `enemy_score`, including ones
   `performs()` says the enemy cannot run. Adding a planned melee attack to Hornback
   increases its displayed score from 17.29 to 19.55 without changing its behavior.
   Expected: the live repertoire score excludes unsupported attack bindings and
   unsupported follow-ups. Retain planned data and, if useful, show a separate clearly
   labelled planned score. Do not change the general reference scorer into a runtime-
   only scorer: the Attack library must still be able to score standalone plans.
   Test: an unsupported binding does not change the live score, remains visible as
   planned, is skipped at runtime, and round-trips through save/reload. Include a
   supported attack with an unsupported follow-up.

4. Make Ossling projectile controls truthful while preserving default combat.
   Its ranged form exposes Multishot and Spread, but SkeletonEnemy still hard-codes
   one shot, or two for Armored, with a fixed extra arc. A configured count of five
   currently emits one for a normal Ossling.
   Expected: implement supported CSV volley/spread inputs for this attack, or mark
   intentionally unsupported inputs read-only with a clear reason. Keep the same
   field slots per type; do not hide them. Preserve the default normal/Armored
   behavior and the existing active-bone budget. Document how a configured volley
   interacts with that budget rather than silently ignoring it. Avoid changing
   every enemy's balancing as a side effect.
   Test: normal Ossling with multishot=2 and an empty projectile budget produces the
   documented two-shot pattern; default normal/Armored behavior still passes; the
   active-bone cap and return/recovery behavior remain valid. If a field is deliberately
   score-only or unsupported, test its UI state and explanatory tooltip instead.

5. Add recovery for interrupted saves of the CSV pair.
   save_all keeps backups but reload never tries them. An interruption after replacing
   attacks.csv and before replacing enemy_attacks.csv can make the main pair invalid,
   even when both backup files form a valid previous pair.
   Expected: validate a pair as a pair, never mix a main file and an unrelated backup.
   Provide an explicit recovery path from a verified backup pair and explain recovery
   status in the editor. Preserve the damaged main files for inspection; do not
   silently overwrite newer external edits. Revalidate successful restoration/readback
   before clearing dirty or claiming success, and check rollback copy errors.
   Tests: simulate interruption after the first replacement; valid backups are usable;
   invalid/mismatched backups are refused; a valid main pair wins over old backups;
   user cancellation and restoration failures do not destroy the private draft.
   Use disposable paths, not the project's real CSVs or player saves.

6. Unify numeric commit behavior across the two forms.
   Attack-library fields normalize on focus exit, but compact loadout fields and
   range fields do not. A compact value of 1.234 remains displayed after focus exit,
   though its saved input will be 1.23.
   Expected: normalize through one reusable commit path on Enter/focus exit, preserve
   integer fields and blank optional values, and recalculate against the normalized
   draft. Keep editing smooth; do not force formatting on each digit. Retain two
   decimal places MAXIMUM in authored values, without rounding internal calculations.
   Test both forms and binding fields, including blanks, integers, invalid input,
   and positive durations that would round to zero.

7. Make live validation identify the control that needs fixing.
   Error colors are only applied while controls are constructed. Newly entering an
   invalid value disables Save but does not mark that existing field.
   Expected: update and clear field errors reactively; identify invalid collapsed
   sections; provide a way to reveal/focus an offending field without rebuilding
   the form or losing the caret. Retain model validation for external CSVs.
   Test: valid -> invalid -> corrected through the real widgets updates feedback,
   Save state, and the field/section marker in both views.

Constraints

- Do not edit `worlds/` or repopulate enemies. Calibrated placement/budgets are a
  separate feature; do not copy that task from an older monsters prompt.
- Preserve current priorities, skip-once cooldowns, boss safety sequences, phase
  transitions, and CSV IDs/defaults except where an explicit task changes behavior.
- Preserve the current swept-strip scoring rule (`SWEEP_LENGTH=15`), the wind-up
  curve, and two-decimal CSV policy. Do not invent scores for missing speed or
  measured times >=2 seconds; those remain designer decisions.
- Keep the editor out of web builds and both raw CSVs available to runtime exports.
- Reuse existing validators and gameplay entry points; avoid adding a second source
  of truth or a new combat framework. Refactor UI helpers only where these fixes need it.
- Preserve unsaved-change prompts, external-file conflict checks, protected IDs,
  deferred rename validation, and the lazy 2-column organized UI.
- Do not treat an observation-only review probe's zero exit code as a passing
  regression suite, and do not overwrite historical observation JSON with post-fix data.

Verification

Use disposable user data. Run at least:

  XDG_DATA_HOME=/tmp/summit-claude-monster-catalog godot --headless --path . res://tests/attack_catalog.tscn
  XDG_DATA_HOME=/tmp/summit-claude-monster-physics godot --headless --path . res://tests/test.tscn
  XDG_DATA_HOME=/tmp/summit-claude-monster-smoke godot --headless --path . res://tests/smoke.tscn
  sh tools/verify.sh
  git diff --check

Expected markers: ATTACK CATALOG OK; 0 failure(s); SMOKE OK; final verification
summary 0 failing. Inspect the logs for script/parse/load errors even if Godot
exits zero. Extend the relevant custom tests for each task; do not weaken prior
assertions just to make changed behavior pass. For UI changes, inspect screenshots
of both views, invalid-field states, and recovery/confirmation flows. For any
performance change, measure the same scenario before/after; label headless/debug
measurements and do not claim release/mobile performance from them.

At completion, summarize each fixed finding, commands/results, any unresolved
questions, and the commits. Update the usage docs to match actual behavior.


---

<a id="docs-reviews-monster-editor-followup-review"></a>

## Source: docs/reviews/monster-editor-followup/REVIEW.md

Original source: `docs/reviews/monster-editor-followup/REVIEW.md`. [Evidence directory](../../docs/reviews/monster-editor-followup/).

# Review: Monster Editor follow-up (2026-11-01)

Reviewed commit `450a07e`: `scripts/attack_catalog_editor.gd`, `scripts/attack_catalog.gd`,
`scripts/menu.gd`, relevant family/Ape consumers in `scripts/entities.gd`, CSV data,
custom tests, and usage docs. Read the paths, ran the current regression scene and
fresh disposable-data probes, and inspected new windowed screenshots of both views.
Used game-review with code-review, systematic-debugging, verification-before-completion,
godot-best-practices, godot-ui-control, godot-state-machine, save-systems,
performance-optimization, and test-driven-development for the fix prompt. The optional
ponytail/security/simplify helpers were unavailable; applied their scope, file-safety,
bounds, and reuse fallbacks. **Headline: 0 blocking, 5 major, 2 minor; 1 existing
scoring question remains with the designer.** No production fixes are made here.

This supersedes the *open-task list* from the earlier review, not its historical
evidence. Commits `082e3e5`, `2344655`, and `3833bed` fixed the original dangerous
rename/exit/count issues, required IDs, single-binding handling, score completeness
and rounding, width/scroll/help issues, and most editor rebuild cost. The latest
`450a07e` intentionally changes moving-attack scoring to include swept coverage.
Do not ask another agent to redo those changes or restore the old score formula.

## Findings

1. **[MAJOR] A valid empty binding table revives fixed-family attacks.**
   `entities.gd:750–757` treats `assignments.is_empty()` as a catalogue read failure.
   But a header-only assignment CSV validates. The probe clears all bindings in
   memory; a SkeletonEnemy with a nearby player enters `windup` using fallback
   range. An individual removed binding is now handled correctly; the globally
   empty case is not. Track successful load state separately from row count and
   test actual enemy updates with valid empty, individual removed, and failed-load
   catalogues. This is the highest-priority remaining editor/gameplay contract bug.

2. **[MAJOR] Dependent attack-card scores still stay stale.**
   `attack_catalog_editor.gd:756–774` refreshes the edited card and total, but not
   parent cards whose follow-up uses the edited attack. With the current formula,
   changing the throw wind-up to `1.90` leaves the retreat card at **236.72**, while
   recalculation gives **140.89**. The original footer-staleness bug is fixed;
   dependency invalidation is incomplete. Notify all dependent visible score
   widgets, including collapsed cards, without rebuilding controls per keystroke.

3. **[MAJOR] Planned attacks inflate the apparent live enemy score.**
   `attack_catalog_editor.gd:998–1013` sends every binding to `enemy_score()`;
   `attack_catalog.gd:193–208` has no executable/planning distinction. Adding a
   planned melee attack to Hornback raises the displayed score **17.29 -> 19.55**
   while `performs()` remains false and runtime skips that binding. Keep reference
   scores for plans, but label/separate planning totals from the executable
   repertoire. Unsupported follow-ups need the same treatment.

4. **[MAJOR] Ossling's ranged controls still include inputs gameplay ignores.**
   `entities.gd:1088–1092` hard-codes normal/Armored volley count and the extra arc.
   The common ranged form exposes Multishot and Spread, but configuring five shots
   on `ossling_bone_throw` emits **one** for a normal SkeletonEnemy. The family
   projectile budget of three is a separate existing constraint; the current
   implementation ignores the value rather than applying that budget. Wire
   supported values consistently or mark intentionally unsupported/score-only
   fields explicitly. Preserve default combat and same field slots per type.

5. **[MAJOR] Backup files exist, but interrupted-pair recovery is not implemented.**
   `attack_catalog.gd:52–69` reads only the main pair. `save_all():356–372` replaces
   two files sequentially. A simulated interruption after the first replacement
   makes reload fail with `Unknown attack binding: draft_old`; both previous backup
   files exist and form a valid pair. Provide explicit validated-pair recovery,
   preserving damaged files and checking all restore results. Do not confuse
   `.bak` existence with crash-atomic saving or successful recovery.

6. **[MINOR] Numeric commit/rounding differs between forms.**
   Main fields normalize on Enter/focus exit (`attack_catalog_editor.gd:347–354`),
   compact fields do not (`:756–775`); binding fields have the same gap. The probe
   leaves a compact field at **1.234** after focus exit although CSV persistence
   rounds it to two decimals. Use a shared numeric commit path and update scores
   against that normalized draft. Preserve integer and blank-value semantics.

7. **[MINOR] Newly invalid controls are not marked live.**
   Error color is assigned only while the control is built (`:337–338`, `:766–767`).
   A later invalid compact value correctly disables Save and locates the model
   error, but the existing field receives no error color. Update/clear markers in
   place and identify collapsed sections containing errors; offer reveal/focus.

## Verification and UI observations

Evidence: [observations JSON](../monster-editor-followup-2026-11-01/observations.json),
[probe script](../monster-editor-followup-2026-11-01/probes.gd),
[Attack library screenshot](../monster-editor-followup-2026-11-01/attacks.png),
[Enemy loadouts screenshot](../monster-editor-followup-2026-11-01/enemies.png).

- Current `tests/attack_catalog.tscn` passes. The new probe exercises missing cases
  using disposable `user://` files and restores shared in-memory catalogue edits.
- The prior 57 ms observation is obsolete. Fresh warm headless/debug navigation
  measured about **7 ms**, with **86** overview nodes instead of the previous 210.
  This is a method measurement, not release FPS or a GPU/mobile benchmark. Preserve
  lazy detail construction and the pixel-icon controls; no broad optimization
  rewrite is justified by this measurement.
- New screenshots show clear navigation, a read-only divider, compact cards,
  collapsed animation references, and pinned Save/Reload controls. The remaining
  UI problems concern trustworthy feedback and what the controls actually change.
- A suspected Escape bug for an uncommitted ID was **not reproduced** with a real
  input event: the focused ID field did not leave the editor. It is excluded from
  the findings; do not undo deferred rename handling based on the old probe.
- The old observation-only probe uses superseded APIs/assumptions. Use current
  product tests plus these fresh cases; a probe's zero exit code means it collected
  observations, not that all recorded behavior is correct.

## Fix prompt

The following is also saved separately as [CLAUDE_PROMPT.md](../../docs/reviews/monster-editor-followup/CLAUDE_PROMPT.md).

```text
You are fixing the Monster Editor in Bethe Knight, a Godot 4 platformer. Work inside
`/home/viridjan/Projects/videogame` and follow its `AGENTS.md`.

Read first:
- `docs/reviews/monster-editor-followup/REVIEW.md` — current findings, reviewed at `450a07e`.
- `reports/monster-editor-followup-2026-11-01/observations.json` and `probes.gd` — reproducible evidence.
- `docs/ATTACK_CATALOG.md`, `docs/ATTACK_SCORING_PLAN.md`, and the relevant portions of `gdd.txt`.

Implement the fixes below, rather than writing another review. First check current
HEAD: some findings may have been fixed since this prompt was written. Reproduce
remaining issues and add a failing regression test before each fix. Keep each task
small and reviewable; one commit and one dated gdd.txt line per task. Do not commit
unrelated work or push unless the user authorizes it.

Context

`scripts/attack_catalog.gd` validates, scores, selects, and saves `data/attacks.csv`
and `data/enemy_attacks.csv`. `scripts/attack_catalog_editor.gd` implements Attack
library / Enemy loadouts, with a private editable draft and lazy detail panels.
`scripts/menu.gd` owns editor navigation and guarded exits. Runtime consumers are
in `scripts/entities.gd`: ActionMonster, fixed CombatEnemy families, and the Ape.
The family helpers are `_binding`, `atk_range`, and `atk_ready`. Existing protection
uses `EXECUTABLE`, `RUNTIME_ONLY`, `runtime_used`, `MAX_SHOTS`, `MAX_FOLLOW_UPS`, and
`FOLLOW_UPS`/`follow_up_runs`.

The original review's rename, Escape, ID-protection, count-bound, single-binding
removal, score-rounding, and layout-width bugs have already been fixed. Preserve
those fixes. The earlier 57 ms Ape rebuild was also fixed with lazy construction
and pixel icons; the latest probe is about 7 ms with 86 overview nodes. Do not
reintroduce system-font-fallback arrow glyphs or rebuild hidden settings eagerly.

Tasks (all currently confirmed; address in this order)

1. Distinguish a successfully loaded EMPTY binding table from a failed/uninitialized catalogue.
   `CombatEnemy.atk_range()` and `atk_ready()` currently use `assignments.is_empty()`
   as a load-failure signal. A valid header-only assignment CSV therefore enables
   fallback attacks, while the common selector correctly finds none.
   Expected: a valid empty loadout disables attacks for every migrated enemy; any
   intentional behavior for a genuine read failure must use an explicit load state.
   Test: load a valid empty table, run an actual SkeletonEnemy update with an eligible
   nearby player, and assert it never enters wind-up. Cover the individual removed
   binding and genuinely failed-load cases separately. Do not just test selector output.

2. Refresh dependent scores, including collapsed cards, after editing a shared attack.
   Compact fields refresh their own score and the footer but not other cards whose
   follow-ups reference that attack. With the current data, editing ape_throw wind-up
   to 1.90 leaves the retreat card at 236.72 while recomputation gives 140.89.
   Expected: one draft-change path invalidates every dependent displayed score and
   the total. Handle direct edits, follow-up changes, and shared definitions; preserve
   caret/focus and expanded-card state. Avoid rebuilding the whole form per keystroke.
   Test: open both Ape cards, edit the throw through its actual field, and compare
   the parent card, child card, and footer with fresh model calculations.

3. Separate executable loadout scores from planning scores.
   `_score_text()` currently passes every binding into `enemy_score`, including ones
   `performs()` says the enemy cannot run. Adding a planned melee attack to Hornback
   increases its displayed score from 17.29 to 19.55 without changing its behavior.
   Expected: the live repertoire score excludes unsupported attack bindings and
   unsupported follow-ups. Retain planned data and, if useful, show a separate clearly
   labelled planned score. Do not change the general reference scorer into a runtime-
   only scorer: the Attack library must still be able to score standalone plans.
   Test: an unsupported binding does not change the live score, remains visible as
   planned, is skipped at runtime, and round-trips through save/reload. Include a
   supported attack with an unsupported follow-up.

4. Make Ossling projectile controls truthful while preserving default combat.
   Its ranged form exposes Multishot and Spread, but SkeletonEnemy still hard-codes
   one shot, or two for Armored, with a fixed extra arc. A configured count of five
   currently emits one for a normal Ossling.
   Expected: implement supported CSV volley/spread inputs for this attack, or mark
   intentionally unsupported inputs read-only with a clear reason. Keep the same
   field slots per type; do not hide them. Preserve the default normal/Armored
   behavior and the existing active-bone budget. Document how a configured volley
   interacts with that budget rather than silently ignoring it. Avoid changing
   every enemy's balancing as a side effect.
   Test: normal Ossling with multishot=2 and an empty projectile budget produces the
   documented two-shot pattern; default normal/Armored behavior still passes; the
   active-bone cap and return/recovery behavior remain valid. If a field is deliberately
   score-only or unsupported, test its UI state and explanatory tooltip instead.

5. Add recovery for interrupted saves of the CSV pair.
   save_all keeps backups but reload never tries them. An interruption after replacing
   attacks.csv and before replacing enemy_attacks.csv can make the main pair invalid,
   even when both backup files form a valid previous pair.
   Expected: validate a pair as a pair, never mix a main file and an unrelated backup.
   Provide an explicit recovery path from a verified backup pair and explain recovery
   status in the editor. Preserve the damaged main files for inspection; do not
   silently overwrite newer external edits. Revalidate successful restoration/readback
   before clearing dirty or claiming success, and check rollback copy errors.
   Tests: simulate interruption after the first replacement; valid backups are usable;
   invalid/mismatched backups are refused; a valid main pair wins over old backups;
   user cancellation and restoration failures do not destroy the private draft.
   Use disposable paths, not the project's real CSVs or player saves.

6. Unify numeric commit behavior across the two forms.
   Attack-library fields normalize on focus exit, but compact loadout fields and
   range fields do not. A compact value of 1.234 remains displayed after focus exit,
   though its saved input will be 1.23.
   Expected: normalize through one reusable commit path on Enter/focus exit, preserve
   integer fields and blank optional values, and recalculate against the normalized
   draft. Keep editing smooth; do not force formatting on each digit. Retain two
   decimal places MAXIMUM in authored values, without rounding internal calculations.
   Test both forms and binding fields, including blanks, integers, invalid input,
   and positive durations that would round to zero.

7. Make live validation identify the control that needs fixing.
   Error colors are only applied while controls are constructed. Newly entering an
   invalid value disables Save but does not mark that existing field.
   Expected: update and clear field errors reactively; identify invalid collapsed
   sections; provide a way to reveal/focus an offending field without rebuilding
   the form or losing the caret. Retain model validation for external CSVs.
   Test: valid -> invalid -> corrected through the real widgets updates feedback,
   Save state, and the field/section marker in both views.

Constraints

- Do not edit `worlds/` or repopulate enemies. Calibrated placement/budgets are a
  separate feature; do not copy that task from an older monsters prompt.
- Preserve current priorities, skip-once cooldowns, boss safety sequences, phase
  transitions, and CSV IDs/defaults except where an explicit task changes behavior.
- Preserve the current swept-strip scoring rule (`SWEEP_LENGTH=15`), the wind-up
  curve, and two-decimal CSV policy. Do not invent scores for missing speed or
  measured times >=2 seconds; those remain designer decisions.
- Keep the editor out of web builds and both raw CSVs available to runtime exports.
- Reuse existing validators and gameplay entry points; avoid adding a second source
  of truth or a new combat framework. Refactor UI helpers only where these fixes need it.
- Preserve unsaved-change prompts, external-file conflict checks, protected IDs,
  deferred rename validation, and the lazy 2-column organized UI.
- Do not treat an observation-only review probe's zero exit code as a passing
  regression suite, and do not overwrite historical observation JSON with post-fix data.

Verification

Use disposable user data. Run at least:

  XDG_DATA_HOME=/tmp/summit-claude-monster-catalog godot --headless --path . res://tests/attack_catalog.tscn
  XDG_DATA_HOME=/tmp/summit-claude-monster-physics godot --headless --path . res://tests/test.tscn
  XDG_DATA_HOME=/tmp/summit-claude-monster-smoke godot --headless --path . res://tests/smoke.tscn
  sh tools/verify.sh
  git diff --check

Expected markers: ATTACK CATALOG OK; 0 failure(s); SMOKE OK; final verification
summary 0 failing. Inspect the logs for script/parse/load errors even if Godot
exits zero. Extend the relevant custom tests for each task; do not weaken prior
assertions just to make changed behavior pass. For UI changes, inspect screenshots
of both views, invalid-field states, and recovery/confirmation flows. For any
performance change, measure the same scenario before/after; label headless/debug
measurements and do not claim release/mobile performance from them.

At completion, summarize each fixed finding, commands/results, any unresolved
questions, and the commits. Update the usage docs to match actual behavior.
```

## Suggestions for the future

- Show a shared-definition badge/use count so an edit's impact across enemies is visible.
- Add undo or per-card revert; reloading the whole draft is an expensive recovery workflow.
- Offer a standalone New attack action in the library, instead of requiring an enemy binding first.
- Separate implemented authoring and planning modes without hiding stored planned work.
- Keep scoring, draft-change propagation, and field validation in reusable helpers;
  split the 1,000-line UI controller incrementally, not through a new combat framework.
- Replace duplicated numeric LineEdit logic with one validated field component or
  carefully configured Godot numeric control. Preserve keyboard editing and CSV validation.
- Remove unused arguments such as `_edit_notes`'s title parameter, and consider
  simplifying the currently unused caller-facing `size_scale` option only after
  confirming its intended future API; neither is an urgent gameplay fix.
- Runtime attack-ID/binding indexes may help large encounters, but profile that
  workload before changing it. Current editor latency does not warrant replacing
  working art caches or reintroducing eager UI construction.

## Question left to the designer

The score for measured times >=2 seconds and initially stationary falling hazards
is still undefined. Leave those explicitly unavailable. Preserve the swept-strip
rule and the two-decimal policy; this review does not authorize a new scoring scale,
region budgets, randomized placement changes, or edits to World Editor room data.


---

<a id="docs-reviews-monsters-codex-prompt"></a>

## Source: docs/reviews/monsters/CODEX_PROMPT.md

Original source: `docs/reviews/monsters/CODEX_PROMPT.md`. [Evidence directory](../../docs/reviews/monsters/).

# Codex prompt: monsters and the Monster Editor — fixes, cleanup, and placement by budget

Read `AGENTS.md`, `docs/ATTACK_CATALOG.md` and `docs/ATTACK_SCORING_PLAN.md` first. Stay inside this repository. Keep
gameplay identical unless a task says otherwise. Run `sh tools/verify.sh` (must end with `0 failing`) and add one dated
line per task to `gdd.txt`. Commit each numbered task separately.

## Context (verified in code, 2026-11-01)

- Attacks live in `data/attacks.csv` (mechanics + score inputs) and `data/enemy_attacks.csv` (per enemy / phase:
  min / max range in tiles, `priority`, `skip_chance` %). Loader, validation, scoring and selection:
  `scripts/attack_catalog.gd` (`AttackCatalog.shared()`, `ordered_attacks`, `select_attack`, `score_attack`,
  `enemy_score`, `shot_angles`, `max_range`, `performs`, `EXECUTABLE`, `CHOSEN_BY_RULE`).
- Enemies reading the CSV (`scripts/entities.gd`): `ActionMonster` (library monsters: `charge` for walkers and flyers,
  `leap`, `shoot`, `lob`), the `Ape` (`ape_retreat` with a follow-up, `ape_throw`, `ape_leap`, `ape_scream`, plus
  `ape_slam` / `ape_split` / `ape_log` values), and the families through `CombatEnemy.attack_id()` / `atk()` /
  `atk_range()` / `atk_ready()`: Dropwing `dropwing_dive`, Duskflit `charge` (flying), Ossling `ossling_bone_throw`,
  Hornback `charge`, Cragjaw `cragjaw_leap`, Murkspore `shoot`. Thornmite, Fuzzbob, Mosstrot only hurt on touch.
- The Monster Editor (`scripts/attack_catalog_editor.gd`, main menu → Monster Editor): **Attacks** tab (per-type
  boxes `TYPE_FIELDS`, Name / ID / Type, Weight, Delete attack) and **Enemies** tab (`CSV_ENEMIES` editable: sprite,
  frames, attacks in priority order with min / max / skip %, ▲ ▼ ✕, values grid, follow-up row, + Add attack, pinned
  score line; every other enemy type read-only). Tests: `tests/attack_catalog.gd`, `tests/test_runner.gd`.
- The story's 45 "library monsters" were placed by `tools/populate.gd` (random builds from `scripts/monster_library.gd`
  per zodiac region). The designer **does not want random builds**: enemies should be placed per area in calibrated
  ways (task 7).

## Findings to fix (most severe first)

1. **[BLOCKING] Renaming an attack ID corrupts bindings.** `_add_field` connects `text_changed` → `_change("name")`,
   which renames every binding / follow-up whose name equals the *previous keystroke's* value. Typing through an
   existing ID (e.g. `shoo` → `shoot` → `shoot2`) re-points the real `shoot` attack's bindings too. Fix: commit the
   rename only on Enter / focus-out, reject empty, duplicate or code-used IDs, and rename from the ID as it was when
   editing started. Add a test that types `shoot` then `shoot2` into a new attack's ID and checks `shoot`'s bindings
   are untouched.
2. **[BLOCKING] Skip % barely works for library monsters and the Ape.** `select_attack` rolls the skip chance on every
   call, and `ActionMonster` (idle branch) and `Ape` (idle with `timer <= 0`) call it every frame until something is
   chosen, so a 50 % skip is re-rolled ~60 times a second. Families already do it right (`atk_ready` → `skip_cd`). Fix:
   one roll per decision — a skipped attack waits (a per-enemy, per-attack cooldown = its recovery), like `atk_ready`.
   Test: skip 50 % gives roughly half the attacks over many decisions; skip 100 % never.
3. **[MAJOR] Follow-ups are editable everywhere but only one works.** Only `ape_retreat` honours `follow_up*`, and it
   always throws stones whatever `follow_up` names. Either run follow-ups generically (after an attack ends, start
   `follow_up` `follow_up_count` times, `follow_up_gap_s` apart, for enemies whose code performs that attack), or show
   "not in game yet" next to follow-ups the enemy can't do. Make the Ape use the named follow-up.
4. **[MAJOR] Values still hard-coded next to CSV ones.** Ossling: the Armored double throw (`volley := 2`) and the
   +25 px/s per extra arc ignore `multishot`; Cragjaw: fall cap 220 px/s and walking gravity 400 px/s² are constants
   while the leap uses CSV gravity; Bat: swoop distance is multiplied by `recovery_multiplier`. Move what the CSV can
   express into it (multishot + spread for Ossling; a max fall speed column if needed), keep variants as multipliers.
5. **[MAJOR] Families ignore part of their binding.** `atk_range` uses only the maximum; minimum range and priority
   are ignored (`atk_ready` rolls without a range check). Use `select_attack` for families too, so min / max /
   priority / skip mean the same for every enemy.
6. **[MAJOR] One source of truth for attack IDs.** IDs are repeated in `EXECUTABLE` (catalog), each class's
   `attack_id()` / match cases (entities), `CSV_ENEMIES` and `APE_POSES` (editor). Derive the editor's lists from
   `EXECUTABLE` and keep a test that every ID in code exists in the CSV and vice versa.
7. **[FEATURE, designer's decision] Calibrated placement per region instead of random builds.** Replace
   `tools/populate.gd`'s library monsters with the real families (and their variants): each region in
   `worlds/story/world.json` gets a `"spawns"` spec — which families/variants may appear and a **danger budget** (sum of
   `enemy_score`, see `AttackCatalog.enemy_score`, body area from the entity rect). A tool fills each region's
   fighting rooms until the budget, choosing spots that fit the family: walkers on flat floor (existing spot rules in
   `tools/populate.gd`), Dropwing under a ceiling with open space below, Duskflit / Fuzzbob / Murkspore in open air,
   Thornmite on any surface; never near doorways, respawns, spikes, liquids or other enemies; peaceful regions and
   boss arenas get none. Placed enemies carry `"placed_by": "budget"` and are replaced on each run; hand-placed ones
   stay. Deterministic with `--seed`, `--dry` prints the per-region plan (families, count, budget used). Remove the 45
   library monsters (`"populated": true`) in the same commit; keep `enemy_monster` working for hand placement. Show the
   region budget / used in the World Editor or the progression page (pick one, document it).
8. **[MAJOR, performance]** Per frame, every active enemy calls `ordered_attacks` (filter + sort whose comparator does
   `assignments.find()`, O(n²)) and `attack(id)` (linear scan) several times (`atk`, `atk_range`, `atk_ready`, the
   ActionMonster eligibility lambda). Cache rows by ID and ordered bindings by (enemy, phase); invalidate on `reload()`
   and on any editor edit (a version counter). Measure before/after with `tests/bench.tscn` or a 50-enemy room.
9. **[MINOR] Editor reloads the whole world JSON on clicks** (`_code_enemy_info`, `_score_text`, `_sample_monster` call
   `Adventure.load_world` each time). Load once per editor session (refresh on Reload CSV).
10. **[MINOR] Dead code after removing "Library monster" from the Enemies tab:** `_sample_monster`, the build table and
    the library branch of `_score_text`; unused fields in `monster_library.gd`. Remove what task 7 no longer needs.
11. **[MINOR] Precision.** Saving rounds every value to 2 decimals (`format_cell`), so converted values drift
    (8.125 tiles/s → 8.13). Use up to 3 decimals, trimming trailing zeros.
12. **[MINOR]** `SpritePreview` redraws every frame even when not visible; stop processing when hidden.
13. **[QUESTION for the designer, don't change]** Scores aren't comparable across types (area dominates: scream 165
    vs. shots 0.1-2) and some are unavailable (giant charge, `ape_log`: the "≥ 2 s" rule). Write the options in
    `docs/ATTACK_SCORING_PLAN.md`; task 7's budget must handle "unavailable" (count it at the attack's median).

## Possible additions (only if time allows, each its own commit)

- Per-variant overrides in the Enemies tab (e.g. Giant: speed × 0.7) instead of fixed `VARIANTS` multipliers.
- Eligibility rules as data (same height ±N tiles, needs line of sight, only when cornered) instead of code lambdas.
- A "test fight" button: opens a small room with the selected enemy and the player (reuse the playtest path).

## Verification

- `godot --headless --path . res://tests/attack_catalog.tscn` → `ATTACK CATALOG OK`; `res://tests/test.tscn` →
  `0 failure(s)`; new tests for findings 1, 2, 3, 5, 6, 7 (placement: budget respected per region, no spot violations,
  deterministic with a seed, peaceful regions empty).
- `godot --headless --path . res://tools/room_safety.tscn -- --world res://worlds/story/world.json` → `FINDING GROUPS 0`.
- `python3 tools/progression.py` still runs.
- `sh tools/verify.sh` → `0 failing`.


---

<a id="reports-claude-fix-prompt"></a>

## Source: reports/CLAUDE_FIX_PROMPT.md

Original source: `reports/CLAUDE_FIX_PROMPT.md`. [Evidence directory](../).

You are working in /home/viridjan/Projects/videogame on Bethe Knight, a Godot 4 pixel platformer with a level/world editor. Fix the concrete issues below, then evaluate the listed optimization candidates.

Read AGENTS.md first. This review was run on 2026-10-25 with Godot 4.7.2, at HEAD 2f01697 plus existing uncommitted work. Re-read the current code because it may have changed. Preserve all unrelated edits; do not reset, stash, regenerate the story, or overwrite other work. Do not commit or push unless the user asks.

Preserve 60 Hz physics, the pixel movement model, movement tuning, authored story layout, the Ape's side-view design, and Nori's brown/gray hair behavior. Do not redesign gameplay to make tests pass.

For each bug, reproduce it, add a meaningful regression test, implement the smallest fix, and rerun the relevant suite. Report what you fixed, what you could not reproduce, and remaining warnings. Do not report success from exit code alone: Godot can return zero after parse/runtime errors.

Evidence is in reports/code-review-2026-10-25/. The reproduction script uses disposable levels and must be run with isolated user data:
    XDG_DATA_HOME=/tmp/summit-claude-review godot --headless --path . --script reports/code-review-2026-10-25/reproduce.gd

CONFIRMED BUGS, IN PRIORITY ORDER

1. Chase path cache reuses an invalid route after the level/configuration changes.
   Location: scripts/entities.gd, ApeChase.update(), around line 1925, and static _plans.
   Key is only w.star_key("") plus Ape x/y. It omits world identity, level geometry, endpoint, effective movement tuning, and relevant simulation settings. Outside adventure, star_key("") is empty for all levels.
   Reproduced in one process with two otherwise identical standalone levels:
     first chase end=200: 90 frames, final feet=(212,224)
     second chase end=350: same 90 frames, same final feet=(212,224)
   The second chase should continue to its own endpoint, but instead stops on the first cached route. Editing a level and playtesting again or switching worlds with matching room names can reuse stale paths.
   Fix cache identity/invalidation for the actual inputs used by the planner. Bound/clear the cache at an appropriate lifecycle point. Avoid hashing full terrain every physics frame.
   Tests: different endpoints, changed terrain at same spawn, distinct levels/worlds, tuning changes, and valid reuse of identical inputs.

2. Benchmark scene fails to compile.
   Location: tests/bench.gd:33, BenchWorld._build().
   Override declares _build() but scripts/world.gd now declares _build(keep_player := false).
   Repro:
     XDG_DATA_HOME=/tmp/summit-claude-bench BENCH_RUNS=1 BENCH_TICKS=5 BENCH_ONLY=normal godot --headless --path . res://tests/bench.tscn --quit-after 120
   Error: "The function signature doesn't match the parent. Parent signature is _build(bool = <default>) -> void".
   The audited process returned exit 0 despite the parse error.
   Match the signature, forward the argument correctly, preserve benchmark Bot behavior, and prove the benchmark actually emits timing results. A quit-after exit is not proof it ran.

3. Missing tuning directory logs errors on a fresh installation.
   Location: scripts/tuning.gd:199, list_presets(); scripts/debug_panel.gd:_fill_presets().
   Opening the debug panel before any tuning preset has been saved calls DirAccess.get_files_at("user://tuning/") on a nonexistent directory.
   Fresh-user smoke run logged this error twice:
     Couldn't open directory at path "user://tuning/".
   Guard the read or create the directory at the appropriate time. Return an empty list cleanly when no presets exist. Do not hide genuine permission/read failures indiscriminately.
   Test fresh user data with no tuning directory, then save/list/delete a disposable preset.

4. Save restoration accepts malformed coordinates and impossible numeric state.
   Location: scripts/adventure.gd:173, restore_run(); scripts/world.gd:_build() consumes run.spawn.
   It validates only spawn array length and top-level exact types, not element types, finite values, or numeric bounds.
   Reproduced input:
     {"room":"room", "spawn":["bad",{}], "blocks":-20, "energy":99999.0}
   Output retains all those values. _build() later constructs Vector2(spawn[0],spawn[1]); malformed coordinates cannot be used safely, and negative blocks produce impossible maximum energy.
   Normalize invalid fields using existing game rules: finite numeric coordinates, valid block count, energy within valid limits, valid counters and collection entries. Decide and test backward-compatible int/float handling instead of blindly rejecting equivalent numeric types. Preserve valid saves.
   Test malformed spawn values, NaN/infinite numbers where supported, negative/oversized energy and blocks, valid legacy saves, and actually constructing a World from the restored run.

5. Ape run-frame cache is inconsistent with its image builder.
   Location: scripts/ape_art.gd:12-15 and build()'s run swing calculation.
   texture() caches by frame % 4 but passes the original unbounded frame into build().
   build() also uses frame % 3 for arm swing, so build("run",0) != build("run",4), even though texture() maps both to the same key.
   Current renderer passes int(clock * 10), so which image gets stored depends on when the Ape first becomes visible. A prior boss/chase can seed images for a later one.
   Define a coherent animation period and canonicalize before both cache lookup and building, or author a consistent four-frame sequence. Normalize equivalent static poses too, where useful.
   Test cold caches first accessed at different clocks and verify equal canonical frames yield equal images. Inspect the loop visually; do not merely change a hash assertion.

TEST-HARNESS RELIABILITY

6. A passing label/exit code currently masks engine errors.
   tests/smoke.gd printed SMOKE OK and exited zero while logging the missing tuning directory errors.
   tests/bench.tscn exited zero after its parse failure.
   Add a practical verification entry point or equivalent mechanism that fails on parse errors, SCRIPT ERROR, failed script loads, and unexpected runtime ERROR lines, while also requiring each runner's success output or actual benchmark result.
   Audit teardown warnings separately: physics logged 41 ObjectDB leaks; smoke logged CanvasItem, texture, text and font RID leaks plus 128 ObjectDB leaks. Counts vary, so do not assert exact counts or assume these are all gameplay leaks. Attribute ownership using --verbose and distinguish test teardown, app-owned resources, and engine/addon behavior. Do not broadly suppress all errors.
   Python unittest discovery passed 12 tests but tools/check_entrances.py emits ResourceWarning for unclosed files; close files with context managers.
   The SFX pool test calls play("jump") 50 times in one synchronous loop, but the 35 ms per-key cooldown rejects nearly all calls. Add a meaningful saturation test with distinct admitted effects / controlled timing and assert actual active voice behavior. Keep tests about behavior rather than source strings.

MEASURED OPTIMIZATION CANDIDATE

7. First sound blocks on full synchronous synthesis.
   Location: scripts/game.gd:get_sfx(), Game.button(); scripts/sfx.gd:_ready().
   get_sfx() constructs the service lazily and _ready() generates all effects, the cave roar and both Ape screams on the main thread before the requested effect starts.
   Measured cold initialization: 187.406 ms in the disposable probe (another run ~190 ms). This can stall the first menu click or action, even when only a UI click is needed.
   Measure again on the current build. Move cost to an explicit loading phase, generate/cache offline using the existing authoring workflow, or stage synthesis without introducing audio/threading hazards. Preserve sound design, independent volume controls, bounded playback, and the left-biased cave roar. Do not silently lower sample quality.
   Report before/after cold and warm timings. Avoid a fragile machine-specific timing assertion in the unit suite.

FURTHER OPTIMIZATION / LOGIC CHECKS — INVESTIGATE, NOT YET PROVEN USER-VISIBLE BUGS

- ApeChase.plan() runs synchronously inside update(): up to 6*7*5 parameter trials, each up to 3600 simulated player frames. Profile an unplannable or difficult edited level, not just the successful story route. If path is empty it only warns, enters chase, and remains stationary. Provide a bounded, explicit fallback without changing authored chase behavior.
- scripts/ape_art.gd rasterizes each polygon by testing every pixel. First-use pose generation happens from Ape.draw(), which also calls load() each draw. Godot may cache that script resource; do not claim disk I/O every frame. Measure cold-pose stalls, canonicalize duplicate poses, then consider prewarming/baking or scanning polygon bounds.
- scripts/world.gd:_near_solid() returns the first matching neighbouring room's tile, whereas Adventure.room_at() prefers open cells in overlapping irregular room bounds. Construct a minimal overlap case and check whether neighbour order incorrectly blocks a valid transition before changing collision rules.
- The chase planner simulates the smaller player footprint while the Ape renders at 32px with a 24px contact box. Determine whether any current route visibly clips the Ape through ceilings/obstacles; keep intentional chase design and physical collision requirements separate. Do not assume route validity for a small runner proves clearance for the Ape.

VALIDATION BASELINE AND REQUIRED FINAL CHECKS

At audit time:
- physics: 0 failure(s), with shutdown ObjectDB warnings.
- smoke: SMOKE OK, but missing-directory errors and shutdown resource leaks.
- SFX, roar, music, environment music, Ape art and character-style scripts: success output; several report teardown warnings.
- Python: 12 tests passed, with unclosed-file warnings.
- benchmark: parse failure, despite exit 0.

Use isolated user data for all checks to avoid touching personal settings, saves or levels. Run commands sequentially or give concurrent processes different XDG_DATA_HOME directories:
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . res://tests/test.tscn
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . res://tests/smoke.tscn
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . --script tests/sfx.gd
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . --script tests/roar.gd
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . --script tests/music.gd
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . --script tests/environment_music.gd
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . --script tests/ape_art.gd
    XDG_DATA_HOME=/tmp/summit-claude-check godot --headless --path . --script tests/character_style.gd
    python3 -m unittest discover -s tests -p 'test_*.py'
    XDG_DATA_HOME=/tmp/summit-claude-check BENCH_RUNS=1 BENCH_TICKS=120 BENCH_ONLY=normal godot --headless --path . res://tests/bench.tscn
    git diff --check

Also run your new regressions and the disposable reproduction script. After fixes, the probe should show independent chase endpoints and normalized save values; update/remove diagnostic assumptions if the public API changes, without weakening regression coverage. Inspect the Ape animation and smoke scenes on a working display if available. Report limitations explicitly.

Deliver a concise change summary, test results including unexpected engine logs, measured performance changes, and unresolved findings. Do not expand this into a general rewrite.
