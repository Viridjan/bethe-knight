# Documentation

Use the current documents below for work. Dated reports and old prompts preserve history; they are not instructions to restore superseded behavior.

| Need | Read |
| --- | --- |
| Active tasks and deferred ideas | [TODO](../TODO.md) |
| What actually exists, including limits | [Implementation ledger](IMPLEMENTATION_STATUS.md) |
| Merge decision record | [Document conflicts](DOCUMENT_CONFLICTS.md) |
| Story, island progression and cluster/shortcut map plan | [Story design](STORY_DESIGN.md) |
| Quest/inventory/boat/environment/HUD implementation and authoring | [Non-map systems](NONMAP_SYSTEMS.md) |
| Project architecture and contribution | [Code guide](CODE_GUIDE.md), [adding entities](ADDING_ENTITIES.md), project `AGENTS.md` |
| Retained interiors and layer passages | [Room layers](ROOM_LAYERS.md) |
| Room/world editing and reachability tools | [World design](WORLD_DESIGN.md), [selection/snapping](WORLD_EDITOR_SELECTION.md), [progression explorer](PROGRESSION_REPORT.md), [terrain morphing](TERRAIN_MORPHING.md), [respawns](RESPAWN_POINTS.md) |
| Attacks, enemies, patrols | [Catalogue](ATTACK_CATALOG.md), [enemies](ENEMIES.md), [patrol authoring](PATROL_AUTHORING.md) |
| Plans awaiting implementation / decisions | [mechanics architecture](MECHANICS_ARCHITECTURE_PLAN.md), [attack scoring](ATTACK_SCORING_PLAN.md), [enemy patterns](ENEMY_PATTERNS.md), [older character/Kraken proposals](BETHE_KNIGHT_DESIGN.md) |
| Merged reviews, delivery evidence and historical design | [Reports](../reports/README.md) |

## Confirmed resource and timing rules

The [whole-number tick](plans/WHOLE_NUMBERS_TICK.md) is implemented. Physics and inputs retain normal precision and responsiveness. Whole-number rules apply to
resources and scores; the resource tick does not drive movement, input or attacks.
Stress uses completed blocks with a maximum 30% penalty. Both former conflicts are resolved. Details: [decision record](DOCUMENT_CONFLICTS.md)
and [implementation plan](plans/WHOLE_NUMBERS_TICK.md).

## Maintaining one source of truth

Record a task once in TODO; record implementation status once in the ledger. Keep detailed schemas/controls in the responsible guide, and design decisions in the responsible design document. Link between them rather than copying status checklists. A system being implemented does not imply its room content is placed.

When later user direction explicitly supersedes an older requirement, label the old text historical and link to the current rule. When two applicable requirements genuinely conflict and precedence is unclear, record the question in DOCUMENT_CONFLICTS and ask the designer before merging that rule. Do not promote proposals or old fix prompts into approved work.

Merged reports retain original source sections and an SHA-256 provenance manifest. Historical Markdown paths are small redirects so old links remain usable; screenshots, logs, data and runnable probes stay in their evidence directories. Refresh any knowledge index after document changes; generated knowledge graphs do not override current source instructions or prove runtime/map connectivity.
