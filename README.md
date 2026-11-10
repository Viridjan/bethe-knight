# Bethe Knight

A Celeste-style platformer in Godot 4 (tested on 4.4.1 and 4.7.2) with a built-in world editor.
Be is the protagonist: she faces entities that mostly exist within her. Regions echo
real-world experiences; the jungle can, for example, evoke a city jungle.
Start with the [documentation index](docs/README.md), [current tasks](TODO.md),
[implementation ledger](docs/IMPLEMENTATION_STATUS.md) and [merged reports](reports/README.md).
The current story/map plan is in [Story design](docs/STORY_DESIGN.md).

Player physics are a GDScript port of Celeste's `Player.cs`
(MIT, Maddy Makes Games — https://github.com/NoelFB/Celeste).
Art: Paper Pixels (blue) by VEXED, CC0 — see `assets/paper-pixels/LICENSE.txt`.

## Play in the browser
https://viridjan.github.io/summit/ — built and published by `.github/workflows/pages.yml` on every push to `main`
(Godot web export, preset "Web" in `export_presets.cfg`). Click the game once so it gets keyboard focus.
In the browser, saves, options and your own levels are kept by the browser; the world editor and
"Add to Adventure" can't write the shipped files there, so do that work in the desktop version.

## Run
    sudo pacman -S godot
    godot --path . --import   # first time only: imports the sprite sheets
    godot --path .            # play
    godot -e --path .         # open in editor

## Controls (remappable in Options)
Arrows move · C/Space jump · X/Shift dash · Z/V grab · S interact (house doors) · Q punch · A sword attack (swings toward the held direction; F1 → `DASH_DIRS` / `ATTACK_DIRS` limit dash and attack to 0 off, 1 horizontal, -1 vertical, 2 four-way, 3 eight-way, 4 free aim) · Esc pause · M map · F1 movement tuning · F2 hitboxes · F3 stamina · F4 state machine · F12 assist mode (the pause menu also opens F1, F3 and F4, top right). Gamepad: A jump · R1 dash · X sword · Y punch · R2 grab · B interact, back in menus (remap in Options → Controller Buttons).

## Stress

Current runtime uses owned stress-capacity blocks, completed-block penalties up to 30%,
and attached stamina/stress bars. New runs default to one stress block; legacy saves retain five.
Death/exhaustion gains, kill/collectible relief and durable twelve-hour rest recovery persist.
See [the resource rules and authoring details](docs/NONMAP_SYSTEMS.md#stamina-and-stress).

## Numeric values and responsiveness

Physics, collision, input sampling/buffering and attack timings/speeds retain normal precision
and the existing responsive update cadence. The physics step remains 60 Hz.

Whole-number arithmetic applies to gameplay resources and scores, including their saved,
editor and displayed values. The approved migration uses a 0.2-second tick **only for continuous
resource accounting**; one-off jump/attack costs remain immediate. This migration is planned,
not implemented. See the [tick plan](docs/plans/WHOLE_NUMBERS_TICK.md).

The newer stress rule remains: only completed blocks contribute, with a maximum 30% penalty.
In the planned integer calculation, truncate the cumulative percentage: four owned blocks give
0/7/15/22/30% penalty as blocks fill. See the [confirmed decisions](docs/DOCUMENT_CONFLICTS.md).

## Moves
Run, variable jump, coyote time, input buffering, wall jump, wall slide, climb + stamina,
climb hop, 8-way dash, super/hyper jump, wavedash, super wall jump, corner correction, duck, fast fall.

**Stamina (adventure):** a base of 27 that always regenerates, plus 17 per stamina block; a jump or wall jump costs 5,
climbing drains it, water drains 40/s. All owned bars regenerate to full, even after being completely emptied. Regeneration: 4/s empty, 8/s at half, 3/s full (`scripts/adventure.gd`).
A fall of 10+ tiles is a hard landing: stamina to 0 and a 1 s stun (stars over the head; regeneration restarts with the
second star). F3 shows a stamina recap.

## Objects
Spikes and springs (one editor entry each: they face away from the wall they're placed on; click again to rotate), dash crystal, double-dash crystal, star (collectible), jump-through,
crumble block, falling block, zip mover, dream block, green/red bubble, bumper, feather, crystal heart (goal),
dash / climb ability orbs (adventure only), note (design reminder: "Needs double jump", "Boss arena"…;
its text shows in the editor, and in game while standing on it), door (drag a rectangle; links to another door by
"room:id" or "id": rooms that don't touch, elevators, shortcuts), water (drains adventure stamina), acid (kills on touch),
enemy and breakable placeholders (named boxes, harmless, stand-ins until real ones are coded).
Punch: always available, with a tiny 3×3 pixel reach beyond the body and a brief active window. Punch and sword share a cooldown and adventure costs: 2 stamina per attempt, plus 4 on the first successful enemy hit. Punches cannot damage walls.

Hidden Wall: author in the Terrain palette; concealed until punched directly, then shown as a breakable wall. Discovery persists for the run, and the wall remains solid until broken with the sword.

Breakable Wall: solid until hit 3 times with the attack (`hp` in the level file); stays broken for the run.

## Adventure
Title screen → Adventure → New Game / Continue. The adventure is one big world of connected rooms (Metroid style):
walk off a room's edge into the next one. The story starts without dash, climb and sword. Ability pickups unlock them; the current
map plan places the first sword at the lighthouse quest NPC (placement pending). Bosses (the Ape, the Guardian) open their gates when beaten. Rooms are grouped in regions,
each with a zodiac sign that sets its monsters; moving into a new region plays a fade.
M offers Map, Monsters, Items and Abilities tabs; the map shows explored rooms. Progress saves automatically (`user://save.cfg`, section `[adventure]`).
The game ships one world, the story (`res://worlds/story/`, chapter 1 in progress, see `docs/STORY_DESIGN.md`); the world editor edits it (cyan lines = door links).

**World editor** (main menu → World Editor, only when run from source because it writes `res://worlds/story/`):
drag rooms on the grid; where two rooms touch and both have open tiles on the shared edge, that's a passage (green).
Drag empty space to select multiple rooms, then drag a selected room to move the group.
Shift-drag adds rooms; Ctrl-click toggles individual rooms. Nearby compatible passages snap together
when **Snap passage connections** is enabled; hold Alt to bypass snapping and Escape to cancel a move.
See [selection and snapping controls](docs/WORLD_EDITOR_SELECTION.md).
"+ Add empty room (draft)" (placed right of the selected room) or "+ Add copy of my level", Edit room (or double-click a
room; Esc goes back and asks to save), Playtest from here, Set as start. **Build drafts** turns draft rooms into
connected, playable rooms (`tools/story/build_drafts.py`: a maze with one way into each, two shortcuts behind an ability
gate, generated terrain checked to be crossable; `"attach": [room]` lets a draft open a doorway into a finished room).
**Place respawns** adds checkpoint activation areas at uncovered safe entrances and preserves authored regions. See [checkpoint areas](docs/RESPAWN_POINTS.md). Files: `res://worlds/story/world.json` (room positions) + one level file per room.
Background and ideas for later (doors, gates, map stations, hurt states): `docs/METROID_NOTES.md`.

## Map and tuning (in-game, also in editor playtests)
M opens a full-screen map of the level (paused; wheel zoom, drag pan).
F1 opens the debug panel: the player's state machine (live state, transitions seen, recent log), live variables,
and every movement variable as an editable value. Edits apply immediately and survive respawns and playtests.
Save them as a named preset in `user://tuning/` (the last saved/loaded preset is active at startup);
"Export to project" writes `res://config/tuning.cfg`, the project-wide defaults (only when run from source).
"Pause sim" and "Step" advance the game one tick at a time. "Hitboxes" (also Options → Show Hitboxes) outlines the player (green), the sword swing (red) and objects (yellow/orange).

## Adding objects
See `docs/ADDING_ENTITIES.md`.

## Checkpoint areas

Use **Respawn** in the room editor to drag an activation rectangle, optionally up to the ceiling.
Its marker sits on the lowest safe permanent ground inside; entering the region in midair also activates it.
The story map and interior layers use these wider areas. See [respawn areas and map tools](docs/RESPAWN_POINTS.md).

## Room layers

Rooms can retain interiors behind their exterior. Layer passages switch the active plane while the previous
view stays loaded under a thick black overlay. Inactive planes freeze and their sounds stop; only the active
plane handles physics, input, interaction and music. The room editor has **Room layer**, **+ Layer** and
**Layer Passage** controls. See [retained room layers](docs/ROOM_LAYERS.md).

Cove Town's Villager and Quest houses are interior layers. Shore contains the lighthouse rooftop/lamp and
its narrow interior layer, with five mages distributed across the stairs.

## Level editor

Select **Room size (drag edges)** in the left palette, then drag any edge or corner. The preview snaps to tiles; release to apply, Escape to cancel, Ctrl+Z to undo. Left/top resizing shifts tiles, objects and movement paths together, and saving updates the world room position so the opposite edges stay fixed. New space is empty; shrinking crops terrain and objects, and refuses changes that cut a retained patrol path or mover destination. The W/H fields and Resize button still resize the right/bottom sides.
LMB paint/place (drag to size blocks; zip mover asks for a target click) · RMB erase ·
MMB or Space+drag pan · wheel zoom · Ctrl+Z undo · Ctrl+S save · F5 playtest ·
Shift+drag select an area, Ctrl+X / Ctrl+C cut or copy it, Ctrl+V paste at the mouse (also into another room).
Editing a world room: yellow arrows outside the edges lead to the touching rooms (click, or Ctrl + arrow key), cyan
arrows over doors to the rooms they lead to; both ask to save first.
Settings, saves and custom levels live in the `Bethe Knight` data directory. Levels save as JSON in `user://levels/` (Linux: `~/.local/share/godot/app_userdata/Bethe Knight/levels/`).

## Combat enemies

Nine original enemy families:
Thornmite (wall crawler), Dropwing (ceiling dive), Duskflit (swoop), Ossling (bone
throw), Hornback (charge), Fuzzbob (bouncing flight), and the big Cragjaw (leaping
brute) and Murkspore (spore spitter), plus the story jungle's calm Mosstrot (wanders, never chases). Attack with A; bones and orbs can be swatted
away. Most families come in 2-4 variants (Swift, Armored, Giant, Shielded, Brood,
Venom); all 32 types are in the room editor, in the Monster Editor (main menu, desktop source version) and on the
in-game map's Monsters tab (the ones you've met, with kill counts).

**Library monsters** (`scripts/monster_library.gd`, entity `enemy_monster`): built from a move (walk, hop, hover),
attacks (charge, leap, shoot, lob) and traits (the variants above). An upgrade adds an attack or a trait: once
upgraded they're 1.25x and amber, twice 1.5x and magenta. `godot --headless --path . --script tools/populate.gd`
fills each region: 30% of the previous region's monsters as they are, 20% upgraded, 50% the region's own (its zodiac
sign's); twice-upgraded ones stay in their region. `--dry` previews, `--clear` removes what it placed. These random
builds are being replaced by calibrated placement per region (families and a danger budget):
`docs/reviews/monsters/CODEX_PROMPT.md`, task 7. See [behaviour and placement notes](docs/ENEMIES.md) and the
[animated sprite gallery](assets/enemies/preview.html).

## Tests
    godot --headless --path . res://tests/test.tscn    # physics checks, exit code = failures
    godot --headless --path . res://tests/smoke.tscn   # opens every screen
    godot --path . res://tests/bench.tscn              # benchmarks (see OPTIMIZATION_RESULTS.md)

### Music Studio (prototype)

Open **Music Studio** from the main menu and press **Play** to hear an original
four-channel chiptune loop. Click steps to cycle through rests and C-major notes;
choose pulse, triangle, saw, synthesized percussion, or FM piano per channel.
Tempo, volume, and channel mute controls are available. Pattern/instrument/tempo
edits restart playback; volume changes apply immediately. Back or Esc stops music.
Edits survive returning to the menu during the current session, but are not yet
saved to disk. This first version is a synth/sequencer; automatic composition and
gameplay-driven music are future work.

The bundled GDSiON 0.7-beta8 runtime currently supports **Linux x86_64**. Other
platforms need matching upstream binaries; see `addons/gdsion/README.md` for
provenance, licenses, and integration notes. Run the audio and lifecycle checks:

```sh
godot --headless --path . --script tests/music.gd
```

### Environment soundtrack

Gameplay now follows each room's background (`environment`). Nine original
8-bar chiptune arrangements cover mountain/default, forest, sand, sea, cavern,
deep cavern, sky, temple and village/building. Rooms with the same environment
continue the current loop; entering a different environment starts its theme.
Leaving gameplay stops music. The studio shares the gameplay volume control.

In **Music Studio**, select a named environment to hear its arrangement against
its background. Use **Steps … >** to browse all four pages of a 64-step score.
Selecting a theme replaces the current working pattern; Reset demo restores the
short demo. Theme changes currently restart immediately, without crossfading.
The compositions use adventure-game moods, modal melodies and chip instruments;
no Zelda melodies, recordings or samples are included.

Scores live in `scripts/environment_music.gd`. Each defines a key/mode, tempo,
instruments, chord progression and two original phrases, arranged as A/B/A'/B'.
Run the soundtrack rendering and selection checks with:

```sh
godot --headless --path . --script tests/environment_music.gd
```

### Sound effects

Original retro sound effects are synthesized and cached at startup in `scripts/sfx.gd`. Movement, combat, enemy warnings/projectiles, the Ape boss, pickups, doors, notes, blocks, and menu buttons trigger effects independently of the music synth. Options → Audio → Sound effects controls their volume (including Off). Playback uses a 16-voice pool and suppresses duplicate bursts. No external sound files or licenses are required.

Run audio checks with `godot --headless --path . --script tests/sfx.gd`.

## Understanding the code

Start with [the beginner code guide](docs/CODE_GUIDE.md) for the file map, execution flow, Godot vocabulary, coordinate conventions and safe editing/testing workflow. First-party scripts, tests, tools and artwork previews include purpose and function comments.

Development-assistant setup and installed skills are documented in [the skills installation report](docs/DEVELOPMENT_SKILLS.md).

## Respawn checkpoints

One respawn per room entry (doors and other interactables don't get one), invisible in play: walking onto it makes it
the respawn point; entering a room doesn't. Placement: a side entry gets it 1 tile in from the edge, on the floor under
the entry's lowest row; a top or bottom entry on its middle column, on the first floor below / above. Where there's no
floor there, no respawn: an error instead. Place them all with World Editor → **Place respawns** or
`python3 tools/world_fixups.py --respawns worlds/story`; the room editor's **Respawn** tool places one by hand.
Nearby entrances can share a checkpoint when connected by a short, safe walk.

Preview redundant-point cleanup with:

```sh
python3 tools/prune_respawns.py worlds/story --output reports/checkpoint-review
```

Add `--apply` to save changes with a backup. Use `--rooms c6_wall_cave` for one
room. See [Respawn placement and automated cleanup](docs/RESPAWN_POINTS.md) for
merge rules, report files and validation commands.

## Progression report

In the desktop source version, open **World Editor → Tools → Progression**. The editor
saves the current layout, analyzes a snapshot in the background, and opens the
interactive report in your browser. Python 3 is required. You can keep editing;
**Open progression report** reopens the latest result.

The report has independent **Progression** and **Route choices** tabs, with a
large central map. Explanations are available on hover and in the compact Key,
Route, and Rooms controls. See [the progression guide](docs/PROGRESSION_REPORT.md)
for filters, route selection, output locations, and command-line use.

The checked-in [progression page](reports/progression.html) is also available.
After the Ape fight, a thorn barrier prevents returning to early Jungle; the
onward routes remain Jungle Depths and Sand Cave.

The online build shows Adventure, Options, and Credits; World Editor, Monsters,
Art, and Music Studio remain desktop tools. The web export excludes development
screens, the native Linux synth, and artwork reference sheets generated by the
runtime drawing code. Gameplay textures, recorded music, and the in-game bestiary
remain included. The engine download is still the largest part of the web build.

In the desktop **Monsters** screen (also available from the map's Monsters tab),
**Monster Editor** (main menu, desktop source version) edits `data/attacks.csv` and `data/enemy_attacks.csv`:
**Attack library** (each attack's values by type) and **Enemy loadouts** (each enemy's attacks in priority order,
ranges, skip %, follow-ups, frames, scores). See [the attack catalogue guide](docs/ATTACK_CATALOG.md).
The Ape also exposes health, phase threshold, and phase-entry hop scales in
`data/enemy_profiles.json`. Its triggered effects appear below its selected attacks;
falling and thrown logs share floor-spike behavior, and phase-two logs split at their apex.

In the desktop source version, **Monster Editor** on the main menu opens the CSV
editor directly. Restart the game after updating the source to see the new entry.

Room editor: use **Object movement** to configure surface/sticky patrols or editable
open/closed paths for movable enemies and objects. See [patrol controls and runtime rules](docs/PATROL_AUTHORING.md).
