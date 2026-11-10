# Retained room layers and town/lighthouse conversion

Delivered 2026-11-08. [Behavior, data format and editor controls](../../docs/ROOM_LAYERS.md).

- All planes preload with independent terrain, entities and triggers. Inactive planes remain loaded and frozen beneath 90% black; unvisited planes remain concealed. One player transfers between planes; old transient sounds stop and active environment music restarts.
- The room editor can add/select planes, author passages, save/reload every plane, playtest the selected one, and resize/undo all planes together.
- Villager and Quest houses are layers of Cove Town. Lighthouse stairs are a narrow Shore interior layer, with five mages distributed vertically. The exterior roof/flame/mirror are now in Shore. Detached rooms were embedded and removed from the world manifest/regions.
- Shore expands upward while preserving the original global ground/seam positions. Legacy interior/top saves migrate to their new parent/plane; layer checkpoint/continue and cross-room respawn are covered.

## Visual checks

[Cove exterior](cove-exterior.png) · [Villager interior](villager-interior.png) · [Shore base](shore-base.png) · [Lighthouse interior overview](lighthouse-interior.png) · [Roof and flame](lighthouse-rooftop.png)

Reproduce with `godot --path . res://reports/room-layers-2026-11-07/capture.tscn`. The capture uses disposable progress. The interior overview zooms out to inspect the distributed landings; normal gameplay retains its normal camera zoom.

## Verification

The feature's first regression run failed because retained room layers were absent. Subsequent checks exercise actual World objects, entity retention, independent controls, darkness, old sound shutdown, invalid arrivals, save/continue, editor serialization/resize/undo, legacy saves and the real jump-only lighthouse climb. The climb includes safe recovery pauses; it uses no capacity/movement upgrade. A detailed trace identified low stamina blocking the last jump during the first nonstop climb attempt.

The old standalone-house transition checks now use retained interiors; the region-mask test remains isolated in a temporary small room. The registry fixture supplies valid links for the new passage type. Existing main/smoke checks were rerun after the final transition ordering change.

Final full verifier: **0 failing** ([verification.txt](verification.txt)). The expanded [layer regressions](layer-regressions.txt), [gameplay](gameplay-latest.txt) and [smoke](smoke-latest.txt) checks also passed after the final transition-ordering change. Migration unit tests: 3 passed. Documentation links and `git diff --check` pass. This delivery does not author the crystal ruins, replace the boat route, implement the resource tick or provide complete offline layered progression analysis. See the guide for current limits.
