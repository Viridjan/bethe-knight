# Room-editor object movement

Implemented 2026-11-05. Existing rooms keep their original behaviour until a
movement override is authored. No shipped room layouts were changed for this work.

## Use it

1. Place an enemy, platform, pickup, hazard or decoration normally.
2. Select **Object movement** in the left room-editor palette, then click the object.
3. In the right inspector choose **Surface patrol** or **Path patrol**.
4. Enable **Preview movement** to see the outlined body. Preview uses static room
   terrain/objects; it does not run gameplay, move the saved object, or animate
   other objects. A red path preview indicates collision blocking its movement.
5. Save and playtest normally. Choose **Original behaviour** to remove the override.

Controls have hover explanations. Scrolling the inspector does not zoom/pan the
room. Motion edits use the existing undo, save, load and unsaved-room navigation
workflow. Copy/paste moves all path coordinates with the object and rejects a paste before
changing anything if its route would leave the room. Invalid motion cannot be
saved or playtested; errors appear in the editor status bar. Shrinking a room
is rejected if it would cut a surviving object's path; edit that path first.

## Surface patrol

**Speed (tiles/second)** controls travel speed; one tile is eight pixels. Zero holds
position. **Starting direction** is Right, Left, Down or Up. **Attached surface**
chooses floor, ceiling, wall on left or wall on right. Direction must be tangent
to the surface; changing the support chooses a valid tangent if needed.

Place the body adjacent to its selected support. Without **Sticky**, it reverses
at a wall or surface end; **Pause (seconds)** waits before departing again. With
Sticky, it follows connected inner/outer corners across floor, walls and ceiling.
If support is lost, gravity settles it onto the floor. Ordinary floor support also
includes the top of one-way platforms, not their underside or sides.

The controller moves an axis-aligned pixel body. It is not a navigation/pathfinding
system, does not make a surface-connected enemy chase the player, and does not
rotate every family's artwork automatically. Thornmite retains its existing
surface-oriented drawing. Those are separate behaviour/art decisions.

## Path patrol

A new route starts with two points. **Open paths** go from end to end and reverse;
**Closed path (loop)** traverses the final-to-first segment repeatedly.
**Pause (seconds)** waits at each visited waypoint, including turnaround points.
There is no initial pause when already placed at the first point.

- Enable **Add path points**, then click the canvas to append a point.
- Drag a numbered point to move it; points snap to the room grid.
- Right-click a point, or select it and use **Delete selected point**, to remove it.
- Keep at least two points and at most 64. Adjacent duplicates and a repeated
  first/last point on a closed path are rejected; closing is automatic.
- Arrows show forward traversal. If point 1 differs from the object's placed
  anchor, a faint connector shows the initial approach to it.

Points are room-local placement-anchor positions, not player positions. Collider
setup offsets are retained: a centred pickup follows the same authored route
without jumping its collider to a different anchor. Speed is independent of point
spacing. Overshoot and waypoint pause time are accounted for, while runtime
movement visits intermediate vertices and checks collision one pixel at a time.

## Runtime ownership and collision

`World._tick_entity` calls the shared entity tick. An authored route owns idle
motion; an enemy's existing warning/attack/recovery sequence retains its own
movement and pauses the route. Resumption starts at the actor's actual position,
so a leap/charge does not teleport it back onto an earlier path point. Health,
variants, attack selection and projectile lifetimes retain their existing rules.

Moving solids use the existing push/carry adapter. One-way platforms carry riders
without pushing a player from underneath. Dynamic platform collision columns are
updated after movement, and originally fixed solids join the moving-solid list.
Moving hazards/pickups check contact during movement to avoid skipping over Be.
Movable decorations may ignore terrain; physical bodies and all motion remain
inside the room. Paths stop when terrain blocks them rather than tunnelling.

Room/encounter anchors are deliberately excluded: spawn/respawn markers, doors,
camera/automatic-walk zones, boss gates, boss encounters/chases and vent plugs.
The inspector explains the restriction and the loader rejects unsupported motion;
it is never silently saved as a working patrol. Moving those anchors requires
specific room/progression semantics, rather than just displacing their rectangle.

Pausing the game/map freezes runtime motion. Room reset/re-entry rebuilds route
state from its authored start. Each mover owns its own immutable settings snapshot,
route cursor, support direction and fractional movement remainder.

## Saved schema

An optional `motion` dictionary lives on the normal entity JSON. For example:

```json
{
  "t": "jumpthru", "x": 80, "y": 160, "w": 24, "h": 8,
  "motion": {
    "mode": "path", "speed": 3.0, "pause": 0.5, "closed": false,
    "points": [[80, 160], [160, 160], [160, 128]]
  }
}
```

Surface settings use `mode: "surface"`, `speed`, `pause`, `sticky`, `direction`
and `support`. Directions are cardinal `[x,y]` vectors. The shared validator checks
finite speed 0–100 tiles/second, pause 0–60 seconds, valid perpendicular support and
direction, path length, whole pixel coordinates and points inside the room.
Legacy entities without motion are unchanged. This is an optional room field,
not a second source of enemy-family defaults.

Implementation: `scripts/editor_motion.gd` owns the inspector and preview;
`motion/patrol_settings.gd` validates; `motion/path_patrol.gd` owns route timing;
`motion/patrol_runtime.gd` adapts path/surface movement to injected collision and
movement callbacks; `motion/surface_patrol.gd` retains shared crawler traversal.

Regression scene: `res://tests/patrol_authoring.tscn`. It covers route timing,
validation, actual platform/rider/index movement, enemy override and attack pause,
sticky and vertical surfaces, one-way support, room walls, point dragging, undo,
copy/paste, saving/loading and inspector wheel input.
