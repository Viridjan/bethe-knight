# Respawn activation areas

Updated 2026-11-08. A checkpoint has a user-defined **activation rectangle** and a separate **grounded respawn anchor**. The original white player outline/red head shows the anchor in the editor; the tinted rectangle shows where the checkpoint activates. Both stay invisible during normal play.

## Using the tool

1. Choose **Respawn** in the room editor.
2. Drag a rectangle over the area that should activate the checkpoint. It can be wide and can extend up to the ceiling. Select at least two tiles of height so a standing player fits.
3. Release: the tool finds the lowest safe permanent-ground point **inside that rectangle**. If several points have the same height, the nearest to the rectangle's horizontal centre wins (left candidate breaks an exact tie).
4. The outline previews the actual respawn position. Unsupported selections are rejected; a region made unsafe by later terrain edits appears red and cannot be saved until fixed. Painting/erasing terrain refreshes the preview when the stroke ends.
5. Right-click an area to remove it; redraw to change its bounds. Undo restores the previous region. Multiple checkpoints are allowed; placing a new one does not remove the others.

Entering any part of the selected region activates its anchor, including while jumping, falling or climbing. A checkpoint does not activate while the player is fatigued: in water or in a room whose heat drains stamina. Saving there could respawn the player straight into another death. The player does **not** need to touch the ground marker. Activation is silent, without particles or a stamina refill. An unchanged checkpoint is not repeatedly saved.

If regions overlap, the smaller/more specific rectangle wins; equal-sized regions choose the nearer anchor. Only one can activate during a contact check, preventing repeated save changes from overlapping zones.

## Safe grounded anchors

The whole standing player must fit within the selection, clear of solid terrain/objects, water, thick water, acid and spikes. Feet must stand on permanent terrain. Suspended jump-throughs and movable/breakable platforms do not count as checkpoint ground.

A selection containing no safe floor does not create a checkpoint. Moving platforms and temporary trap states cannot turn an unsafe point into permanent support. Runtime activation checks safety again if a cached anchor becomes unsafe.

Layer entrances no longer automatically create a checkpoint just because their destination is grounded. Only an authored checkpoint region or a compatible legacy marker can update it; otherwise the previous checkpoint is retained. The saved checkpoint keeps its room and layer, and death/Continue return there.

## Data and compatibility

```json
{"t":"spawn","x":64,"y":64,"w":96,"h":160,"respawn_at":[124,224]}
```

`x/y/w/h` are the selected activation rectangle in room pixels. `respawn_at` is the derived player-feet position. The editor/loader recompute it from the selected geometry; move or redraw the region rather than hand-editing the anchor. Copy/move/resize translates the region and refreshes the anchor against the destination terrain. Room layer saves and resizing preserve all planes' regions.

Legacy `spawn` and `respawn` point markers without width/height still load and keep their original walk-on behavior. Only one Respawn palette entry is shown. A legacy point stays a point when an old room is resized; it is not silently changed into an invalid one-tile-tall area.

Offline progression/accessibility tools read `respawn_at`, rather than mistaking the rectangle's top-left for the player start. They still have their documented approximation/layer limits.

## Map migration and automatic tools

The shipped story map now has **75 explicit checkpoint regions across 41 files**, including room variants and the retained house/lighthouse layers. Regions extend toward the ceiling above their safe landing. Adjacent same-floor points split their horizontal coverage where possible. Existing terrain, hazards and other entities are preserved.

Repeat the migration after legacy generation:

```sh
python3 tools/checkpoint_areas.py worlds/story
```

The migration preserves existing authored rectangles and recomputes their anchors; a repeat run on the current map makes no changes. It resolves every room before writing changes, refusing a map with an area that has no safe ground.

World Editor **Place respawns** preserves authored regions, skips covered entrances, and turns newly generated markers into regions. `tools/prune_respawns.py` still prunes redundant **legacy points** on safe shared landings, but it never deletes or merges user-defined rectangles. Its older reports describe the former point-marker map, not the current area count.

```sh
python3 tools/prune_respawns.py worlds/story --output reports/checkpoint-review
```

## Verification

`tests/checkpoint_areas.tscn` checks lowest-safe-ground selection, airborne activation, liquids, overlap priority, area placement, unsupported selections, resizing/undo and retaining the previous checkpoint at an unconfigured layer entrance. Python tests cover conversion, ground safety, idempotence, automatic placement and preserving authored rectangles. Both are included in `tools/verify.sh`; existing room/layer/editor/traversal tests remain in the gate.
