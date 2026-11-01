# Review: Monster Editor (2026-11-01)

Reviewed `scripts/attack_catalog_editor.gd` (1031 lines), `scripts/attack_catalog.gd` (load, validate, score,
select, save), the editor's exits in `scripts/menu.gd`, and the runtime consumers in `scripts/entities.gd`
(ActionMonster, families, Ape), at commit `2f64b3a`. Method: read end to end; re-ran Codex's probe scene
(`reports/monster-editor-review-2026-11-01/probes.tscn`, all 12 of its findings reproduce today); windowed screenshots
of both tabs at 1280x720; `tests/attack_catalog.tscn` passes (it misses everything below). Skills used: code-review,
systematic-debugging, verification-before-completion, godot-best-practices, ponytail-review, godot-ui-control,
save-systems, performance-optimization. **Headline: 3 blocking, 8 major, 6 minor, 2 questions.** Codex's
`reports/monster-editor-review-2026-11-01/README.md` has the raw evidence for the findings marked (C).

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
