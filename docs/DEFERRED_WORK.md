# Deferred-work audit — updated 2026-11-07

Checked TODO.md, IMPLEMENTATION_STATUS.md, the architecture and Be/Kraken design plans, the entity registry, and the existing editor/runtime primitives. This is a backlog audit, not authorization to implement all proposals.

## Latest confirmed systems delivered

The non-map lighthouse quest, sword reward, unique crystal pickups, item/key transactions, persistent story flags, Items/Abilities tabs, boat survival/shipwreck encounter, thick water, plateau giant feet, heat, double jump/heat resistance and attached HUD/stress upgrades are implemented. See [NONMAP_SYSTEMS.md](NONMAP_SYSTEMS.md) for concrete behavior, defaults and authoring.

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
