# Recursive Ape audit evidence

See [the review](../../docs/reviews/ape-recursive/REVIEW.md) and
[fix prompt](../../docs/reviews/ape-recursive/CODEX_PROMPT.md). The original
[Ape follow-up prompt](../../docs/reviews/ape-composition/CODEX_PROMPT.md) was
cross-checked and corrected during this audit.

`*.json` files contain observed behavior, not assertions that the behavior is
correct. `zero_wave.log` and `invalid_health_ui.log` intentionally contain the
reproduced engine errors; `configured_health_tests.log` contains the test failure
under valid modified HP. `capture.log` includes the intentional invalid-draft
failure and its shutdown resource leaks. Keep those separate from the ordinary
passing checks in `verification.txt`.

Reproduce a probe from the repository root with disposable user data:

```sh
SUMMIT_REVIEW_CASE=retreat_gravity XDG_DATA_HOME=/tmp/summit-audit-replay godot --headless --path . res://reports/ape-recursive-review-2026-11-03/probes.tscn
```

Other cases are the JSON filenames without their suffix. Probe definitions are
in `probes.gd`; they mutate catalogue copies or process-local state, never the
authored room/catalogue files. Save-failure cases write only under `user://`.
Re-running probes refreshes their evidence JSON files; preserve the historical
observations when converting these into permanent regression tests.

`capture.tscn` opens the actual Monster Editor, captures the normal/enraged pages,
and reproduces blank-Health navigation using its real private draft. It never
invokes Save. The final screenshot shows the missing health input, not a mock UI.

Performance figures are local headless/debug observations. `ui_validation_cost`
warms the page and permits a process frame between each sample, recording
catalogue-validation calls/time separately. `projectile_cost` measures ordinary
updates; `outside_sweep_cost` deliberately measures an extreme accepted setting
and an already-expired/outside object. They do not establish mobile GPU or FPS
performance. `ui_cost` is an exploratory repeated-build sample; use the framed,
warmed measurement for the review's UI figures.
