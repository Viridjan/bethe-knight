# Story systems delivered 2026-11-07

This delivery implements the confirmed lighthouse/island systems without editing any file in `worlds/`. Later map delivery placed the lighthouse keeper and distributed its mages inside the [retained lighthouse layer](ROOM_LAYERS.md); Cove Town houses are also layers and the rooftop is in Shore. Crystals/ruins, boats, giants and upgrade locations still need their own map pass. The sword now comes from the dead skeleton on Shore after Sand Cave; Climb is placed in Treetop Village.

## Quest and inventory

`StoryProgress` stores versioned items, quest stages and unique event flags in the existing adventure save. Interact with `dead_skeleton` after Sand Cave to receive Sword (`attack`) once; the bones remain. Speak to a `lighthouse_keeper` to start the three-crystal quest. The keeper does not grant Sword. `quest_crystal` is collected with Interact, only during the quest. Return all three to the keeper: exactly three are consumed once, the quest completes, and `boat_unlocked` is set. Repeat interactions cannot duplicate pickups, rewards or turn-in. Existing sword-breakable walls provide the ruins gate; the entrance itself can stay open.

The Map overlay has Map, Monsters, Items and Abilities tabs; Q/E or controller shoulders cycle them. Items shows crystals, quest status and other held items. Abilities lists owned sword, dash, wall climb, double jump and heat resistance. Sword and double jump are not automatically granted to every new run; the initial normal jump remains available.

The editor offers `dead_skeleton`, `lighthouse_keeper`, `dialogue_npc`, `quest_crystal`, `item_pickup`, `stress_block` and `boat`. Click a placed story entity again with its tool to edit it. IDs are generated on placement and regenerated on copy/paste; keep IDs stable when moving objects. The NPC settings allow `name`, `text`, `kind` (elf/mage), item requirements/rewards, required/set events, consume-items and repeatable. Collections use JSON: for example `{"red_key":1}` or `["gate_open"]`. Transactions preflight all requirements and reward capacity before changing anything. They default to once per NPC; a retained key is supported by leaving Consume items off. Advanced entity JSON also supports `locked_text`, `repeat_text` and an explicit `once_event`.

Dash and double-dash crystals are retired from gameplay and the editor. Older saved rooms discard their definitions and trigger links to them on load. Stamina orbs remain full-energy refills with a 2.5-second recharge; normal dash recovery through landing/movement remains.

## Crossing

Size a `boat` rectangle, then configure its door destination as `room:door_id`, pointing to a real arrival door. An invalid destination refuses departure. The quest unlock is the only progression requirement; old full-stamina/max-stress/underwater checks do not apply.

The first crossing contains eight rushing tentacle waves, one-second jump/stay-low warnings, lateral movement and jumping on a large deck. Three impacts fail the attempt; retry or return to the departure dock. There is no Kraken health or sword combat. Surviving leads to a short wreck sequence, moves the player to the arrival door and saves `sea_crossed` plus `boat_lost`. The boat cannot then be reused. Encounter drawings are native canvas graphics; existing character art is reused.

## Environment and abilities

Room editor Environment and Heat drain controls use undo and persist in the room definition. `marsh`, `rocky_plateau` and `ruins` are supported theme aliases, currently reusing forest, shore and temple artwork respectively; they are not new bitmap art sets.

- `thick_water` is water for immersion/drain rules, with 45% horizontal swim speed and 70% stroke strength.
- `rock_giant` draws a huge leg/foot, patrols over supported ground, warns for 0.8 seconds, stomps and emits a brief ground wave. Run under the raised foot and jump the wave. It reverses at unsupported ground/obstacles and is not yet climbable.
- Volcano/volcanic-cave rooms default to heat drain of 2 stamina/second, with a red screen tint. Room `heat_drain` overrides this (0 disables it, whole numbers, allowed maximum 100). Heat replaces natural regeneration, also drains while climbing/stunned and adds to water loss. Zero stamina in heat is lethal.
- `ability_double_jump` grants one extra normal airborne jump, with normal jump stamina cost, rearmed on landing. `ability_heat_resist` disables heat loss/tint. Existing climb/dash ability gates remain available; actual routes and reward locations are map work.

## Stamina and stress

Top-left resource graphics contain two attached segmented rows with no text/icons: stamina above stress. Existing stamina tuning is preserved: base 27, +17 per upgrade; regeneration 4/8/3 per second at empty/half/full before stress.

New runs start with **one stress block**, an implementation default because starting capacity was unspecified. Old saves without capacity migrate to five blocks, preserving the former 0–250 range. Each block holds 50 stress; `stress_block` adds one block, up to 20, without adding stress. Existing gain/relief/rest rules remain.

Only completed stress blocks penalize regeneration: `30% × completed blocks / owned blocks`, capped at 30%. Truncate the cumulative percentage: four blocks give 0/7/15/22/30% penalties as blocks complete; a partially filled block adds nothing. Capacity, stress, inventory, quests, pickups, abilities and events survive save/continue.

## Integer resources and resource tick — 2026-11-10

Stamina, stress, resource rates, action costs and final attack/enemy scores are whole numbers.
Legacy fractional stamina/stress truncate on load; new saves store integer resources. Enemy HP
already uses validated whole numbers. Geometry, movement, collision remainders, input buffers,
attack timings/speeds and the physics timestep retain their normal precision at 60 Hz.

Only continuous resource accounting runs every twelve active physics frames (0.2 seconds at
normal speed). Since 2026-11-11 that tick covers drains only (water, heat, climbing): regeneration is paced per active frame, the same whole rate per second added one point at a time at an even pace. Pausing, frozen frames and inactive layers do not advance that world's resource
clock. As specified by the frame-based plan, the resource clock counts active frames rather than
scaled `dt`; assist game speed still scales movement/timers. A stateless integer share distributes
each whole per-second rate over five resource ticks, so small rates are not lost to rounding.

Regeneration computes a whole fill percentage, integer interpolation of the 4/8/3 curve, then
truncates its stress adjustment. Water drains 40 points/second (8/tick). Heat defaults to 2/second,
suppresses natural regeneration and adds to climbing or water drain; it continues during stun.
Existing stun/climb/water precedence remains. Adventure climbing drains 11/second upward,
2/second holding and zero descending, after the existing grab grace. Standalone climb physics
keeps its original precise 110-unit meter. Airborne climb jumps pay an additional 6 points plus
the ordinary 5-point jump cost. Jump, attack, pickup and hard-landing/exhaustion events are
immediate between resource ticks. Exhaustion and grey hair use the truncated threshold `max / 5`.

The F3 panel uses whole resource values/rates and integer stress percentages; graph positions
and elapsed seconds retain precision. Room heat controls step by one and saved room validation
rejects fractional heat rates. Attack/enemy scoring truncates at each returned score boundary;
CSV and editor totals are whole numbers while timing/geometry calculations remain precise.

Integer truncation changes effective regeneration and refill times; this is not identical to the
old fractional balance. Measurements and the HUD capture are in the [delivery report](../reports/integer-resources-2026-11-10/README.md).
See the [implemented plan](plans/WHOLE_NUMBERS_TICK.md) and [decision record](DOCUMENT_CONFLICTS.md).

## Validation

`tests/integer_resources.tscn`, `tests/nonmap_progression.tscn`, `tests/nonmap_entities.tscn` and `tests/sea_crossing.tscn` exercise transactions, migration/round-trip, capacity math, real entity interactions, inventory, water, heat, double jump, giants and boat handoff. They are included in `tools/verify.sh`. Screenshots and a reproducible in-memory preview are in `reports/nonmap-systems-2026-11-07/`; the preview writes no room files.

The older idea catalogue, unresolved stat/phase redesigns and explicitly deferred Ape transformation artwork remain separate proposals. This delivery does not claim that every historical backlog entry is complete.
