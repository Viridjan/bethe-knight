# Remaining work: sequential delivery plan

Prepared 2026-11-10 from TODO.md, the implementation ledger and current design decisions.
This is a delivery order, not a record of implementation. TODO.md remains the active status list.
Work through one numbered item at a time; update its evidence and status before advancing.
Preserve the existing uncommitted work. Do not commit unrelated changes.

## Delivery rules

- Start each item by checking current code/content and existing tests; dated reports are evidence, not fresh defects.
- Deliver the smallest coherent change, its relevant checks and documentation together.
- Run gameplay and smoke scenes for gameplay changes, plus feature-specific checks. Inspect visual changes in-game.
- Run the full verifier at integration milestones. Record actual results and limitations.
- Resolve design dependencies with concrete proposals before implementing dependent behavior.
- Preserve 60 Hz physics/input, integer resource/score policy, existing licenses and save compatibility.
- No new passive stars; ordinary rooms remain compact, with safe passages and exceptional tall arenas.

## Ordered queue

1. **Establish the current baseline.** Inventory modified/untracked files, review the verifier's scope, run it, and separate current failures from already delivered work. Deliver a baseline report with logs and a precise failure list. Complete when every check has a recorded result and any blocker has a reproduction.
2. **Migrate whole-number resources and scores.** Follow WHOLE_NUMBERS_TICK.md: deterministic resource shares; stamina/world/climb; stress/heat; save migration/displays; scores. Keep immediate costs immediate and physics/input precise. Verify rate totals, truncation, stress capacities, save compatibility, resource combinations, HUD and actual refill times. Complete with focused checks, full verification and visual evidence.
3. **Set progression rewards and resource policies.** Propose exact dash/wavedash, climb, double-jump and heat-resistance rewards; Ape reward, village rewards/onward route, wall-grab drain and reusable-refill policy. Record the state at each mandatory gate and prove no reward gates itself. Confirm unresolved choices before dependent map authoring.
4. **Retain the existing upgrade requirements.** The designer has already specified the desired upgrades; do not replace them with a new proposal. Unplaced upgrades are later map work. Preserve existing movement/resource baselines; resolve only a concrete missing runtime contract when its implementation requires it.
5. **Review enemy composition.** Inspect current catalogue/profile authority and Ape controls. Propose a compatible model for conditions, phases, attacks, attached effects, summoners and death actions, with migration examples and editor sketches. Confirm schema/UI decisions before implementation.
6. **Extend cornered detection.** Add ordinary-enemy footprint/context adapters against the agreed attack model. Verify reachable escape space, blocked space, moving attacks and Ape regressions.
7. **Implement general enemy composition.** Deliver conditions/phases, attached weapons/effects, active summoners, then conditional death actions/drops/explosions in independently checked slices. Bound recursive spawning and preserve existing profiles/loadouts.
8. **Implement the agreed damage/stat behavior.** Add shared multi-hit damage and knockback, stat derivation/allocation and whole-number editor/save/HUD values. Verify repeated hits, invulnerability, lethal hits, persistence and affected traversal budgets.
9. **Complete terrain and hazard interactions.** Define pogo eligibility; implement progressive occluded hidden-tile discovery, agreed damage-based tough walls and distinct discovery audio. Preserve punch reveal and existing sword barriers. Verify persistence, hidden boundaries and each attack/hazard combination.
10. **Finish outstanding world interactions.** Complete net capture animation, flexible bridges and lighthouse mirror/flame behavior. Define animation completion/cancellation and save/reset behavior before implementation. Verify escape, death, room/layer transitions and editor authoring.
11. **Complete layer authoring and analysis support.** Add safe rename/removal UI with passage/checkpoint/save handling; extend offline progression/accessibility analysis across layers and conditional variants. Preserve existing layer IDs or migrate them explicitly. Verify dangling links, undo, save/reload and inactive-plane behavior.
12. **Design the full world graph.** Draw irregular clusters, connector branches, secret pockets, coastline and local/regional shortcuts. Label all edges by progression state, one-way rules and dependencies. Preserve useful room IDs and keep mainland/island physically disconnected. Complete with a state-by-state gate/reward table and room inventory.
13. **Build one representative blockout.** Author one compact cluster plus branching connector and shortcut. Measure jump/camera/resource budgets and first/return travel times. Adjust the design before expanding; target substantial first connectors around 45–90 seconds and opened shortcuts at most half that, without padding.
14. **Author mainland loops and village routes.** Shape Meadow/Lake/Cove/Jungle branches, the pre-Ape loop, Treetop Village and safe post-Ape returns around sealed sections. Keep the wavedash gap a later return gate and provide the jump-only onward route. Verify mandatory Ape gating and optional-branch exits.
15. **Author the lighthouse crystal quest loop.** Build an open ruins entrance and at least two compact varied rooms, sword-breakable internal barriers, three unique interactable crystals and a short return. Preserve the delivered keeper/five mages. Verify sword acquisition, unique collection, one-time turn-in and departure unlock from fresh and saved runs.
16. **Author the first crossing.** Place the departure boat, island arrival dock/lighthouse and landmarks. Run the tentacle survival, failure/retry and shipwreck handoff. Verify no usable replacement boat, no walking seam and no accidental bypass of quest/encounter gates.
17. **Author island arrival, marsh and plateau.** Build west-shore/coastal loops, safe thick-water teaching, marsh branches and dodgeable giant-foot encounters with a quieter alternative. Place checkpoints and retreats. Verify the critical path without optional upgrades or giant climbing.
18. **Author maze links and shore satellites.** Fold the underground network, add multiple surface accesses and vent return; build north/south/east areas with at least two rooms each. Keep the Guardian a single tall arena. Verify geographic consistency and progression-safe shortcuts.
19. **Author volcano and later ability routes.** Add cool foothills, short heat previews/retreats, ascent/slope/tunnel cross-links and agreed later rewards. Verify heat budgets, ability gates and return routes without hidden upgrades.
20. **Author discoveries, dialogue and teaching encounters.** Place fragments (three per capacity upgrade), NPC transactions, optional encounters and agreed village rewards. Teach timed spikes, triggers and patrols before combining threats. Replace legacy stars gradually; required quest items must not depend on unmarked secrets.
21. **Develop regional art and identity.** Propose real-world/city-jungle references; produce missing marsh/plateau/ruins art after geometry stabilizes. Update visible legacy protagonist labels while preserving licensed names/save paths. Review art direction before creating final assets and inspect assets in gameplay.
22. **Evaluate spatial/elevation audio.** Research and prototype positional/elevation cues, test readability and accessibility, then implement the selected design. Verify active-layer routing and avoid ambiguous or excessive cues.
23. **Implement later progression/persistence systems separately.** Plan and deliver general story-event graphs, save slots, map stations, per-screen exploration, broader ability presentation and animation-driven state endings as distinct follow-on items. For each, confirm behavior/schema first and test migration/reset/transition cases. Expand this item into individual plans when reached; none is a prerequisite unless explicitly adopted above.
24. **Validate the complete authored chapter.** Check seams, all-edge resizing, variants, layers, safe spawns/checkpoints, quest events and state-specific reachability. Keep isolated movement tests separate from full encounters. Play the critical path without optional upgrades, revisit shortcuts and measure travel times. Fix current reproducible failures and run the full verifier.
25. **Package the reviewed work.** Reconcile TODO/ledger/guides with delivered behavior, retain evidence, review diffs and prepare focused commits containing only attributable work. Use existing public export/deployment configuration when release is requested; deployment is a separate action.

## Deferred choices outside the delivery queue

- Ape phase-two true-form art remains deferred; preserve the original Ape/red pulse runtime.
- Older full Kraken combat, ink/Undertow and a return voyage require separate decisions.
- Reference-game idea catalogues are proposals, not accepted feature scope.
- Private hosting remains undecided; public web export already exists.
- Revisit rejected/deferred optimizations only after fresh profiling demonstrates a need.

## First item: baseline procedure

1. Record current Git status and a diff summary without staging, discarding or committing changes.
2. Read tools/verify.sh and determine which gameplay, smoke, layer, checkpoint, Python and lint checks it runs.
3. Run the verifier into a dated report directory in this project; preserve complete output and exit status.
4. Reproduce failures with the narrowest relevant check. Do not treat old report failures as current failures.
5. Record delivered features, open failures, missing coverage and any environment limitation. Identify whether any baseline failure must be fixed before the integer migration.
6. Report the result, then proceed to item 2 with the working tree preserved.

## Progress

- Point 1 completed 2026-11-10: [baseline report](../../reports/baseline-2026-11-10/README.md). All 41 Godot checks and Python tests passed; both linters passed after an approved retry with uv cache access. The original aggregate run's two environment failures remain recorded. No source changes were required.
- Point 2 completed 2026-11-10: [integer-resource delivery](../../reports/integer-resources-2026-11-10/README.md). Integer resources/scores, twelve-frame continuous accounting, immediate costs, legacy save truncation and integer displays are implemented. Final verifier: 0 failing across 42 Godot checks, Python tests, both linters and diff checks; HUD/F3 capture inspected.
- Point 3 design accepted 2026-11-10: [rewards and resource policies](PROGRESSION_REWARDS.md). Sword moves to a dead skeleton after Sand Cave, climb remains on the opposite village branch, and dash crystals are removed. The remaining proposal was accepted, including one-way shipwreck. Requested runtime/map corrections are in the [delivery report](../../reports/sword-skeleton-2026-11-10/README.md).
- Point 4 steering: use the designer's existing upgrade requirements; unplaced upgrades are added later. No replacement upgrade/stat proposal was created.
- Point 5 review prepared: [enemy composition](ENEMY_COMPOSITION_REVIEW.md), preserving catalogue/profile authority and current Ape controls. Generic schema/UI/runtime changes are not implemented by this review.
- Point 6 delivered: [ordinary ground-charge cornered coverage](../../reports/ordinary-cornered-2026-11-10/README.md) for Hornback and grounded library monsters, real swept footprints, AI context, editor selection and save/reload. Flying/leap/projectile adapters remain conservative/unsupported until corresponding accurate runner models are added.
- Next: point 7, general enemy composition in small supported slices.
