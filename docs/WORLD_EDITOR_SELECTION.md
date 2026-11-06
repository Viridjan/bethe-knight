# World editor selection and snapping

Drag a rectangle from empty map space to select rooms. Every room touched by the
rectangle is selected. Shift-drag starts an additive rectangle even over a room;
Ctrl-click adds or removes one room.

Drag any selected room to move the entire selection. Relative room positions stay
fixed. Dragging an unselected room selects and moves that room alone. Release to
save the layout; Escape restores the positions before the drag. A failed save also
restores those positions. Room-editing and other selected-room buttons still apply
to the primary room, which is the room most recently grabbed.

**Snap passage connections** starts enabled. While dragging, nearby opposing open
room edges align so their passages meet. The whole selection receives the same
correction. Green outlines identify the snapped room pair. Hold Alt to bypass
snapping, or turn the checkbox off. Snapping rejects positions with overlapping
open room space and does not attract distant rooms or remote door/panel links.
It aligns physical entrances; it does not edit room terrain or create new doors.

Right/middle drag pans and the wheel zooms. Hover the bottom-right legend for the
full controls. Selection itself does not write the layout.

Implementation: `scripts/world_editor.gd` owns selection and drag/save transactions;
`scripts/world_layout.gd` finds compatible border openings and snap candidates.
`tests/world_selection.tscn` verifies selection, group offsets, snapping,
cancellation, persistence, failed saves, and exclusion of remote door links.
