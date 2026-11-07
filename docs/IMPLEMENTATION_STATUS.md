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

The non-map portion of the lighthouse/island follow-up is implemented: quest/unique crystals/sword reward, item/key transactions, named events, Items/Abilities pages, boat tentacle-dodging survival and shipwreck handoff, thick water, giant feet, heat, double jump/heat resistance, attached HUD and stress-capacity/30% rule. See [NONMAP_SYSTEMS.md](NONMAP_SYSTEMS.md) for authoring, defaults, verification and limits. All room layouts and entity placements remain unchanged; ruins, docks, NPC placements and movement-gated routes still need the map pass.

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
[PATROL_AUTHORING.md](PATROL_AUTHORING.md). Room and encounter anchors remain
explicitly excluded. Timed retracting spikes, trigger zones and pressure plates were subsequently implemented; see the current deferred-work audit in `docs/DEFERRED_WORK.md`.

## Implemented

| Request | Evidence / limits |
| --- | --- |
| Game title Be the Knight; protagonist Be | `project.godot:5`, `scripts/menu.gd:_main`, story/README. Legacy save-directory and source asset names intentionally remain stable |
| Ape falling/thrown logs share their consequences; splitting logs and impact spikes | `scripts/effects/attack_effects.gd`, `scripts/entities.gd:Ape`, `data/enemy_profiles.json`; actual Ape integration tested |
| Triggered Ape effects bypass attack selection, appear after selected attacks, and have live source descriptions | `scripts/attack_catalog.gd:effect_links`, `enemy_entries`, `select_attack`; profile-derived listing rather than a skip-100 workaround |
| Ape health/phase-entry threshold/wave scales editable | `scripts/attack_catalog_editor.gd:_ape_profile_fields`; profile is specific to Ape |
| One Ape page, compact inputs, Enemy loadouts open first, redundant right-side phase box removed | `scripts/attack_catalog_editor.gd:25`, `CSV_ENEMIES`, `_enemy_rows`, `_binding_controls`; phase-specific bindings remain independent |
| Stress 0–250, persistence, death/exhaustion gains and kill/collectible relief | `scripts/progression/stress.gd`, `adventure.gd`, world/entity hooks; five-bar HUD |
| Stress recovery targets 100/90/80/75/70/65%, interpolated | `Stress.RECOVERY`, `Adventure.regen_stamina`; no change to water/climbing/stun exclusions |
| Twelve-hour save-load rest relief with durable repeat-claim prevention | `scripts/game.gd:claim_stress_rest`, `save_adventure`, actual Continue flow; failed writes do not award relief |
| Research and architectural/encounter plans | `docs/MECHANICS_ARCHITECTURE_PLAN.md`, `BE_THE_KNIGHT_DESIGN.md`; research itself does not implement the plans |

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
