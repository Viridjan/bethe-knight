# Non-map story systems — 2026-11-07

Implemented behavior and authoring: [NONMAP_SYSTEMS.md](../../docs/NONMAP_SYSTEMS.md).

## Scope

Quest/dialogue/inventory transactions; Items/Abilities pages; boat survival/shipwreck; thick water; giant feet; volcanic heat; double jump/heat resistance; attached stamina/stress HUD and capacity upgrades. Map work and the older undecided/deferred proposals are excluded.

All 61 files under `worlds/` have identical SHA-256 hashes before/after this delivery. Test and preview rooms are generated in memory.

## Visual checks

Run `godot --path . res://reports/nonmap-systems-2026-11-07/capture.tscn` to reproduce:

- [HUD and giant](hud-and-giant.png)
- [Items](items.png)
- [Dialogue](dialogue.png)
- [Boat crossing](crossing.png)

The capture uses disposable progress and does not save authored rooms. Theme aliases reuse existing art; boat/tentacles/giant and pickup drawings use native canvas primitives.

## Validation

The three new deterministic runners are included in `tools/verify.sh`. Integration coverage includes actual entity interaction, duplicate prevention, NPC key consumption, giant warnings/stomps, real swimming/heat/double jump, boat destination handoff, editor settings/undo and copied pickup IDs. Existing gameplay, smoke and stress runners also pass. Final complete verifier: **0 failing**, including Python tests, GDScript lint, Pyflakes and diff checks. See [verification.txt](verification.txt). The expanded entity/editor integration runner was also rerun separately with zero failures.
