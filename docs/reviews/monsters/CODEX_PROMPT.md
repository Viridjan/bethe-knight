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
