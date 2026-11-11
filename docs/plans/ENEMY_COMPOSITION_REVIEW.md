# Point 5: enemy composition review

Reviewed 2026-11-10 against current runtime, catalogue, editor and regression scenes. This is an implementation plan; no enemy schema, gameplay or UI was changed. Existing upgrade requirements are retained and unplaced upgrades remain later map work.

**Recommendation:** extend the working catalogue/profile system in small steps. Keep the current Ape editor and behavior as the compatibility reference.

## What exists and where it stops

| Area | Current source / behavior | Missing extension |
| --- | --- | --- |
| Attack values | `data/attacks.csv`, read/validated by `scripts/attack_catalog.gd` | New attack runners need explicit capability registration; a row alone does not make an enemy execute it |
| Attack selection | `data/enemy_attacks.csv`: priority, ranges, skip cooldowns, selected/triggered separation | Phase names and non-default decision conditions are currently restricted to the Ape |
| Health | `scripts/actors/enemy_health.gd`: shared family HP and variant modifiers | General phase/composition definitions; variants must still modify base health exactly once |
| Ape phases/effects | `data/enemy_profiles.json`; `effect_links()` derives the editor's consequences from those same references | `effect_links()` returns nothing for other enemies; profile validation explicitly allows only current Ape effect IDs |
| Detached effects | `scripts/effects/attack_effects.gd`: swept projectiles, bounded two-child splits, areas and emitted impact events | Reusable attached weapons, active summoning and general effect event dispatch |
| Death behavior | `CombatEnemy.hit()` has a once-only lethal transition; `death_actions.gd` produces brood children through World’s spawn queue | Conditional drops, arbitrary death actions, explosion handling and shared live-child budgets |
| Enemy editor | `scripts/attack_catalog_editor.gd`: family HP, Ape threshold/entry controls, compact phase-labelled attack rows and derived consequence tooltips | General conditions/phases, attachment/spawn/death configuration and capability-aware add controls |

These are extension boundaries, not newly reproduced gameplay defects. In particular, shared health, patrols, brood spawning and the Ape effect chains are already implemented.

## Keep one owner for every value

- **Attack CSV:** stable attack IDs, measured geometry/timing/trajectory values and the existing flat follow-up fields.
- **Binding CSV:** enemy/phase selection, range, priority, skip policy and a condition reference. Triggered consequences never enter selection.
- **Enemy profile JSON:** health/phase definitions, structured condition trees, effect event links, attachments, summon budgets and death/drop entries. Expand the existing profile file rather than adding competing enemy/phase CSV tables from older proposals.
- **Room entity:** position, stable placed-object ID, patrol path and explicit instance overrides. Do not copy the entire family definition into each room.
- **Runtime instance:** HP, action state, combat phase, timers, once-only event latches, owned effect/child handles and cooldowns. Shared definitions are snapshots during an attack.

Recommend a versioned profile extension, compiled into one validated runtime definition. Version-1 profiles compile through adapters. Keep the Ape's current profile keys authoritative while its existing controls remain in use; do not write a second generic copy of its landing/throw/impact chains. Existing CSV follow-ups likewise compile once; a generic event link must not duplicate the same follow-up. Any eventual storage migration replaces one representation with the other in one validated save.

## Runtime responsibilities

1. **Conditions:** bounded `all` / `any` / `not` plus existing player-context facts and named progress/item/quest predicates. Read supplied context; no free-form scripts or save mutation. Cheap range/phase checks precede costly geometry; ordinary-enemy cornered facts need real footprint adapters (point 6).
2. **Phases:** separate combat phase from action strings such as `windup` or `air`. Preserve the Ape's threshold and once-only entry sequence. Death takes precedence over phase entry. Define crossing/cancellation order explicitly before supporting arbitrary multi-phase profiles.
3. **Selected attacks:** priority order, actual family capabilities, eligibility and existing skip cooldowns. A skipped attack is not rerolled every frame. Do not expose a combination as executable until its runner exists.
4. **Consequences:** dispatch named events such as release, landing, apex split and floor impact after iteration. Reuse the same ordinary-log impact result for thrown, falling and split children. Enforce finite counts/depth and reject unbounded chains.
5. **Attached weapons:** owner anchor/facing, local shape, wind-up/active/recovery window and cancellation policy. Owner death, reset and layer/room exit release their hitboxes. Sword/tongue/flame shapes share lifetime infrastructure without sharing one forced silhouette.
6. **Summons:** explicit family, placement policy, cooldown, maximum live children and encounter ownership. Check valid spawn space; queued and live children both count toward the budget. Retry failure through a cooldown, not a per-frame spawn loop. Release reservations on cancellation/failure.
7. **Death actions:** one committed death event; evaluate conditions once, then queue drops/spawns/explosions. Persist unique drops by stable source/reward IDs. Brood children retain their non-recursive restriction. An armed explosion and an on-death explosion must not both fire for the same event.

All collision, active hit windows, fuse checks and movement stay at 60 Hz with normal precision. Resources/HP/counts/scores remain whole numbers. This work does not invent new damage/stat formulas or change current contact lethality.

## Enemy tab: extend the current page

```text
Enemy name + current preview
Health & phase entry             existing Ape controls retained
Motion                          existing patrol controls
Attack order                    existing compact rows, phase tags, range/skip/trigger
Consequences                    derived source → event → effect; editable source parameters
Attached effects / Summons      shown only when configured or explicitly added
On death                        conditions, drop/spawn/explosion and once-only policy
Validation                      actionable errors; affected source field and reference
```

Keep full attack names, the removed redundant phase box removed, lazy previews, dirty/save behavior, current per-phase controls and web exclusion. A shared attack edit must make its shared scope clear; cloning creates a new stable ID. Do not replace the current page with a generic graph editor.

Scores stay with the current calculator. Preserve integer totals and the existing “consequence totals pending” distinction; do not silently sum attached effects, summons or persistent hazards into a fabricated combat score. A new consequence-scoring model is separate work.

## Small implementation slices

1. Add the profile compiler/validation layer and legacy adapters without changing encounter behavior. Validate references, capabilities, conditions, phase IDs and bounded event graphs before accepting a save.
2. Prove general conditions and a two-phase loadout with one disposable ordinary-enemy fixture using an existing attack. Keep existing Ape UI/tests unchanged.
3. Add one attached weapon fixture and its cancellation/ownership checks.
4. Add a summoner fixture using the existing queued-spawn path and explicit population bounds.
5. Generalize once-only death actions from brood, then add conditional item drops and one explosion fixture.
6. Expose each supported capability in the existing editor only after its runtime round-trip works. Preserve catalogue rollback if any CSV/profile write fails.

Do not create new story rooms or upgrade rewards for these fixtures. Keep the current movement classes/adapters until parity tests support extracting them.

## Acceptance evidence

Fresh runs are recorded in [the review report](../../reports/enemy-composition-2026-11-10/README.md). Existing Ape composition, ordinary-enemy foundations, attack triggers and catalogue rollback are the initial regression baseline.

Future implementation must additionally demonstrate: ordinary phase/condition execution; truthful capability filtering; no duplicate landing/impact/death events; attached-hitbox cleanup; simultaneous summon reservations respecting caps; blocked-spawn failure recovery; once-only saved drops; no brood recursion; rejected cycles/dangling references; editor undo/save/reload and rollback; unchanged Ape gates, aftermath and inactive-layer behavior.

Review complete. Generic schema/UI changes are recommendations for point 7, not changes already applied. Next is point 6: ordinary-enemy cornered coverage using real attack footprints.
