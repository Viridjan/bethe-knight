# Bethe Knight: identity, Kraken, and character progression

Historical character/stat/Kraken design from 2026-11-05. The identity framing remains applicable; the old Kraken entry gates, combat proposal and interpolated stress curve below are **not the current first-crossing specification**. Current implementation: [NONMAP_SYSTEMS.md](NONMAP_SYSTEMS.md). Current map/progression: [STORY_DESIGN.md](STORY_DESIGN.md). The whole-number scope and newer stress rule are confirmed in [DOCUMENT_CONFLICTS.md](DOCUMENT_CONFLICTS.md). Old proposals are retained here for review, not automatically promoted to active tasks.
The application/menu title and protagonist references have been renamed. Existing
save directories, source asset paths, content IDs and hosted URL remain stable.

## Identity

The game is **Bethe Knight**. The protagonist is **Be** (she/her). Most opponents
are entities within her. Regions reference real-world experiences; the jungle may
suggest a city jungle. Keep references grounded in encounters, scenery and dialogue
rather than assigning unapproved psychological explanations to every enemy.

## Current implementation and dependencies

The Ape already shares ordinary thrown/falling logs, impact spikes, splitting logs,
area effects, editable health/phase-entry settings and a combined loadout page.
The reusable effects are in `scripts/effects/attack_effects.gd`; its decisions and
encounter orchestration still live in `entities.gd`. A general enemy composition
runner is **not** implemented. The attack catalogue is not yet a general scripting
language. Trigger-only effects bypass selection rather than rolling a 100% skip.

General traps/triggers, arbitrary-object patrol, inventory/keys, isolated story
modules, hidden-terrain changes and the teaching-room pass remain in
[the mechanics architecture plan](MECHANICS_ARCHITECTURE_PLAN.md). They are not
completed by this design. Preserve the user's current jungle room edits.

## Kraken availability and explicit information

Confirmed 2026-11-05: the boat encounter requires **exactly one full energy bar**
(the base bar, with upper bars empty), **five full stress bars (250 stress)**,
and the ability to remain underwater. Death count is not an independent gate;
deaths increase stress. Energy and stress are separate resources.

The underwater capability ID/duration and boat interception policy remain pending.
Evaluate entry on boat interaction and latch the result for the attempt: changes
to stress/energy during the fight do not abort or restart it.

| Condition | Source | Player feedback |
| --- | --- | --- |
| `kraken_not_defeated` | Saved encounter progress | Defeated encounter no longer intercepts the route |
| `kraken_stress_ready` | Stress equals its cap, 250 | “Stress: 5/5 full bars” |
| `lowest_energy_bar` | Stamina equals base-bar capacity | “Energy: exactly one full bar; upper bars empty” |
| `can_remain_underwater` | Ability/equipment capability | Show missing capability by its eventual display name |
| `boat_route_available` | Existing route/item requirements | Ordinary boat requirements also remain visible |

Energy is currently stored as `stamina`: base-bar capacity is
`Adventure.BASE_STAMINA` (currently 32); upper bars add 20 each. Compare stamina to
BASE_STAMINA with a small float tolerance, not total capacity or hardcoded 32.
Zero and a partly filled first bar do not qualify. A run with only one capacity bar
can meet this energy condition; it still needs the stress and underwater conditions.

Show a boat checklist with text and met/unmet states, and repeat the requirements
in the map/inventory encounter description. No hidden death quota. Denied entry
must consume neither items nor energy. Proposed: unmet boss conditions should
leave an otherwise valid boat trip available, rather than strand Be between islands.

## Stress: confirmed rules and regeneration targets

Implemented 2026-11-05 in `scripts/progression/stress.gd`, integrated into stamina,
real death/kill/collection events, saved runs and the HUD. The Kraken requirement
report is a tested API; the boat/underwater capability and actual encounter remain
planned. The API does not claim to provide a playable Kraken encounter.


Stress has **five bars of 50**, a total range of **0–250**, and starts at **0**.
Higher stress slows stamina recovery. It persists across deaths and save/load.
Always clamp changes into the range; a “bar” reduction subtracts 50 points, not a
rounded bar index, and may leave partial bars.

| Event | Stress change | Rule |
| --- | --- | --- |
| Death | +20 | Once per actual death; preserve the result through respawn |
| Reaching white hair | +5 | Once per exhaustion entry, not once per frame |
| Kill an ordinary monster | −50 | Once per actual kill |
| Kill a boss | −100 | Replaces the ordinary-kill reduction; not −150 |
| Obtain a collectible | −100 | Once per genuine collection event |
| Open a saved run after at least 12 hours since saving | −100 | One reduction on that load, not one per elapsed 12-hour interval |

Implemented interpretation: white hair means the stamina exhaustion
condition (currently below 20% of total stamina), not merely grey hair after a dash.
The renderer also greys hair when no dash is available, so stress must observe the
resource transition directly, not sample `hair_color()` or change state from drawing.
Recovery rearms the exhaustion event. Loading/rebuilding a room while already
exhausted must not repeatedly add five. Decide whether a small rearm hysteresis is
needed during tuning to avoid repeated threshold crossings.

Collection/kill callbacks must not fire again on reload, duplicate damage,
or replaying a presentation event. Collectibles here include permanent fragments,
capacity/ability pickups and legacy stars. Reusable stamina orbs and dash-refill
crystals restore a resource; they do not count as permanent collectible acquisitions. A boss plus an actual collectible reward can
legitimately reduce stress twice: −100 for victory and −100 for collection, clamped
at zero. Do not silently suppress one of these distinct user-specified events.
Respawned monsters can reduce stress on later genuine kills unless explicitly
designed otherwise; no unique-enemy/farming restriction has been approved.

**Recovery targets, updated 2026-11-05:**

| Stress | Recovery speed |
| --- | --- |
| 0 | 100% |
| 50 | 90% |
| 100 | 80% |
| 150 | 75% |
| 200 | 70% |
| 250 | 65% |

All targets are now implemented. For partial bars, recovery interpolates
linearly between neighbouring targets, rather than using the previous single
linear formula. Multiply the existing stamina-dependent recovery rate by the
stress factor and the Constitution modifier once. At maximum stress a refill
takes approximately 1.54 times as long under otherwise identical conditions.
Retain existing no-regeneration rules (water, climbing, stun); stress must not
grant regeneration where it is currently disallowed. Constitution tuning remains separate from the implemented stress system.

Avoid zero recovery: a death already adds stress, and making recovery stop could
trap the player in a cycle of further deaths. Conversely, five ordinary kills clear
maximum stress; check encounter density before adding anti-farming rules.

### Persistence and twelve-hour recovery

Store stress and a real UTC last-save timestamp per saved run; old saves migrate
to zero stress without a retroactive rest bonus. Use wall-clock elapsed time while
the game was closed, not the current playtime counter. Exactly 12 hours qualifies;
24 hours still grants only the specified −100, not −200. Backwards clock movement
must not grant a bonus or create negative elapsed time.

A qualifying load must durably record the reduced stress and a consumed rest
claim/new timestamp through the existing safe-save transaction before treating
that reduction as committed. Reopening the same old file repeatedly must not
award it again. Failed writes leave the prior save recoverable and must not claim
the rest was durably consumed. Merely browsing the save menu or entering a playtest
must not claim recovery. Define the timestamp update on successful saves, and show
a brief “Rested: stress −100” message only for an actual claimed reduction.

Regression coverage: fresh zero, cap/floor, deaths persist, exhaustion enters once and
rearms, dash-only grey gives no stress, boss kill does not double-count, legitimate
reward collection still applies, duplicate pickups/kill callbacks do not, old-save
migration, 11:59:59 versus 12:00:00, 24-hour single bonus, repeated load protection,
failed save recovery, clock rollback, isolated run slots and stress-independent
no-regeneration states. Kraken requires all five full stress bars and exactly the
full first energy bar, but stays active if the values change after entry.

**Important dependency:** existing water drains 40 stamina/second. A base bar would
last at most 0.8 seconds, so lower-energy entry cannot use ordinary swimming rules
unchanged. The underwater capability must define sustained breathing/energy policy
for the encounter. Dexterity improves steering; it does not silently grant breathing.

## Encounter ownership and lifecycle

A named `kraken_boat_encounter` owns boat interception, arena handoff, opening
sequence, encounter-local ink and victory. The Kraken enemy owns health, phase and
attack selection. Tentacle objects own their collision/platform state. Presentation
owns the dark overlay; none of those modules checks boat story flags internally.

Suggested flow:
`boat interaction -> condition report -> encounter start -> opening tentacles ->
head reveal -> attack/recovery cycles -> phase transitions -> defeat -> boat route`.

Consume an activation token immediately to reject repeated boat presses. Keep
persistent defeat/reward facts separate from an attempt's timers and effects.
On death/retry/exit cancel attacks, release attached platforms, clear ink and restore
camera/audio/input. A failed attempt must not set a permanent “already played” flag
that prevents retry. Save victory and its unique reward through the existing safe
save path, with stable event IDs to prevent duplication.

## Attack model

An attack has wind-up, active and recovery states. Spawned effects receive a stable
owner/attempt ID, definition ID and parameters; they emit local events such as
`reached_pose`, `head_hit`, `finished` and `owner_cancelled`. Phase tuning is read at
attack start, so a transition does not mutate tentacles halfway through a motion.

| Attack | Required behaviour | Proposed implementation and fairness rule |
| --- | --- | --- |
| Opening reach | Tentacles approach Be from several directions, then head appears centrally | Authored opening sequence, once per attempt. Clearly telegraphed safe lane; no random unavoidable opening hit |
| Tentacle ascent | Tentacles slowly descend into climbable platforms; hurt from below, safe above; reach head for one hit | Separate one-way support surface and underside damage region following the same tentacle pose. Do not mark the whole collider dangerous. Vulnerability token permits one accepted head hit per window, not one hit per physics tick |
| Ink sweep | Head submerges, ink applies; four horizontal rounds, random first top/bottom, then alternating, gaps shorten | Choose start lane once, generate deterministic four-entry schedule. Telegraph each lane; clamp interval to a tested reaction floor. Recover to a visible safe pose |
| Radial tentacles | Show tentacles, then extend as radial spikes | Fixed origins/directions per volley, visible wind-up. Adjacent safe angular gaps must fit Be's body and achievable movement |
| **Undertow** (proposal) | A visible current draws Be toward a marked danger lane; tentacles offer shelter | Apply one external motion contribution through the existing mover. Shelter interrupts the force. Never teleport or bypass collision; give a clear recovery/head approach opportunity |

The requested ascent's one-hit limit applies to a **window**, not damage equal to
one HP. Attack investment may increase that hit's damage. If damage crosses phase
thresholds, play each newly required transition once in order; do not lose a
transition or stack several damaging moves on the same frame. Exact HP and damage
values remain tuning decisions. Whether lethal damage ends the fight immediately
or must respect phase gates should be chosen explicitly before implementation.

Undertow fits the underwater setting and offers a different response from repeated
spike dodges. It should not impose a Dexterity-only gate beyond the boat's stated
requirements. Supply a shelter-based solution for every legal build.

## Phase proposal

The three phases are one `boss_kraken` definition, not three enemy types. Thresholds,
speeds, timings and volley counts are editable data. HP thresholds are not chosen yet.

| Setting | Phase 1 | Phase 2 | Phase 3 |
| --- | --- | --- | --- |
| Global pace (initial tuning proposal) | 1.00 | 1.10 | 1.20 |
| Radial volleys per attack | 1 | 2 | 3 |
| Horizontal sweep rounds | 4 | 4 | 4 |
| Sweep order | Random first lane; alternate | Same, slightly shorter gaps | Same, slightly shorter gaps |
| Tentacle ascent | Teach underside danger/top safety | Stagger descent of two tentacles | Stagger again, preserving a reachable route |
| Undertow, if approved | One direction and obvious shelter | Reverse after a fresh warning | Reverse twice with warnings and reachable shelter |
| Transition ink | None forced before the first phase | Apply once on entry | Apply once on entry |

Do not multiply every timer blindly: acceleration should not erase warning time or
make the tentacle route unreachable. Use independent wind-up, travel and recovery
settings with tested lower bounds. Phase 2 and 3 transition ink guarantees at least
two ink applications by phase 3. A transition should wait for/cancel the current
attack cleanly, neutralise lingering hitboxes, then resume from a safe known pose.

## Ink: one darkness layer, stacking borders

Separate **darkness** from **border occlusion**. On the first ink application set a
black layer to alpha 0.10; later applications do not add more darkness layers or
increase alpha. Increment only the border-stack count, including phase-entry ink.
Use one persistent Canvas overlay with an opaque black texture stretched into
border regions; never allocate a full-screen image every hit or every frame.
A solid black PNG can be generated deterministically at build/import time; there
is no need to generate unique artwork for a uniform colour.

Proposed interpretation for “reduce the borders by 10%”: each stack reduces the
visible width and height by **10% of the original viewport** (5% per side), centred
on Be's combat view. Two stacks leave 80% width and 80% height. This is a proposal,
not a settled rule: reducing each edge by 10% would remove 20% per axis instead.
Choose the exact geometry and a cap before implementation; initial proposal is a
60% minimum visible width/height. Uncapped repeatable ink would eventually hide the
entire fight. HUD, pause/menu, condition prompts and danger telegraphs must remain
readable. Pause freezes the encounter. All ink clears on attempt cleanup.

Prefer camera framing and readable warning indicators so off-screen tentacles
cannot cause unavoidable damage. The visual overlay itself must never change
physics or Be's hitbox. An accessibility option may soften border opacity while
keeping the encounter's warning rhythm; define its progression/scoring policy later.

## Enemy stub and Enemy-tab proposal for review

Use composition around the existing RefCounted update/draw lifecycle. Avoid a new
subclass for every combination and avoid replacing pixel physics while refactoring.

A minimal `EnemyDefinition` describes identity, body/hurtbox, health, capabilities,
motion, selected attacks, consequences and phases. `EnemyInstance` holds mutable
health, current phase/attack, timers and owned-effect handles. `EncounterDefinition`
contains boat/stress/one-time story policy outside the reusable enemy definition.

| Module | Owns | Example |
| --- | --- | --- |
| Motion | Desired displacement/support/path state | Surface patrol, sticky attachment, open/closed path, grounded/flying charge |
| Decision | Eligible selected attacks; range/chance once per decision tick | Kraken picks ascent; Ape picks leap |
| Attack runner | Warning/active/recovery, cancellation, accepted hit window | Ascent can accept one head hit |
| Effect runtime | Attached/spawned hitboxes, projectiles, lifetime and child events | Tentacle underside, log, spike, explosion |
| Phase controller | Threshold crossings, overrides and ordered entry events | Phase 2 ink exactly once |
| Conditions/progress | Read-only queries and explicit state transactions | Held key, quest-dependent death drop, boss defeated |
| Presentation | Animation/audio/ink and environment skins | City-jungle visual references; no save decisions |

Compile/validate definitions when loading or saving, not every physics tick.
Separate selected attacks from consequences before selection, compare squared
ranges, cache stable definitions, and use deterministic injectable randomness.
Query targets at decision points; collision/damage still updates every physics
step. Bound child spawns, summoning population, and graph depth; reject unbounded
cycles. Measure real room profiles before adding pooling or a spatial index.

Proposed Enemy-tab groups (discuss before implementing):

1. **Identity & body**: name, health, hitbox, motion/capabilities.
2. **Phases**: thresholds, explicit overrides, entry events; one enemy page.
3. **Selected attacks**: full names, compact grouped fields, phase-labelled binding
   rows and per-phase priority/range/skip. Keep the redundant right-side phase box
   removed, as requested.
4. **Consequences**: derived effect list and source tooltips; parameters editable,
   no selectable-attack chance checks. Attached effects show owner lifetime.
5. **Preview & validation**: phase/attack preview, readable dependency errors,
   missing assets/conditions and rejected effect loops.

Do not make boat conditions fields on every enemy. Keep CSV rows for flat attack
parameters/bindings; keep nested phases/effect links in a validated JSON profile.
There must be one authoritative source for each field, shared by editor/runtime.
The existing Ape effect chains are specialised; expand their schema with migration
and round-trip tests rather than pretending the general graph already exists.

## Three-stat progression

Dexterity, Constitution and Attack are **working labels** until the user supplies
the final names. Use stable internal IDs; names shown to players can change later.
A limited common point budget creates opportunity costs. Do not assign a point
budget, stat caps, numerical nerfs, or respec cost without a tuning decision.

| Stat | Requested effects | Constraints and proposed treatment |
| --- | --- | --- |
| Dexterity | Movement speed, dash distance, very small jump-height increase, weaker underwater movement at low values | Reduce base movement only after measuring routes. Derive speed/distance from one stat service; do not multiply displacement in several states. Use a small capped jump change to protect level gates |
| Constitution | Stamina recovery, more survivable hits, eligibility for special skills such as dash/quick attack | Separate recovery/capacity/health and ability unlock requirements. A stat enables eligibility; collected power-ups still matter unless deliberately redesigned. Lower starting recovery only after checking early-room safety |
| Attack | More damage and easier boss kills, competing with exploration investment | Damage improves exposed-hit value, not bypassing every encounter mechanic. Support low-damage puzzle/dodge victories. High damage must not be required for mandatory exploration walls |

An Attack-heavy build should make exploration **harder through the point trade-off**,
without accidentally making the critical route impossible. Optional shortcuts may
require Dexterity/Constitution; mandatory checkpoints must be solvable by every
allowed build or allocation must be recoverable before the gate. Keep hard ability
locks distinct from a stat's movement tuning so the progression graph can explain
both. If several stats are combined in a gate, show the actual requirement.

Current hazards/projectiles generally call a lethal contact path rather than a
multi-hit player-health system. “Constitution allows more hits” therefore requires
a real damage-receiving contract: damage amount/type, invulnerability interval,
health depletion and recovery policy. Proposed rule: ordinary attacks consume
health and briefly grant invulnerability; explicitly lethal hazards such as a
bottomless fall keep their authored lethal policy. Keep stamina/energy separate
from health unless the user deliberately chooses a shared resource. This decision
also affects Kraken entry and must be visible in the stat description.

Use a single derived-stat function from base tuning + allocated points + equipment;
movement states/power-ups consume its result. Save allocations and stable unlocked
ability IDs, not already-multiplied speed/damage values. Migrate old saves to a
baseline that preserves their current mobility until the authored route pass is
ready. Do not apply the proposed movement/regen nerfs as part of a title change.

## Delivery and acceptance

1. **Identity**: title/menu/docs renamed; saves and existing levels still resolve.
2. **Design decisions**: settle breathing requirements, ink geometry/cap,
   HP/phase rules, stat names/budget. Review Enemy-tab model before changing it.
3. **Shared mechanics**: complete the architecture plan's trigger/motion/conditions
   slice; expose stable events, IDs and cancellation. Add inventory in the Map menu.
4. **Kraken blockout**: isolated boat fixture, arena, safe tentacle surfaces,
   one-hit head windows and deterministic telegraphs; no art dependency for physics.
5. **Phases/ink**: three phases, ordered transitions, fixed darkness and capped
   border stacking; reset on every exit path. Then art/audio and real boat route.
6. **Stats and authored routes**: measure every affected mandatory jump/dash/water
   segment before changing base tuning. Keep this separate from Kraken plumbing.

Required encounter tests: zero/partial-first-bar energy rejected; full first bar accepted;
higher bars rejected; stress below 250 rejected; missing underwater capability explained;
double interaction starts once; denied entry consumes nothing; opening occurs once
per attempt; tentacle top safe/bottom dangerous; one head hit per window; four sweep
rounds alternate from both starting lanes; radial counts 1/2/3; phase entry ink once
even after large damage; darkness always 0.10; borders stack/cap; all ink/effects
clean up on death/retry/exit; victory/reward persists once; low/high stat builds can
complete the critical path. Add controller/touch and viewport checks to UI tests.

## Manuals and learning material

These are research references, not claims that their authors prescribe our exact
Kraken design. The design above is project-specific synthesis.

- [Godot: scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html): focused responsibilities, ownership and explicit dependencies.
- [Godot: Resources](https://docs.godotengine.org/en/stable/classes/class_resource.html): data definitions separate from runtime actor state.
- [GDQuest: Make a Finite State Machine in Godot 4](https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/): practical tutorial and companion demos; adapt its contracts to our custom mover rather than copying node physics.
- [Game Programming Patterns: decoupling chapters](https://gameprogrammingpatterns.com/decoupling-patterns.html): Component and Event Queue patterns; keep local effect chains local instead of adopting an all-purpose global bus.
- [GDC: Level Design Fundamentals & Techniques](https://www.gdcvault.com/play/1022456/Level-Design-Fundamentals): a level-design lecture reference for the later teaching-room pass.
- [Godot: file paths](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html): why changing the project title can change save locations and how custom directories preserve them.
