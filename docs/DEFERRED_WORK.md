# Deferred-work audit — 2026-11-05

Checked TODO.md, IMPLEMENTATION_STATUS.md, the architecture and Be/Kraken design plans, the entity registry, and the existing editor/runtime primitives. This is a backlog audit, not authorization to implement all proposals.

## Explicitly saved for later

- **Ape phase-two true form.** Charcoal/silverback artwork and animation preview are in `pixel-art/ape-phase2/`. TODO explicitly says to keep this deferred; runtime currently uses the original Ape with a red pulse.

## Requested systems still incomplete

- **Kraken/boat encounter:** entry-condition presentation, underwater-capability integration, tentacles/head windows, sweep/radial phases and ink overlays. The eligibility helper and design exist; the encounter does not. Undertow is only a proposed extra attack.
- **Inventory, keys, quests and story transactions:** Map has no item inventory. General item consumption/retention, NPC quest branches, raft unlocks and reusable one-time event authoring remain missing or specialised.
- **Stats and damage:** Dexterity/Constitution/Attack allocation, derived values, multi-hit player damage and stat-based attack damage. Final naming/budget and route-safe movement/recovery changes still need decisions. The basic punch/sword costs are already implemented.
- **General enemy composition:** extracted health, movement, brood and Ape effects exist, but general phases/conditions, active summoners and attached attack effects are not a complete shared system. Broader Enemy-tab redesign is still a proposal requiring review.
- **Terrain/content:** progressive occluded tile discovery, pogo/non-pogo hazard distinctions, damage-based tough walls, additional timed-trap types, and Lake Caves/jungle teaching routes. Punch-revealed hidden walls already exist; a dedicated discovery sound is still absent.
- **Chapter-one story interactions:** full dialogue/quests, net capture animation, flexible moving bridges, raft quest behavior and lighthouse mirror/flame puzzle. Elf/mage artwork is not evidence of implemented quests or dialogue. Branch destinations and several rewards remain undecided.
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
