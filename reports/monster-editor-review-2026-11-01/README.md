# Monster Editor review — 2026-11-01

Reviewed commit `2f64b3a`, covering the editor, CSV model, menu exit paths, and the
runtime consumers in `entities.gd`. Production code and source CSVs were not changed.
The existing catalogue suite passes, but the targeted probes reproduce defects it
currently misses. See [observations.json](observations.json) for the raw evidence
and [probes.gd](probes.gd) for the disposable-data reproducer.

## Highest-priority findings

### 1. P1 — Renaming can redirect unrelated enemies to a planned attack

Location: `scripts/attack_catalog_editor.gd:344–350`.

Every keystroke in an ID field immediately rewrites all matching binding and
follow-up references. Create a planned attack, change its ID to `shoot`, then
continue to `shoot_variant`. The intermediate duplicate ID is invalid, but its
reference rewrites are retained. Both original bindings to the implemented
`shoot` are now redirected to the new planned attack. The final catalogue
validates, so Save can persist the corruption. A normal user typing a name with
an existing ID as its prefix can encounter this.

Fix: edit IDs as local text, then commit a unique validated rename atomically on
confirmation/focus commit. Use immutable internal IDs for references if display
names need frequent editing. Test intermediate collisions and cancelled renames.

### 2. P1 — Escape silently discards the draft

Location: `scripts/menu.gd:124–126`, compared with the guarded Back action at
`menu.gd:91–99`.

Edit a field, then deliver `ui_cancel` while no text control consumes it. The menu
immediately calls `_main()`, detaches the editor, and creates no confirmation.
Back does ask. Probe: dirty editor removed, confirmation count **0**.

Fix: route Back, Escape, and page-close requests through one guarded exit method.
Offer Save / Discard / Cancel and test the actual unhandled-input path.

### 3. P1 — Runtime-used component IDs can be renamed or deleted

Locations: `attack_catalog_editor.gd:285–289`, `:319–320`, `:868–879`;
`attack_catalog.gd:7`, `:127–129`; runtime consumers in
`entities.gd:2785`, `:2894`, and `:2944`.

Protection checks only `EXECUTABLE`, the ordinary attack-selector registry.
`ape_slam`, `ape_log`, and `ape_split` are also used by gameplay but are missing
from that registry. The editor allows renaming/deleting them, and deleting
`ape_slam` still passes validation. Gameplay retains hard-coded lookups and
fallbacks, disconnecting the saved data from the effects that still occur.

Fix: maintain a complete required-runtime-ID registry, separate from which attacks
an enemy can select. Check all runtime references before rename/delete and on load.

### 4. P1 — Some enemy range/removal edits do not control gameplay

Locations: `entities.gd:745–758`, `:1095–1101`, and `:1227–1231`;
UI removal at `attack_catalog_editor.gd:861–866`.

Fixed enemy families use `atk_range()` and `atk_ready()` rather than the common
selector. These helpers do not check minimum range; a missing binding falls back
to the previous code-defined range and still permits an attack.

Probe: an Ossling at **5.50 units** attacks with its minimum set to **10**. Removing
its binding entirely also leaves it entering wind-up. Thus the editor's Remove
and minimum-range controls can misrepresent the resulting fight.

Fix: make bindings authoritative and use one eligibility/selection contract for
all migrated families. Test below-minimum, exact boundaries, missing binding,
skip chance, and variants in the actual enemy update functions.

### 5. P2 — Follow-up controls promise behavior the runtime does not execute

Locations: `attack_catalog_editor.gd:886–904`; `entities.gd:2797–2802`;
ActionMonster execution at `entities.gd:1353–1390`.

The editor permits arbitrary follow-up IDs and scores them. The boss retreat
reads count/gap but unconditionally transitions to `throw`: setting its follow-up
to `ape_scream` still enters **throw** in the probe. Clearing it also leaves the
code's default volley behavior available. ActionMonster has no general follow-up
executor at all.

Fix: implement a shared follow-up scheduler, or limit the picker to supported
runtime transitions and clearly mark score-only plans. Test changing and removing
the follow-up ID, not just whether the picker stores a value.

## Scoring and validation findings

### 6. P2 — Scores can look complete when part of the attack is unscored

Location: `attack_catalog.gd:159–166`.

An invalid/unscored follow-up is silently omitted and the parent returns
`valid: true`. With a retreat followed by the unscored log, the parent reports a
complete numeric score of **17.442**. It should report an incomplete result and
identify the missing component, optionally retaining a known subtotal.

Related: validation accepts multi-node follow-up cycles. Scoring avoids recursion
by silently truncating after one level, so accepted data and computed semantics
differ. Either reject cycles and evaluate supported chains consistently, or
explicitly constrain the data model to a single follow-up level.

### 7. P2 — Persisted scores can disagree with their saved inputs

Location: `attack_catalog.gd:289–305` and recursive lookup at `:161–163`.

The saver calculates a rounded parent row against follow-ups from the unrounded
in-memory catalogue. With the throw's weight edited to `1.0049`, the retreat's
persisted score is **33.06**, but reloading and recomputing from the saved inputs
gives **32.98**. Compact enemy fields do not normalize on focus exit, making this
reachable through the UI.

Fix: normalize the complete catalogue once, then calculate every score and
reference lookup against that same snapshot before writing either file.

### 8. P2 — Enemy totals remain stale while individual attack scores change

Location: `attack_catalog_editor.gd:728–745`, versus `_score_text()` at `:967`.

Compact-field edits update one row score and validation feedback but not the
selected enemy's summary. Probe: after increasing charge wind-up, the summary
continues to show **3.16**, while recomputation gives **2.24**.

Fix: recalculate dependent totals on draft changes, including every attack that
shares the edited definition or follows it. Keep reference scores distinct from
actual enemy-size/variant scores.

### 9. P2 — Data-driven loop counts have no practical upper bound

Locations: `attack_catalog.gd:95–97`, `:153–155`, and `:199–208`.

`multishot = 100000000` validates. Score calculation and projectile creation then
iterate/allocate per shot. The UI recalculates on text changes, so an accidental
large number can lock the editor or exhaust memory before saving.

Fix: bound shot counts and follow-up counts to deliberate authoring limits;
reject oversized CSV values before evaluation. Consider closed-form score counts
for large uniform patterns. The safe probe measured 10,000 shots at about **1 ms**;
the 100-million-shot calculation was deliberately not executed.

## UI and workflow findings

### 10. P2 — Long dropdown entries force the page wider than requested

Locations: `attack_catalog_editor.gd:633–646`, and the form scroll container at
`:106–110`.

A requested **1,000 px** editor expands to a **1,193 px** minimum. The Add Attack
OptionButton alone has a **777 px** minimum; its full row is **953 px**. Disabling
horizontal scrolling does not make that minimum responsive. Wider names/planned
labels worsen the problem.

Fix: constrain the selected dropdown's width, fit the popup independently, and
use clipping/hover text for long names. Add viewport tests for the full form,
including the add row and expanded follow-up controls.

### 11. P3 — Switching enemies retains the previous scroll offset

Location: `attack_catalog_editor.gd:471–481`.

The probe changes from Ape normal to enraged and retains **180 px** of scrolling.
The new enemy title/preview can start out of sight.

Fix: reset to the top on a new selection, or remember offsets separately per
enemy. Preserve the offset only when rebuilding the same enemy after an edit.

### 12. P3 — Help text describes the wrong priority algorithm

Locations: `attack_catalog_editor.gd:1022` and `:1029`, versus
`attack_catalog.gd:190–193`.

Help still says maximum range determines order and priority only breaks equal
ranges. Runtime and the arrows now use priority first regardless of range.
Update the help and show a short actual decision explanation for each loadout.

Additional workflow improvements:

- Mark shared definitions visibly, including how many enemy/build users will be
  affected; important information currently lives mostly in tooltips.
- Add undo/revert for field edits and binding removal. Only whole-draft reload is
  available, which is costly after several unrelated edits.
- Show a persistent distinction between implemented attacks and planned entries;
  creating a CSV row does not implement its gameplay. Exclude unsupported choices
  by default or make planning mode explicit.
- Group the **28 read-only entries out of 36** separately from editable families.
- The story contains **45 `enemy_monster` instances and 9 Mosstrots**. The generic
  `enemy_monster` recipe/build view is excluded from navigation even though score
  code for it exists. This is a scope/usability gap, not classified as a regression
  because current tests intentionally exclude it. Offer an explicit placed-build
  view so users know whether they are editing a fixed family or a generated build.
- Provide an actual attack sandbox/trajectory preview. Current sprites/frame
  references do not exercise the edited timing or projectile path.
- Make validation errors actionable: focus/open the relevant field and section.
  Error colors are currently assigned during form construction, not updated for
  each live edit.

## Performance observations

Warm headless/debug runtime instrumentation, eight selections per entry, same
machine and scene. These are synchronous method timings, not release FPS, mobile
measurements, or GPU profiling. Raw process-monitor values in the JSON are not
interpreted as representative frame times.

| Selection | Median rebuild | Form nodes | Validation calls |
|---|---:|---:|---:|
| Ape | 57.67 ms | 210 | 5 |
| Hornback | 20.52 ms | 66 | 2 |
| Guardian | 6.15 ms | 5 | 0 |

For the Ape, frame-texture lookup averages **0.09 ms**, score-text computation
**0.37 ms**, tooltip wrapping **0.78 ms**, and validation **1.38 ms** per selection.
Some timings overlap; do not sum them as independent costs. Most elapsed time
remains in the rest of the form rebuild. The current art texture cache is already
working; replacing it is not the first optimization to pursue.

Prioritized optimization candidates:

1. Build collapsed attack settings and animation strips only when opened. Their
   controls and textures are currently created even while hidden.
2. Reuse the preview and field widgets; update row data rather than rebuilding the
   entire form after moving an attack or selecting a follow-up.
3. Cache the world snapshot/placement index for read-only enemy information instead
   of reparsing room files on each selection; invalidate on explicit refresh.
4. Validate once per edit transaction and batch dependent score updates. Debounce
   expensive work during typing; preserve immediate syntax feedback.
5. After the above, consider ID/assignment indexes. Their small current data sizes
   make them a lower priority than rebuilding the UI.

No speedup is claimed: release/graphical profiling and before/after measurements
are required before choosing a performance patch.

## Code organization

`attack_catalog_editor.gd` is now **1,031 lines**. It combines navigation, draft
state, field widgets, sprite/frame presentation, score inspection, and file-save
orchestration. This already permits inconsistent paths: Back vs Escape, main
fields vs compact fields, and fixed-family runtime selection vs ActionMonster.

Prefer an editor controller plus reusable attack form, loadout card, and field
components. Keep a single draft/change notification path, one guarded exit action,
and a runtime adapter that explicitly declares supported parameters/IDs. Avoid
mixing numeric row indexes from different views as the selection model.

Saving stages both files and attempts rollback, but the pair of renames is not a
crash-atomic transaction. A later hardening pass should preserve a recoverable
snapshot/version and validate reload success before declaring the draft saved.

## Suggested patch order

1. Guard all exits; make ID rename atomic; protect every runtime component ID.
2. Make family bindings authoritative and constrain/implement follow-ups.
3. Fix score completeness, canonical rounding, stale totals, and loop bounds.
4. Fix the dropdown minimum width, selection scroll behavior, and priority help.
5. Refactor reusable UI components and measure lazy construction/control reuse.

## Reproduce safely

```sh
XDG_DATA_HOME=/tmp/summit-monster-review-baseline godot --headless --path . res://tests/attack_catalog.tscn
XDG_DATA_HOME=/tmp/summit-monster-review-probes godot --headless --path . res://reports/monster-editor-review-2026-11-01/probes.tscn
```

The first command is the existing product regression suite. The second is a review
probe that records current defects; its successful exit means the observations
were collected, not that the editor is bug-free. It writes test CSVs under the
throwaway `user://` directory and restores in-memory shared catalogue edits. It
never saves the project's attack/range CSVs. Its timing samples are diagnostic,
not stable performance-test thresholds.
