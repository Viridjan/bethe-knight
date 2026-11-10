# Checkpoint activation areas — 2026-11-08

[Tool, data and runtime guide](../../docs/RESPAWN_POINTS.md) · [Editor capture](editor.png)

The Respawn tool now drags an activation rectangle, including ceiling-height regions. Its previewed marker resolves to the lowest safe permanent ground inside; equal-height candidates prefer the centre. Entering the rectangle in midair can activate it. Overlapping regions select one specific checkpoint, and layer entrances retain the previous checkpoint unless they enter an authored region.

The map migration converted 75 checkpoints across 41 files, including variants and retained interiors. Only checkpoint definitions change; terrain and other entities are preserved. A repeated migration reports zero changes. The loader, save workflow, copy/resize/undo, automatic placement, pruning, accessibility and progression tools use the grounded anchor rather than the area's top-left. Authored rectangles are never automatically pruned.

The first runtime regression failed because area resolution was absent; the first migration checks failed before the migration module existed. Final targeted checks cover lowest-floor selection, hazard avoidance, airborne activation, overlap priority, placement/invalid selection, resize/undo, and no implicit layer checkpoint. Existing legacy point behavior, room resizing, editor playtest, map traversal and layered-house/lighthouse checks remain covered.

The editor capture was rendered and inspected: the tall central Lake Cave region reaches the ceiling, with its player marker on the bottom floor; nearby lower-ceiling regions keep their own grounded markers. Capture scene: `res://reports/checkpoint-areas-2026-11-08/capture.tscn`.

Full verifier: **0 failing**, including Godot, Python, GDScript lint, Pyflakes and diff checks. See [verification.txt](verification.txt) and [targeted regressions](regressions.txt).
