# Reports and review history

Merged 2026-11-07. Read [current implementation status](../docs/IMPLEMENTATION_STATUS.md) and [TODO](../TODO.md) before acting on an older finding. Reports describe their original baseline; historical “missing”, “fixed” and test results are not fresh claims about HEAD.

| Consolidated record | Contents |
| --- | --- |
| [Checkpoint areas](checkpoint-areas-2026-11-08/README.md) | User-drawn activation regions, lowest safe grounded anchors, airborne activation and 75 migrated checkpoints |
| [Retained room layers and map conversion](room-layers-2026-11-07/README.md) | Active/inactive planes, audio isolation, editor support, Cove Town houses and Shore lighthouse conversion (2026-11-08) |
| [Combat and editor deliveries](consolidated/COMBAT_AND_EDITOR.md) | Ape composition/follow-ups, attack catalogue/UI/triggers, corner coverage, punch, health/motion/brood foundations, patrols, stress and non-map story systems |
| [World and art](consolidated/WORLD_AND_ART.md) | Island design/reviews/connections, room sizing, progression, respawns/checkpoints, traversal, lake/art/accessibility reviews |
| [Code reviews](consolidated/CODE_REVIEWS.md) | Whole-codebase, Monster Editor and Ape reviews/fix prompts, Codex follow-up and Graphify/LightRAG output check |
| [Project history](consolidated/PROJECT_HISTORY.md) | Original design/development log, full old TODO/idea catalogue, previous implementation/deferred audits and code-health notes |
| [Merge provenance](consolidated/MANIFEST.json) | Original source paths and SHA-256 hashes, merged destinations and section anchors |

## How to interpret findings

- The November 7 non-map delivery records a complete verifier with **0 failing**: [verification.txt](nonmap-systems-2026-11-07/verification.txt). This is delivery evidence, not a new run during cleanup.
- The November 5 traversal-isolation report and later passing suite supersede the earlier “known Jungle Falls bot failure” baseline in patrol/foundation/stress reports.
- The November 4 Ape follow-ups close their five-task prompt; they do not claim that every item in the broader recursive audit was fixed. Preserve this distinction when choosing work.
- Earlier Monster Editor reviews include resolved findings and later follow-up findings. Reproduce a finding against the current code before treating an old severity list as a current bug count.
- The latest Codex commit review covered the earlier committed baseline, explicitly excluding the then-in-progress non-map work. Its old literal stress-HUD finding predates the replacement HUD; its clock/farming questions do not authorize gameplay changes.
- Graphify omitted GDScript/world data and missed newer rules/map planning. LightRAG's output location was not supplied. Both remain knowledge-source checks, not gameplay or map-connectivity proof.

## Evidence retained in place

Original directories keep PNGs, HTML viewers, JSON results, logs, captured scenes and probe scripts. Generated progression and room-safety outputs remain at their tool-defined paths. Old Markdown entry points redirect into the merged records, including their old section anchors. No assets, room data or regression fixtures were deleted.

Use original fix prompts as historical evidence only. For new work, make a fresh bounded prompt from current source, current requirements and a reproduced finding.
