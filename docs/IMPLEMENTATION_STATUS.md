# Current implementation ledger

Updated 2026-11-07. This ledger consolidates the old implementation/deferred audits and subsequent delivery records. It distinguishes runtime systems from authored content and proposals. Current work belongs in [TODO](../TODO.md); historical audits are preserved in [Project history](../reports/consolidated/PROJECT_HISTORY.md).

| Area | Delivered | Remaining / limits |
| --- | --- | --- |
| Identity | Bethe Knight title; Be as protagonist; stable legacy save/asset identifiers | Real-world regional references and visible legacy gallery labels |
| Lighthouse quest | Keeper grants Sword, unique three-crystal inventory, one-time turn-in, boat unlock, saved stages/events | NPC/crystal/ruins/boat placements; move sand-cave sword during map pass |
| Inventory / dialogue | Map, Monsters, Items, Abilities tabs; NPC item/event requirements/rewards; consumed or retained keys; persistent IDs and copy/paste behavior | General story-event graphs; skill-point/stat allocation and broader ability UI |
| First crossing | Quest-unlocked tentacle survival, retry/failure, shipwreck and destination handoff; lost-boat flag | Authored departure/arrival docks and lighthouse; future return voyage not decided |
| Island mechanics | Thick water, giant feet with warning/stomp, heat tint/drain, double jump and heat resistance | Room/route/reward placement; giant climbing; new marsh/plateau/ruins bitmap sets (themes currently reuse art) |
| Stamina / stress | Full regeneration of owned stamina bars, base 27 +17/block; 4/8/3 per-second empty/half/full rates; attached segmented HUD; owned stress capacity/upgrades | Whole-number resource-tick migration not started; [decisions resolved](DOCUMENT_CONFLICTS.md), preserving normal physics/input precision |
| Current stress behavior | Completed-block penalty up to 30%; new runs default to one block, legacy saves to five; death/exhaustion/kill/collectible/rest rules persist | Starting capacity is an implementation default; the older interpolated curve is historical. The tick plan now retains the newer rule, using cumulative integer percentage truncation |
| Retained room layers | Preloaded planes, frozen inactive state, black backdrop, active-only audio/input/collision; editor creation/selection/passages, full-room save/resize/undo and checkpoints | Layer rename/removal UI and comprehensive offline layered progression analysis remain future work |
| House / lighthouse content | Cove Town house layers; Shore rooftop/flame/mirror; narrow lighthouse interior with five vertically distributed mages and keeper | Crystal ruins and quest/boat route authoring remain separate map work |
| Checkpoint areas | User-drawn activation regions, lowest safe grounded anchors, airborne activation, overlap priority; 75 story checkpoints migrated, including layers | Legacy point markers remain compatible; layer entrances require an authored region to replace the checkpoint |
| Room / world editors | Resize any edge/corner; coordinate/path translation; conditional-variant synchronization; selection/snapping; environment/heat controls | Actual new map cluster/shortcut plan remains unbuilt; author/test transitions after rearranging |
| Patrol / traps | Surface/sticky/path movement authoring, preview/undo/save; moving-body adapters; timed spikes, zones/plates and typed trap/movement links | Additional trap types, teaching rooms, general phase/condition graphs |
| Combat / terrain | Tiny punch, shared sword costs, direct hidden-wall reveal without wall damage; sword breaks walls; persistent discovery | Shared multi-hit player damage, pogo taxonomy, occluded discovery, tough-wall damage policy and discovery sound |
| Enemy foundations | Family HP authoring/modifiers, shared floor/crawler motion, bounded brood death spawns | General attack/effect/phase/death-action composition, summoning and stat damage |
| Ape / catalogue | Phase health/entry and effects; profile-derived follow-ups/tooltips; blocked split handling; catalogue save rollback; compact attack fields, max Range, per-phase triggers and cornered coverage | Other-enemy coverage adapters; broader consequence scoring/model decisions; true-form art explicitly deferred |
| Traversal checks | Encounter-free jump-only copy for movement tests; separate encounter fixtures; current shore-pool exemptions | A movement-only pass does not establish full quest/progression reachability |
| Persistence / web | Crash-safe save/read/backup paths, durable rest claims; web preset and deployment workflow | Save slots/private hosting decisions; no new deployment performed during cleanup |

## Authoritative detail

- [Story/map plan](STORY_DESIGN.md): current topology and progression; historical route notes are labelled below it.
- [Non-map systems](NONMAP_SYSTEMS.md): actual mechanics, IDs, editor fields, defaults and save behavior.
- [World authoring](WORLD_DESIGN.md), [patrols](PATROL_AUTHORING.md), [attack catalogue](ATTACK_CATALOG.md), [progression explorer](PROGRESSION_REPORT.md): current tool guidance, with dated examples labelled where needed.
- [Mechanics architecture](MECHANICS_ARCHITECTURE_PLAN.md), [enemy patterns](ENEMY_PATTERNS.md) and [attack scoring plan](ATTACK_SCORING_PLAN.md): proposals/dependencies, not completion evidence.

## Verification provenance

The non-map delivery's recorded complete verifier finished with **0 failing**; see [its log](../reports/nonmap-systems-2026-11-07/verification.txt) and [merged delivery record](../reports/consolidated/COMBAT_AND_EDITOR.md#reports-nonmap-systems-2026-11-07-readme). Earlier reports of a Jungle Falls bot failure remain historical; the later traversal isolation and full verification supersede that baseline.

This documentation cleanup is not a new gameplay audit and does not reclassify every old review finding as fixed. Review baselines, screenshots and raw logs remain available in the merged reports.
