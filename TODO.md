# Current work

Updated 2026-11-10. This is the single active task list. [Documentation index](docs/README.md) · [Implementation ledger](docs/IMPLEMENTATION_STATUS.md) · [Merged reports](reports/README.md).

## Map delivery

Follow the [cluster/connector/secret/shortcut plan](docs/STORY_DESIGN.md#0-current-map-plan-room-clusters-and-branching-connections). Systems being available does not mean their content has been placed.

- [ ] Arrange dense, irregular room clusters separated by branching playable connectors; add local loops, regional shortcuts and reserved secret-room pockets. Most rooms stay low; each area has at least two varied rooms, with each boss arena a single tall room.
- [x] Place the crystal quest keeper near the top of the lighthouse interior; spread its five mages across landings. Sword is now taken from the dead skeleton after Sand Cave.
- [ ] Author the small ruins below the lighthouse: open entrance, at least two compact varied rooms, sword-breakable internal barriers, three unique interactable crystals and a short quest-return loop.
- [ ] Configure departure boat and arrival dock/lighthouse; keep sea left of West Shore and keep the two landmasses physically disconnected. First voyage must run the tentacle survival/shipwreck and leave no usable boat.
- [ ] Build the island's west → marsh → rocky plateau → volcano progression, north/south/east shore satellites, and maze/surface cross-links. Preserve useful existing rooms/IDs and hand-shaped shore pools.
- [ ] Place thick water, giant feet, heat previews, cool retreat points and later movement/heat-resistance rewards. Do not require giant climbing, hidden upgrades or an ability obtainable only beyond its own gate.
- [ ] Author the remaining [accepted rewards and village return route](docs/plans/PROGRESSION_REWARDS.md): Ape dash, marsh double jump, cool-foothill heat resistance and the canopy return. Sword/climb placements are delivered. The initial wavedash gap remains a pre-departure return gate, with a jump-only alternate route.
- [ ] Author teaching encounters for existing timed spikes/triggers/patrols and optional discoveries. New discoveries are interactable fragments, upgrades, NPCs or encounters; no new passive stars.
- [ ] Validate seams, four-sided resizing, conditional variants, safe entrances/spawns, progression-state reachability, quest events and shortcut travel times. Keep isolated movement tests separate from full encounter tests.

## Systems and design work

- [ ] Add accurate cornered coverage for further flying/leap/projectile runners as their shared models are implemented. [Grounded Hornback/library charge coverage is delivered](reports/ordinary-cornered-2026-11-10/README.md), alongside the existing Ape adapter.
- [ ] General enemy composition: conditions/phases, active summoners, configurable attached weapons/effects, conditional death actions, item drops and explosions. Shared health, patrol and brood foundations already exist.
- [ ] Implement the [reviewed Enemy-tab composition model](docs/plans/ENEMY_COMPOSITION_REVIEW.md) in small supported slices; preserve current Ape phase/loadout controls and existing catalogue/profile authority. The review is complete; generic runtime/schema/UI changes remain.
- [ ] Complete progressive occluded hidden-tile discovery, pogo/non-pogo hazard distinctions, damage-based tough walls and a distinct hidden-wall discovery sound. Punch reveal and three-hit sword-breakable walls already exist.
- [ ] Decide final stat names/budget and the multi-hit damage/knockback contract before implementing Dexterity/Constitution/Attack derivation or route-affecting base nerfs.
- [ ] Finish net capture animation, flexible bridges and lighthouse mirror/flame interaction; place dialogue/quests and agreed branch rewards.
- [ ] Author the accepted village skill-point quests and broader ability-page presentation. [Climb and stamina-orb policies are settled](docs/plans/PROGRESSION_REWARDS.md); dash crystals are removed.
- [ ] Evaluate positional audio and research elevation cues before implementing them.
- [ ] Develop region-specific real-world references/city-jungle direction and update visible legacy protagonist labels where appropriate; preserve licensed source names and save-directory compatibility.
- [ ] General story-event graph authoring, save slots, map stations, per-screen exploration and animation-driven state endings remain later system work; named flags and NPC transactions are already available.
- [ ] Optional private hosting remains undecided. Public web export/deployment is already configured; do not redo it as an unimplemented feature.

## Explicitly deferred and proposed

- **Ape true form:** keep the charcoal/silverback phase-two artwork deferred in `pixel-art/ape-phase2/`. Runtime uses the original Ape with its red pulse.
- **Older Kraken fight:** head-window combat, climbable tentacles, three phases, ink and Undertow are separate historical proposals. They are not requirements for the first crossing; ink geometry/cap and any future sea-return policy need decisions.
- **Reference-game ideas:** charms, crests, tools, familiars and the long ability catalogue are preserved in [the original backlog record](reports/consolidated/PROJECT_HISTORY.md#todo), not accepted implementation commitments.
- **Optimizations:** measure again before reviving deliberately rejected/deferred pooling, batching, undo-storage or label/grid changes. Historical measurements are in `OPTIMIZATION_RESULTS.md` and the merged history.

## Recent delivery

[Sword skeleton and branch reward](reports/sword-skeleton-2026-11-10/README.md): take Sword from the dead skeleton after Sand Cave; Climb is in Treetop Village. Keeper retains the crystal quest. Dash crystals are removed, including editor/runtime support and obsolete saved-room entities.

[Integer resources and scores](reports/integer-resources-2026-11-10/README.md): continuous accounting every twelve active physics frames; immediate action costs; legacy save truncation; integer stress percentages, heat controls, F3 and catalogue scores. Physics/input remain precise at 60 Hz.

[Checkpoint areas](docs/RESPAWN_POINTS.md) replace tiny map markers: user-drawn activation rectangles, lowest safe grounded anchors, airborne activation and 75 migrated story/layer checkpoints.

Retained [room layers](docs/ROOM_LAYERS.md) now keep interiors loaded with darkened, frozen inactive planes and active-only audio. The two Cove Town houses and lighthouse interior are layers; the lighthouse roof is part of Shore.

The [implementation ledger](docs/IMPLEMENTATION_STATUS.md) records delivered systems and limits: lighthouse quest/inventory/boat encounter, new environmental mechanics and abilities, HUD/stress capacity, full stamina regeneration, room resizing/variant synchronization, patrol/trap authoring, punch, attack controls and Ape triggers.

The original full checklist, completed entries and idea catalogue are preserved in [Project history](reports/consolidated/PROJECT_HISTORY.md#todo). Historical fix prompts and measurements are in the [report index](reports/README.md); reproduce old findings before promoting them to current tasks.
