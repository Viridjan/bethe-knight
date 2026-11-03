# Codex prompt: Ape composition follow-up fixes

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

Commit each task when its checks pass (Codex files included).

Verification: XDG_DATA_HOME=$(mktemp -d) godot --headless --path . res://tests/ape_composition.tscn → 0 failure(s);
res://tests/attack_catalog.tscn → ATTACK CATALOG OK; sh tools/verify.sh → 0 failing; a screenshot of both Ape pages.
One dated line in gdd.txt per task.
