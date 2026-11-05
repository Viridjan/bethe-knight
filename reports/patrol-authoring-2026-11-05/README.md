# Patrol authoring — 2026-11-05

Delivered a dedicated Object movement tool and right-side inspector for movable
objects: surface/sticky patrol, support and starting direction, speed, pause,
open/closed paths, numbered points, canvas creation/drag/deletion, and live body
preview. Unrelated controls are hidden per mode; details are in hover help.

Runtime adapters integrate with the existing entity lifecycle and pixel mover:
no doubled enemy locomotion, patrol pauses for attacks, resumes from actual actor
position, platforms carry riders, dynamic collision indices follow moving bodies,
and physical paths stop at walls. Support includes the top of one-way platforms.
Existing rooms retain original behaviour unless given a motion definition.

Editor mutations use normal undo/save/load. Copy/paste offsets the whole route;
invalid out-of-room pastes are rejected atomically. Save/playtest reject invalid
motion, and validation messages take priority over movement-tool help. Resizing
cannot silently cut surviving path points. Preview never changes saved positions.

Validation:

- Final patrol_authoring.tscn: **34 checks, 0 failures**, no script/engine errors.
- Final smoke.tscn: SMOKE OK.
- Final editor_scroll.tscn: EDITOR SCROLL OK.
- Final editor_playtest.tscn: EDITOR PLAYTEST OK.
- Full tools/verify.sh run: one known Jungle Falls story-bot traversal failure;
  other Godot/Python/lint/benchmark gates passed. Final save/paste/feedback guards
  were additionally checked by the subsequent targeted patrol/editor runs above.
- Shared-foundation tests and legacy corner/variant/brood checks pass.
- GDScript lint and git diff --check pass. Screenshots path.png/surface.png were
  rendered from the disposable capture scene and visually inspected.

Room/encounter anchors are excluded explicitly; this is not a new way to relocate
bosses, doors or respawn markers. Sticky chase, general sprite/body rotation,
timed traps and linked triggers remain separate work. No shipped room data was
modified for this feature; existing jungle edits were left intact.

Usage and schema: [PATROL_AUTHORING.md](../../docs/PATROL_AUTHORING.md).
