# Point 3: accepted rewards and resource policies

Confirmed by the designer on 2026-11-10, with sword placement and crystal removal superseding the earlier proposal. [Delivery queue](REMAINING_WORK.md).

| Reward | Location / rule | Delivery |
| --- | --- | --- |
| Sword | Interact with the dead skeleton after Sand Cave, on Shore's entrance landing | Placed; keeper no longer grants it |
| Climb | Opposite branch, Treetop Village; optional | Placed on the safe village floor |
| Dash / wavedash | First Ape victory grants dash; wavedash is a technique, not another unlock | Accepted; victory integration remains later work |
| Double jump | Visible marsh-exit reward before plateau height gates | Accepted; later map work |
| Heat resistance | Cool volcano foothill shelter, before sustained heat | Accepted; later map work |

The shipwreck is one-way. Mainland returns are unnecessary; island progression must work without optional mainland climb. No duplicate island climb reward is required. Before sailing, the village canopy route should reconnect to the jungle/town side, avoiding the sealed chase.

The lighthouse keeper starts the three-crystal ruins quest and unlocks departure at turn-in. The sword comes from the skeleton. Preserve existing owned swords in older saves.

Dash crystals and double-dash crystals are removed entirely. Ordinary dash recovery from landing and existing movement actions remains. Old room files discard retired crystal entities and links to them when loaded.

Accepted resource policies:

- Climb drain: 11 upward / 2 holding / 0 descending; airborne climb jump costs 6 extra plus the ordinary 5.
- Reusable stamina orbs refill all owned energy and recharge after 2.5 gameplay seconds; no stress relief or permanent reward.
- Three energy fragments grant one +17 capacity upgrade. No extra automatic Ape capacity block. Required routes work at base capacity, full stress and without optional climb/upgrades.
- Keep ordinary jump cost 5, attack attempt 2 and first accepted enemy hit surcharge 4; new runs start with one stress block. Stat work must explicitly review any change to these baselines.
- One skill point per settlement quest, once: Cove's two resident conversations, Treetop's safe training circuit, and the lighthouse crystal turn-in. These quests/points remain to be authored; point 4 owns the stat balance/spending contract. They do not gate movement abilities.

Required order: jump-only start → Ape/dash → Sand Cave → skeleton/Sword → lighthouse crystal quest → boat/shipwreck → marsh double jump → cool foothill heat resistance → sustained hot routes. Optional Treetop/climb branches after the Ape and before departure. Each reward is reached without requiring itself. Physical gates, shortcut timing, village training and later room layouts still need blockout validation.

Runtime/map delivery for this correction is recorded in [the skeleton report](../../reports/sword-skeleton-2026-11-10/README.md). Point 3 design decisions are settled; point 4 is next.
