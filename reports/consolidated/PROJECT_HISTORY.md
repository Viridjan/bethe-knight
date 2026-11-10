# Project History: consolidated historical records

Merged 2026-11-07. These are dated records, **not a current task list or instructions to rerun old fix prompts**.
Current status: [implementation ledger](../../docs/IMPLEMENTATION_STATUS.md). Current tasks: [TODO](../../TODO.md).
Later delivery records can supersede earlier findings. Recorded test results describe their original run; this cleanup did not rerun gameplay.
Screenshots, logs, code probes and data remain in their original evidence directories. Original Markdown paths are compatibility redirects.

## Contents

- [TODO.md](#todo)
- [gdd.txt](#gdd)
- [docs/IMPLEMENTATION_STATUS.md](#docs-implementation-status)
- [docs/DEFERRED_WORK.md](#docs-deferred-work)
- [docs/CODE_HEALTH.md](#docs-code-health)

---

<a id="todo"></a>

## Source: TODO.md

Original source: `TODO.md`. [Evidence directory](../../).

# TODO

Current delivery audit: [implemented, partial and missing requests](../../docs/IMPLEMENTATION_STATUS.md) (2026-11-05). Design documents do not imply playable completion. Current deferred-work check: [DEFERRED_WORK.md](../../docs/DEFERRED_WORK.md).

## Current priority: lighthouse, crossing and volcanic island
Map direction: [room clusters, branching long routes, secret pockets and shortcut plan](../../docs/STORY_DESIGN.md#0-current-map-plan-room-clusters-and-branching-connections). Apply this topology before final room placement.

Confirmed story/HUD systems are implemented; map placement and route authoring remain. See [system behavior and authoring](../../docs/NONMAP_SYSTEMS.md). These take precedence over conflicting older quest, Kraken and stress proposals below.

- [x] Lighthouse NPC system grants the sword and a quest for three crystals. The sword is an ability; placing the NPC and removing the earlier sand-cave reward remain map work.
- [ ] Small old-ruins area below the lighthouse: at least two varied compact rooms, open entrance, sword-breakable obstacles guarding the three interactable quest crystals. Quest stages, unique pickups, turn-in and boat unlock are implemented; author the ruins and placements.
- [x] Items and Abilities pages alongside Map/Monsters. Initially show quest crystals and acquired sword; ability-page redesign can follow later.
- [ ] Boat-only sea crossing between lighthouse shores. West Shore's left rock wall has already been removed in current map edits; preserve that improvement, finish the arrival lighthouse and ensure both shores meet the sea without a direct walk-through connection.
- [x] First-crossing system (boat/dock placement remains): dodge rushing Kraken tentacles on a large boat; the encounter destroys the boat and washes Be ashore without it. This replaces the earlier first-crossing boss-fight/head-window/stat-gate proposal; it must not require unimplemented abilities to reach the island.
- [ ] Volcanic-island progression: west/east/north/south shores, complex marshes with thick-water behavior/environment, rocky plateau and a large volcanic zone. Preserve useful existing island rooms while adapting the routes.
- [x] Plateau giant-foot system: enormous walking rock inhabitants/enemies, raised-foot passage, warning and dodgeable ground stomps. Placement is map work; climbing them is a later progression feature.
- [x] Volcanic heat: red tint and continuous stamina drain, plus double-jump and heat-resistance abilities. Movement-gated route design and reward placement remain map work.
- [x] HUD: no top-left text; wider segmented stamina bar attached directly above segmented stress bar. Stress-capacity upgrades add blocks. Each completely filled stress block contributes an equal share of a maximum 30% stamina-regeneration penalty; four owned blocks means 7.5% per completed block. New runs default to one stress block; old saves retain five. Upgrade locations remain map work.

Recently completed: full stamina regeneration, four-sided/corner room resizing with variant synchronization, compact attack cards, one maximum Range field, per-phase Ape attack triggers and coverage-based Player cornered. Other enemies still need accurate attack-footprint/context adapters before using that condition.

### Partial-system foundations
- [x] Ordinary enemy family health overrides in Enemy loadouts, including library monsters; preserve variant modifiers and legacy defaults; validate and save profiles.
- [x] Extract existing floor/crawler motion and bounded brood death-spawn definitions into shared modules, with actual enemy regression tests.
- [x] Author movement overrides for movable enemies/objects: surface/sticky patrol, starting direction/support, speed, open/closed paths, waypoint pauses, draggable points, collision-aware preview and undo/save/load. See [patrol authoring](../../docs/PATROL_AUTHORING.md).
- [ ] Extend the foundations to condition-gated death actions and general phases. Timed spikes and typed trap/movement triggers are implemented; author teaching encounters next.

### Bethe Knight: identity and new design
- [x] Rename the application/menu to Bethe Knight and establish Be as the protagonist; retain the legacy save directory and source asset identifiers.
- Historical Kraken stat/underwater entry gates in [the older design](../../docs/BETHE_KNIGHT_DESIGN.md) are superseded for the first crossing by the current quest-unlocked tentacle-dodging sequence above.
- [x] Persistent stress with owned capacity, upgrades and completed-block penalties up to 30%; death/exhaustion gains, relief and durable rest claims preserved. See `tests/stress.tscn` and `docs/NONMAP_SYSTEMS.md`.
- Historical Kraken head-window/phased combat and Undertow are separate older proposals, not requirements for the newly specified first crossing.
- [ ] Ink: darkness once at 10%; borders stack independently, with agreed geometry/cap and attempt cleanup.
- [ ] Review Enemy-tab composition model before changing its schema/UI; preserve the combined Ape page and omit redundant phase boxes.
- [ ] Three working stats (Dexterity, Constitution, Attack): confirm final names/point budget; measure critical routes before base movement/recovery nerfs. Keep underwater survival separate from steering.
- [ ] Ground each region in real-world references alongside Be's inner journey; city-jungle is a direction to develop, not an implemented rename of all rooms.


- [ ] Modular mechanics programme: start with the Ape attack/effect and phase decomposition, then shared triggers/patrols/traps, inventory/keys, isolated story events, player abilities, hidden terrain, and teaching routes. See [implementation plan and acceptance gates](../../docs/MECHANICS_ARCHITECTURE_PLAN.md).
- [x] First Ape composition slice: shared log effects, trigger-only bindings, editable health/phase entry, anchored waves, and regression checks. See [implementation and verification](../ape-composition-2026-11-03/README.md).

- [ ] Web version: install Godot export templates (~1 GB), add a Web export preset, export to HTML5, publish as a private claude.ai page so the game is playable from a link.
- [ ] Adventure backlog (hurt/knockback state, more abilities, event flags, ability gates, map stations, camera zones, room-transition polish, save slots, areas): see `docs/METROID_NOTES.md` section 6.
- [ ] Replace the three placeholder adventure rooms with real ones (World Editor).

## Story world: chapter 1
Design: `docs/STORY_DESIGN.md`. Systems first, since the rooms depend on them.

### Systems
- [x] Stamina as health: base 27 plus 17 per extra block; all owned bars regenerate fully, even when emptied, with stress scaling. Contacts cause respawn; zero stamina underwater causes drowning. (`Adventure.*_stamina`, HUD, `stamina_block` + `stamina_orb` pickups)
- [x] Attack is an adventure ability (`ability_attack` orb); existing worlds list it in their start abilities
- [x] Story world starts with jump only (`worlds/story`, `"abilities": []`)
- [ ] Big wavedash jump is a later gate (needs dash): decide which later level gives dash
- [ ] Decide stamina thresholds, then build the unlocks: +10% jump, attack, abilities
- [x] Jump costs 5 stamina and needs it (no jump with less; `Player.JUMP_STAMINA`, `Player.can_jump`)
- [x] Punch and sword share costs: 2 per attempt, +4 on first accepted enemy hit. Punch is always available, tiny reach, reveals hidden walls without damaging them.
- [ ] Decide wall grab stamina drain (20 or 30/s)
- [ ] Stamina orb refills everything for now; decide how much collectibles restore
- [x] Water drains stamina: 2.08 every 0.1 s, no regeneration in water; at 0 stamina in water the player dies (`Adventure.water_stamina`, `World.update_stamina`)
- [x] HUD: attached text-free stamina/stress rows (top left), area name (top centre), timer and deaths with a skull (top right)
- [x] Interact button (keyboard, controller, touch)
- [x] NPC entity + dialogue box; "..." reply for silent NPCs
- [x] Lighthouse quest, item/key transactions and story flags; boat unlock. Other authored village quests and skill-point rewards remain pending.
- [ ] Skill points: regeneration, damage, speed, other stats; active abilities later
- [ ] Positional stereo audio: sounds attached to sprites, panned by position
- [ ] Research height cues for audio (above/below; HRTF or elevation tricks) before building

### Content
- [ ] Add traps to rooms.
- [ ] Expand basic enemy behaviors and attacks: roaming, jumping, jumping to the opposite wall, and other patterns. Audit existing primitives first; see [enemy pattern research](../../docs/ENEMY_PATTERNS.md) for movement/attack candidates and priorities.
- [x] Forest environment theme (`forest`: grass tops, trunks, vines, ferns)
- [x] Leaf platforms (`leaf`, a jump-through)
- [x] Waterfall blocks (`waterfall`: inside, the player can't rise and is pushed down)
- [ ] Breakable sand platforms
- [ ] Moving bridges between platforms (flexible)
- [ ] Net trap + capture animation
- [x] Quest-locked boat and first-crossing shipwreck system; raft/boat placements remain map work.
- [ ] Stone lighthouse with a mirror-aimed magic flame
- [x] Wandering jungle enemy: Mosstrot (`enemy_mosstrot`, walks back and forth, never chases; touching it hurts)

### Rooms
- [x] Start meadow: flat, few jumps and spikes, no enemies (`m1_meadow`)
- [x] Big wavedash jump (cone shape, tip up); uncrossable at the start, comes back when dash is unlocked (`m2_big_jump`, star on the far side)
- [x] First lake and dark cave with dead-end tunnels (`c1_lake_cave`); Roar Tunnel plays a one-shot stereo cave roar from the left. Expanded with 4 rooms of their own: Roar Tunnel (left), Cave Teeth and Cove Tunnel (right), Deep Lake (below: a hole in the lake floor drops in, a jump-through shaft leads back up)
- [x] Cove Town houses enterable through house doors (`house_door`: stand at it, press up): Villager's House, Quest Giver's House
- [x] Cove or small city: 2nd stamina block (`t1_cove_town`); the 2 NPCs and the quest are notes until NPCs exist
- [x] Jungle: Jungle Edge (hollow trunk, leaf climb) → drop → Jungle Falls (waterfall, lake, tunnel hill) → Jungle Hills (tunnel hill, trunk, leaf climb); the Ape is a note at the end
- [x] Ape boss arena (`a1_ape_arena`): open fighting floor, ledges at both exits and a gated hole to the left branch; tree, bridge pit and tree instructions removed; 56 tiles wide (70%); entering walks you in (`auto_walk`) and the way back shuts (`boss_gate` with `closes_behind`)
- [x] Right branch room: sand cave climbing at about 25° (`s1_sand_cave`), crumble blocks over pits stand in for breakable sand
- [ ] Sand cave: finish the authored chase/rockfall event chain if still needed. Sword reward moves to the lighthouse quest in the current progression.
- [x] Shore (`s2_shore`): the mountain's foot with a star out of reach, the sea, the lighthouse tower (a house door at its foot); raft is a note
- [x] Lighthouse Stairs (`lh1_lighthouse_stairs`): the tower's inside, two screens of zigzag platforms between a door at the bottom and one onto the gallery
- [x] Lighthouse top (`s3_lighthouse_top`): silent village and the mirrored flame as notes until NPCs exist
- [x] Left branch rooms: Jungle Depths (`l1_jungle_depths`), Net Trap (`l2_net_trap`, a door stands in for the net lift), Treetop Village (`l3_treetop_village`, a branch floor so nobody falls; jump-throughs stand in for the moving bridges)
- [ ] Left branch: net capture animation, moving bridges, wall grab reward (notes for now)
- [ ] Treetop Village: decide where the player goes after it (exits, next area, whether the two branches meet again)

### Boss: the Ape
- [ ] `ape-trueform`: revisit the approved charcoal/silverback transformation for phase two. Artwork, source and animated preview are saved in `pixel-art/ape-phase2/`; keep it deferred. For now phase two uses the original Ape sprites with a pulsing red light.
- [x] Ape boss (`boss_ape`), 4 units (32x32), 3 hits; arena `a1_ape_arena`; tests in `check_ape()`
- [x] Stone throw (far): parabolic, 2x2-unit stone (sprite = hitbox, per the exact-hitbox rule)
- [x] Slam (mid): a leap that lands 3 units past the player; safe when moving toward the Ape; the landing sends a shockwave 2 units out along the ground (jump it)
- [x] Scream (near): circular damage, 40px radius, with matching wind-up and debug rings
- [x] Open arena: one leap range; lure leaps onto spikes, with a new spike patch after each hit
- [x] Ape body contact: 70% linear bounds (22×22), narrowed around the head and shoulders; debug overlay matches
- [x] Exits sealed during the fight (`boss_gate`); beaten for the run
- [x] Post-boss exhaustion: stamina drops to 5, an stamina orb appears
- [ ] Ape reanimates (later: the chase in the sand cave?)
- [ ] Ground slime hazard
- [ ] The Ape's power-up reward (decide which)

## Power-ups from the reference games
One ability = one coded unit (player state/flag + orb/pickup entity + tuning vars + test), added methodically per
`docs/ADDING_ENTITIES.md`. Grouped by scope: items in a group share code, so build them together.
Sources: HK Hollow Knight, SS Silksong, SotN Symphony of the Night, MZM Metroid Zero Mission.
Dropped by choice: Space Jump, Screw Attack, bat/wolf/mist forms, Dreamgate, Morph Ball, Needolin music doors, Sylphsong, Beastling Call, Elegy of the Deep.
Gathered from fan wikis/guides (Oct 2026); recheck details before building.

### Already in Bethe Knight
- [x] Dash (HK Mothwing Cloak, SS Swift Step dash)
- [x] Wall cling, wall jump, climb (HK Mantis Claw, SS Cling Grip)
- [x] Melee attack (HK nail, SS needle)

### Direction upgrades (DASH_DIRS / ATTACK_DIRS, already tunable in F1)
Pickups that raise the value for the run and save it: 1 horizontal -> 2 four-way -> 3 eight-way -> 4 free aim.
- [ ] Dash direction upgrades: start horizontal only, unlock four-way, eight-way, free aim
- [ ] Attack direction upgrades: start horizontal only, unlock up/down (four-way), eight-way, free aim
- [ ] Vertical-only stage (-1) as an option for special rooms or challenges

### Movement: jumps (player jump code)
- [ ] Double jump (HK Monarch Wings, SS Faydown Cloak, SotN Leap Stone)
- [ ] High jump, passive: higher normal jump (MZM Hi-Jump)
- [ ] Super jump, active: vertical launch (SS Silk Soar, SotN Gravity Boots)
- [ ] Glide (SS Drifter's Cloak)

### Movement: dashes and speed (dash / run code)
- [ ] Charged long horizontal super dash (HK Crystal Heart); reuse the red-bubble dash
- [ ] Dash through enemies, invulnerable while dashing (HK Shade Cloak); needs enemies that hurt
- [ ] Sprint after a dash (SS Swift Step)
- [ ] Speed Booster: long run builds speed, breaks blocks; Shinespark: store it, launch in any direction (MZM)

### Movement: body shape and grabbing (collision code)
- [ ] Ledge hang and pull up (MZM Power Grip)
- [ ] Grapple to a target point (SS Clawline)

### Environment: liquids and hazards (liquid entities)
- [ ] Acid immunity (HK Isma's Tear)
- [ ] Move freely in water: swim / walk underwater (SotN Holy Symbol, MZM Gravity Suit)
- [ ] Heat / damage reduction (MZM Varia Suit)
- [ ] Ferry across water (SotN Merman Statue)

### Gates and keys (door / block entities)
- [ ] Coloured key doors: blue doors (SotN Jewel of Open), missile red/green doors (MZM)
- [ ] Hidden wall: looks like rock, walk through it and it fades to reveal a secret (HK, SotN, MZM)
- [ ] Hidden things revealed by a special hit (HK Dream Nail / Awoken Dream Nail)
- [ ] Bomb blocks and bomb jump (MZM Bombs); screen-wide blast (MZM Power Bombs)

### Combat base (needed by everything below)
- [ ] Player health + hurt/knockback (HK masks, MZM stamina)
- [ ] Resource meter for skills (HK soul, SS silk), filled by hitting enemies
- [ ] Healing from the meter (HK Focus, SS bind)

### Combat: melee upgrades (attack layer)
- [ ] Hold attack to charge a strong strike (HK Nail Arts: Cyclone, Dash, Great Slash; SS Needle Strike)
- [ ] Downward slam that breaks floors (HK Desolate Dive / Descending Dark)
- [ ] Parry / counter (SS Cross Stitch)
- [ ] Area lash around the player (SS Thread Storm)
- [ ] Dash blade through enemies (SS Sharpdart)
- [ ] Attack damage upgrades (HK nail upgrades, SS needle upgrades)

### Combat: projectiles (new projectile entity)
- [ ] Forward projectile (HK Vengeful Spirit / Shade Soul, SS Silkspear)
- [ ] Upward blast (HK Howling Wraiths / Abyss Shriek)
- [ ] Homing projectiles (SS Pale Nails)
- [ ] Beams that stack: Long, Charge, Ice (freeze enemies into platforms), Wave (through walls), Plasma (pierce) (MZM)
- [ ] Missiles / Super Missiles with ammo (MZM)
- [ ] Stun gun, short sequence (MZM Zero Suit Paralyzer)
- [ ] Rune Rage (SS); check details

### Capacity pickups (save data)
- [ ] Extra health (HK Mask Shards, MZM Stamina Tanks)
- [ ] Bigger meter (HK Vessel Fragments)
- [ ] Ammo tanks (MZM Missile, Super Missile, Power Bomb tanks)
- [ ] Stat boosts (SotN Dracula's relics: Heart, Tooth, Rib, Ring, Eye of Vlad)

### Loadout systems (menus + save)
Build order: one equip screen (at benches/save rooms) + slot rules, then the items one by one.
Most items need the combat base (health, meter) first; movement ones can come earlier.

#### Charms (HK): passives, each costs 1-4 notches; 3 notches at start, 11 max
- [ ] Charm system: equip screen, notch budget, overcharm (equip over budget, take double damage)
- Attack:
  - [ ] Quick Slash: faster attacks
  - [ ] Longnail: +reach; Mark of Pride: +more reach
  - [ ] Fragile / Unbreakable Strength: +50% attack damage (fragile breaks on death)
  - [ ] Fury of the Fallen: more damage at 1 health
  - [ ] Heavy Blow: more knockback on enemies; Steady Body: no recoil when hitting
  - [ ] Grubberfly's Elegy: attack fires a beam while at full health
  - [ ] Nailmaster's Glory: charge strikes faster
- Meter and skills:
  - [ ] Soul Catcher / Soul Eater: more meter per hit
  - [ ] Shaman Stone: stronger skills; Spell Twister: skills cost less
  - [ ] Flukenest: forward projectile becomes a spread of small flies
  - [ ] Grubsong: meter when hurt
- Healing:
  - [ ] Quick Focus: heal faster; Deep Focus: heal 2 at once, slower
  - [ ] Shape of Unn: move while healing; Baldur Shell: shield while healing
  - [ ] Spore Shroom: healing releases a damaging cloud
  - [ ] Hiveblood: slowly regenerate 1 health
- Defense and health:
  - [ ] Fragile / Unbreakable Heart: +2 health
  - [ ] Lifeblood Heart (+2), Lifeblood Core (+4): extra blue health that doesn't heal back
  - [ ] Joni's Blessing: more health, all blue, no healing
  - [ ] Stalwart Shell: longer invulnerability after a hit
  - [ ] Thorns of Agony: hurt enemies around you when hit
  - [ ] Defender's Crest: poison cloud around you
  - [ ] Dreamshield: orbiting shield
  - [ ] Carefree Melody: chance to block a hit
- Movement:
  - [ ] Dashmaster: shorter dash cooldown, downward dash
  - [ ] Sprintmaster: faster running
  - [ ] Sharp Shadow: dashing through enemies damages them
- Companions:
  - [ ] Glowing Womb: spend meter to spawn small attackers
  - [ ] Weaversong: three helper spiders
  - [ ] Grimmchild: flying fire companion
- Map and economy:
  - [ ] Wayward Compass: your position on the map
  - [ ] Gathering Swarm: picks up dropped currency
  - [ ] Fragile / Unbreakable Greed: more currency
  - [ ] Dream Wielder: faster Dream Nail
  - [ ] Kingsoul / Void Heart: meter over time, story charm

#### Crests (SS): replace the attack moveset and set the tool slots
- [ ] Crest system: swap at benches; each crest = attack shapes + slot layout
- [ ] Hunter: forward slash, bouncing lunge dash, down stab; 1 slot of each colour (starter)
- [ ] Reaper: heavy slow slash, wide arcing down attack
- [ ] Wanderer: fast short slashes, quick down pogo; 2 yellow + 1 red
- [ ] Beast: scratches up/forward, rolling air spin; 2 red (+2 yellow)
- [ ] Witch: wide slashes in 3 directions, double-swipe dash; 2 red (+3 blue)
- [ ] Architect: drill thrust, stab, charge, diagonal dive; 3 red (+2 blue, +2 yellow)
- [ ] Shaman: beam slashes, projectile dash, down beam; skill slots instead of tools

#### Tools (SS): red = active with limited charges (refill at benches), blue = passive combat, yellow = passive exploration
- [ ] Tool system: slots from the crest, charges, refill at benches
- Red, thrown or shot:
  - [ ] Straight Pin (forward), Threefold Pin (spread of 3), Longpin (heavy, pierces in an arc)
  - [ ] Curveclaw / Curvesickle (arcing throw), Throwing Ring (ricochets), Conchcutter (bounces off walls)
  - [ ] Silkshot (piercing beam), Rosary Cannon (shoots currency), Cogwork Wheel (rolling saw)
- Red, traps and bombs:
  - [ ] Pimpillo (contact bomb), Snare Setter (ground mine), Sting Shard (hanging trap), Tacks (floor spikes)
  - [ ] Voltvessels (lightning column), Delver's Drill (drill down into an enemy)
- Red, buffs and helpers:
  - [ ] Flea Brew (faster for 10 s), Flintslate (more damage for 8 s), Cogfly (flying helper)
  - [ ] Plasmium Phial / Needle Phial (extra health item)
- Blue, attack:
  - [ ] Volt Filament (+damage to skills), Longclaw (+20% reach), Pin Badge (faster charged strike)
  - [ ] Pollip Pouch (poison on hits), Claw Mirror(s) (burst after healing), Quick Sling (throw 2 tools at once)
- Blue, survival:
  - [ ] Fractured Mask (survive one lethal hit), Warding Bell (no damage while healing)
  - [ ] Injector Band (heal faster), Multibinder (heal more), Reserve Bind (one free heal)
  - [ ] Magma Bell (less fire/hazard damage), Wreath of Purity (immunity to one status), Memory Crystal (ice burst when hit)
- Blue, meter:
  - [ ] Spool Extender (bigger meter), Weavelight (meter regen), Druid's Eye(s) (meter when hurt)
  - [ ] Egg of Flealia (cheaper skills at full health), Wispfire Lantern (spends meter near enemies), Sawtooth Circlet (slash on cloak use)
- Yellow, movement:
  - [ ] Ascendant's Grip (wall cling holds longer), Silkspeed Anklets (faster sprint), Scuttlebrace (quick backstep), Weighted Belt (less knockback)
- Yellow, map and economy:
  - [ ] Compass (position on map), Magnetite Brooch (pulls pickups), Shard Pendant / Thief's Mark / Snitch Pick (more currency)
  - [ ] Dead Bug's Purse (keep half currency on death), Shell Satchel (more tool charges)
- Yellow, other:
  - [ ] Barbed Bracelet (+25% damage), Magnetite Dice (chance to block), Spider Strings (wider song range)

#### Familiars (SotN): companions that follow and fight, level up with use
- [ ] Familiar system: one active at a time, follows the player, gains levels
- [ ] Bat: attacks enemies, later fires
- [ ] Ghost: drains health from enemies
- [ ] Faerie: heals and revives
- [ ] Demon: attacks, presses switches
- [ ] Sword: flies and slashes; can be wielded as a weapon at high level

### UI helpers
- [ ] Item drops / damage numbers / enemy names (SotN Cube of Zoe, Spirit Orb, Faerie Scroll)


---

<a id="gdd"></a>

## Source: gdd.txt

Original source: `gdd.txt`. [Evidence directory](../../).

SUMMIT - GAME DESIGN DOCUMENT
=============================
Living document. Updated whenever something important is added or changed;
newest entries at the bottom of the DEVELOPMENT LOG (section 12).
Last update: 2026-10-24


1. CONCEPT
----------
Bethe Knight is a 2D precision platformer with Celeste's movement (a GDScript port of
Celeste's Player.cs) placed inside Metroidvania worlds. Level design studies Hollow
Knight, Hollow Knight: Silksong, Castlevania: Symphony of the Night and Metroid
Zero Mission. It ships with a level editor and a world editor, so content is
built inside the game.

Pillars
- Tight, pixel-exact movement at a fixed 60 Hz, readable and tunable live.
- One connected world: walk off a room's edge into the next, no loading screens.
- Abilities gate the world (Metroid-style); every ability is coded methodically.
- Tools are in the game: map, state machine, tuning, hitboxes, editors.

Platform: Godot 4.7.2 (also tested on 4.4.1). Desktop (Linux) and web
(https://viridjan.github.io/summit/). Repo: github.com/Viridjan/summit (public).


2. CONTROLS
-----------
Keyboard (remappable in Options):
  Arrows move · C/Space jump · X/Shift dash · Z/V grab · A attack
  Esc pause · M map · F1 state machine & tuning · F2 hitboxes
Gamepad (remappable in Options > Controller Buttons):
  D-pad/left stick move · A jump · R1 dash · X attack · R2 grab
  Start pause · Back/Select map · B back in menus
Touch (phones/tablets, shown only on touchscreens):
  Left stick (8 directions) · Jump, Dash, Atk, Grab on the right · Map, Pause top right


3. PLAYER
---------
Hitbox 8x11 px, 8 px tiles. Position = bottom-centre of the hitbox, whole pixels.
Moves: run, variable jump, coyote time, input buffering, wall jump, wall slide,
climb with stamina, climb hop, 8-way dash, super/hyper jump, wavedash, super wall
jump, corner correction, duck, fast fall.

State machine (9 states): Normal, Climb, Dash, Boost, Red Dash, Dream Dash,
Star Fly, and the rest of the Celeste set. Visible live in the F1 panel.

Attack: a LAYER on top of the current state (not a state), so dash-attack,
climb-attack etc. work. Blocked during Boost, Red Dash, Dream Dash.
  - Swing: triangle blade sweeping a 120° arc toward the held direction.
  - ATTACK_TIME 0.143 s (140% speed of the first 0.2 s), cooldown 0.25 s.
  - ATTACK_RANGE 15.4 px (110% of the first 14 px).
  - ATTACK_DIRS / DASH_DIRS limit directions: 0 off, 1 horizontal, -1 vertical,
    2 four-way, 3 eight-way, 4 free aim. Defaults: ATTACK_DIRS 1, DASH_DIRS 3.
  - Each target is hit at most once per swing.

Character: animated sprite with Celeste-style hair whose colour shows dash count.


4. OBJECTS (entity registry in scripts/entities.gd)
--------------------------------------------------
Spikes (4 dirs), springs (3 dirs), dash crystal, double-dash crystal, star
(collectible; replaced the strawberry), jump-through, crumble block, falling
block, zip mover, dream block, green/red bubble, bumper, feather, crystal heart
(goal), dash/climb ability orbs (adventure), note (design reminder text), door
(links rooms that don't touch), water (drains adventure energy; drown at 0), acid (kills), leaf platform (jump-through), waterfall (pushes down), breakable wall
(3 hits, stays broken for the run), enemy/breakable placeholders, spawn markers
(one per entrance; Retry respawns there).
Enemies (docs/ENEMIES.md), 8 original families: Thornmite (crawls floors, walls,
ceilings), Dropwing (ceiling dive), Duskflit (swoop), Ossling (throws bones),
Hornback (warns, then charges), Fuzzbob (bounces diagonally), and the big Cragjaw
(leaps and slams) and Murkspore (spits three orbs); Mosstrot (story jungle) just wanders
and has no variants. The others have 2-4 of these
variants: Swift, Armored, Giant (2x size), Shielded (blocks front hits), Brood
(splits in two), Venom (poison puddles). 32 types.
Adding a new object: docs/ADDING_ENTITIES.md (one class + one registry line).


5. WORLDS AND LEVEL DESIGN
--------------------------
Adventure world: world.json {start, abilities, rooms} + one level file per room.
Rooms are disjoint rectangles on a global tile grid; touching open edges are
passages. Neighbour rooms load seamlessly; collision past an edge checks the
next room's tiles; arrivals are un-stuck automatically.

Shipped adventure (res://adventure/): 14 rooms in 4 areas borrowing from the four
games (docs/WORLD_DESIGN.md): village and well, crossroads hub, dash-orb arena,
vertical shaft, climb vault, castle corridor, clock tower, spire, crown (goal).

Story world (res://worlds/story/, picked in Adventure > World): chapter 1, docs/STORY_DESIGN.md.
  (The Hollow Knight and Metroid reference worlds were removed on 2026-10-24.)
  King's Pass hand-fixed (breakable wall, entrance).

World rules enforced by tools/world_fixups.py:
  1. seal_edges: side/top openings facing nothing or rock become rock.
  2. settle_liquids: water/acid settles like real liquid, wall to wall on every
     row; pools crossing room edges were removed (24).
  3. unblock_acid: acid that would cut off rooms becomes water (13 of 27 kept).
  4. drop_unreachable: rooms not reachable from the start are deleted.
  5. add_spawns: one spawn marker per entrance.
Navigability: every room must allow a 2x2-tile body through one connected area.

Map (M): full-screen, zoom and pan; shows navigable space (blue) vs walls,
pits (death) vs holes (lead to another room), explored rooms.


6. EDITORS AND DEV TOOLS (all in-game)
--------------------------------------
Level editor: paint tiles, place/size objects, notes, undo, playtest (F5);
asks before leaving with unsaved changes. New/Load always save as custom
levels, never over the world room the editor was opened on.
World editor: drag rooms on the grid, add empty/copied rooms, edit a room,
playtest from a room, set start; door links shown as cyan lines.
F1 debug panel: live state machine (with Attack layer row), transitions log,
live variables, every movement variable editable; presets saved to
user://tuning/, export to res://config/tuning.cfg; Pause sim / Step; Hitboxes.
Monsters page (main menu, and the map screen's second tab): every enemy kind
with its Swift/Armored variants, animated sprite and HP, read from the entity
registry. Map screen tabs: Map (always opens first, Select / M) and Monsters;
L1 / R1 (Q / E) switch.
F2 / Options > Show Hitboxes: player (green), sword arc (red), objects
(yellow), touch/hazard areas (orange).
Reports: reports/hk-room-safety.md (transition/bounds checker, 0 findings),
hk-accessibility, hk-enemy-placements.


7. PRESENTATION
---------------
Art: Paper Pixels (VEXED, CC0) + original pixel art for enemies.
Camera: 1280x720 window, zoom 4.8 (120%) = 267x150 game pixels visible.
Screen shake (toggle), snow particles, background parallax.
Options: fullscreen, vsync, shake, assist mode (game speed, infinite stamina,
air dashes, invincibility), keyboard and controller remapping.


8. PROGRESSION AND SAVE
-----------------------
Start without dash and climb; orbs unlock them. Save: user://save.cfg
[adventure]; settings: user://settings.cfg; levels: user://levels/.
In the browser, saves live in browser storage; editors can't write game files.
Old or hand-edited saves load: missing fields are filled from a fresh run.


9. TECH NOTES
-------------
Fixed 60 Hz physics, pixel-based movement. Rendering culls offscreen objects
but keeps them simulating. Tile chunks, incremental editor previews
(OPTIMIZATION_RESULTS.md). Web: Godot web export without threads, deployed by
GitHub Actions (.github/workflows/pages.yml) on every push to main.
Tests: tests/test.tscn and tests/smoke.tscn (exit code = failures), plus
tests/test_world_accessibility.py; CI runs all three before every web deploy.
Code-health audit, optimization and future-feature strategy: docs/CODE_HEALTH.md.


10. PLANNED (see TODO.md)
------------------------
- Power-ups from the four reference games (grouped by game). Dropped: Space Jump,
  Screw Attack, SotN bat/wolf/mist forms, Dreamgate, Morph Ball.
- Health/hurt state, event flags, map stations, save slots (docs/METROID_NOTES.md).
- Replace placeholder rooms with real ones.


11. OPEN QUESTIONS
------------------
- Touch controls: layout and comfort not yet tried on a real phone.
- Zoom 4.8 is not a whole number: some game pixels show 4 px wide, some 5.
  125% (zoom 5) would keep them even.


12. DEVELOPMENT LOG
-------------------
Phase 1 - Core game
- Celeste movement port, level editor, menus, options, remapping.
- Performance pass: benchmarks, culling, tile chunks, editor batching.
- In-game state machine view + editable variables with presets and config file.
- In-game map. Strawberry replaced by a star. Entity registry for new objects.

Phase 2 - Adventure
- Adventure mode, then a Metroid-style connected world with a world editor.
- Character animation and hair, stamina; UI fixes; F1 panel transparency.
- Note object for design reminders; level design study of HK/Silksong/SotN/MZM.

Phase 3 - Reference worlds
- Recreated the four games' global maps, fixed scale, doors between rooms.
- Hollow Knight focus: enemies, spikes, water/acid, breakables as placeholders.
- 2x scale, no overlaps, fewer disconnected rooms, merged maps, no thin strips.
- 2026-10-21: public GitHub repo "summit" (graphify-out excluded).

Phase 4 - Combat and safety (2026-10-21)
- Attack with 120° triangle swing; breakable wall; DASH_DIRS/ATTACK_DIRS.
- Seamless neighbour-room loading; 2x2 navigability, one connected area/room.
- Acid/spike accessibility fixes; pit vs hole markers; entrance spawns + Retry.
- Map shows navigable space vs walls.
- Room-safety checker findings fixed (edge collision, door arrival, ceilings).
- Web build on GitHub Pages.
- Attack became a layer over states; liquids settle wall to wall; unreachable
  rooms removed; attack speed 140%.

Phase 5 - Input and tooling (2026-10-21/22)
- Controller defaults R1 dash, X attack, R2 grab; Controller Buttons page.
- Hitbox overlay (F1 button, Options, F2 key); sword range +10%.
- Five original enemies placed in the HK world (Ripper, Skree, Bat, Skeleton, Medusa).
- Touch controls for phones; camera zoom 120%.
- TODO: power-up list from all four games.
- This GDD created.
- 2026-10-22: dropped from the power-up plan: Space Jump, Screw Attack,
  bat/wolf/mist forms, Dreamgate.
- 2026-10-22: TODO power-ups regrouped by scope (jumps, dashes, liquids, gates,
  combat base, melee, projectiles, capacity, loadouts) instead of by game.
- 2026-10-22: Morph Ball dropped from the power-up plan.
- 2026-10-22: music doors (Needolin) dropped; hidden wall added to the plan.
- 2026-10-22: direction upgrades for dash and attack added to the plan
  (pickups stepping DASH_DIRS / ATTACK_DIRS up: horizontal, four-way, eight-way, free aim).
- 2026-10-22: Sylphsong, Beastling Call, Elegy of the Deep dropped from the plan.
- 2026-10-22: loadout systems expanded in TODO: all HK charms by effect,
  SS crests and tools by colour, SotN familiars.
- 2026-10-22: code-health audit (docs/CODE_HEALTH.md). Smoke test can fail now,
  CI runs the tests. Fixed: free-aim super jumps, red bubble aim, climbing walls
  on a room seam, restart/door/camera/save/editor bugs.
- 2026-10-22: Monsters page in the main menu and as a map-screen tab (L1/R1).
- 2026-10-22: Ripper and Medusa removed; Thornmite, Hornback and Fuzzbob added
  (Hollow Knight-inspired); all enemies renamed to original names.
- 2026-10-22: Cragjaw and Murkspore (big families); Giant, Shielded, Brood and Venom
  variants, 2-4 per family; enemy atlas cells grew to 32px.
- 2026-10-24: story world chapter 1 designed (docs/STORY_DESIGN.md): route, Ape boss,
  energy as health (blocks of 100), NPCs, positional audio, skill points; tasks in TODO.md.
- 2026-10-24: energy (adventure): 100 per block, start with 1, regen 3/s inside the current block,
  a hit costs a block (hazard respawn), last block = death. Attack is now an adventure ability.
- 2026-10-24: Silksong (Pharloom) and Symphony of the Night (Dracula's Castle) reference worlds removed.
- 2026-10-24: story Lake Cave gets 4 neighbour rooms: Roar Tunnel (left), Cave Teeth + Cove Tunnel (right),
  Deep Lake (below, back up via jump-throughs); Cove Town moved right. House doors are a TODO.
- 2026-10-24: story jungle: forest theme, leaf platforms, waterfall blocks, Mosstrot (calm wanderer, 9th
  enemy family, 3 also in HK). Rooms Jungle Edge, Jungle Falls, Jungle Hills; bot runs meadow -> jungle end.
- 2026-10-24: water drains adventure energy (0.5/s, no regen in water); 0 energy in water = death.
- 2026-10-24: backgrounds no longer jump: the parallax shift follows the camera's place in the room,
  bounded by the 10% overscan (EnvironmentArt.parallax_shift), instead of wrapping.
- 2026-10-24: room transitions: the old room's objects stay drawn until the camera has left it; each themed
  room's background is pinned to its room and slides in/out with it. Hazards and enemies hit a box 20%
  smaller than the hurtbox (Player.damage_rect; pickups keep the full one). Exit-time texture leak warnings
  fixed (art caches cleared on quit; no const preloads of cached scripts in the Game autoload).
- 2026-10-24: story rooms past the jungle: Ape Arena, the right branch (Sand Cave, Shore, Lighthouse Top)
  and the left branch (Jungle Depths, Net Trap, Treetop Village); 18 rooms, all reachable with jump only.
  tools/world_check.py now follows doors.
- 2026-10-24: player environment layers (Player._layers, on top of any state): underwater (buoyancy,
  drag, swim stroke, bubbles; water draws over the player) and waterfall (pushed down, can't rise).
  Lake Cave's water now fills the hole, Deep Lake and the shaft. Down + jump drops through jump-throughs.
  Pickups and platforms touch exactly what they draw (tools/check_hitboxes.tscn checks it).
- 2026-10-24: water drains energy 10x faster: 5/s (0.5 every 0.1 s).
- 2026-10-24: the debug panel's state machine view lists the layers (Attack, Underwater, Waterfall), lit
  while active; the live state reads e.g. "Normal + Waterfall". Touch controls always let go of a
  released finger, even while hidden.
- 2026-10-24: underwater is now a state, Normal (Underwater), replacing Normal in water: no walking on the
  floor, no normal jump; Jumping (Underwater) is a weaker stroke (~14 px vs ~29 px), a full jump out when
  the surface is within 12 px. Waterfall stays a layer.
- 2026-10-24: underwater, the floor no longer stops the player: along it they move as mid-water (air poses).
- 2026-10-24: water drain doubled (10/s); waterfalls pull down (600 px/s² towards 70 px/s) instead of pinning.
- 2026-10-24: underwater jump has no cooldown: every press is a stroke.
- 2026-10-24: water drain doubled again: 20/s (2 every 0.1 s).
- 2026-10-24: HUD: bolt + one bar per energy block (top left, stars below), area name (top centre),
  timer and skull + deaths (top right). Drawn by World.Hud.
- 2026-10-24: each jump costs 10 adventure energy (never blocks it; wall jumps and swim strokes are free).
- 2026-10-24: the death counter counts every respawn (spare-block hits too).
- 2026-10-24: Boss 1, the Ape (entities.gd Ape/ApeTrunk/BossGate): throw far, leap past the player mid,
  scream near; a stone fells the trunk into a bridge; 3 spike landings beat it; gates open, exhaustion.
- 2026-10-24: no energy, no jump (adventure); water drain 16/s (1.6 every 0.1 s).
- 2026-10-24: jump costs 5 energy (was 10).
- 2026-10-24: the Ape's landing slams the ground: a 0.2 s shockwave 2 units out on both sides.
- 2026-10-24: hitbox overlay (F2) draws damage boxes in red (Ent.damage_boxes: stones, scream, slam,
  bones, orbs, puddles) and the player's damage box in pink.
- 2026-10-24: energy base 50, always regenerating; blocks add 100. A jump needs its 5 energy.
- 2026-10-24: energy regenerates 6/s (was 3).
- 2026-10-24: hitbox overlay lines are 1 screen pixel; a colour legend shows bottom right while it's on.
- 2026-10-24: Ape arena: meet the Ape first; past the tree its stone or leap fells it into the bridge; it follows
  you across for the spike phase. Ape leaps keep sub-pixel motion.
- 2026-10-24 (Codex): Nori's coordinated motion pass: four-row run cycle (hips, bent legs, sleeve swing,
  down-step compression), authored jump/apex/fall poses; height and gameplay unchanged (assets/nori/README.md).
- 2026-10-24 (Codex): Ape contact uses body bands (Ape.body_boxes, 70% of the sprite) so empty corners don't hurt;
  the scream is a circle (scream_hits); the hitbox overlay draws body bands and damage circles
  (docs/ADDING_ENTITIES.md "Contoured and circular damage areas").
- 2026-10-24: Lake Cave's in-editor edits (stepping blocks above the lake) restored after a regeneration
  overwrote them; tools/story/gen_first_stretch.py now rewrites only the rooms named (or "all").
- 2026-10-24: water drain +30%: 20.8/s (2.08 every 0.1 s).
- 2026-10-24: an energy block adds 75 (was 100); hits still cost 100 (Adventure.HIT_ENERGY).
- 2026-10-24: Ape arena 56 wide; auto_walk carries the player in, the entrance boss_gate closes behind
  (closes_behind); s1/s2/s3 shifted 24 tiles left.
- 2026-10-24: Ape contact hitbox is one centred 24x24 rectangle (replaces the 22px body bands).
- 2026-10-24: room changes: crossing sideways walks the player 1 unit in (middle of tile column 2),
  where the entrance spawn is and where they respawn. Entrances must be flat for 2 tiles
  (tools/check_entrances.py; story world 0). Cove Town's sea ends a tile earlier.
- 2026-10-24: Hallownest (Hollow Knight) and Zebes (Metroid ZM) reference worlds removed, with their builder
  (tools/reference_worlds.py), the HK enemy placer, the room-safety probes and the hk-* reports. Worlds now:
  the main adventure and the story world.
- 2026-10-24: room-safety probes, side-opening check and summary ported to the story world (they defaulted to HK);
  no escapes found; 7 harmless side openings (Lighthouse Top's sky edges, 3 facing rock). Reports: reports/story-*.
- 2026-10-24: house doors (house_door): a visible wooden door, up at it to go through (same id/to links as
  Door; Entities.DOOR_TYPES). Cove Town's two houses lead to interiors h1_villager_house and h2_quest_house.
- 2026-10-24: lighthouse: solid tower with a house door, inside room lh1_lighthouse_stairs (zigzag climb), door out to the top.
- 2026-10-24: energy base 35 (was 50); a block adds 25 (was 75), so one upgrade = 60. Hits still cost 100: any hit at 60 or less is a death.
- 2026-10-24: Assist Mode moved out of Options to its own page, opened in game with F12 (rebindable action "assist"); it pauses the game, Esc/F12/Back resumes.
- 2026-10-24: energy base 25 (was 35); a block adds 35, so one upgrade is still 60.
- 2026-10-24: music muffles (low-pass 600 Hz on its own "Music" bus) while paused, in Assist Mode or on the map.
- 2026-10-24: an energy block adds 20 (base 25, so one upgrade = 45).
- 2026-10-24: buildings with a door are backdrops (entity "building", style house/tower; never collides): Cove Town houses, the lighthouse on the shore and its top.
- 2026-10-24: house doors use a new "interact" action (keyboard S, pad B), not up.
- 2026-10-24: all music plays 25% slower and two whole tones lower (MusicEngine.TEMPO_SCALE / TRANSPOSE, applied at playback).
- 2026-10-24: Options → Audio: Music and Sound Effects volume sliders (0-100%, both default 100%). Effects play at 20% of their synthesized level, so 100% in Options is that.
- 2026-10-24: music another 20% slower: TEMPO_SCALE 0.6 (60% of written tempo).
- 2026-10-24: Sand Cave 120 wide (was 80): same 30-row climb as 15 two-tile steps (~14 deg), spike pits, crumble bridges,
  a low-ceiling hop. The beaten Ape chases the player up it (entity ape_chase: follows the player's path at 75 px/s,
  wakes past "trigger", gives up for the run at "end"). Shore and Lighthouse Top moved 40 tiles right.
- 2026-10-24: HUD energy bars drawn twice as long (0.92 px per energy).
- 2026-10-24: energy bar colour follows energy / max: red empty, yellow at half, mint full (was orange under 30).
- 2026-10-24: hair turns grey below 20% energy (adventure), same grey as a spent dash.
- 2026-10-24: floor-walking enemies walk until their box's edge lines up with the end of the floor before turning (CombatEnemy.walk, pixel by pixel; was turning while still overhanging up to almost the whole box).
- 2026-10-24: main menu: "Level Editor" replaced by "World Editor" (moved out of the Adventure menu; source runs only). Rooms are still edited in the level editor via World Editor → Edit room.
- 2026-10-24: main menu: "Custom Levels" removed (level list, play/edit/delete).
- 2026-10-24: Ape sounds: "ape_scream" (harsh shriek, the boss fight now opens with it) and "ape_scream_cave" (same with dark left/right cave echoes, the Sand Cave chase).
- 2026-10-24: the Sand Cave Ape moves by the player's rules: a copy of the player's movement code (ChaseRunner) with
  AI input (run at the player, jump 12 px before walls and at gaps), through a stand-in world (ChaseWorld) that only
  forwards collision: no energy cost, no player sounds, can't die. Replaces the path-following version.
- 2026-10-24: Ape scream five whole tones lower.
- 2026-10-24: Sand Cave Ape only replays one planned run: when the chase starts, ApeChase.plan() simulates the player's
  movement running right and tries take-off distances (px before a wall / past a gap's edge) until a run reaches the
  end without touching spikes; the Ape follows that run frame by frame (cached per room). Sand Cave pits moved so each
  starts 3 tiles after a step (the jump up a step carried straight into the pit).
- 2026-10-24: stretch aspect "expand": on phones the touch controls sit at the real screen edges (TouchControls.at keeps each one's distance to the nearest edges); the world keeps its 1280x720 view centred with black bars (World.Letterbox).
- 2026-10-24: the Sand Cave Ape's planned path never touches breakable blocks (crumble/breakable walls are empty to the planner, which also rejects any run whose box touches one; breakables get their own take-off margin). Crumble bridges now 3 wide with 3 tiles of run-up (26-28, 79-81).
- 2026-10-24: more platforming in every room on the route. Meadow: harmless (no spikes; dips you can hop out of,
  ledges, an arch with a star, a 3-high block). New room m3_the_hole: the Big Jump's gap now drops a whole extra
  screen (46 rows, was 23) before the Lake Cave; every room below moved down 23 rows. Harm starts past the hole:
  spike/thorn pits (3 wide, 3 tiles of run-up) in Lake Cave, Cave Teeth, Cove Tunnel, Jungle Edge/Falls/Hills,
  Shore, Jungle Depths and Net Trap; leaf hops over the jungle lakes; stepping stones on the shore.
  Tests: the hold-right story bot checks the route (invincible); the Ape planner proves a spike-free run with plain
  jumps across Meadow, Cave Teeth, Cove Tunnel, Jungle Edge, Jungle Hills and Shore.
- 2026-10-24: buildings always draw first (behind doors), whatever their order in the level file.
- 2026-10-24: Story is the default adventure world (first in the menu picker; settings world "" = story). Bethe Knight is second.
- 2026-10-25: Godot keeps 30 log files (tests were rotating play logs away).
- 2026-10-25: Codex review fixes: Ape chase plan cache keys on all planner inputs (world, room, level data, tuning, endpoint), capped at 16; malformed saves normalized (finite spawn, blocks >= 1, energy clamped, int/float accepted); Ape run animation is a coherent 4-frame loop; tuning preset list ok on fresh install; bench compiles again; SFX synthesized at boot. tools/verify.sh runs every suite and fails on engine errors, not just exit codes.
- 2026-10-25: Sand Cave low ceiling removed; ApeChase planner now also keeps the Ape's 24px body out of terrain (longer wall run-ups 22-34px). Ape screams and chase rules documented in STORY_DESIGN.
- 2026-10-25: Sand Cave low ceiling back as breakable rock (breakwall over cols 55-59): player short-hops under it, the chasing Ape smashes it (not saved). Planner may pass through breakable walls, never stand on them.
- 2026-10-25: Sand Cave: Ape blinks hurt when it smashes rock; at the last step a cave-in (ape_chase 'seal' rect, a resting falling block) drops behind the player and stays for the run. Spawned entities now register as solids too (World._register).
- 2026-10-25: Removed solved design notes: Ape arena (fight hint, lure onto spikes, left branch) and Sand Cave (chase, cave-in).
- 2026-10-25: Ape arena: Ape HP 4; each spike hit crumbles the spikes in its range and the next patch appears on the other side (20-22, then 46-48, then 8-9 + 26-27); two jump-through platforms (18-21 and 33-36, row 16).
- 2026-10-25: Door prompt is the interact button sprite, not a triangle. scripts/button_art.gd generates keycaps (3x5 pixel font, arrows) and pad buttons (Xbox-coloured A/B/X/Y, LB/RB/LT/RT, ST/BK, d-pad); Game.using_pad tracks the last device used.
- 2026-10-25: Sand Cave chase: kill line instead of body contact (Ape centre past player centre = death, any height); 5 hanging breakwall chunks (32,47,62,70,85) + low ceiling hurt the Ape; landings drop cosmetic debris; the Ape triggers the cave-in itself on reaching end (99*T), seal at cols 102-103.
- 2026-10-25: Perf pass (measured): story rooms run 35-75 us/tick physics, room change ~2 ms. Ape chase planner 76 -> 27 ms (long run-ups tried first) and runs on the room's first tick, not at the trigger.
- 2026-10-25: Ape chase planner has a 150 ms budget (0 = unlimited for offline proofs); with no route the Ape screams and leaves (not saved). Cave-in rock drawn with breakable-rock art (falling block d.art). Jungle Depths note plays ape_scream.
- 2026-10-25: Fixes: chase planner sliced over frames (ChasePlan, 3 ms/frame, worst frame 27 -> 3 ms); PlayStation prompts (Game.pad_ps by joy name); collision indexes (fixed solids + jump-throughs by 64px column, touchables by type): dense bench 3.5 -> 1.3 ms, normal 368 -> 233 us; player_touch/player_riding cheap rejects; Level Complete leaked a Button (smoke leaks 128 -> 1); smoke fails on orphan nodes.
- 2026-10-25: Game.quit_game(): menu Quit, window close and test runners stop all sound, free the music engine and wait 0.1+0.25 s so audio playbacks are released; roar test reads PCM once. Exit leak warnings: 0 in every runner.
- 2026-10-25: Energy block +10 (was +20). F3 energy panel (scripts/energy_panel.gd): live energy/max/blocks, current rate and cause, all gain/loss rules, 10 s graph with block lines, last changes logged by World.energy_event (jump, hit, death refill, block, orb, Ape).
- 2026-10-25: A hit is always a death and never touches energy (HIT_ENERGY/hit_energy removed; no refill on death). Beating the Ape no longer drains energy.
- 2026-10-25: Roar Tunnel roar at 200% (sfx GAIN per sound, applied as voice volume).
- 2026-10-25: Ape throws from 96 px (was 140): scream <= 44, leap 44-96, throw > 96, wakes < 220 (centre-to-centre horizontal).
- 2026-10-25: Ape arena: 4 asymmetric solid platforms (29-32 r16, 34-36 r13, 38-41 r15, 10-12 r14), wall spikes (left r5-8, right r4-8). After the fight a death keeps the spikes as left (World.kept_spikes) and the orb. Conditional rooms: world.json "variants" {room: [{when: run flag, room: file}]}; a beaten Ape's arena re-enters as a1_ape_arena_after (base terrain + spawns, variant objects). World editor keeps variants on save.
- 2026-10-25: Ape range is the whole arena (cols 1-55, exit ledges included); its spike hits clear only floor spikes (wall spikes stay). Test: 600 leaps land on floor, ledges and all platforms, cols 3-52, never stuck or inside rock.
- 2026-10-25: Fundamental rule (WORLD_DESIGN.md): respawn points are never in a hazard (World.safe_spawn: no water/acid/spikes, on ground). A room with no safe point (Deep Lake) keeps the last safe respawn, even in the previous room; death returns there; the save keeps it.
- 2026-10-25: Ape arena walk-in works on every entry: AutoWalk takes over from the room-change walk-in (which cancelled it when entering sideways).
- 2026-10-25: Ape throws from 72 px (was 96): scream <= 44, leap 44-72, throw > 72.
- 2026-10-25: Ape throws from 72 px. Kept user's World Editor arena edits (only platform 10-12 r14, block r11 cols 49-50 making the right exit ledge Ape-free, note removed) and Lighthouse Stairs at (618,-14); generator updated to match. Arena coverage test reads surfaces from the layout.
- 2026-10-25: Render interpolation: physics stays 60 Hz; each displayed frame draws the camera and the player between their last two ticks (World._process, Player.draw_off). Fixes the judder/blur on 120-165 Hz screens; room changes rebase it, doors/respawns snap.
- 2026-10-25: Music without the SiON synth (web, non-Linux): the engine plays baked recordings (assets/music/*.wav, QOA-compressed on import, looping) made by tools/bake_music.gd (rerun after changing scores/tempo/instruments). SiON classes are reached by name so the script loads without the add-on. Studio edits only sound with the synth.
- 2026-10-25: F2 hitbox overlay shows the Ape's attack ranges (scream <= 44, leap <= 72, throw beyond, wakes within 220).
- 2026-10-25: Ape attack choice is radial (straight-line centre distance, not horizontal): scream <= 44, leap 44-96, throw > 96 (throw distance back to 96), wakes within 220. F2 overlay draws circles.
- 2026-10-25: Ape always leaps when the player is above or below it (vertical gap > horizontal gap); F2 overlay draws the two diagonals.
- 2026-10-25: Removed the Bethe Knight world (res://adventure/) and the menu's world picker; the story is the only world. Saves use run_story.
- 2026-10-25: Respawn refills the base energy bar (25); extra blocks keep their energy. World.respawn().
- 2026-10-25: Ape arena 39 tiles wide (30% narrower); Sand Cave, Shore, Lighthouse rooms moved 17 tiles left. Ape idle waits x0.85, slam reach 16 -> 24 px. Enraged from 2 hits: stones split in two on landing, landings drop 2 logs from the ceiling, scream followed by 2 hops in place (shockwave 125%, then 150% wide).
- 2026-10-25: Energy: base 25 -> 20, jump cost 5 -> 2.5.
- 2026-10-25: Ape arena exit ledges removed (user's World Editor edit kept, generator matches; small 2-tile stairs under both doorways so they stay jump-reachable). Enraged logs: one pair per real leap (not the hops), 0.5 s apart. Spike hits break only the spikes the Ape landed on.
- 2026-10-25: Enraged Ape logs fall at random spots across the whole arena range, never overlapping.
- 2026-10-25: Ape arena emptied by the user (no ledges/platforms/starting spikes/walk-in; check_entrances DROP_IN). Every leap drops 1 log at a random spot; a log leaves a 1-tile spike where it breaks; spikes are never auto-generated, landing on them hurts the Ape and breaks them. Slam 60 px wide (-25%), enraged hops 130%/170%.
- 2026-10-25: The way down to the left branch moved from the Ape arena floor to Jungle Hills (cols 48-51, before the arena); Jungle Depths and Net Trap moved 44 tiles left to stay under it. Arena has no floor hole or hole gate.
- 2026-10-25: The Ape's hops in place drop a log each too (every landing drops one).
- 2026-10-25: Ape arena 20% narrower: 31 tiles; Sand Cave, Shore, Lighthouse rooms moved 8 more tiles left.
- 2026-10-25: Level saves write whole numbers as ints (Game.whole_numbers; world_fixups reads 8.0 as 8): world data is in whole units.
- 2026-10-25: Eastern island built (blockout, tools/story/gen_island.py): 13 rooms east of the Shore, raft door from the Shore beach, jump-only (tests/test_island.py; world_check models down+jump drop-through). Guardian boss: erupts under the player, bait 3 vent plugs; victory saves, opens the gate, door home + after-variants for the chamber and island shore. Shore stepping stones and notes removed (user's World Editor edit kept).
- 2026-10-25: Ape logs fall slower (gravity 200, max 140 px/s) and their hitbox is 20% smaller (19x6).
- 2026-10-25: Spike hitboxes 7 px along the tile (10% less than 8, whole pixels); art unchanged.
- 2026-10-25: Rooms smaller than the view: centred (as before) with a black mask around them; it fades in once the camera settles and drops when the next room is entered (World.RoomMask).
- 2026-10-25: Island reorganized into 17 smaller rooms: West/North/South/East shores, Foothills, Ascent, Crater, East Slope, Sea Cave, Junction, Flooded Hall (water + falling rocks, new `rockfall` entity), Echo Gallery, Lower Maze, Vent Shaft, Refuge, Guardian Chamber, Crystal Pocket. Raft lands on the West Shore.
- 2026-10-25: Ape arena left exit at floor level (the high doorway is closed; Jungle Hills' right ledge lowered). The hole to Jungle Depths is covered (boss_gate "until") until the Ape is beaten; then leaving the arena left, the Ape chases leftward (ApeChase dir -1, after) and stops at the big trunk.
- 2026-10-25: F3 energy panel gets a recap: per cause, how often (or how long) and how much energy since the level started, plus total spent/gained.
- 2026-10-25: Fix: F3 energy panel was placed off-screen (position instead of top-right offsets).
- 2026-10-25: All energy values doubled (whole numbers): base 40, block +20, regen 12/s, water 41.6/s, jump 5; HUD bar 0.46 px per energy (same look).
- 2026-10-25: Wall jumps (and super wall jumps) cost a jump's energy (5) and need it; climb jumps already did.
- 2026-10-25: Ape attacks: a stone throw at random on 20% of attacks; otherwise distance picks scream (<= 44 px) or leap. No scream when the player is cornered against a wall the scream would fully reach (it leaps). Idle waits 10% shorter (x0.765 overall).
- 2026-10-25: Energy renamed stamina everywhere (code, level types stamina_block / stamina_orb, F3 stamina_panel, action stamina_debug; old saves' "energy" read as stamina). Regen = k x 12/s with k 0.5 empty -> 1 at half -> 0.75 full. Water drain 40/s. Climbing merged into the stamina bar in the adventure (a full base bar = a full climb meter; no regen on the wall; ground/crystal climb refills don't fill it); editor levels keep the separate climb meter.
- 2026-10-25: Stamina regen factor more aggressive: 0.2 empty -> 1 at half -> 0.5 full.
- 2026-10-25: Stamina regen by fill: 3/s empty -> 12/s at half -> 4/s full (STAMINA_REGEN_EMPTY / _MAX / _FULL).
- 2026-10-25: Stamina HUD bar twice as wide (0.92 px per stamina; graphics only).
- 2026-10-25: Debug tools split: F1 movement tuning, F4 state machine + live variables (new), F3 stamina, F2 hitboxes. The pause menu lost "Tuning & State"; its top right has Tuning / State / Stamina buttons.
- 2026-10-26: Monsters tab on the map screen (M, Q/E) tracks the run: monsters are found once on screen (run.seen), unknown ones show as ???, kills counted per type (run.kills), with Found X/Y and total kills. Main menu Monsters still shows everything.
- 2026-10-26: Removed the red 'tired' flash (it fired at low stamina once climbing shared the bar). F2 overlay mouse-over: legend rows explain each kind of box; pointing at the player or an object shows what it is and its current state (Ent.describe; per-phase help for enemies, Ape, Guardian; player from the state help).
- 2026-10-26: Level editor palette grouped into foldable sections (Terrain, Hazards, Movement incl. dream blocks, zip movers and water, Pickups, Doors & people, Enemies & bosses sorted by family, Placeholders: placeholder boxes and notes); Terrain open by default.
- 2026-10-26: Editor palette: Leaf Platform sits right after Jump-Through (same behaviour, different art). Codex art prompt for both: docs/reviews/platform-art/CODEX_PROMPT.md.
- 2026-10-26: Main menu Art screen (scripts/art_gallery.gd): every PNG in assets/ by folder (one section per theme; review shots skipped) plus the Ape's poses; sprites at true size, full-screen backdrops (background, foreground, preview, contact sheet) at 30%; name and size under each.
- 2026-10-26: Image cleanup to one standard (assets/README.md): one sheet per subject + manifest.json per folder. blocks: 40 single files -> one sheet per style; enemies: one sheet per family (enemies.png/new-families.png gone); nori run-poses.png dropped (it is row 2 of nori.png); themes contact sheet dropped; theme review shots moved to docs/reviews/themes-before/.
- 2026-10-27: Art screen cuts every sheet into its single sprites at true size (cells from each folder's manifest.json or known layouts), one row per pose/variant, empty cells skipped, sized in physical pixels (the UI scale is divided out, so nothing is stretched); backdrops whole at 30%. Ape export gains the land pose (7 rows); the separate code-drawn Ape section is gone (ape.png is in Enemies).
- 2026-10-27: Room entry reveal: the new room starts black and a soft black-to-clear edge (48 px gradient) sweeps from the entry side to the far side paced by the camera sliding in (at least 0.4 s; doors: from the player along the room's longer side). World.reveal_t / _draw_reveal. Fix: the small-room black frame only covers the axes where the room is smaller than the view (it hid the old room during sideways slides).
- 2026-10-27: Room transition as one wave of darkness moving with the player: the room left darkens from its far side towards the new room while the new room clears from the entry side onwards; both edges soft (96 px gradient), paced by the camera (World._sweep/_band). Doors: only the new room's reveal.
- 2026-10-27: Room transition timeline (same edge and pace both sides): the room left darkens towards the new one in 0.35 s, all black for 0.2 s, then the new room clears from the entry side in 0.35 s (smoothstep); time-based (REVEAL_OUT/HOLD/IN).
- 2026-10-27: Room transition fades 0.5 s each side (0.5 out, 0.2 black, 0.5 in).
- 2026-10-27: Fix: a closes-behind boss gate shuts as soon as the player is fully past it (was 4 px further), so respawning at the Ape arena's left spawn (next to the gate) no longer leaves the way out open. Same for the Guardian chamber.
- 2026-10-27: Room transition also blacks out the other preloaded rooms on screen (fades with the darkening, black during the hold, back with the clearing): World._outside_black.
- 2026-10-27: Room transition no longer slides the view: it holds on the room being left while it darkens, cuts to the new room in the middle of the black hold, then the new room clears in place (World.reveal_cut).
- 2026-10-27: Freefall rooms (nowhere to stand: no floor tile, no jump-through; in the story only The Hole) skip the transition fade when entering or leaving them; the view follows the fall (World.freefall).
- 2026-10-27: Camera Zone (editor group Triggers): while the player is inside, the view stays fixed on its focus point (default: the zone's centre), kept inside the room; leaving it eases back to following (World.cam_goal).
- 2026-10-28: Regions (the term from now on, for groups of rooms): 10 named, coloured regions in worlds/story/world.json, grouped by background (Meadow, Lake Caves, Cove Town, Jungle, Treetop Village, Sand Cave, Lighthouse Coast, Island Shores, Volcano, Volcanic Maze). Map screen and World Editor tint rooms by region and print region names. Adventure.region_of; save_world keeps them. Lake Cave landing has a fixed-camera zone (end of the first descent).
- 2026-10-28: Lake Caves rewritten (gen_first_stretch section 3): one tunnel never more than 4 tiles tall, floor unchanged; lake crossed on stepping stones (3-tile gaps: a jump rises ~2 under a 4-tile roof), a gap drops into the Deep Lake (4-tall tunnel with three pools, the star, a jump-through ladder back up); Cave Teeth pinch the roof to 3; spike pits kept; Codex's trims re-applied (refine_regions). Lake Cave's camera zone kept. Lesson: world_fixups deletes rooms it can't reach - dry-run world rewrites on a copy first.
- 2026-10-28: Lake Caves made a maze on three 4-tall levels (main, upper, Deep Lake): Roar Tunnel upper side loop with a star; Lake Cave's main tunnel walled after the lake, so the way on is down into the Deep Lake and up its ladder; Cave Teeth walled, so up into the upper tunnel (spike pits, roof spikes) and back down; Cove Tunnel water pit bridged by a crumble block, roof spikes over flat floor. Ladders = jump-throughs 3 rows apart.
- 2026-10-28: Leaf Platform merged into Jump-Through: one type whose look follows the room's environment (d.look overrides; forest = leaves). Old "leaf" data converts on load; the 16 story leaf platforms and the generator now write jumpthru + look "forest". Editor palette: water and acid in Terrain. Codex prompt for one jump-through per environment: docs/reviews/platform-art/CODEX_PROMPT.md.
- 2026-10-28: Editor palette: Enemies & bosses split into foldable subgroups per enemy family, then Ape, Guardian and Boss arena (gates, walk-in).
- 2026-10-28: Touching water (and acid) pools draw as one: each pool draws its surface line only where no pool of the same liquid sits right above it (game and editor preview); the old manual top:false flag still works.
- 2026-10-28: World Editor: double click a room to edit it. Room editor: Esc goes back (to the World Editor or menu); with unsaved edits it asks Save / Don't save / Cancel (the World button uses the same question).
- 2026-10-28: Touching blocks of one kind draw as one: breakable walls, crumble blocks and jump-through rails skip their frame on sides touching another (BlockArt joins, Ent.joins; a broken piece gives its neighbour its edge back); lava acid shows its glowing top only where nothing is above. Falling/zip blocks stay separate (they move); dream blocks not yet.
- 2026-10-28: Pushing against a wall on the ground shows idle, not the walk animation (Player._animation). Kept the user's World Editor edits: Lake Cave's wall after the lake is now a stepped stack of breakable walls; the Deep Lake reshaped (12 rows).
- 2026-10-28: Fix: blocks of the room being left (drawn during the transition) stayed joined: Ent.peers() uses the leaving room's objects while they're drawn (Ent.draw_peers).
- 2026-10-28: Lake Cave split into three one-screen rooms from the user's latest edit: Lake Cave (cols 0-29, the landing), Lake Crossing (30-57, the lake; its doorways open onto water by design: check_entrances DROP_IN), Wall Cave (58-79, the breakable wall and the ladder). All in the Lake Caves region; Lake Cave's camera zone removed; generator mirrors the split. Only edge sealing and spawns were re-run (world_fixups' water rule would have deleted the user's hand-shaped pools; the wall-to-wall water test skips the lake rooms).
- 2026-10-28: The fade only plays when moving into another region; rooms of one region join with the normal follow camera. Order now: darken, cut, clear, then a 0.2 s wait with the player held still.
- 2026-10-28: Fix: the chasing Ape left at once on slower runtimes (web, Steam Deck): planning the Sand Cave route takes ~90 ms natively, over the 150 ms budget when scripts run slower. Budget now 1500 ms (still spread 3 ms per frame).
- 2026-10-28: Ape: when the player is cornered (scream range, wall behind), it leaps to the far end of its range, then throws 3 stones 0.35 s apart (VOLLEY, VOLLEY_GAP); a spike hit cancels the volley.
- 2026-10-28: Room editor: Shift+drag selects an area; Ctrl+X / Ctrl+C cut or copy its tiles and objects (top-left inside), Ctrl+V pastes at the mouse, also into another room (clipboard kept across rooms; one spawn per room).
- 2026-10-28: Ape logs never drop onto the player's column or an existing spike (no free spot: no log).
- 2026-10-28: The Hole merged into the Lake Cave: one 30x46 room (the shaft on top of the landing; the Hole's solid right 10 columns dropped), at The Hole's place [80, 23]. m3_the_hole is gone; no freefall rooms remain, so falling in from The Big Jump fades into the Lake Caves region. Generator: under_hole() stacks them.
- 2026-10-29: Base stamina 40 -> 32 (-20%: too much for the first part).
- 2026-10-29: Hard landing (adventure): a fall of 10+ tiles (measured from speed, so it carries across rooms) sets stamina to 0 and stuns for 1 s (no control, crouched pose). Stars circle the head: one at once, the second after 0.5 s; regeneration restarts with the second star. F3 logs "hard landing" / "stunned".
- 2026-10-29: Room editor: Spikes and Spring are one palette entry each; placing faces away from the wall touched (floor first, then roof, then walls), clicking a placed one rotates it (spikes up/right/down/left; spring up/right/left).
- 2026-10-29: tools/progression.py [world] [out.html] -> reports/progression.html: progression graph (top to bottom = abilities gained, left to right = choices; branches labelled with the ability and the rooms they open; dashed = an ability with no pickup in the world yet). Clicking a node draws the whole map: green = cautious model, orange = generous model (skill), purple = exploit model (not intended), red = unreachable; breakable walls are rock until the attack. Today the three models agree on every room.
- 2026-10-29: Monster action library (scripts/monster_library.gd): moves patrol / hop / hover, attacks charge / leap / shoot / lob / dive (each move only gets attacks it can do), traits = the enemy variants (swift, armored, giant, shielded, brood, venom). build(rng) = random move + one attack + a fitting look; upgrade() adds one attack or trait (tier +1, red marks over the head). Entity "enemy_monster" (ActionMonster) runs any build; placed bare in the editor it rolls one from its position and keeps it. Traits stack. Monsters tab: one "Monster" row.
- 2026-10-29: Regions carry a zodiac sign (world.json "sign"; "peaceful": true for Meadow, Cove Town, Treetop Village). Signs: Meadow Taurus, Lake Caves Cancer, Cove Town Libra, Jungle Leo, Treetop Gemini, Sand Cave Capricorn, Lighthouse Coast Aquarius, Island Shores Pisces, Volcano Aries, Volcanic Maze Scorpio. MonsterLib.SIGNS: each sign's moves and attacks for its native monsters.
- 2026-10-29: tools/populate.gd (godot --headless --path . --script tools/populate.gd -- [--dry] [--clear] [--seed N]) fills the fighting regions in world.json order. Of each region's whole population: 30% the previous region's monsters as they are, 20% upgraded one tier, 50% natives of the sign (3 kinds per region). Picks spread over the previous kinds in proportion, fractions rounded at random by weight; tier-2 monsters stay where they appear; one upgraded version per kind per region; a region with no room for monsters passes the previous ones on. Spots: flat floor (3 wide, 2 open rows), not near doorways, liquids, spikes, spawns or enemies; boss arenas and towns skipped; one per 200 open cells, max 3 per room. Placed monsters are tagged "populated" and replaced on the next run. Seed 1 today: Lake Caves 3, Jungle 10, Island Shores 5, Volcano 8, Volcanic Maze 8 (Sand Cave and Lighthouse Coast: no spots).
- 2026-10-29: Map pipeline: World Editor "+ Add empty room (draft)" marks the room "draft": true; "Build drafts" (or python3 tools/story/build_drafts.py [world] [--seed N] [--extra K] [--dry]) links the drafts as a maze (random spanning tree: one way into each; finished rooms link only where their edge is already open), adds K (default 2) shortcuts behind an ability gate (attack: breakable wall/plug, dash: spike pit at a floor doorway, climb: high doorway over a sheer wall), then builds each draft: floor, 3-tile doorways with ledges, stepping platforms (rises of 3), random rock chunks, checked with the cautious model until every ungated doorway reaches every other. Ends with edge sealing and entrance spawns. Drafts without a region join a linked neighbour's.
- 2026-10-29: Radial start (existing rooms kept): new start room hub_landing (Landing, Virgo, peaceful) left of the meadow; Western Wilds (Sagittarius, 5 rooms: w1-w5) further left and below, with 15 monsters (more enemies on the left); x1_serpent_lair (64x30, "arena": true, waiting for the Serpent boss) under Crystal Pocket in the Volcanic Maze (the serpent maze, bottom right). All built by build_drafts.py seed 1 ("attach" opened doorways in m1_meadow and i17_crystal_pocket); 2 shortcuts behind dash / climb in the Wilds. Regions reordered for the monster chain: Landing, Western Wilds, Meadow, ... Repopulated.

- 2026-10-29: i09 is now Ash Passage: a tall, climbable tunnel directly under Foothills. The remaining Volcanic Maze rooms shift together, preserving their internal alignment; the extra i18 room is removed and the former East Shore descent sealed. North Shore ↔ South Shore retains interactable direction signs.
- 2026-10-29: tools/morph_terrain.py adds a seeded cavern contour preset for regions or room lists: preview by default, protected floors/entrances/entities, atomic apply and conflict-checked restore. References and commands: docs/TERRAIN_MORPHING.md.
- 2026-10-29: Terrain morph presets expanded to cavern, desert, coast, volcanic, forest and ruins; distinct contour brushes, compatible-environment selection, per-terrain reports and --list-terrains. Preview comparison: reports/terrain-morph/index.html.
- 2026-10-29: Progression page, second view "Choices" (for the ability set picked above): zones = groups of room entrances (spawn points) that reach each other with the cautious model; arrows = ways that don't lead back (drops, one-way doors, cave-ins); yellow arrows = a choice. Clicking a zone colours the map: this zone, still ahead, left behind (no way back), not reached. The Sand Cave chase's cave-in rock counts as down for entrances behind it. Room searches stop at the room's edge (world_check explore room=/exits=) and run in parallel; the page takes ~1.5 min.
- 2026-10-29: Choices view drawn as a metro map: one thick coloured line per route (start to an end), a stop per zone (one row each, label column on the right), choice stops ringed dark; the same stop on several lines joined by dashed links (arched over any other stop in between); hover a stop: the decision there (ways on, no way back); click: the map. progression.html#dash opens an ability set directly.
- 2026-10-29: Stamina regeneration 2/s empty, 9/s at half, 3/s full (was 3 / 12 / 4).

2026-10-29 — Long shores and direction panels: all four shores extend to 120
tiles, each with a separate Interact panel for every other shore. The original
North Shore panel leads west; another leads south. North and South are separate
map locations rather than vertically stacked rooms. Shallow pools and low stone
shelves vary the beaches; volcano connections and the Guardian reward survive.
- 2026-10-29: Progression page top graph also a metro map (shared metro() drawing): each line an order of picking up abilities, each stop an ability set (rooms reachable), faded segments = an ability with no pickup placed yet; hover a stop: what each next pickup opens.

2026-10-29 — Shore travel correction: remove direct North–South and East–West
panels. Each shore has two panels, forming North–East–South–West–North.

2026-10-29 — Applied the cavern terrain morph to Volcanic Maze (seed 42,
intensity 0.45). Safe shallow recesses in Ash Passage and Junction; remaining
rooms protected. Existing maze layout, platforms and boss arenas retained.

2026-10-29 — Per-room enemy_count in room editor and JSON: -1 automatic, 0 none,
positive values request a generated population. Draft building populates only
newly built rooms after entrance placement; safe placement and peaceful/boss
exclusions remain, and hand-authored enemies are preserved.

2026-10-29 — Room editor connected-room buttons follow physical passages and
valid door/panel links. Unsaved edits prompt Save / Don't save / Cancel before
switching; failed saves stay in the current room with edits intact.

2026-10-29 — Editor room switches fit the destination inside the usable canvas;
plain masking outside room bounds hides uncovered scenery. Manual pan/zoom stay
available.
- 2026-10-29: Progression counts bosses as powers: Ape / Guardian beaten opens their boss gates (the arena exit; "until" gates such as the Jungle Hills hole); reaching a boss offers "beat it" as a branch. Abilities with no pickup in the world are checkboxes ("assume") instead of lines, so the lines show only real choices. Today with dash+climb+attack assumed: start 16 rooms -> Ape beaten 41 -> Guardian beaten 41 (its after-room variants aren't modelled). Tests follow the World Editor's start change back to the meadow.
- 2026-10-29: hub_landing's right doorway closed to match the meadow's left edge (closed in the World Editor).

2026-10-29 — Progression page separates boss/powerup unlocks from room route
choices. Reversible forks stay visible, and both unlocked branches count in
accessibility. Hypothetical unplaced powerups are unchecked by default.
- 2026-10-29: Upgraded library monsters: no red marks; tier 1 is 1.25x and amber, tier 2 is 1.5x and magenta (sprite tint, EnemyArt.draw tint). They grow from the spot they're placed at (feet and middle kept); populate places every monster at the base size. Repopulated.
- 2026-10-29: Room editor (editing a world room): yellow arrows just outside the edges, one per connected room touching that edge; click one or press Ctrl + arrow key to edit that room (asks to save unsaved changes first). Builds on the Connected rooms list.

2026-10-29 — Unlock and route-choice graphs are independent. Route choices use
the full modeled topology with gates open; selecting either graph leaves the
other graph and map untouched.

2026-10-29 — Reduced excessive entrance respawns: one point per ordinary room,
two for long/tall rooms, preserving authored checkpoints. Fixup and shore
generators enforce sparse placement so excess markers do not return.
- 2026-10-29: Room editor: rooms linked only by a door get a cyan arrow over that door (click to edit the room it leads to).

2026-10-30 — Editor menus isolate wheel scrolling from room/map zoom. Room
controls and tools explain themselves on hover. Spawn placement and paste keep
existing markers so multi-entrance rooms can be authored manually.

2026-10-30 — Room Playtest supports respawn-only and markerless rooms with a
temporary safe floor start. Respawn checkpoints are invisible during gameplay
and remain visible in the editor.

2026-10-30 — Unified Spawn and walk-on Respawn under one editor tool using the
original icon. Both activate checkpoints invisibly without particle bursts.
- 2026-10-30: Respawns: entity "respawn", one per room-to-room entry (doors excluded), placed by tools/world_fixups.py add_respawns (--respawns, or World Editor > Place respawns, which lists errors): side entry 1 tile in from the edge on the floor under the entry's lowest row; top/bottom entry on its middle column, first floor below/above; no valid floor = an error, no respawn (8 today, mostly fall-through holes). Walking onto one makes it the respawn point (and the save's); entering a room no longer moves it. Old entrance spawns removed; a room without a start marker starts at its first respawn. (Codex: invisible in game, original spawn marker in the editor, prune pass.)
- 2026-10-30: Progression Graph 2: a ◆ choice is an irreversible decision (taking one way out loses another for good), with the lost way named. Room links from a cave-in room's near side are dropped (its chase starts on entry). Entrances for the room searches: respawn slabs and door arrivals (the old entrance spawns are gone). Irreversible decisions found: Ape Arena (Sand Cave loses Jungle Hills), Jungle Hills (Jungle Depths loses the Ape side), Jungle Edge (the drop to Jungle Falls loses Cove Town), The Big Jump (the drop to the Lake Cave loses the Meadow).
- 2026-10-30: Progression Graph 2 drawn like a git graph (one stop per row, branches in new coloured columns, names at full size on the right, no zoom); 'same stop twice' links behind a checkbox; its map back on the right and pinned while scrolling.
- 2026-10-30: Graph 2 'same stop' links are square paths with rounded corners, each in its own lane (left gutter or right of the lines, whichever crosses fewer lines).

2026-10-30 — After the Ape fight, a thorn barrier left of the Jungle Depths
shaft blocks return to early Jungle. The Depths and Sand Cave choices remain
open. Gates support after-boss activation; progression reports honor it.

2026-10-30 — World Editor Progression runs snapshot analysis in a separate Python
process and opens the browser explorer. Added independent tabs, compact help,
route-preserving navigation, and tests for editor/job/report behavior.

2026-10-31 — Attack CSV catalogue: reusable timings, reference scores, and
descending range selection for ActionMonster and the Ape. Monsters opens a
validated CSV editor in source builds; web includes gameplay tables only.
- 2026-10-31: Attack CSV editor (Codex's Monster Editor): "Enemy ranges" and "Enemy scores" merged into an "Enemies" tab: pick an enemy (library monster, Ape, Ape enraged), see its sprite, its attacks in priority order with editable ranges and Skip %, ▲/▼ to move (priorities renumbered), ✕ / + Add attack, and its scores. Attack order is now priority only (was longest range first; library monster priorities set to keep today's order: shoot, charge, lob, dive, leap). New column skip_chance in data/enemy_attacks.csv. Validation reports the row and field (shown red). Overlap warnings skip the Ape's rule-picked attacks and library monsters.
- 2026-10-31: Cmd+Q (macOS) / Ctrl+Q quits from anywhere, also paused or with a dialog / editor window focused (Game.QuitKey, always processing); desktop only.
- 2026-10-31: Attack catalogue: a max range of 0 (empty in the editor, "no max") means no maximum; body attacks have no area of their own (blank in attacks.csv, "body" in the editor), scored with the body's size (reference 10x10 px / the Ape's 3x3 tiles).
- 2026-10-31: attacks.csv: source_url merged into notes ("Source: <url>").
- 2026-10-31: Attack catalogue multishot: projectiles_toward / projectiles_other / omnidirectional replaced by multishot (shots at once), aimed_shot (which one points at the player, 0 = lowest, upward from there) and spread_deg (degrees between shots; 0 = evenly around 360). Library monsters' shoot and lob fire the whole fan. Score: shots within 30 degrees of the aimed one count fully, others 20%.
- 2026-10-31: Attack editor: Execution is read-only (greyed) for ranged attacks: they spawn a projectile, no execution animation of their own.
- 2026-10-31: Attack type "movement" for charge, leap, dive, ape_leap and ape_slam (the move sets the duration); Execution read-only for movement and ranged attacks. Scoring unchanged (movement with a speed: travel time; slam: its area over its execution).
- 2026-10-31: Charge and dive end at max_distance_units (charge 16.5 tiles, dive 11.25: the same as their old 1.2 s / 0.6 s at their speeds) or sooner at a wall / ledge / hit; the slam's shockwave lasts shockwave_s (0.2 s). Their Execution is blank now; animation_s is only required for body, melee and area attacks.
- 2026-10-31: Attack editor: Attacks tab keeps only the mechanics (identity, timing, shape, movement); score, base weight, research name, status and notes moved to the Enemies tab, where each attack has a compact editable line of its applicable values (short tags) and its notes underneath. Enemy preview drawn through a scaled node (the Ape now shows at full size).
- 2026-10-31: Enemies tab: attack notes in the name's tooltip and an 'i' button (shows them, opens an edit box); the notes row is gone, values wrap to another row when needed.
- 2026-10-31: Windowed desktop game: a portrait or tiny window (remembered by the window manager, an embedding panel) is resized to 1280x720 fitted to the screen and centred at startup / when settings apply; minimum window 640x360 (Game._fit_window).
- 2026-10-31: Enemies tab values use full names (Wind-up, Recovery, Speed, Max distance...), wrapping onto extra rows; editor tooltips wrap into a squarish block (squarish()).
- 2026-10-31: Window size comes from the window manager: niri rule in ~/Projects/dots (app-id Bethe Knight, column 60% of the monitor width); the game only sets a 640x360 minimum (the earlier 1280x720 resize shrank the tiled window's height instead).
- 2026-10-31: Attack editor: Weight (base_weight, score multiplier) edited in the Attacks tab (Shape section), no longer in the Enemies tab.
- 2026-10-31: Main menu: the Monsters page is gone (the map's Monsters tab stays); Monster Editor opens the attack editor as its own page. Enemies tab: the enemy's frames under its animated sprite, and each attack's animation frames (Ape poses for throw / leap / scream, the slam shockwave, projectiles; library monsters have only walk frames).
- 2026-10-31: world_check: variable jump (let go early = a short hop). test_island fragment/character check also starts at Cove Town: Cove Tunnel's bump under ceiling spikes needs a low hop that fits the 11 px player but not the checker's 2-tile body. Monster Editor: softer theme (off-white text, dimmer labels, darker bordered boxes, dimmed read-only values).
- 2026-10-31: Monster Editor Enemies tab lists every enemy in the game: the CSV-driven ones first (Library monster, Ape, Ape enraged; attacks editable), then all 32 enemy family/variant types, the Sand Cave Ape chase and the Guardian (indented, read-only: sprite, frames, HP, variant, how many are in the story and where; their attacks are in scripts/entities.gd).
- 2026-10-31: The 6 attacking enemy families moved into the attack CSV with their current numbers: dropwing_dive, duskflit_swoop (max distance replaces its 0.9 s), ossling_bone_throw, hornback_charge (max distance replaces 1.2 s), cragjaw_leap, murkspore_spread (multishot 3, aimed 1, spread 17.19°); one range binding each (14, 12, 13, 15, 18.75, 22.5 tiles). Their code reads windup / recovery / speeds / gravity / range / skip chance (CombatEnemy.atk, atk_range, atk_ready; a skipped attack waits its recovery). Editable in the Monster Editor's Enemies tab; variants point to their family; Thornmite, Fuzzbob, Mosstrot: no attack.
- 2026-10-31: Ape retreat leap is a CSV attack (ape_retreat: top priority, 0-5.5 tiles, rule: player cornered and not above/below) with a follow-up (new generic columns follow_up / follow_up_count / follow_up_gap_s: ape_throw x3 every 0.35 s; follow-ups add to the score). Skipped / removed -> plain leap. Editor: Follow-up section in Attacks, Then / Times / Every under the attack in Enemies; the 'Attacks in priority order' heading is gone.
- 2026-10-31: Enemies tab: + Add attack offers every catalogue attack not yet on the enemy, plus '＋ New attack…' (a planned row new_attack_N); attacks the enemy's code can't do yet are tagged 'not in game yet', saved, and skipped in play (AttackCatalog.performs). Bindings no longer have to be implemented for the enemy.
- 2026-10-31: Monster Editor: Attacks tab shows only the fields that apply to the selected attack (plus name, type, weight, follow-up); Delete attack for attacks the code doesn't use (removes their uses too); Enemies tab: score line pinned below the list, Skip % / Min / Max / Score explained in the column tooltips.
- 2026-10-31: Attacks merged (asked): charge = charge + hornback_charge + dive + duskflit_swoop (a rush: walkers along the floor, flyers straight at the player; charge's values: Duskflit swoops faster and farther, its warning is 0.5 s); shoot = shoot + murkspore_spread (Murkspore now a single faster shot, more often; raise shoot's Multishot to bring a fan back, for library shooters too). Library monster attack 'dive' gone (flyers use charge; Aquarius / Pisces natives updated). Ranges stay per enemy.
- 2026-11-01: Follow-up moved out of the Attacks tab: in Enemies, an attack with one shows Then (attack picker, 'none' removes it) / Times / Every; others have a '+ Then…' button.
- 2026-11-01: Monster Editor: every attack of a type shows the same boxes (TYPE_FIELDS: body, melee, area, ranged, movement); Area empty = 'body' (placeholder, editable). Attacks tab: Name (readable) editable, ID editable for attacks the code doesn't use (renaming updates enemies and follow-ups), Type a dropdown (switches the boxes).
- 2026-11-01: Enemies tab layout: each attack's values in a fixed grid (4 per row, same label and box sizes across attacks), follow-up on its own row; Library monster recap is now a table of the monsters placed in the story (identical builds grouped with a count, sorted by score; unscored ones show – with the reason in the tooltip), summary pinned: '45 placed, 13 different builds, scores 1.65 to 10.59'.
- 2026-11-01: Library monster removed from the Monster Editor's Enemies tab (the user prefers enemies placed by area in calibrated ways). Its CSV bindings and the 45 placed library monsters still work until replaced.
- 2026-11-01: Review of monsters and the Monster Editor -> docs/reviews/monsters/CODEX_PROMPT.md (2 blocking: ID rename per keystroke corrupts bindings, skip % re-rolled every frame for library monsters / Ape; follow-ups only work for ape_retreat; hard-coded values next to CSV ones; families ignore min range / priority; IDs in 3 places; per-frame catalog lookups; calibrated per-region placement by danger budget replacing the random library monsters).
- 2026-11-01: Attack type 'body' renamed 'body movement' (no attack uses it today).
- 2026-11-01: cragjaw_leap merged into leap (leap's values: Cragjaw leaps a little faster and lower, wind-up 0.5, recovery 0.9); the Ape keeps ape_leap / ape_retreat. 13 attacks left.
- 2026-11-01: Docs updated (README, ATTACK_CATALOG, ENEMIES, data/README) for the Monster Editor (Attack library / Enemy loadouts), the removed Monsters page and the merged attacks.
- 2026-11-01: Monster Editor review (game-review skill) -> docs/reviews/monster-editor/REVIEW.md: 3 blocking (ID rename hijacks bindings, Esc drops unsaved edits, unbounded multishot hangs), 8 major, 6 minor, 2 questions, with a Codex fix prompt; Codex's probe review committed under reports/monster-editor-review-2026-11-01/.
- 2026-11-01: Monster Editor fixes (Codex review 1-12): ID rename on Enter only (refuses taken/empty/code IDs), Esc asks like Back, Ape slam/split/log protected, family bindings rule min range and removal, unsupported follow-ups labelled and not run, loops rejected, multishot <= 64 / follow-ups <= 10, incomplete follow-up scores, saved scores from rounded values, live enemy total, dropdown width, scroll reset, priority help text; dead library-monster editor code removed.
- 2026-11-01: Monster Editor, rest of the review: skip % rolls once per decision (a skipped attack waits its recovery) for library monsters and the Ape; save keeps a .bak pair and restores both on failure, draft stays dirty if reload fails; world read once per editor session; animation strip built on first open with a +/− toggle; numbers shown without trailing zeros (CSV keeps 2 decimals); enemy list: editable, '— Read only —' divider, read-only.
- 2026-11-01: Monster Editor speed: Ape page 57 -> 8 ms (attack details built on open; ▲▼✕ drawn as pixel icons, since the UI font lacks them and the system-font fallback cost ~2 ms per button; '＋' -> '+').
- 2026-11-01: Attack scores comparable across types: moving hits (shots, leaps, charges) add their swept strip, √area × 15 tiles (SWEEP_LENGTH); Ape scream 165 / leap 105 / throw 44 / slam 37.5, library charge 14 / leap 26 / shot 3.6 / lob 7.2. Score column refreshed.

2026-11-01 — Re-reviewed Monster Editor at 450a07e after the earlier fixes: 5 major and 2 minor remaining issues, fresh probes/screenshots, and a standalone Claude fix prompt in docs/reviews/monster-editor-followup/. Review documents only; gameplay and room data unchanged.
- 2026-11-01: Monster Editor: an attack's follow-up (Then / Times / Every) shows under its Min / Max / Skip row without opening Edit; '+ Then…' stays in Edit.
- 2026-11-01: Monster Editor: one height (33 px) for every box, dropdown and button in the loadout cards and the Attack library (value boxes were 21, the Type dropdown 38).

2026-11-02 — Monster Editor expanded attack settings now fill the card in grouped two-column panels (Timing, Damage & speed, Projectile pattern, Trajectory), replacing the narrow left-aligned grid. CSV values and attack behavior unchanged.
- 2026-11-02: Stamina regeneration at half full 9/s -> 6/s (still 2/s empty, 3/s full).
- 2026-11-03: Review of Codex's Ape composition slice -> docs/reviews/ape-composition/REVIEW.md: 0 blocking, 2 major (triggered CSV rows unused by runtime / duplicate of enemy_profiles.json; tests assume 4 HP), 5 minor, 3 design questions (phase two hops once; thrown logs leave spikes; stones became logs), with a Codex fix prompt.

- 2026-11-03: Recursive Ape/catalogue/editor/effects audit: 2 blocking, 5 major, 3 minor new findings plus 6 reconfirmed issues; runtime probes, screenshots and a fix prompt in docs/reviews/ape-recursive/. Corrected the earlier Ape prompt (verified CSV rollback scenario; scoring subtotal already labelled). Review artifacts only; gameplay and rooms unchanged.
- 2026-11-03: Whole-codebase sweep (gdlint, gdradon, pyflakes, bench, probes) -> docs/reviews/codebase-2026-11-03/REVIEW.md: 1 blocking (a half-written progress save makes the next save wipe all level records and other runs), 1 major (World Editor files written in place, unchecked), 4 minor; performance fine in real rooms. Codex fix prompt inside.
- 2026-11-04: Crash-safe files: Game.write_safe (write .tmp, keep .bak, rename) for progress, settings, tuning presets, rooms and world.json; Game.read_config falls back to .bak and never saves over an unreadable file (a cut-short save used to wipe level records). Respawn into another room builds it once. Dead code removed. tools/verify.sh runs gdlint (gdlintrc) and pyflakes via uv. Benchmark adds the real Ape arena (0.12 ms physics, 0.07 ms draw).

- 2026-11-04: Ape follow-up 1: derive phase-aware triggered effects from the runtime profile; remove duplicate shipped bindings and migrate legacy effect rows on save. Regression checks, both phase screenshots, and full verification pass.
- 2026-11-04: Ape follow-up 2: isolate HP/phase/hop regression fixtures, verify one-hit damage from starting HP, and include composition/varied-profile/follow-up scenes in the main verification gate. Changed-health and changed-hop regressions plus full checks pass.
- 2026-11-04: Ape follow-up 3: generate card/section tooltips from runtime profile links, refresh source names during editing, and wrap detailed notes. Six tooltip regressions, catalogue/follow-up checks, gdlint, and rendered hover inspections pass.
- 2026-11-04: Ape follow-up 4: cancel obstructed split-child spawns with an explicit one-shot event and visible burst, preserving valid children and avoiding phantom spikes. Free/partial/fully blocked World cases, composition, physics, smoke, and gdlint pass.
- 2026-11-04: Ape follow-up 5: catalogue rollback tracks prior existence and successful replacements, removes new finals instead of restoring stale backups, restores existing files, cleans staging files, and reports recovery failures honestly. Nine failure regressions now pass; final full verification (including all follow-up scenes and linters) reports 0 failing.
- 2026-11-07: Stamina: regen 4/s empty (was 2), 8/s at half (was 6), 3/s full; max energy -15%: base 32 -> 27, each block 20 -> 17. F3 panel: text wraps instead of being cut, bullet points, a legend for the graph (yellow = stamina over 10 s, green = maximum, dashed = block boundaries); 'recent changes' removed.
- 2026-11-07: Review of Codex's commits 11-04..11-06 -> docs/reviews/codex-2026-11-07/REVIEW.md: 0 blocking, 0 major, 2 minor (HUD '/250' literal, rest relief trusts the system clock), 1 question (stress can be farmed on respawned monsters, by design).
- 2026-11-07: Rule (whole game): no floating-point numbers. Every division (and percentages, multipliers, ratios, averages, scaling) keeps only the integer part. Recorded in AGENTS.md and docs/CODE_GUIDE.md.
- 2026-11-07: Player shake while walking fixed: the camera and the player were rounded to whole pixels separately and disagreed by a pixel every few frames (2 reversals per 240 frames at 60 fps, 6 at 144 fps). Now the player's on-screen spot is round(position - camera) and the camera stays on whole pixels: 0 reversals. Regression check in test_runner (camera section).


---

<a id="docs-implementation-status"></a>

## Source: docs/IMPLEMENTATION_STATUS.md

Original source: `docs/IMPLEMENTATION_STATUS.md`. [Evidence directory](../../docs/).

# Requested mechanics: implementation status

Checked 2026-11-05 against the working tree, including uncommitted changes.
Scope: the large traps/inventory/modularity/enemy/terrain request, the Be/Kraken/stat
request, and the subsequent Ape-editor/stress decisions. This is a delivery audit,
not a claim that the older, entire conversation backlog has been retested.

“Implemented” means an active code path exists. “Partial” identifies the actual
subset; a design document, a helper without a caller, or an old similar mechanic
does not count as a playable implementation of the full request. Gameplay was not
changed during this audit. Existing user edits to the two jungle rooms were preserved.

## Current follow-up (2026-11-07)

The non-map portion of the lighthouse/island follow-up is implemented: quest/unique crystals/sword reward, item/key transactions, named events, Items/Abilities pages, boat tentacle-dodging survival and shipwreck handoff, thick water, giant feet, heat, double jump/heat resistance, attached HUD and stress-capacity/30% rule. See [NONMAP_SYSTEMS.md](../../docs/NONMAP_SYSTEMS.md) for authoring, defaults, verification and limits. All room layouts and entity placements remain unchanged; ruins, docks, NPC placements and movement-gated routes still need the map pass.

The older status table below records the earlier architecture audit. The current follow-up above supersedes its inventory, first-crossing and stress entries; it does not mark the unrelated older proposals complete.

Subsequent completed work: full stamina regeneration; room-edge/corner resizing with variant synchronization; compact attack fields and one Range control; configurable Ape attack conditions; coverage-based Player cornered with grounded-player/order/floor/real-shape checks. The helper is reusable, but other enemy adapters remain to be written. This follow-up is a source/document status check, not a new full gameplay verification run.

## First partial-system batch (2026-11-05)

Implemented after this audit: ordinary family HP overrides and validation in the
Monster Editor (including library monsters); extracted floor/crawler motion;
shared brood child-spawn definitions. See `docs/ATTACK_CATALOG.md` and
`reports/partial-foundations-2026-11-05/README.md`. Original layouts and legacy
movement/variant defaults are preserved. The following table is updated for this
batch; it does not mark the whole programme complete.

## Patrol authoring batch (2026-11-05)

Movable enemies, platforms, hazards, pickups and decorations now have room-editor
surface/sticky and open/closed path controls, speed/support/direction settings,
point editing and motion preview. Runtime adapters preserve attack ownership,
carry riders, update dynamic collision and stop at walls. See
[PATROL_AUTHORING.md](../../docs/PATROL_AUTHORING.md). Room and encounter anchors remain
explicitly excluded. Timed retracting spikes, trigger zones and pressure plates were subsequently implemented; see the current deferred-work audit in `docs/DEFERRED_WORK.md`.

## Implemented

| Request | Evidence / limits |
| --- | --- |
| Game title Bethe Knight; protagonist Be | `project.godot:5`, `scripts/menu.gd:_main`, story/README. Legacy save-directory and source asset names intentionally remain stable |
| Ape falling/thrown logs share their consequences; splitting logs and impact spikes | `scripts/effects/attack_effects.gd`, `scripts/entities.gd:Ape`, `data/enemy_profiles.json`; actual Ape integration tested |
| Triggered Ape effects bypass attack selection, appear after selected attacks, and have live source descriptions | `scripts/attack_catalog.gd:effect_links`, `enemy_entries`, `select_attack`; profile-derived listing rather than a skip-100 workaround |
| Ape health/phase-entry threshold/wave scales editable | `scripts/attack_catalog_editor.gd:_ape_profile_fields`; profile is specific to Ape |
| One Ape page, compact inputs, Enemy loadouts open first, redundant right-side phase box removed | `scripts/attack_catalog_editor.gd:25`, `CSV_ENEMIES`, `_enemy_rows`, `_binding_controls`; phase-specific bindings remain independent |
| Stress 0–250, persistence, death/exhaustion gains and kill/collectible relief | `scripts/progression/stress.gd`, `adventure.gd`, world/entity hooks; five-bar HUD |
| Stress recovery targets 100/90/80/75/70/65%, interpolated | `Stress.RECOVERY`, `Adventure.regen_stamina`; no change to water/climbing/stun exclusions |
| Twelve-hour save-load rest relief with durable repeat-claim prevention | `scripts/game.gd:claim_stress_rest`, `save_adventure`, actual Continue flow; failed writes do not award relief |
| Research and architectural/encounter plans | `docs/MECHANICS_ARCHITECTURE_PLAN.md`, `BETHE_KNIGHT_DESIGN.md`; research itself does not implement the plans |

Stress interpretation to keep visible: white hair means stamina exhaustion, not
dash-only grey hair. Permanent fragments, ability/capacity pickups and legacy stars
reduce stress; reusable dash crystals/stamina refills currently do not. The latter
is an implementation interpretation of “collectible”, not a separately confirmed
rule about reusable refill objects.

## Missing or partial implementation

| Requested feature | Status | What exists now / what is missing |
| --- | --- | --- |
| Timed traps: activation period, stay-up duration, deployment and retraction timing | **Implemented for spikes** | `interaction/trap_cycle.gd`, `entities.gd:TimedSpikes`, room inspector and `tests/traps_triggers.tscn`; more trap types and authored teaching encounters remain |
| Triggers targeting traps and other moving objects | **Implemented, bounded scope** | `trigger_zone` / `pressure_plate`, typed trap/movement actions, cooldown/once/ability conditions, inspector and link validation; general story-event graphs remain separate |
| Patrol for movable objects | **Implemented, bounded scope** | Shared optional motion for movable enemies/platforms/hazards/pickups/decorations; room/encounter anchors are explicitly excluded |
| Surface patrol and sticky authoring | **Implemented for movable bodies** | Shared inspector exposes support normal, tangent direction, speed, pause and sticky corners. Sticky chase/pathfinding and general artwork rotation remain separate |
| Authored open/closed path patrol | **Implemented** | Numbered draggable points, creation/deletion, loop/ping-pong, speed/pauses, preview, undo, copy/paste and room save/load |
| Inventory alongside Map | **Missing** | `scripts/map_view.gd:16` defines only Map and Monsters tabs; no item/count inventory schema or inventory panel |
| Keys and key-dependent item/NPC interactions | **Missing** | Ability pickups and dialogue/door interactions exist; no held-item conditions, retained/consumed-key transactions or inventory-aware branches |
| Reusable enemy composition/stub | **Partial** | `CombatEnemy` shares helpers, health/motion/brood definitions are extracted, CSV selects attacks, and extracted effects support Ape. Enemy families and attack execution remain mostly in `entities.gd`; no general motion/decision/attack/phase components |
| Player-state and individual power-up separation | **Partial** | Player has an explicit state enum and transition functions already, but states and ability implementations remain together in `scripts/player.gd` |
| World, interactables, hitboxes and ornament boundaries | **Partial** | Art, map views, tile rendering and effects have dedicated files. Registry, interactables, hazards and encounters remain together in `entities.gd`; room orchestration stays in `world.gd` |
| Isolated one-time story events | **Partial** | Persistent boss/wall/pickup IDs exist, but named story-event modules/registry and common condition transactions are missing; bespoke Ape/chase/Guardian scripts still own story transitions |
| Universal stable object IDs | **Partial** | Some definitions supply IDs, but BreakWall and several fallback pickup IDs derive from coordinates. General editor migration/validation has not been applied |
| All enemy HP and phases editable in Enemy tab | **Partial** | Ordinary family base HP and Ape HP/threshold/hop scales are editable. General configurable phases and a three-phase Kraken profile remain missing; Guardian stays puzzle-based |
| General event-chain editing and complete consequence scoring | **Partial** | `attack_catalog.gd:effect_links` explicitly handles only Ape. Editor does not author arbitrary graphs; score text explicitly says triggered-consequence totals are pending |
| Flying diagonal chargers, grounded chargers and sticky chase | **Partial** | Ground charges and flying charges exist in `ActionMonster`; flying charge uses the direct target vector. No allowed-diagonal/clearance selector or shared sticky chase controller |
| Explosive enemies / fuse-before-charge / short explosion | **Missing** | No generic armed/fuse/detonation lifecycle or explosion definition connected to an enemy |
| Death-spawn enemies, explosions and condition-gated item drops | **Partial** | Brood variants now share `actors/death_actions.gd` child definitions. General death-action lists, explosion/item drops and a quest condition layer remain missing |
| Straight and gravity projectiles through one reusable launch model | **Partial** | ActionMonster can shoot straight and lob with gravity; Ape uses extracted projectile effects. All families have not migrated to a common spawn/launch contract |
| Attached tongue/arm/sword/flame effects | **Missing as a shared system** | No configurable owner-anchored effect with active hitbox windows and common cancellation/despawn behaviour |
| Enemies that summon other enemies during combat | **Missing as requested** | Brood is a death reaction, not a bounded active summoner with cooldown and population limit |
| Three stats: Dexterity, Constitution, Attack | **Missing** | No allocation budget, save schema, derived-stat service, stat-based movement/regen/damage, or progression UI. Final displayed names are pending |
| Lower base movement/recovery for the stat system | **Not applied** | Stress modifies existing recovery; the separate proposed starting-stat nerfs have not been applied or route-balanced |
| Constitution allowing several hits | **Missing** | `Player.die()` still turns ordinary lethal contacts into respawn. No multi-hit health/damage/invulnerability contract |
| Low-cost basic attack with an additional enemy-hit cost | **Implemented for punch and sword** | `combat/player_melee.gd`, player/world hooks: 2 stamina per attempt plus 4 on first accepted enemy hit; stronger stat-based damage remains missing |
| Kraken boat encounter and underwater arena | **Missing** | No `boss_kraken` registry/profile or playable boat encounter. Story entity scan found no boat/Kraken note marker either |
| Kraken entry conditions explained at the boat/map/inventory | **Helper only** | `Stress.kraken_requirements()` checks full first energy bar, 250 stress and a supplied underwater Boolean. It has no production caller; no prompt/checklist or real underwater-capability integration |
| Kraken opening, climbable tentacles, head window, sweep/radial attacks and three phases | **Missing** | Design only; no encounter/controller/collision/effect code |
| Ink: fixed 10% darkness and separately stacking borders | **Missing** | No combat ink overlay, black texture, stack state, reset lifecycle or editor parameters |
| Additional Kraken attack | **Proposal** | Undertow and its phase variations were suggested; they have not been approved or implemented |
| Pogoable versus non-pogoable hazards and environment-specific visuals | **Missing** | `Spikes` are directional lethal contacts, with no pogo `hit()` response or separate hazard category. No requested thorn/vine skin distinction |
| Progressive hidden-tile discovery with wall-occluded visibility | **Missing** | `World.reveal_t` is the room-transition sweep, not hidden-tile discovery. No per-tile reveal state/LOS/revealed-border logic; map thumbnails have no such concealment layer |
| Hidden walls matching normal terrain, 3–4 hit-count breakage and distinct sound | **Partial** | `HiddenWall` disguises terrain, direct punches reveal without damage, discovery persists and swords break it (default 3 hits). Discovery currently reuses impact sound; broader hidden-tile discovery remains missing |
| Tough damage-based blocks/walls versus hit-count secret walls | **Partial** | Existing BreakWall has an `hp` field but always subtracts 1. Stronger attack damage is not passed through; the two requested destruction policies are not separated |
| Semantic wall/terrain traits | **Missing as a general taxonomy** | Runtime uses solid/grid flags and class-specific checks; no shared reveal/patrol/breakability trait system consumed across tools and runtime |
| Lake Caves and jungle teaching/optional-route pass | **Pending** | Existing platforms/spikes remain, but the requested timed-trap teaching sections and new hazard distinctions have not been authored or playtested |
| Real-world environmental references across levels | **Design direction** | Title/story framing updated; a city-jungle art/layout/narrative pass and region-by-region references are not implemented |
| Be naming throughout presentation | **Mostly applied** | Title/protagonist docs updated. Art gallery folder naming still produces a visible Nori category (`art_gallery.gd:_title`); source asset paths and attribution should stay unchanged |

## What the world scan confirms

Runtime/editor now include timed spikes, linked triggers, authored paths and hidden walls. These primitives do not establish that teaching rooms, inventory, the Kraken or broader story-event systems have been delivered. Counts of placed story entities change during manual room editing and should be obtained from the current files rather than treated as fixed acceptance criteria.

## Proposed delivery order

1. Shared IDs, terrain queries/traits, conditions and motion; keep pixel physics.
2. Authorable trap cycle, trigger links, surface/path patrol adapters and previews.
3. Inventory/keys in Map, interaction transactions and isolated one-time events.
4. Reusable enemy attack/effect/death actions; migrate representative enemies and
   generalise editable health/phases without duplicating CSV/profile truth.
5. Player damage/basic-attack contracts and stat derivation; measure route safety
   before changing base movement or regeneration.
6. Pogo/hidden/breakable terrain, then carefully authored Lake Caves/jungle routes.
7. Kraken boat/capability integration, arena, attacks, phases and ink, building on
   those primitives. Review the broader Enemy-tab proposal before changing it.

Outstanding design decisions should be called out at the relevant step: final stat
names/budget; ink border geometry/cap; exact breathing capability; hidden reveal
radius and vine/rope art; whether reusable refill pickups should also reduce stress.
Do not invent these as already-approved gameplay rules.

## Verification and limits

Fresh checks for this audit: `tests/stress.tscn` (0 failures), `tests/identity.tscn`
(0 failures), and `tests/ape_composition.tscn` (0 failures). Source/data checks cover
the runtime registry, map tabs, enemy library, attack/effect/profile code, player
combat, editor authoring and story entity types.

The preceding full verification run is recorded in
`reports/stress-2026-11-05/verification.log`: all gates except the known Jungle Falls
story-bot traversal pass; shutdown resource warnings remain in some fixtures.
This audit does not claim an end-to-end playtest for features whose implementations
are absent. No gameplay or map modifications were made during the audit.


---

<a id="docs-deferred-work"></a>

## Source: docs/DEFERRED_WORK.md

Original source: `docs/DEFERRED_WORK.md`. [Evidence directory](../../docs/).

# Deferred-work audit — updated 2026-11-07

Checked TODO.md, IMPLEMENTATION_STATUS.md, the architecture and Be/Kraken design plans, the entity registry, and the existing editor/runtime primitives. This is a backlog audit, not authorization to implement all proposals.

## Latest confirmed systems delivered

The non-map lighthouse quest, sword reward, unique crystal pickups, item/key transactions, persistent story flags, Items/Abilities tabs, boat survival/shipwreck encounter, thick water, plateau giant feet, heat, double jump/heat resistance and attached HUD/stress upgrades are implemented. See [NONMAP_SYSTEMS.md](../../docs/NONMAP_SYSTEMS.md) for concrete behavior, defaults and authoring.

Ruins rooms, barriers, NPC/crystal/boat placements, arrival lighthouse, shore connections, environment layouts and movement-gated routes remain map work. The earlier sand-cave sword must be moved during that pass. New themes currently reuse existing artwork; giants are not yet climbable. The old Kraken combat/stat gates and interpolated stress rule do not apply to this crossing.

Recent completed work is not deferred: full stamina recovery, resize from every edge/corner, conditional-room synchronization, compact attack controls, one maximum Range field, Ape attack triggers and the coverage-based Player cornered detector. That detector is reusable; other enemies still need real attack-shape/context adapters. The current West Shore map already has sea rather than solid tiles along its left edge; do not report that terrain correction as wholly unimplemented.

## Explicitly saved for later

- **Ape phase-two true form.** Charcoal/silverback artwork and animation preview are in `pixel-art/ape-phase2/`. TODO explicitly says to keep this deferred; runtime currently uses the original Ape with a red pulse.

## Requested systems still incomplete

- **Kraken/boat encounter:** the latest quest-unlocked first-crossing tentacle dodge, boat destruction and washed-ashore handoff are implemented; author the docks. Older head-window/phased fights, ink and Undertow remain separate historical designs, not acceptance criteria for this crossing.
- **Inventory, keys, quests and story transactions:** Items/Abilities pages, consumed/retained-key transactions, NPC conditions/rewards and one-time named flags now exist. General story-event graphs remain separate.
- **Stats and damage:** Dexterity/Constitution/Attack allocation, derived values, multi-hit player damage and stat-based attack damage. Final naming/budget and route-safe movement/recovery changes still need decisions. The basic punch/sword costs are already implemented.
- **General enemy composition:** extracted health, movement, brood and Ape effects exist, but general phases/conditions, active summoners and attached attack effects are not a complete shared system. Broader Enemy-tab redesign is still a proposal requiring review.
- **Terrain/content:** progressive occluded tile discovery, pogo/non-pogo hazard distinctions, damage-based tough walls, additional timed-trap types, and Lake Caves/jungle teaching routes. Punch-revealed hidden walls already exist; a dedicated discovery sound is still absent.
- **Chapter-one story interactions:** dialogue/quest entity placement, net capture animation, flexible moving bridges, raft quest behavior and lighthouse mirror/flame puzzle. Elf/mage artwork is not evidence of implemented quests or dialogue. Branch destinations and several rewards remain undecided.
- **Presentation/audio/export:** region-by-region real-world references/city-jungle pass, positional/elevation audio research, and optional Web export/hosting remain listed. Visible Art Gallery naming still includes the legacy Nori asset category.

## Decisions and old idea lists

- Later dash/wavedash unlock placement, stamina thresholds, wall-grab drain, refill policy and branch rewards still appear as open design decisions.
- TODO's long reference-game ability/loadout/familiar lists are an idea catalogue, not a set of accepted implementation commitments. Audit individual entries before promoting one to active work.
- Older checked/unchecked story descriptions also contain historical placeholders; actual registry/runtime/test evidence takes priority.

- Older Metroid notes also defer **map stations, per-screen exploration, save slots, general ability-locked passages and animation-driven state endings**. These are design/backlog items, not all active requests. Their blanket “none exist yet” statement is historical: camera zones, region presentation and transition polish already have production code.
- `OPTIMIZATION_RESULTS.md` records deliberately deferred **undo-storage changes, row-edit batching and label/grid micro-optimizations**. They were left out for measured cost/benefit reasons. Terrain caching was subsequently implemented, and current World already has collision buckets; do not reimplement historical optimization suggestions without fresh profiling.

## Stale backlog entries corrected in this pass

Timed retracting spikes, enter/exit triggers and pressure plates, typed trap/movement links, path/surface patrol authoring, interact input, punch/sword two-part costs and the new hidden-wall type already exist. They must not continue to be described as wholly missing.

Room resizing and conditional-room synchronization are implemented. The jump-only route test now uses an isolated copy without bosses, chase/gate/auto-walk/linked-trigger/sound events; full encounter fixtures remain intact. Hand-shaped shore pools are exempt from the legacy generated-pool rule.


---

<a id="docs-code-health"></a>

## Source: docs/CODE_HEALTH.md

Original source: `docs/CODE_HEALTH.md`. [Evidence directory](../../docs/).

# Code health

Audit of 2026-10-22, using the dev skills from `tools/install-dev-skills.sh`: godot-best-practices, godot-state-machine, systematic-debugging, test-driven-development and verification-before-completion.

## Verdict

The core is solid:

- The Celeste port is faithful: update order, corner correction, climb hop and coroutine timing all match.
- Movement is integer-pixel with sub-pixel remainders.
- Level JSON is validated before any entity is built.
- Nothing is loaded in a hot loop, and there are no `get_parent` chains.
- Entities and the player are RefCounted, so freed-node bugs can't happen.
- The player state machine is already disciplined: everything goes through `_set_state`, which runs the end and begin steps. A node-based FSM rewrite (godot-state-machine) would cost more than it gains.

The weak spots were save and editor robustness, a few gameplay edge cases, a test net that could not fail, and an untyped API between objects.

## Workflow for every fix

1. Reproduce the bug with a `check()` in `tests/test_runner.gd`, or in `tests/smoke.gd` for UI. Watch it fail.
2. Find the root cause before changing code. Two suspected bugs turned out not to be real (see below).
3. Make the smallest fix, then run all three suites:
   ```sh
   godot --headless --path . res://tests/test.tscn    # exit code = failures
   godot --headless --path . res://tests/smoke.tscn   # exit code = failures
   python3 -m unittest tests/test_world_accessibility.py
   ```
   CI (`.github/workflows/pages.yml`) runs the same three before every deploy.

## Fixed (regression checks in `check_bugfixes()`)

- **Smoke test could never fail.** It now exits with its failure count. Its touch-Jump check was flaky (about 1 run in 3) because buffered input wasn't flushed; that's fixed too.
- **Free-aim super jumps.** With `DASH_DIRS = 4`, super jumps and super wall jumps never fired. The checks now use an 8-way snap of the dash direction (`dash_dir8()`).
- **Red bubble aim.** It ignored `DASH_DIRS`; it now follows it.
- **Room-seam walls.** A wall on a shared room edge couldn't be climbed or wall-jumped. It now works like any other wall.
- **Restart Level** now clears broken walls and a pending door.
- **Dead player and doors.** A player who died this tick is no longer moved by a door.
- **Camera through doors.** A door into a far room now snaps the camera instead of sweeping it across the world.
- **Dropwing** (then called Skree) no longer gets stuck pushing forever against a ceiling on its way home.
- **Level validation** now rejects bad `facing`, `patrol` and `top` values.
- **Old saves.** Continue on an old or hand-edited save no longer crashes: `Adventure.restore_run` fills in missing fields.
- **Editor:**
  - New/Load never overwrite the world room the editor was opened on.
  - It asks before leaving with unsaved changes.
  - A drag released over the UI no longer keeps painting.
- **World editor:** a level that can't be loaded is reported instead of crashing.

Checked and **not** bugs:

- `WALL_SLIDE_TIME = 0` can't produce NaN, because a wall slide only starts while its timer is above 0.
- In `world_check.py`, refills do reach the next states the BFS explores.

## Open findings (low severity, fix when nearby)

- **Undo history.** The editor pushes undo on every click, even when nothing changes. The no-ops fill the 60-step history.
- **Stale references after a room change.** The player keeps references into the old room (`climb_hop_solid`, `dream_block`, `current_booster`, `attack_hit`). This is harmless today because the objects are RefCounted.
- **`tools/world_check.py`** raises `AttributeError` when the start room has no spawn.
- **`tools/world_fixups.py` `drop_unreachable`** deletes room files and has no dry run. A rebuild restores them.
- **Test isolation.** Tests use the real `user://`, and one long `_ready` holds most checks.
- **Magic numbers.** Some tests depend on them (e.g. `Tuning.names().size() == 99`).

## Optimization strategy (not started)

Measure first with `tests/bench.tscn`. Add an enemy-heavy scene before changing anything, because the current "normal" scene predates enemies. Don't re-propose what `OPTIMIZATION_RESULTS.md` already rejected: particle pooling, spatial index, HUD label skipping, batched tile edits, undo storage.

1. **Line of sight.** `CombatEnemy.sees_player` (`entities.gd`) runs up to about 28 `collide_solid` calls per enemy per tick. Check only the tile grid, and/or run it every N ticks.
2. **`SkeletonEnemy.safe_step`** string-matches every touchable every tick. Cache the hazard rects once per `_build`.
3. **Colours parsed per draw.** Turn the `Color("hex")` calls in entity `draw()` and `_draw_floor_gaps` into consts. Cache `CharacterArt.hair_shades()` per colour.
4. **Array literals in per-frame code.** Make them consts: `player.gd` (`state not in [...]`, `visual_animation in [...]`) and `character_art.gd` `frame()`.
5. **`_draw_floor_gaps`** draws across the whole room width. Cull it to the view.
6. **Neighbour `TileLayer` build.** A large neighbour room is built in one frame and can hitch. Spread its chunks over several frames.

## Future-feature compatibility (not started)

In dependency order. Hurt/HP unlocks most of `TODO.md`.

1. **Hurt entry point.** Add `player.hurt(src, dmg)`, which for now calls `die()`, and route the 8 call sites that kill the player instantly through it:
   - `entities.gd`: Spikes, CombatEnemy, bones, Liquid
   - `world.gd`: pits
   After that, HP, knockback and invincibility frames only change one function.
2. **Save version.** Add a `"v"` field to the adventure run, with a `migrate()` step on top of `restore_run`. This is a prerequisite for save slots.
3. **Typed state enum.** Replace the anonymous enum with `enum State {...}` and build `STATE_NAMES` from `State.keys()`. Adding a state currently means updating about 9 places in `player.gd`.
4. **Enemies in one place.**
   - Phase enums instead of strings.
   - One shared patrol/turn helper for the floor walkers (Ossling, Hornback).
   - Move the `EnemyArt.KINDS/SPRITES` lookups into the `TYPES` row.
5. **Typed API.**
   - Add `class_name` and types for `w`, `player` and `ents`.
   - `collide_solid` returns the string `"tile"` or an entity. Give it one typed result.
6. **Per-run ability overrides.** Layer them above tuning (`DASH_DIRS`/`ATTACK_DIRS`) for direction upgrades. `world_softlock.py` should read its stages from `world.json` instead of hard-coding dash → climb → goal.
7. **One reachability model.** Four exist today: `world_check`, `world_accessibility`, `world_fixups.drop_unreachable` and `check_shipped_world`. Pick one as the authority.
8. **Stale `TODO.md` entries.** "Web version" is done. Shade Cloak no longer needs "enemies that hurt" (they kill already). The placeholder rooms were replaced.
