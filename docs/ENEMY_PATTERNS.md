# Enemy movement and attack candidates

Research notes, 2026-10-30. This is a design backlog, not an implementation checklist
of features currently missing. Summit already has reusable patrol, hop, hover,
charge, leap, and shooting primitives in `scripts/monster_library.gd`; audit and
reuse them before adding variants.

Movement determines where an enemy goes; an attack determines when and how it
threatens the player. Combine one simple movement pattern with one attack first.
The taxonomy and Summit applications below are design proposals synthesized from
the references, rather than an official classification used by those games.

## Movement

| Pattern | Behavior | Suggested placement |
|---|---|---|
| Roamer / patroller | Walks between limits; turns at walls and optionally at ledges | Ordinary floors |
| Pursuer | Approaches when the player enters detection range; stops chasing outside it | Open platforms |
| Rhythmic hopper | Repeats short jumps with predictable pauses | Uneven ground |
| Targeted jumper | Chooses the player's position at takeoff and jumps toward it | Wider rooms |
| Wall-to-wall jumper | Clings, telegraphs, jumps to the opposite wall, then pauses | Tall tunnels with safe landing space |
| Surface crawler | Follows floors, walls, and ceilings | Cavern outlines |
| Hoverer / wave flyer | Follows a straight or oscillating aerial path | Open air above platforms |
| Ambusher | Waits on a ceiling, wall, or underground until triggered | Clearly signposted ambush spots |

## Attacks

| Pattern | Threat | Player response to design for |
|---|---|---|
| Contact / body bump | Its normal movement makes touching it dangerous | Jump over or keep distance |
| Short melee swipe | Stops and attacks a small area ahead | Bait the swing, retreat, counter |
| Thrust / lunge | Fast forward reach after a clear windup | Step away or jump across |
| Ground charge | Commits to a horizontal rush with limited steering | Jump it; punish the recovery |
| Leap / pounce | Arcs toward a chosen landing point | Move after the target is committed |
| Ceiling drop / dive | Drops or dives from above, then recovers | Read the warning and move sideways |
| Slam / shockwave | Hits nearby ground; optional traveling wave | Leave the impact area or jump the wave |
| Straight projectile | Fires along a fixed direction | Cross between shots |
| Aimed shot | Aims at the player's position when fired | Move after the shot is committed |
| Burst / spread | Fires several shots in sequence or a fan | Read the gaps and firing rhythm |
| Lobbed bomb | Arcing projectile lands and detonates after a delay | Leave the landing zone |
| Returning projectile | Travels out and back | Account for both passes |
| Beam / sweep | Warns along a line or arc before damaging it | Leave the marked path |
| Area denial | Leaves a temporary pool, cloud, spikes, or trail | Take a different safe route |
| Shield bash / counter | Guards one side, then retaliates | Flank or bait an opening |
| Suicide explosion | Approaches, signals detonation, then explodes | Create distance during its warning |
| Summon / split | Produces smaller threats, possibly on death | Prioritize the source; cap active children |

## Suggested first set for Summit

1. Audit existing roaming/contact, hopping, charge, leap, and bolt attacks.
2. Add a wall-to-wall jumper, with a readable cling/windup and landing pause.
3. Add a ceiling ambusher and a lobbed projectile variant.
4. Add spread shots, shockwaves, and temporary hazard zones later, once ordinary
   rooms give enough space to avoid them.

For active attacks, specify windup, committed attack, recovery, cooldown, target
selection, interruption rules, and what ends the attack. Movement-driven contact
hazards instead need readable paths and turn/jump timing. Do not require abilities
that the player has not unlocked; introduce patterns alone before combining them.

## References and observed examples

- [Metroid original instruction manual](https://metroid.retropixel.net/games/metroid/manual/metroid1_manual.pdf):
  its enemy descriptions include jumping attackers such as Dessgeega. Primary
  source; useful for simple enemies differentiated by movement.
- [Dead Cells enemy catalogue](https://deadcells.wiki.gg/wiki/Enemies): community
  reference for bat charges, delayed grenades, wall-passing bolts, and explosive
  enemies. Use the pattern, not necessarily its wall-passing rules, in Summit.
- [Hollow Knight: Mantis Youth](https://hollowknight.wiki/w/Mantis_Youth): community
  reference for a wall/ceiling ambusher. This is inspiration for the wall-jumper
  proposal, not evidence that it repeatedly jumps between opposite walls.
- [Enemy design and enemy AI for melee combat systems](https://www.gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems):
  design discussion of readable tells, attack timing, recovery, and coordination
  between multiple enemies.
