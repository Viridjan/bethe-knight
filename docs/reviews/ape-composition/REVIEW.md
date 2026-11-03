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
