# Baseline — 2026-11-10

Point 1 of [the sequential plan](../../docs/plans/REMAINING_WORK.md).

## Starting state

Project: `/home/viridjan/Projects/bethe-knight`. Engine: Godot 4.7.2 stable, Arch Linux build `ed1daf0bf`.

The tracked working tree and index were clean at the start of verification. The only untracked entry was this newly created report directory. This supersedes the earlier session's dirty-tree observation; no existing changes were staged, discarded or committed during this baseline.

- [Git status before verification](git-status-before.txt)
- [Tracked diff summary](diff-stat-before.txt)
- [Staged diff summary](staged-stat-before.txt)
- [Verifier output](verification.txt) and [exit status](verification-exit.txt)

## Check scope

`sh tools/verify.sh` runs 41 Godot invocations: gameplay, punch, smoke, identity, stamina/stress, non-map progression/entities, checkpoint areas, retained layers, crossing, enemy foundations, patrols/traps, traversal, resize/selection, web menu, attack catalogue/Ape suites, audio/art/discoveries, progression/editor workflows, island routes, character style and a short benchmark.

It also discovers 17 Python test modules, runs GDScript lint and Pyflakes if `uvx` is available, and checks tracked diff whitespace. Godot runners use disposable user data. The script checks success markers and selected engine-error lines, reporting shutdown leak warnings separately.

## Coverage limits and follow-up

- Passing existing tests does not implement or certify the proposed world graph, all quest placements, every layered route or a complete fresh-run chapter playthrough.
- No interactive visual/play inspection was performed for this read-only baseline. The benchmark is one short normal run, not a performance study.
- The verifier prints summaries, suppresses successful runner output and Python/linter details, and does not explicitly check each Godot process exit status. This report preserves its complete emitted output, not full internal logs. Future failures need a direct targeted rerun to retain diagnostic output.
- Pyflakes uses tracked Python files; untracked Python additions require explicit coverage until tracked. No such additions existed at baseline start.
- Integer migration remains pending in current code: `Adventure.regen_stamina` accepts fractional elapsed time, resource values/rates use floats and `World.update_stamina` accounts for resources per frame.

## Final result

Point 1 is complete. No reproducible code/test failure blocks point 2.

| Check | Result |
| --- | --- |
| 41 Godot invocations | Passed |
| Python unittest discovery | Passed |
| GDScript lint | Passed on targeted retry with cache access |
| Pyflakes | Passed on targeted retry with cache access |
| Tracked diff whitespace | Passed |

The original aggregate run exited **2**, reporting only the two lint invocations as failures. Direct reruns reproduced both errors: `uvx` could not create a temporary lock file under the read-only `/home/viridjan/.cache/uv` sandbox path. These were environment failures before source analysis. After approved execution with cache access, both commands exited **0** without source changes. The aggregate command was not rerun; its original output and exit status are retained honestly.

Diagnostics: [initial GDScript lint](gdlint.txt), [initial Pyflakes](pyflakes.txt), [successful GDScript lint retry](gdlint-retry.txt), [successful Pyflakes retry](pyflakes-retry.txt), [GDScript lint exit](gdlint-exit.txt), [Pyflakes exit](pyflakes-exit.txt).

Non-blocking observations: `partial_foundations.tscn` and `attack_catalog.tscn` each reported five shutdown leak warnings. Their success/error checks passed. These warnings were not individually diagnosed in this baseline and are not claimed fixed.

Next: point 2, the approved whole-number resource/score migration. No gameplay, map, verifier or test source was changed for point 1.
