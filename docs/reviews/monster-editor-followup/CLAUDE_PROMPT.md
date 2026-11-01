You are fixing the Monster Editor in Summit, a Godot 4 platformer. Work inside
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
