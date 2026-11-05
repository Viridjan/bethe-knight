# Short punch and hidden-wall discovery

- Q / controller Y / touch Punch; remappable and available before the sword unlock.
- Horizontal 3×3 pixel fist, 3 pixels beyond the movement body, with wind-up, contact and recovery. Shared sword cooldown.
- Both attacks cost 2 stamina per attempt plus 4 on the first accepted enemy hit. Shields and walls do not charge the hit surcharge. Standalone levels and infinite-stamina assist remain free.
- Punches cannot damage breakable walls. New Terrain → Hidden Wall entities reveal only on direct fist contact; discovery persists in adventure progress. They stay solid and require the sword to break.
- No hidden walls have been placed in the shipped story rooms in this change.

## Review and verification

Run `godot --headless --path . res://tests/punch.tscn` for deterministic reach, cost, shield, obstruction and persistence checks. The runner reports 0 failures.

`tests/punch_preview.tscn` renders the real player draw code in both directions; `poses.png` shows wind-up, contact and recovery at enlarged pixel scale.

Gameplay regression tests were updated to explicitly activate the melee window and refill stamina before checking the sword unlock. The main gameplay runner retains two map assertions unrelated to the punch: East Shore water/acid rows are not wall-to-wall, and the jump-only story bot stops in Jungle Falls. The full verification log is included separately.
