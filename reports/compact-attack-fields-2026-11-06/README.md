# Compact attack mechanics and one Range field

Mechanics cards now use natural widths with wrapping rather than equal-width grid columns. Cards no longer stretch to their neighbor's height; odd field counts no longer insert expanding filler controls. Reduced padding and shorter Horizontal/Vertical labels keep tooltips and inputs intact.

At a 900 px fixture width (852 px available), the leap's Timing / Damage & speed / Trajectory section drops from 194 px to 90 px high. At narrow widths cards wrap without losing fields. `before-900.png`, `after-900.png`, and `after-600.png` document those layouts. `editor.png` shows the actual Monster Editor.

Enemy bindings now expose **Range** and **Skip %**. Range is maximum center-to-center distance in tiles; 0 means any range. Editing Range also clears any imported minimum so it cannot silently constrain the displayed rule. Shipped minimums were already all zero. Existing CSV columns and the runtime's exclusive maximum convention remain compatible.

Verification: `tests/attack_catalog.tscn` → ATTACK CATALOG OK; `tests/ape_followups.tscn` → 0 failures; `tests/smoke.tscn` → SMOKE OK; GDScript lint and `git diff --check` pass. The catalogue runner still emits its existing shutdown resource-leak warnings. The new range assertions first failed with a legacy minimum of 100, then passed after the single-field normalization.

Render fixtures: `CAPTURE_PHASE=after godot --path . --rendering-method gl_compatibility res://reports/compact-attack-fields-2026-11-06/capture.tscn`; `page.tscn` captures the real page. No catalogue data is saved by these fixtures.
