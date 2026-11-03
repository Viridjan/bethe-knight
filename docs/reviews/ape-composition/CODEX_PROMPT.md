# Codex prompt: verified Ape composition follow-up fixes

Checked against `953b8ca` on 2026-11-03. Original tasks 1, 2, 3, and 5 are still
reproducible. Original task 4's general cleanup gap is also real, but its stated
profile scenario had the wrong order: the profile is replaced last. A verified
first-save failure leaves a newly created attacks CSV instead; the corrected
task below uses that reproduction. Original task 6
should not be treated as an outstanding numerical bug: the UI already labels its
total **Selected attacks**, with consequence totals explicitly pending.

The five tasks below replace the earlier six. Additional verified defects and
their evidence are in [the recursive review](../ape-recursive/REVIEW.md).

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
1. One source of truth for the effect chain: derive the editor's triggered-effects list from the profile
   (landing_effects, log_impact_effect, phase2_throw_effect; split only on the enraged page) and drop the triggered
   rows from enemy_attacks.csv, or make runtime read them and drop the profile fields. Test: the list shown for each
   Ape page equals what gameplay does.
2. tests/test_runner.gd lines ~2082-2086: isolate configurable HP in fixtures or derive expectations from the
   fixture's max_hp instead of E.Ape.HP. Check hardcoded phase assumptions in tests/ape_composition.gd too.
   Test: valid max_hp 5 still verifies one lost HP and the intended spike removal. Do not weaken the assertion.
3. Effect tooltips built from the profile (what triggers each effect), not a hard-coded dictionary.
4. Split children: use bounded free-position resolution or emit a visible "split_blocked"/cancelled event when
   placement is impossible. Test: a parent at (25,100), size (19,6), speed (0,-1), gravity 200 splits against the
   real World boundary; a child must not silently vanish. Do not force children through solid terrain.
5. Correct first-save rollback: record which destinations existed before replacement. Restore old files and
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
