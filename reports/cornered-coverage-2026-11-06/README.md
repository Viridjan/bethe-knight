# Coverage-based Player cornered

Implemented the approved logic in a reusable collision-query helper. The player must be grounded, supported within one tile of the enemy floor, fully between the enemy body and the nearest wall, and every available standing position in that corridor must be hit by the reference attack. Any solid in the first three rows above the floor qualifies as a wall; one-way platforms support floors but are not walls. Gaps and uncovered standing positions reject the condition.

The player-centred candidate tracer is the attack bounds plus two tiles total. It never enlarges damage coverage. Real hit callbacks avoid rectangle-versus-circle corner errors and can represent disjoint coverage; the helper does not infer an attack shape from area alone.

A separate enemy profile/editor setting chooses the coverage attack. The Ape supplies its actual circular scream footprint; retreat leap remains the independently configured reaction in both phases. Unsupported moving attacks are not offered as if they had complete static coverage. The shared helper is reusable, but other enemies still require an accurate footprint/context adapter.

Tests: `cornered_coverage.tscn` covers grounded/airborne and floor-height rules, low/third/fourth-row wall detection, ordering, gaps, circular corners, insufficient real reach despite tracer inclusion, coverage holes, mirrored sides, rectangular adapters and actual Ape retreat execution. It also checks that changing the real scream area affects detection. `ape_attack_triggers.tscn` covers separate coverage UI/save persistence. Both report 0 failures.

Gameplay: 0 failures after updating the old direct-decision fixtures to mark their standing players as grounded. Ape composition: 0 failures. Catalogue: ATTACK CATALOG OK. Smoke: SMOKE OK. GDScript lint and whitespace checks pass. The existing catalogue/composition shutdown resource warnings remain.

`capture.tscn` renders the production settings and reaction rows in `editor.png`. Source story room edits were preserved.
