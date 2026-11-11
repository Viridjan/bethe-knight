# Documentation decisions

Resolved by the designer on 2026-11-07. No documentation-merge questions remain open.

| Former conflict | Confirmed decision |
| --- | --- |
| Blanket decimal ban versus physics/timing exemptions | Physics and inputs follow normal precision and cadence to preserve responsiveness. Whole numbers apply to gameplay resources/scores and their saved/editor/displayed values. The slower resource tick must not drive movement, collision, input or attacks. |
| Old interpolated stress curve versus the newer HUD rule | Retain the newer completed-block rule, capped at a 30% regeneration penalty. The old interpolated 35% penalty is superseded. |

The decisions are reflected in `AGENTS.md`, [CODE_GUIDE.md](CODE_GUIDE.md) and the [tick migration plan](plans/WHOLE_NUMBERS_TICK.md). The resource-tick/integer migration was implemented on 2026-11-10; see the [delivery report](../reports/integer-resources-2026-11-10/README.md). Current runtime behavior remains documented in [NONMAP_SYSTEMS.md](NONMAP_SYSTEMS.md).

For the whole-number calculation, truncate the **cumulative** stress percentage: `30 * completed_blocks / owned_blocks`. Four owned blocks give 0/7/15/22/30% penalty as blocks fill; a partial block adds nothing. Do not repeatedly add a separately truncated 7% share, which would incorrectly cap four blocks at 28%.

## Already settled by explicit later direction

These are historical changes, not new unresolved choices:

- **2026-11-10 supersedes the November 7 sword location:** take Sword from an interactable dead skeleton just after Sand Cave. Climb is on the opposite Treetop Village branch; the keeper retains the crystal quest. Dash crystals are removed. See [accepted rewards](plans/PROGRESSION_REWARDS.md).
- First crossing uses the crystal quest and tentacle survival/shipwreck, with no old full-energy/max-stress/underwater entry gate.
- Map topology uses dense clusters, branching connectors, secrets and shortcuts; shore-to-shore sea travel cannot become a walking seam.
- Passive stars are legacy; new discoveries must be interactable.
- Base stamina is 27 +17 per block, with 4/8/3 recovery tuning. Older 32/+20 or 2/6/3 descriptions are historical.
- Public web export/deployment already exists; the old “Web version missing” checkbox is stale. Private hosting remains separate.
