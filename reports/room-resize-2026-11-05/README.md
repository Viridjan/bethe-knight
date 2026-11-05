# Resize rooms from any side

In the room editor, choose **Room size (drag edges)** in the left palette. Drag any edge or corner; the green preview snaps to tiles and displays the proposed dimensions. Release to apply. Escape cancels; Ctrl+Z undoes the complete change. W/H + Resize keeps its previous right/bottom behavior.

Left/top changes translate tiles, object positions, zip destinations and patrol paths together. Saving a world room also updates its manifest origin to keep existing content and the opposite edge fixed in world space. Playtest return retains the unsaved origin and undo history. Added space is empty; shrinking clips terrain/sized objects and removes outside objects. A retained patrol path or zip destination cannot be silently cropped. Limits remain 10–400 by 6–400 tiles.

## Verification

- `tests/room_resize.tscn`: 0 failures (all sides/corners, object/path translation, undo, cancellation, size constraints, world-origin persistence, custom-room saves and playtest resume).
- `tests/editor_navigation.tscn`: EDITOR NAVIGATION OK.
- `tests/editor_scroll.tscn`: EDITOR SCROLL OK.
- `tests/editor_playtest.tscn`: EDITOR PLAYTEST OK.
- `tests/smoke.tscn`: SMOKE OK; no script errors.
- `tests/test.tscn`: two existing map assertions remain: East Shore water/acid rows and the jump-only Jungle Falls bot route.
- GDScript lint and `git diff --check`: pass.
- Rendered Godot review: `handles.png` and `preview.png`. `capture.tscn` regenerates these using the actual editor.
