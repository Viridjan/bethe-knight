# Story systems delivered 2026-11-07

This delivery implements the confirmed lighthouse/island systems without editing any file in `worlds/`. Later map delivery placed the lighthouse keeper and distributed its mages inside the [retained lighthouse layer](ROOM_LAYERS.md); Cove Town houses are also layers and the rooftop is in Shore. Crystals/ruins, boats, giants and upgrade locations still need their own map pass. The sand cave currently contains no sword orb.

## Quest and inventory

`StoryProgress` stores versioned items, quest stages and unique event flags in the existing adventure save. Speak to a `lighthouse_keeper` to receive Sword (`attack`) and start the three-crystal quest. `quest_crystal` is collected with Interact, only during the quest. Return all three to the keeper: exactly three are consumed once, the quest completes, and `boat_unlocked` is set. Repeat interactions cannot duplicate pickups, rewards or turn-in. Existing sword-breakable walls provide the ruins gate; the entrance itself can stay open.

The Map overlay has Map, Monsters, Items and Abilities tabs; Q/E or controller shoulders cycle them. Items shows crystals, quest status and other held items. Abilities lists owned sword, dash, wall climb, double jump and heat resistance. Sword and double jump are not automatically granted to every new run; the initial normal jump remains available.

The editor offers `lighthouse_keeper`, `dialogue_npc`, `quest_crystal`, `item_pickup`, `stress_block` and `boat`. Click a placed story entity again with its tool to edit it. IDs are generated on placement and regenerated on copy/paste; keep IDs stable when moving objects. The NPC settings allow `name`, `text`, `kind` (elf/mage), item requirements/rewards, required/set events, consume-items and repeatable. Collections use JSON: for example `{"red_key":1}` or `["gate_open"]`. Transactions preflight all requirements and reward capacity before changing anything. They default to once per NPC; a retained key is supported by leaving Consume items off. Advanced entity JSON also supports `locked_text`, `repeat_text` and an explicit `once_event`.

## Crossing

Size a `boat` rectangle, then configure its door destination as `room:door_id`, pointing to a real arrival door. An invalid destination refuses departure. The quest unlock is the only progression requirement; old full-stamina/max-stress/underwater checks do not apply.

The first crossing contains eight rushing tentacle waves, one-second jump/stay-low warnings, lateral movement and jumping on a large deck. Three impacts fail the attempt; retry or return to the departure dock. There is no Kraken health or sword combat. Surviving leads to a short wreck sequence, moves the player to the arrival door and saves `sea_crossed` plus `boat_lost`. The boat cannot then be reused. Encounter drawings are native canvas graphics; existing character art is reused.

## Environment and abilities

Room editor Environment and Heat drain controls use undo and persist in the room definition. `marsh`, `rocky_plateau` and `ruins` are supported theme aliases, currently reusing forest, shore and temple artwork respectively; they are not new bitmap art sets.

- `thick_water` is water for immersion/drain rules, with 45% horizontal swim speed and 70% stroke strength.
- `rock_giant` draws a huge leg/foot, patrols over supported ground, warns for 0.8 seconds, stomps and emits a brief ground wave. Run under the raised foot and jump the wave. It reverses at unsupported ground/obstacles and is not yet climbable.
- Volcano/volcanic-cave rooms default to heat drain of 2 stamina/second, with a red screen tint. Room `heat_drain` overrides this (0 disables it, allowed maximum 100). Heat replaces natural regeneration, also drains while climbing/stunned and adds to water loss. Zero stamina in heat is lethal.
- `ability_double_jump` grants one extra normal airborne jump, with normal jump stamina cost, rearmed on landing. `ability_heat_resist` disables heat loss/tint. Existing climb/dash ability gates remain available; actual routes and reward locations are map work.

## Stamina and stress

Top-left resource graphics contain two attached segmented rows with no text/icons: stamina above stress. Existing stamina tuning is preserved: base 27, +17 per upgrade; regeneration 4/8/3 per second at empty/half/full before stress.

New runs start with **one stress block**, an implementation default because starting capacity was unspecified. Old saves without capacity migrate to five blocks, preserving the former 0–250 range. Each block holds 50 stress; `stress_block` adds one block, up to 20, without adding stress. Existing gain/relief/rest rules remain.

Only completed stress blocks penalize regeneration: `30% × completed blocks / owned blocks`, capped at 30%. Thus four blocks give 7.5% per completed block; a partially filled block adds nothing. Capacity, stress, inventory, quests, pickups, abilities and events survive save/continue.

## Confirmed numeric policy and pending migration

Physics and input handling keep normal precision and cadence, including movement remainders,
collision, input buffering and attack timings/speeds. Only gameplay resources/scores and their
saved/editor/displayed values move to whole-number arithmetic. The approved 0.2-second tick is
for continuous resource accounting; it must not slow physics, input or one-off action costs.

The migration is **not implemented**. The fractional stress example above describes the current
runtime. The planned integer version keeps the same completed-block/30% policy, truncating the
cumulative percentage: four owned blocks produce 0/7/15/22/30% penalties. It must not restore
the older interpolated 35% curve. See the [migration plan](plans/WHOLE_NUMBERS_TICK.md) and
[decision record](DOCUMENT_CONFLICTS.md).

## Validation

`tests/nonmap_progression.tscn`, `tests/nonmap_entities.tscn` and `tests/sea_crossing.tscn` exercise transactions, migration/round-trip, capacity math, real entity interactions, inventory, water, heat, double jump, giants and boat handoff. They are included in `tools/verify.sh`. Screenshots and a reproducible in-memory preview are in `reports/nonmap-systems-2026-11-07/`; the preview writes no room files.

The older idea catalogue, unresolved stat/phase redesigns and explicitly deferred Ape transformation artwork remain separate proposals. This delivery does not claim that every historical backlog entry is complete.
